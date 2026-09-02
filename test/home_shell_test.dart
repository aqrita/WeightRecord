import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:weight_record/db/weight_record_repository.dart';
import 'package:weight_record/main.dart';
import 'package:weight_record/models/weight_record.dart';
import 'package:weight_record/services/photo_store.dart';

class _FakeRepository implements WeightRecordRepository {
  _FakeRepository(this._records);

  final List<WeightRecord> _records;
  int getAllCalls = 0;

  @override
  Future<int> insert(WeightRecord record) async => 0;

  @override
  Future<List<WeightRecord>> getAll({bool ascending = false}) async {
    getAllCalls++;
    return List<WeightRecord>.of(_records);
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

void main() {
  final _FakeRepository repo = _FakeRepository(<WeightRecord>[
    WeightRecord(
      id: 1,
      weightKg: 65.5,
      recordedAt: DateTime(2026, 8, 31, 10, 30),
    ),
  ]);

  testWidgets('默认显示首页折线图，底部导航可切换并触发首页刷新', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: HomeShell(repository: repo, photoStore: _FakePhotoStore()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // 初始为首页：折线图可见
    expect(find.byType(LineChart), findsOneWidget);
    expect(find.text('首页'), findsOneWidget);
    expect(find.text('我的'), findsOneWidget);

    // 切到「我的」：出现记录入口
    await tester.tap(find.text('我的'));
    await tester.pumpAndSettle();
    expect(find.text('记录体重'), findsOneWidget);
    expect(find.text('查看记录'), findsOneWidget);

    // 切回「首页」：重新加载数据
    await tester.tap(find.text('首页'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(LineChart), findsOneWidget);
    expect(repo.getAllCalls, 2);
  });
}
