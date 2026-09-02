import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:weight_record/db/database_helper.dart';
import 'package:weight_record/db/weight_record_repository.dart';
import 'package:weight_record/models/weight_record.dart';
import 'package:weight_record/services/photo_service.dart';
import 'package:weight_record/services/record_service.dart';

/// 记录 insert 调用的假仓库。
class _RecordingRepository implements WeightRecordRepository {
  final List<WeightRecord> inserted = <WeightRecord>[];

  @override
  Future<int> insert(WeightRecord record) async {
    inserted.add(record);
    return 1;
  }

  @override
  Future<List<WeightRecord>> getAll({bool ascending = true}) async =>
      List<WeightRecord>.of(inserted);

  @override
  Future<WeightRecord?> getById(int id) async => null;

  @override
  Future<int> delete(int id) async => 0;
}

/// insert 永远失败的假仓库。
class _FailingRepository implements WeightRecordRepository {
  @override
  Future<int> insert(WeightRecord record) async => throw Exception('db down');

  @override
  Future<List<WeightRecord>> getAll({bool ascending = true}) async =>
      <WeightRecord>[];

  @override
  Future<WeightRecord?> getById(int id) async => null;

  @override
  Future<int> delete(int id) async => 0;
}

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfiNoIsolate;
  });

  final DateTime fixedTime = DateTime(2026, 8, 31, 9, 15);
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('wr_record_service_');
  });

  tearDown(() async {
    try {
      await tempDir.delete(recursive: true);
    } catch (_) {
      // Windows 上偶发占用，测试结果不受影响。
    }
  });

  Future<File> makePhoto({int width = 2400, int height = 1800}) async {
    final img.Image image = img.Image(width: width, height: height);
    img.fill(image, color: img.ColorRgb8(30, 60, 90));
    final File file = File(p.join(tempDir.path, 'source.png'));
    await file.writeAsBytes(img.encodePng(image));
    return file;
  }

  RecordService realService(DatabaseHelper db) => RecordService(
        repository: DatabaseWeightRecordRepository(dbHelper: db),
        photoService: PhotoService(baseDirectory: tempDir),
      );

  test('带照片且压缩：写入数据库并保存压缩文件', () async {
    final DatabaseHelper db =
        DatabaseHelper(overridePath: p.join(tempDir.path, 'test.db'));
    final RecordService service = realService(db);
    final File photo = await makePhoto();

    await service.save(
      weightKg: 70,
      recordedAt: fixedTime,
      photoPath: photo.path,
      compress: true,
    );

    final List<WeightRecord> records = await db.getAll();
    expect(records, hasLength(1));
    expect(records.first.weightKg, 70);
    expect(records.first.recordedAt, fixedTime);
    expect(records.first.photoPath, isNotNull);
    expect(records.first.compressed, isTrue);

    final File saved = File(
      p.join(
        tempDir.path,
        PhotoService.photosDirName,
        records.first.photoPath!,
      ),
    );
    expect(saved.existsSync(), isTrue);
    final img.Image? decoded = img.decodeJpg(await saved.readAsBytes());
    expect(decoded, isNotNull);
    expect(decoded!.width, 1920); // 长边压缩到 1920
    expect(decoded.height, 1440);
    await db.close();
  });

  test('无照片记录正常保存且 compressed 为 false', () async {
    final DatabaseHelper db =
        DatabaseHelper(overridePath: p.join(tempDir.path, 'test.db'));
    final RecordService service = realService(db);

    await service.save(
      weightKg: 60.5,
      recordedAt: fixedTime,
      photoPath: null,
      compress: true,
    );

    final List<WeightRecord> records = await db.getAll();
    expect(records, hasLength(1));
    expect(records.first.photoPath, isNull);
    expect(records.first.compressed, isFalse);
    await db.close();
  });

  test('不压缩时原样保存', () async {
    final DatabaseHelper db =
        DatabaseHelper(overridePath: p.join(tempDir.path, 'test.db'));
    final RecordService service = realService(db);
    final File photo = await makePhoto(width: 800, height: 600);

    await service.save(
      weightKg: 66.6,
      recordedAt: fixedTime,
      photoPath: photo.path,
      compress: false,
    );

    final List<WeightRecord> records = await db.getAll();
    expect(records, hasLength(1));
    expect(records.first.compressed, isFalse);
    final File saved = File(
      p.join(
        tempDir.path,
        PhotoService.photosDirName,
        records.first.photoPath!,
      ),
    );
    expect(await saved.readAsBytes(), await photo.readAsBytes());
    await db.close();
  });

  test('照片源文件不存在时不写入数据库', () async {
    final _RecordingRepository repo = _RecordingRepository();
    final RecordService service = RecordService(
      repository: repo,
      photoService: PhotoService(baseDirectory: tempDir),
    );

    await expectLater(
      service.save(
        weightKg: 70,
        recordedAt: fixedTime,
        photoPath: p.join(tempDir.path, 'missing.png'),
        compress: true,
      ),
      throwsA(isA<FileSystemException>()),
    );
    expect(repo.inserted, isEmpty);
  });

  test('数据库写入失败时清理已保存的照片', () async {
    final RecordService service = RecordService(
      repository: _FailingRepository(),
      photoService: PhotoService(baseDirectory: tempDir),
    );
    final File photo = await makePhoto(width: 400, height: 300);

    await expectLater(
      service.save(
        weightKg: 70,
        recordedAt: fixedTime,
        photoPath: photo.path,
        compress: true,
      ),
      throwsException,
    );

    final Directory photosDir =
        Directory(p.join(tempDir.path, PhotoService.photosDirName));
    expect(photosDir.existsSync(), isTrue);
    expect(photosDir.listSync(), isEmpty);
  });
}
