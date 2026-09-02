import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/weight_record.dart';
import '../services/photo_picker.dart';
import '../services/record_service.dart';
import '../utils/format.dart';

/// 记录页：输入体重（公斤）、可选照片（可选压缩）并保存。
class RecordPage extends StatefulWidget {
  const RecordPage({
    super.key,
    this.recordService,
    this.photoPicker,
    this.clock,
  });

  /// 便于测试注入；默认使用真实保存服务。
  final RecordService? recordService;

  final PhotoPicker? photoPicker;

  /// 记录时间来源，便于测试注入固定时间。
  final DateTime Function()? clock;

  @override
  State<RecordPage> createState() => _RecordPageState();
}

class _RecordPageState extends State<RecordPage> {
  late final RecordService _recordService =
      widget.recordService ?? RecordService();
  late final PhotoPicker _photoPicker =
      widget.photoPicker ?? ImagePickerPhotoPicker();
  late final DateTime Function() _clock = widget.clock ?? DateTime.now;

  final TextEditingController _weightController = TextEditingController();
  PickedPhoto? _photo;
  bool _compress = true;
  String? _weightError;

  @override
  void dispose() {
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto({required bool fromCamera}) async {
    final PickedPhoto? photo = await _photoPicker.pick(fromCamera: fromCamera);
    if (photo != null && mounted) {
      setState(() => _photo = photo);
    }
  }

  void _clearPhoto() {
    setState(() => _photo = null);
  }

  void _validateWeight(String value) {
    final double? weight = double.tryParse(value.trim());
    if (weight == null || !isValidWeight(weight)) {
      setState(() => _weightError = '请输入 20-300 之间的体重（公斤）');
    } else if (_weightError != null) {
      setState(() => _weightError = null);
    }
  }

  Future<void> _save() async {
    final double? weight = double.tryParse(_weightController.text.trim());
    if (weight == null || !isValidWeight(weight)) {
      setState(() => _weightError = '请输入 20-300 之间的体重（公斤）');
      return;
    }

    try {
      await _recordService.save(
        weightKg: weight,
        recordedAt: _clock(),
        photoPath: _photo?.path,
        compress: _compress,
      );
    } catch (e) {
      _showMessage('保存失败：$e');
      return;
    }

    if (mounted) {
      Navigator.of(context).pop(true);
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final DateTime now = _clock();
    return Scaffold(
      appBar: AppBar(title: const Text('记录体重')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          TextField(
            controller: _weightController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
            ],
            decoration: InputDecoration(
              labelText: '体重（公斤）',
              suffixText: 'kg',
              errorText: _weightError,
              border: const OutlineInputBorder(),
            ),
            onChanged: _validateWeight,
          ),
          const SizedBox(height: 12),
          Text('记录时间：${formatDateTime(now)}'),
          const SizedBox(height: 16),
          Row(
            children: <Widget>[
              OutlinedButton.icon(
                onPressed: () => _pickPhoto(fromCamera: true),
                icon: const Icon(Icons.photo_camera),
                label: const Text('拍照'),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () => _pickPhoto(fromCamera: false),
                icon: const Icon(Icons.photo_library),
                label: const Text('相册'),
              ),
              if (_photo != null)
                TextButton(
                  onPressed: _clearPhoto,
                  child: const Text('清除'),
                ),
            ],
          ),
          if (_photo != null) ...<Widget>[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(
                File(_photo!.path),
                height: 160,
                fit: BoxFit.cover,
              ),
            ),
          ],
          SwitchListTile(
            title: const Text('压缩照片'),
            subtitle: const Text('开启后长边缩至 1920px，体积更小'),
            value: _compress,
            onChanged: (bool v) => setState(() => _compress = v),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _save,
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }
}
