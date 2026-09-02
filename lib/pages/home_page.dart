import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../charts/weight_chart.dart';
import '../db/weight_record_repository.dart';
import '../models/weight_record.dart';
import '../services/photo_store.dart';
import 'photo_compare_page.dart';

/// 首页：折线图（X=时间，Y=体重）+「查看变化」入口。
class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    this.repository,
    this.photoStore,
    this.photoCompareBuilder,
  });

  /// 便于测试注入；默认使用真实实现。
  final WeightRecordRepository? repository;
  final PhotoStore? photoStore;

  /// 「查看变化」跳转目标，便于测试注入。
  final WidgetBuilder? photoCompareBuilder;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final WeightRecordRepository _repository =
      widget.repository ?? DatabaseWeightRecordRepository();
  late final WidgetBuilder _photoCompareBuilder =
      widget.photoCompareBuilder ??
      (_) => PhotoComparePage(
            repository: widget.repository,
            photoStore: widget.photoStore,
          );

  bool _loading = true;
  String? _loadError;
  List<WeightRecord> _records = <WeightRecord>[];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final List<WeightRecord> records =
          await _repository.getAll(ascending: true);
      if (!mounted) return;
      setState(() {
        _records = records;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = '加载失败：$e';
        _loading = false;
      });
    }
  }

  void _openPhotoCompare() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: _photoCompareBuilder),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('体重记录')),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_loadError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(_loadError!),
            const SizedBox(height: 8),
            TextButton(onPressed: _load, child: const Text('重试')),
          ],
        ),
      );
    }
    if (_records.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Icon(Icons.monitor_weight, size: 64),
            const SizedBox(height: 12),
            const Text('还没有体重记录'),
            const SizedBox(height: 4),
            const Text('去「我的」页面添加第一条记录吧'),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _openPhotoCompare,
              icon: const Icon(Icons.compare),
              label: const Text('查看变化'),
            ),
          ],
        ),
      );
    }
    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '体重趋势（kg）',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
            child: LineChart(buildWeightLineChart(_records)),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _openPhotoCompare,
              icon: const Icon(Icons.compare),
              label: const Text('查看变化'),
            ),
          ),
        ),
      ],
    );
  }
}
