import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:weight_record/db/weight_record_repository.dart';
import 'package:weight_record/models/weight_record.dart';
import 'package:weight_record/pages/home_page.dart';
import 'package:weight_record/services/photo_store.dart';

class _FakeRepository implements WeightRecordRepository {
  _FakeRepository(this._records);

  final List<WeightRecord> _records;
  int getAllCalls = 0;
  bool fail = false;

  @override
  Future<int> insert(WeightRecord record) async => 0;

  @override
  Future<List<WeightRecord>> getAll({bool ascending = false}) async {
    getAllCalls++;
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
  @override
  Future<void> deletePhoto(String fileName) async {}

  @override
  Future<String> photoFullPath(String fileName) async => 'x';
}

WeightRecord rec(int id, double kg, DateTime at) =>
    WeightRecord(id: id, weightKg: kg, recordedAt: at);

void main() {
  final DateTime t1 = DateTime(2026, 8, 30, 8, 0);
  final DateTime t2 = DateTime(2026, 8, 31, 8, 0);

  Future<void> pumpHome(
    WidgetTester tester, {
    required WeightRecordRepository repository,
    WidgetBuilder? photoCompareBuilder,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: HomePage(
          repository: repository,
          photoStore: _FakePhotoStore(),
          photoCompareBuilder: photoCompareBuilder ??
              (_) => Scaffold(body: Text('照片对比桩')),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  testWidgets('有记录时显示折线图与查看变化按钮', (tester) async {
    final _FakeRepository repo = _FakeRepository(<WeightRecord>[
      rec(1, 65.5, t1),
      rec(2, 66.0, t2),
    ]);
    await pumpHome(tester, repository: repo);

    expect(find.byType(LineChart), findsOneWidget);
    final LineChart chart = tester.widget<LineChart>(find.byType(LineChart));
    expect(chart.data.lineBarsData.single.spots, hasLength(2));
    expect(find.text('体重趋势（kg）'), findsOneWidget);
    expect(find.text('查看变化'), findsOneWidget);
  });

  testWidgets('空记录时显示引导文案，不显示折线图', (tester) async {
    final _FakeRepository repo = _FakeRepository(<WeightRecord>[]);
    await pumpHome(tester, repository: repo);

    expect(find.text('还没有体重记录'), findsOneWidget);
    expect(find.text('去「我的」页面添加第一条记录吧'), findsOneWidget);
    expect(find.byType(LineChart), findsNothing);
    expect(find.text('查看变化'), findsOneWidget);
  });

  testWidgets('加载失败显示错误并可重试', (tester) async {
    final _FakeRepository repo = _FakeRepository(<WeightRecord>[
      rec(1, 65.5, t1),
    ])..fail = true;
    await pumpHome(tester, repository: repo);

    expect(find.textContaining('加载失败'), findsOneWidget);

    repo.fail = false;
    await tester.tap(find.text('重试'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(LineChart), findsOneWidget);
  });

  testWidgets('点击查看变化跳转到照片对比页', (tester) async {
    final _FakeRepository repo = _FakeRepository(<WeightRecord>[
      rec(1, 65.5, t1),
    ]);
    await pumpHome(tester, repository: repo);

    await tester.tap(find.text('查看变化'));
    await tester.pumpAndSettle();

    expect(find.text('照片对比桩'), findsOneWidget);
  });
}
