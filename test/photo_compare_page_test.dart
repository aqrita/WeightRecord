import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:weight_record/db/weight_record_repository.dart';
import 'package:weight_record/models/weight_record.dart';
import 'package:weight_record/pages/photo_compare_page.dart';
import 'package:weight_record/services/photo_store.dart';

class _FakeRepository implements WeightRecordRepository {
  _FakeRepository(this._records);

  final List<WeightRecord> _records;
  bool fail = false;

  @override
  Future<int> insert(WeightRecord record) async => 0;

  @override
  Future<List<WeightRecord>> getAll({bool ascending = false}) async {
    if (fail) throw Exception('db read error');
    final List<WeightRecord> sorted = List<WeightRecord>.of(_records);
    sorted.sort((WeightRecord a, WeightRecord b) => ascending
        ? a.recordedAt.compareTo(b.recordedAt)
        : b.recordedAt.compareTo(a.recordedAt));
    return sorted;
  }

  @override
  Future<WeightRecord?> getById(int id) async => null;

  @override
  Future<int> delete(int id) async => 0;
}

class _FakePhotoStore implements PhotoStore {
  _FakePhotoStore(this.fullPath);

  final String fullPath;

  @override
  Future<void> deletePhoto(String fileName) async {}

  @override
  Future<String> photoFullPath(String fileName) async => fullPath;
}

WeightRecord rec(int id, double kg, DateTime at, {String? photo}) =>
    WeightRecord(
      id: id,
      weightKg: kg,
      recordedAt: at,
      photoPath: photo,
    );

void main() {
  final DateTime t1 = DateTime(2026, 8, 30, 8, 0);
  final DateTime t2 = DateTime(2026, 8, 31, 8, 0);

  late Directory tempDir;
  late File photoFile;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('wr_photo_compare_');
    final img.Image image = img.Image(width: 100, height: 80);
    img.fill(image, color: img.ColorRgb8(10, 120, 200));
    photoFile = File(p.join(tempDir.path, 'photo.png'));
    await photoFile.writeAsBytes(img.encodePng(image));
  });

  tearDown(() async {
    try {
      await tempDir.delete(recursive: true);
    } catch (_) {
      // Windows 上偶发占用，测试结果不受影响。
    }
  });

  Future<void> pumpCompare(
    WidgetTester tester, {
    required WeightRecordRepository repository,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: PhotoComparePage(
          repository: repository,
          photoStore: _FakePhotoStore(photoFile.path),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  testWidgets('按时间升序展示带照片记录（第一页为最早记录）', (tester) async {
    final _FakeRepository repo = _FakeRepository(<WeightRecord>[
      rec(2, 66.0, t2, photo: 'b.jpg'),
      rec(1, 65.5, t1, photo: 'a.jpg'),
    ]);
    await pumpCompare(tester, repository: repo);

    expect(find.byType(PageView), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);
    // 最早记录在第一页
    expect(find.text('2026-08-30 08:00 · 65.5 kg'), findsOneWidget);
  });

  testWidgets('向左滑动切换到下一条记录', (tester) async {
    final _FakeRepository repo = _FakeRepository(<WeightRecord>[
      rec(1, 65.5, t1, photo: 'a.jpg'),
      rec(2, 66.0, t2, photo: 'b.jpg'),
    ]);
    await pumpCompare(tester, repository: repo);

    expect(find.text('2026-08-30 08:00 · 65.5 kg'), findsOneWidget);

    await tester.drag(find.byType(PageView), const Offset(-500, 0));
    await tester.pumpAndSettle();

    expect(find.text('2026-08-31 08:00 · 66.0 kg'), findsOneWidget);
  });

  testWidgets('没有带照片记录时显示提示', (tester) async {
    final _FakeRepository repo = _FakeRepository(<WeightRecord>[
      rec(1, 65.5, t1), // 无照片
    ]);
    await pumpCompare(tester, repository: repo);

    expect(find.textContaining('暂无照片'), findsOneWidget);
    expect(find.byType(PageView), findsNothing);
  });

  testWidgets('空记录时显示提示', (tester) async {
    final _FakeRepository repo = _FakeRepository(<WeightRecord>[]);
    await pumpCompare(tester, repository: repo);

    expect(find.textContaining('暂无照片'), findsOneWidget);
  });

  testWidgets('加载失败显示错误并可重试', (tester) async {
    final _FakeRepository repo = _FakeRepository(<WeightRecord>[
      rec(1, 65.5, t1, photo: 'a.jpg'),
    ])..fail = true;
    await pumpCompare(tester, repository: repo);

    expect(find.textContaining('加载失败'), findsOneWidget);

    repo.fail = false;
    await tester.tap(find.text('重试'));
    await tester.pump();
    await tester.pump();

    expect(find.byType(PageView), findsOneWidget);
    expect(find.text('2026-08-30 08:00 · 65.5 kg'), findsOneWidget);
  });
}
