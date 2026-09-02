import 'package:flutter/material.dart';

import '../db/weight_record_repository.dart';
import '../services/photo_store.dart';
import 'history_page.dart';
import 'record_page.dart';

/// 我的页：提供「记录体重」和「查看记录」两个入口。
class ProfilePage extends StatelessWidget {
  const ProfilePage({
    super.key,
    this.repository,
    this.photoStore,
    this.recordPageBuilder,
    this.historyPageBuilder,
  });

  /// 便于测试注入；默认使用真实实现。
  final WeightRecordRepository? repository;
  final PhotoStore? photoStore;

  /// 便于测试注入目标页面。
  final WidgetBuilder? recordPageBuilder;
  final WidgetBuilder? historyPageBuilder;

  void _openRecord(BuildContext context) {
    final WidgetBuilder builder =
        recordPageBuilder ?? (_) => const RecordPage();
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: builder),
    );
  }

  void _openHistory(BuildContext context) {
    final WidgetBuilder builder =
        historyPageBuilder ??
        (_) => HistoryPage(repository: repository, photoStore: photoStore);
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: builder),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('我的')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          _EntryCard(
            icon: Icons.monitor_weight,
            title: '记录体重',
            subtitle: '添加一条新的体重记录，可附带照片',
            onTap: () => _openRecord(context),
          ),
          const SizedBox(height: 12),
          _EntryCard(
            icon: Icons.history,
            title: '查看记录',
            subtitle: '浏览、删除历史体重记录',
            onTap: () => _openHistory(context),
          ),
        ],
      ),
    );
  }
}

class _EntryCard extends StatelessWidget {
  const _EntryCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: colors.primaryContainer,
          foregroundColor: colors.onPrimaryContainer,
          child: Icon(icon),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
