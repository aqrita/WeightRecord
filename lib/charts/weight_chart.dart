import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../models/weight_record.dart';
import '../utils/format.dart';

/// 根据体重记录构建折线图数据。
///
/// X 轴为记录时间（毫秒时间戳），Y 轴为体重（公斤）。
/// 记录会自动按时间升序排列。
LineChartData buildWeightLineChart(List<WeightRecord> records) {
  final List<WeightRecord> sorted = List<WeightRecord>.of(records)
    ..sort((WeightRecord a, WeightRecord b) =>
        a.recordedAt.compareTo(b.recordedAt));

  final List<FlSpot> spots = <FlSpot>[
    for (final WeightRecord r in sorted)
      FlSpot(r.recordedAt.millisecondsSinceEpoch.toDouble(), r.weightKg),
  ];

  final (double, double) xRange = _xRange(spots);
  final (double, double) yRange = _yRange(spots);
  const Color lineColor = Color(0xFF00897B);

  return LineChartData(
    minX: xRange.$1,
    maxX: xRange.$2,
    minY: yRange.$1,
    maxY: yRange.$2,
    lineTouchData: LineTouchData(
      touchTooltipData: LineTouchTooltipData(
        getTooltipItems: (List<LineBarSpot> touchedSpots) =>
            <LineTooltipItem>[
          for (final LineBarSpot spot in touchedSpots)
            LineTooltipItem(
              '${formatDateTime(DateTime.fromMillisecondsSinceEpoch(spot.x.round()))}\n'
              '${formatWeightKg(spot.y)}',
              const TextStyle(color: Colors.white, fontSize: 12),
            ),
        ],
      ),
    ),
    gridData: const FlGridData(show: true, drawVerticalLine: false),
    borderData: FlBorderData(
      show: true,
      border: Border.all(color: const Color(0xFFE0E0E0)),
    ),
    titlesData: FlTitlesData(
      topTitles: const AxisTitles(),
      rightTitles: const AxisTitles(),
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 40,
          interval: yRange.$1 == yRange.$2
              ? 1
              : (yRange.$2 - yRange.$1) / 4,
          getTitlesWidget: (double value, TitleMeta meta) => Text(
            value.toStringAsFixed(0),
            style: const TextStyle(fontSize: 10),
          ),
        ),
      ),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 30,
          interval: xRange.$1 == xRange.$2
              ? 1
              : (xRange.$2 - xRange.$1) / 3,
          getTitlesWidget: (double value, TitleMeta meta) => Text(
            _shortDate(DateTime.fromMillisecondsSinceEpoch(value.round())),
            style: const TextStyle(fontSize: 10),
          ),
        ),
      ),
    ),
    lineBarsData: spots.isEmpty
        ? <LineChartBarData>[]
        : <LineChartBarData>[
            LineChartBarData(
              spots: spots,
              isCurved: true,
              preventCurveOverShooting: true,
              barWidth: 3,
              color: lineColor,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: <Color>[
                    lineColor.withValues(alpha: 0.25),
                    lineColor.withValues(alpha: 0.02),
                  ],
                ),
              ),
            ),
          ],
  );
}

/// X 轴范围：单点记录两侧各加 1 天，多点记录两端各留 8% 边距。
(double, double) _xRange(List<FlSpot> spots) {
  if (spots.isEmpty) return (0, 0);
  if (spots.length == 1) {
    final double pad = const Duration(days: 1).inMilliseconds.toDouble();
    return (spots.first.x - pad, spots.first.x + pad);
  }
  final double minX = spots.first.x;
  final double maxX = spots.last.x;
  final double pad = (maxX - minX) * 0.08;
  return (minX - pad, maxX + pad);
}

/// Y 轴范围：基于数据上下各留 2kg，空数据时使用默认 20–300。
(double, double) _yRange(List<FlSpot> spots) {
  if (spots.isEmpty) return (20, 300);
  final Iterable<double> ys = spots.map((FlSpot s) => s.y);
  final double minY = ys.reduce(math.min) - 2;
  final double maxY = ys.reduce(math.max) + 2;
  if (minY == maxY) return (minY - 1, maxY + 1);
  return (minY, maxY);
}

String _shortDate(DateTime t) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(t.month)}-${two(t.day)}';
}
