import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:weight_record/db/weight_record_repository.dart';
import 'package:weight_record/models/weight_record.dart';
import 'package:weight_record/pages/history_page.dart';
import 'package:weight_record/services/photo_store.dart';

class _FakeRepository implements WeightRecordRepository {
  _FakeRepository(List<WeightRecord> records) : _records = List.of(records);

  final List<WeightRecord> _records;
  final List<int> deletedIds = <int>[];
  bool failGetAll = false;
  bool failDelete = false;

  @override
  Future<int> insert(WeightRecord record) async {
    _records.add(record);
    return _records.length;
  }

  @override
  Future<List<WeightRecord>> getAll({bool ascending = false}) async {
    if (failGetAll) throw Exception('db read error');
    final List<WeightRecord> sorted = List.of(_records);
    sorted.sort((a, b) => ascending
        ? a.recordedAt.compareTo(b.recordedAt)
        : b.recordedAt.compareTo(a.recordedAt));
    return sorted;
  }

  @override
  Future<WeightRecord?> getById(int id) async => null;

  @override
  Future<int> delete(int id) async {
    if (failDelete) throw Exception('db delete error');
    deletedIds.add(id);
    _records.removeWhere((WeightRecord r) => r.id == id);
    return 1;
  }
}

class _FakePhotoStore implements PhotoStore {
  _FakePhotoStore(this.fullPath);

  final String fullPath;
  final List<String> deleted = <String>[];

  @override
  Future<void> deletePhoto(String fileName) async {
    deleted.add(fileName);
  }

  @override
  Future<String> photoFullPath(String fileName) async => fullPath;
}

void main() {
  final DateTime t1 = DateTime(2026, 8, 31, 10, 30);
  final DateTime t2 = DateTime(2026, 8, 30, 8, 5);

  WeightRecord rec(int id, double kg, DateTime at, {String? photo}) =>
      WeightRecord(
        id: id,
        weightKg: kg,
        recordedAt: at,
        photoPath: photo,
        compressed: photo != null,
      );

  late Directory tempDir;
  late File photoFile;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('wr_history_page_');
    final img.Image image = img.Image(width: 40, height: 40);
    img.fill(image, color: img.ColorRgb8(200, 100, 50));
    photoFile = File(p.join(tempDir.path, 'thumb.png'));
    await photoFile.writeAsBytes(img.encodePng(image));
  });

  tearDown(() async {
    try {
      await tempDir.delete(recursive: true);
    } catch (_) {
      // Windows 上偶发占用，测试结果不受影响。
    }
  });

  Future<void> pumpHistory(
    WidgetTester tester, {
    required WeightRecordRepository repository,
    PhotoStore? photoStore,
    WidgetBuilder? recordPageBuilder,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: HistoryPage(
          repository: repository,
          photoStore: photoStore ?? _FakePhotoStore(photoFile.path),
          recordPageBuilder:
              recordPageBuilder ?? (_) => Scaffold(body: Text('新增桩')),
        ),
      ),
    );
    await tester.pump(); // 触发加载
    await tester.pump();
  }

  testWidgets('展示记录列表：时间、体重与照片缩略图', (tester) async {
    final _FakeRepository repo = _FakeRepository(<WeightRecord>[
      rec(1, 65.5, t1, photo: 'photo_1.jpg'),
      rec(2, 66.2, t2),
    ]);
    await pumpHistory(tester, repository: repo);

    expect(find.text('65.5 kg'), findsOneWidget);
    expect(find.text('2026-08-31 10:30'), findsOneWidget);
    expect(find.text('66.2 kg'), findsOneWidget);
    expect(find.text('2026-08-30 08:05'), findsOneWidget);
    // 只有带照片的记录显示缩略图
    expect(find.byType(Image), findsOneWidget);
  });

  testWidgets('空列表显示引导文案', (tester) async {
    final _FakeRepository repo = _FakeRepository(<WeightRecord>[]);
    await pumpHistory(tester, repository: repo);

    expect(find.textContaining('暂无记录'), findsOneWidget);
  });

  testWidgets('加载失败显示错误与重试', (tester) async {
    final _FakeRepository repo = _FakeRepository(<WeightRecord>[])
      ..failGetAll = true;
    await pumpHistory(tester, repository: repo);

    expect(find.textContaining('加载失败'), findsOneWidget);

    repo.failGetAll = false;
    await tester.tap(find.text('重试'));
    await tester.pump();
    await tester.pump();

    expect(find.textContaining('暂无记录'), findsOneWidget);
  });

  testWidgets('删除记录：确认后删除数据库记录与照片', (tester) async {
    final _FakeRepository repo = _FakeRepository(<WeightRecord>[
      rec(1, 65.5, t1, photo: 'photo_1.jpg'),
      rec(2, 66.2, t2),
    ]);
    final _FakePhotoStore photoStore = _FakePhotoStore(photoFile.path);
    await pumpHistory(tester, repository: repo, photoStore: photoStore);

    await tester.tap(find.byIcon(Icons.delete_outline).first);
    await tester.pumpAndSettle();

    expect(find.text('删除记录'), findsOneWidget); // 确认框出现
    await tester.tap(find.text('删除'));
    await tester.pumpAndSettle();

    expect(repo.deletedIds, <int>[1]);
    expect(photoStore.deleted, <String>['photo_1.jpg']);
    expect(find.text('65.5 kg'), findsNothing); // 列表已刷新
    expect(find.text('66.2 kg'), findsOneWidget);
  });

  testWidgets('点击新增跳转到记录页', (tester) async {
    final _FakeRepository repo = _FakeRepository(<WeightRecord>[]);
    await pumpHistory(
      tester,
      repository: repo,
      recordPageBuilder: (_) => Scaffold(body: Text('新增桩')),
    );

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    expect(find.text('新增桩'), findsOneWidget);
  });

  testWidgets('删除失败时提示错误', (tester) async {
    final _FakeRepository repo = _FakeRepository(<WeightRecord>[
      rec(1, 65.5, t1),
    ])..failDelete = true;
    await pumpHistory(tester, repository: repo);

    await tester.tap(find.byIcon(Icons.delete_outline).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('删除'));
    await tester.pumpAndSettle();

    expect(find.textContaining('删除失败'), findsOneWidget);
    expect(repo.deletedIds, isEmpty);

    // 等待 SnackBar 自动关闭，避免遗留定时器。
    await tester.pump(const Duration(seconds: 5));
    await tester.pump(const Duration(seconds: 1));
  });
}
