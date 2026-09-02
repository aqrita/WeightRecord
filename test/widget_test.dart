import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:weight_record/db/weight_record_repository.dart';
import 'package:weight_record/main.dart';
import 'package:weight_record/models/weight_record.dart';
import 'package:weight_record/services/photo_store.dart';

class _FakeRepository implements WeightRecordRepository {
  _FakeRepository([List<WeightRecord>? records])
      : _records = List<WeightRecord>.of(records ?? <WeightRecord>[]);

  final List<WeightRecord> _records;

  @override
  Future<int> insert(WeightRecord record) async => 0;

  @override
  Future<List<WeightRecord>> getAll({bool ascending = false}) async =>
      List<WeightRecord>.of(_records);

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
  testWidgets('App 冒烟测试：启动渲染首页与底部导航，可切换到我的页', (tester) async {
    await tester.pumpWidget(
      MyApp(repository: _FakeRepository(), photoStore: _FakePhotoStore()),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // 首页：标题、空数据引导、底部导航
    expect(find.text('体重记录'), findsOneWidget);
    expect(find.text('还没有体重记录'), findsOneWidget);
    expect(find.text('首页'), findsOneWidget);
    expect(find.text('我的'), findsOneWidget);

    // 切到「我的」：出现两个入口
    await tester.tap(find.text('我的'));
    await tester.pumpAndSettle();
    expect(find.text('记录体重'), findsOneWidget);
    expect(find.text('查看记录'), findsOneWidget);
  });

  testWidgets('App 冒烟测试：首页有数据时渲染折线图', (tester) async {
    await tester.pumpWidget(
      MyApp(
        repository: _FakeRepository(<WeightRecord>[
          WeightRecord(
            id: 1,
            weightKg: 65.5,
            recordedAt: DateTime(2026, 8, 31, 10, 30),
          ),
        ]),
        photoStore: _FakePhotoStore(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(LineChart), findsOneWidget);
    expect(find.text('查看变化'), findsOneWidget);
  });
}
