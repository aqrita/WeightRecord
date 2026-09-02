import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:weight_record/pages/profile_page.dart';

void main() {
  Widget stubPage(String label) => Scaffold(body: Text(label));

  Future<void> pumpProfile(
    WidgetTester tester, {
    required WidgetBuilder recordBuilder,
    required WidgetBuilder historyBuilder,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ProfilePage(
          recordPageBuilder: recordBuilder,
          historyPageBuilder: historyBuilder,
        ),
      ),
    );
  }

  testWidgets('显示两个入口卡片', (tester) async {
    await pumpProfile(
      tester,
      recordBuilder: (_) => stubPage('记录页桩'),
      historyBuilder: (_) => stubPage('历史页桩'),
    );

    expect(find.text('记录体重'), findsOneWidget);
    expect(find.text('查看记录'), findsOneWidget);
  });

  testWidgets('点击「记录体重」跳转到记录页', (tester) async {
    await pumpProfile(
      tester,
      recordBuilder: (_) => stubPage('记录页桩'),
      historyBuilder: (_) => stubPage('历史页桩'),
    );

    await tester.tap(find.text('记录体重'));
    await tester.pumpAndSettle();

    expect(find.text('记录页桩'), findsOneWidget);
  });

  testWidgets('点击「查看记录」跳转到历史页', (tester) async {
    await pumpProfile(
      tester,
      recordBuilder: (_) => stubPage('记录页桩'),
      historyBuilder: (_) => stubPage('历史页桩'),
    );

    await tester.tap(find.text('查看记录'));
    await tester.pumpAndSettle();

    expect(find.text('历史页桩'), findsOneWidget);
  });
}
