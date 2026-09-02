import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:weight_record/db/database_helper.dart';
import 'package:weight_record/models/weight_record.dart';

void main() {
  late Directory tempDir;
  late DatabaseHelper helper;
  late String dbPath;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('wr_db_test_');
    dbPath = p.join(tempDir.path, 'test.db');
    helper = DatabaseHelper(overridePath: dbPath);
  });

  tearDown(() async {
    await helper.close();
    await tempDir.delete(recursive: true);
  });

  WeightRecord makeRecord({
    double weight = 65.5,
    DateTime? at,
    String? photoPath,
    bool compressed = false,
  }) {
    return WeightRecord(
      weightKg: weight,
      recordedAt: at ?? DateTime(2026, 8, 31, 8, 30),
      photoPath: photoPath,
      compressed: compressed,
    );
  }

  test('insert 后 getAll 能取回完整字段', () async {
    final id = await helper.insert(makeRecord(
      weight: 65.5,
      at: DateTime(2026, 8, 31, 8, 30),
      photoPath: 'a.jpg',
      compressed: true,
    ));
    expect(id, greaterThan(0));

    final records = await helper.getAll();
    expect(records, hasLength(1));
    final record = records.first;
    expect(record.id, id);
    expect(record.weightKg, 65.5);
    expect(record.recordedAt, DateTime(2026, 8, 31, 8, 30));
    expect(record.photoPath, 'a.jpg');
    expect(record.compressed, isTrue);
  });

  test('getAll 默认按时间倒序，ascending 时正序', () async {
    await helper.insert(makeRecord(weight: 60, at: DateTime(2026, 1, 1)));
    await helper.insert(makeRecord(weight: 70, at: DateTime(2026, 6, 1)));
    await helper.insert(makeRecord(weight: 80, at: DateTime(2026, 12, 1)));

    final desc = await helper.getAll();
    expect(desc.map((r) => r.weightKg).toList(), [80, 70, 60]);

    final asc = await helper.getAll(ascending: true);
    expect(asc.map((r) => r.weightKg).toList(), [60, 70, 80]);
  });

  test('getById 命中与未命中', () async {
    final id = await helper.insert(makeRecord(weight: 66));
    final found = await helper.getById(id);
    expect(found, isNotNull);
    expect(found!.weightKg, 66);

    expect(await helper.getById(99999), isNull);
  });

  test('delete 后记录消失', () async {
    final id = await helper.insert(makeRecord());
    expect(await helper.delete(id), 1);
    expect(await helper.getAll(), isEmpty);
    expect(await helper.getById(id), isNull);
  });

  test('关闭并重新打开数据库后数据仍在（持久化）', () async {
    await helper.insert(makeRecord(weight: 71.5));
    await helper.close();

    final reopened = DatabaseHelper(overridePath: dbPath);
    final records = await reopened.getAll();
    expect(records, hasLength(1));
    expect(records.first.weightKg, 71.5);
    await reopened.close();
  });
}