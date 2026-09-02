import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:weight_record/charts/weight_chart.dart';
import 'package:weight_record/models/weight_record.dart';

WeightRecord rec(double kg, DateTime at) =>
    WeightRecord(weightKg: kg, recordedAt: at);

void main() {
  test('按时间升序生成坐标点（X=毫秒时间戳，Y=体重）', () {
    final DateTime t1 = DateTime(2026, 8, 30, 8, 0);
    final DateTime t2 = DateTime(2026, 8, 31, 8, 0);
    final DateTime t3 = DateTime(2026, 9, 1, 8, 0);
    final LineChartData data = buildWeightLineChart(<WeightRecord>[
      rec(66.5, t2),
      rec(65.0, t3),
      rec(67.0, t1),
    ]);

    final List<FlSpot> spots = data.lineBarsData.single.spots;
    expect(spots, hasLength(3));
    expect(spots[0].x, t1.millisecondsSinceEpoch.toDouble());
    expect(spots[0].y, 67.0);
    expect(spots[1].x, t2.millisecondsSinceEpoch.toDouble());
    expect(spots[1].y, 66.5);
    expect(spots[2].x, t3.millisecondsSinceEpoch.toDouble());
    expect(spots[2].y, 65.0);
  });

  test('单条记录：X 轴两侧扩展，Y 轴带边距', () {
    final DateTime t = DateTime(2026, 8, 31, 10, 0);
    final LineChartData data = buildWeightLineChart(<WeightRecord>[rec(70.0, t)]);

    final FlSpot spot = data.lineBarsData.single.spots.single;
    expect(spot.x, t.millisecondsSinceEpoch.toDouble());
    expect(data.minX, lessThan(spot.x));
    expect(data.maxX, greaterThan(spot.x));
    expect(data.minY, lessThan(70.0));
    expect(data.maxY, greaterThan(70.0));
  });

  test('空记录：无折线数据且不抛异常', () {
    final LineChartData data = buildWeightLineChart(<WeightRecord>[]);
    expect(data.lineBarsData, isEmpty);
  });

  test('Y 轴范围基于数据上下各留 2kg 边距', () {
    final LineChartData data = buildWeightLineChart(<WeightRecord>[
      rec(65.0, DateTime(2026, 8, 1)),
      rec(68.0, DateTime(2026, 8, 2)),
    ]);
    expect(data.minY, 63.0);
    expect(data.maxY, 70.0);
  });

  test('底部与左侧坐标轴标题开启', () {
    final LineChartData data = buildWeightLineChart(<WeightRecord>[
      rec(65.0, DateTime(2026, 8, 1)),
      rec(66.0, DateTime(2026, 8, 2)),
    ]);
    expect(data.titlesData.bottomTitles.sideTitles.showTitles, isTrue);
    expect(data.titlesData.leftTitles.sideTitles.showTitles, isTrue);
  });
}
