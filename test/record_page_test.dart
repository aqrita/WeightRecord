import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:weight_record/models/weight_record.dart';
import 'package:weight_record/pages/record_page.dart';
import 'package:weight_record/services/photo_picker.dart';
import 'package:weight_record/services/record_service.dart';

/// 记录页测试使用假保存服务：纯内存、同步完成，无需真实 IO。
class _FakeRecordService implements RecordService {
  final List<WeightRecord> saved = <WeightRecord>[];
  String? lastPhotoSourcePath;
  bool fail = false;

  @override
  Future<void> save({
    required double weightKg,
    required DateTime recordedAt,
    String? photoPath,
    required bool compress,
  }) async {
    if (fail) {
      throw Exception('db down');
    }
    lastPhotoSourcePath = photoPath;
    saved.add(
      WeightRecord(
        weightKg: weightKg,
        recordedAt: recordedAt,
        photoPath: photoPath == null ? null : 'photo_fake.jpg',
        compressed: compress && photoPath != null,
      ),
    );
  }
}

class _FakePhotoPicker implements PhotoPicker {
  _FakePhotoPicker({this.photoPath});

  final String? photoPath;

  @override
  Future<PickedPhoto?> pick({required bool fromCamera}) async {
    if (photoPath == null) return null;
    return PickedPhoto(photoPath!);
  }
}

void main() {
  final DateTime fixedTime = DateTime(2026, 8, 31, 10, 30);
  late Directory tempDir;
  late File photoFile;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('wr_record_page_');
    final img.Image image = img.Image(width: 400, height: 300);
    img.fill(image, color: img.ColorRgb8(10, 20, 30));
    photoFile = File(p.join(tempDir.path, 'picked.png'));
    await photoFile.writeAsBytes(img.encodePng(image));
  });

  tearDown(() async {
    try {
      await tempDir.delete(recursive: true);
    } catch (_) {
      // Windows 上偶发占用，测试结果不受影响。
    }
  });

  Future<void> pushRecordPage(
    WidgetTester tester, {
    required _FakeRecordService service,
    PhotoPicker? picker,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (BuildContext context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => RecordPage(
                        recordService: service,
                        photoPicker: picker ?? _FakePhotoPicker(),
                        clock: () => fixedTime,
                      ),
                    ),
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    // 路由转场完成（此时输入框尚未聚焦，不会触发光标闪烁动画）。
    await tester.pumpAndSettle();
  }

  testWidgets('输入有效体重保存成功并返回上一页', (tester) async {
    final service = _FakeRecordService();
    await pushRecordPage(tester, service: service);

    await tester.enterText(find.byType(TextField), '65.5');
    await tester.pump();
    await tester.tap(find.text('保存'));
    await tester.pump(); // 处理保存异步流程
    await tester.pump(const Duration(milliseconds: 400)); // 返回转场推进
    await tester.pump(const Duration(milliseconds: 400)); // 移除路由后重建

    expect(service.saved, hasLength(1));
    final WeightRecord record = service.saved.first;
    expect(record.weightKg, 65.5);
    expect(record.recordedAt, fixedTime);
    expect(record.photoPath, isNull);
    expect(record.compressed, isFalse);
    expect(find.byType(RecordPage), findsNothing);
    expect(find.text('open'), findsOneWidget);
  });

  testWidgets('非法体重不保存并提示错误', (tester) async {
    final service = _FakeRecordService();
    await pushRecordPage(tester, service: service);

    await tester.enterText(find.byType(TextField), '10');
    await tester.pump();
    await tester.tap(find.text('保存'));
    await tester.pump();

    expect(find.textContaining('20-300'), findsOneWidget);
    expect(service.saved, isEmpty);
    expect(find.byType(RecordPage), findsOneWidget);
  });

  testWidgets('选择照片后保存：显示缩略图且记录标记已压缩', (tester) async {
    final service = _FakeRecordService();
    await pushRecordPage(
      tester,
      service: service,
      picker: _FakePhotoPicker(photoPath: photoFile.path),
    );

    await tester.tap(find.text('相册'));
    await tester.pump();
    expect(find.byType(Image), findsOneWidget); // 出现缩略图

    await tester.enterText(find.byType(TextField), '70');
    await tester.pump();
    await tester.tap(find.text('保存'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400)); // 返回转场推进
    await tester.pump(const Duration(milliseconds: 400)); // 移除路由后重建

    expect(service.saved, hasLength(1));
    expect(service.lastPhotoSourcePath, photoFile.path);
    expect(service.saved.first.photoPath, 'photo_fake.jpg');
    expect(service.saved.first.compressed, isTrue);
  });

  testWidgets('关闭压缩开关后保存为未压缩', (tester) async {
    final service = _FakeRecordService();
    await pushRecordPage(
      tester,
      service: service,
      picker: _FakePhotoPicker(photoPath: photoFile.path),
    );

    await tester.tap(find.text('相册'));
    await tester.pump();

    final Finder switchFinder = find.byType(Switch);
    expect(tester.widget<Switch>(switchFinder).value, isTrue); // 默认开启
    await tester.tap(switchFinder);
    await tester.pump();
    expect(tester.widget<Switch>(switchFinder).value, isFalse);

    await tester.enterText(find.byType(TextField), '66.6');
    await tester.pump();
    await tester.tap(find.text('保存'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400)); // 返回转场推进
    await tester.pump(const Duration(milliseconds: 400)); // 移除路由后重建

    expect(service.saved, hasLength(1));
    expect(service.saved.first.photoPath, isNotNull);
    expect(service.saved.first.compressed, isFalse);
  });

  testWidgets('保存失败时提示错误且停留在记录页', (tester) async {
    final service = _FakeRecordService()..fail = true;
    await pushRecordPage(tester, service: service);

    await tester.enterText(find.byType(TextField), '65.5');
    await tester.pump();
    await tester.tap(find.text('保存'));
    await tester.pump();

    expect(find.textContaining('保存失败'), findsOneWidget);
    expect(service.saved, isEmpty);
    expect(find.byType(RecordPage), findsOneWidget);

    // 等待 SnackBar 自动关闭，避免遗留定时器。
    await tester.pump(const Duration(seconds: 5));
    await tester.pump(const Duration(seconds: 1));
  });
}

