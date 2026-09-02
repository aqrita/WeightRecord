import 'dart:io';

import 'package:flutter/material.dart';

import '../db/weight_record_repository.dart';
import '../models/weight_record.dart';
import '../services/photo_service.dart';
import '../services/photo_store.dart';
import '../utils/format.dart';

/// 照片对比页：按时间顺序（旧到新）左右滑动查看历史照片。
class PhotoComparePage extends StatefulWidget {
  const PhotoComparePage({
    super.key,
    this.repository,
    this.photoStore,
  });

  /// 便于测试注入；默认使用真实实现。
  final WeightRecordRepository? repository;
  final PhotoStore? photoStore;

  @override
  State<PhotoComparePage> createState() => _PhotoComparePageState();
}

class _PhotoComparePageState extends State<PhotoComparePage> {
  late final WeightRecordRepository _repository =
      widget.repository ?? DatabaseWeightRecordRepository();
  late final PhotoStore _photoStore = widget.photoStore ?? PhotoService();

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
      final List<WeightRecord> all = await _repository.getAll(ascending: true);
      final List<WeightRecord> withPhoto = <WeightRecord>[
        for (final WeightRecord r in all)
          if (r.photoPath != null) r,
      ];
      final Map<int, String> photoPaths = <int, String>{};
      for (final WeightRecord r in withPhoto) {
        photoPaths[r.id!] = await _photoStore.photoFullPath(r.photoPath!);
      }
      if (!mounted) return;
      setState(() {
        _records = withPhoto;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('查看变化')),
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
      return const Center(child: Text('暂无照片，先记录一条带照片的体重吧'));
    }
    return PageView.builder(
      itemCount: _records.length,
      itemBuilder: (BuildContext context, int index) {
        final WeightRecord record = _records[index];
        final String? path = _photoPaths[record.id];
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: path == null
                      ? const Center(child: Icon(Icons.broken_image, size: 64))
                      : Image.file(
                          File(path),
                          fit: BoxFit.contain,
                          errorBuilder: (_, _, _) =>
                              const Icon(Icons.broken_image, size: 64),
                        ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '${formatDateTime(record.recordedAt)} · ${formatWeightKg(record.weightKg)}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
        );
      },
    );
  }
}
