import 'dart:io';

import 'package:flutter/material.dart';

import '../db/weight_record_repository.dart';
import '../models/weight_record.dart';
import '../services/photo_service.dart';
import '../services/photo_store.dart';
import '../utils/format.dart';
import 'record_page.dart';

/// 查看记录页：按时间列出全部记录，支持新增与删除（照片一并删除）。
class HistoryPage extends StatefulWidget {
  const HistoryPage({
    super.key,
    this.repository,
    this.photoStore,
    this.recordPageBuilder,
  });

  /// 便于测试注入；默认使用真实实现。
  final WeightRecordRepository? repository;
  final PhotoStore? photoStore;

  /// 「新增」按钮跳转目标，便于测试注入。
  final WidgetBuilder? recordPageBuilder;

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  late final WeightRecordRepository _repository =
      widget.repository ?? DatabaseWeightRecordRepository();
  late final PhotoStore _photoStore = widget.photoStore ?? PhotoService();
  late final WidgetBuilder _recordPageBuilder =
      widget.recordPageBuilder ?? (_) => const RecordPage();

  bool _loading = true;
  String? _loadError;
  List<WeightRecord> _records = <WeightRecord>[];
  Map<int, String> _photoPaths = <int, String>{};

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
      final List<WeightRecord> records = await _repository.getAll();
      final Map<int, String> photoPaths = <int, String>{};
      for (final WeightRecord record in records) {
        final String? fileName = record.photoPath;
        if (fileName != null && record.id != null) {
          photoPaths[record.id!] = await _photoStore.photoFullPath(fileName);
        }
      }
      if (!mounted) return;
      setState(() {
        _records = records;
        _photoPaths = photoPaths;
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

  void _openRecordPage() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: _recordPageBuilder),
    );
  }

  Future<void> _confirmAndDelete(WeightRecord record) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('删除记录'),
        content: Text('确定删除 ${formatWeightKg(record.weightKg)} 的记录吗？照片会一并删除。'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await _repository.delete(record.id!);
      final String? fileName = record.photoPath;
      if (fileName != null) {
        await _photoStore.deletePhoto(fileName);
      }
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('删除失败：$e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('查看记录'),
        actions: <Widget>[
          IconButton(
            onPressed: _openRecordPage,
            icon: const Icon(Icons.add),
            tooltip: '新增',
          ),
        ],
      ),
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
      return const Center(child: Text('暂无记录，点右上角 + 新增'));
    }
    return ListView.builder(
      itemCount: _records.length,
      itemBuilder: (BuildContext context, int index) {
        final WeightRecord record = _records[index];
        return _RecordTile(
          record: record,
          photoPath: record.id == null ? null : _photoPaths[record.id],
          onDelete: () => _confirmAndDelete(record),
        );
      },
    );
  }
}

class _RecordTile extends StatelessWidget {
  const _RecordTile({
    required this.record,
    required this.onDelete,
    this.photoPath,
  });

  final WeightRecord record;
  final String? photoPath;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final String? path = photoPath;
    return ListTile(
      leading: path != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.file(
                File(path),
                width: 56,
                height: 56,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const Icon(Icons.broken_image),
              ),
            )
          : const CircleAvatar(child: Icon(Icons.monitor_weight)),
      title: Text(
        formatWeightKg(record.weightKg),
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(formatDateTime(record.recordedAt)),
      trailing: IconButton(
        onPressed: onDelete,
        icon: const Icon(Icons.delete_outline),
        tooltip: '删除',
      ),
    );
  }
}
