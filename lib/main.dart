import 'package:flutter/material.dart';

import 'db/weight_record_repository.dart';
import 'pages/home_page.dart';
import 'pages/profile_page.dart';
import 'services/photo_store.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, this.repository, this.photoStore});

  /// 便于测试注入；默认使用真实实现。
  final WeightRecordRepository? repository;
  final PhotoStore? photoStore;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '体重记录',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF00897B)),
      ),
      home: HomeShell(repository: repository, photoStore: photoStore),
    );
  }
}

/// 应用壳：底部导航（首页 / 我的）。
class HomeShell extends StatefulWidget {
  const HomeShell({super.key, this.repository, this.photoStore});

  final WeightRecordRepository? repository;
  final PhotoStore? photoStore;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  /// 每次切回首页时 +1，用于让首页重新加载最新数据。
  int _homeRefreshTick = 0;

  void _onDestinationSelected(int index) {
    setState(() {
      if (index == 0) {
        _homeRefreshTick++;
      }
      _index = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: <Widget>[
          HomePage(
            key: ValueKey<int>(_homeRefreshTick),
            repository: widget.repository,
            photoStore: widget.photoStore,
          ),
          ProfilePage(
            repository: widget.repository,
            photoStore: widget.photoStore,
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _onDestinationSelected,
        destinations: const <NavigationDestination>[
          NavigationDestination(
            icon: Icon(Icons.show_chart),
            label: '首页',
          ),
          NavigationDestination(
            icon: Icon(Icons.person),
            label: '我的',
          ),
        ],
      ),
    );
  }
}
