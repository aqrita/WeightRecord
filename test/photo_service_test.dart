import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:weight_record/services/photo_service.dart';

void main() {
  group('compressJpeg', () {
    test('大图按长边等比缩放到 1920', () {
      final large = img.Image(width: 2000, height: 1500);
      img.fill(large, color: img.ColorRgb8(200, 100, 50));
      final Uint8List png = Uint8List.fromList(img.encodePng(large));

      final Uint8List? out = compressJpeg(png);
      expect(out, isNotNull);

      final decoded = img.decodeJpg(out!);
      expect(decoded, isNotNull);
      expect(decoded!.width, 1920);
      expect(decoded.height, 1440); // 1500 * 1920 / 2000
    });

    test('小图不放大', () {
      final small = img.Image(width: 800, height: 600);
      img.fill(small, color: img.ColorRgb8(10, 200, 30));
      final Uint8List png = Uint8List.fromList(img.encodePng(small));

      final Uint8List? out = compressJpeg(png);
      final decoded = img.decodeJpg(out!);
      expect(decoded!.width, 800);
      expect(decoded.height, 600);
    });

    test('压缩后是 JPEG 且质量参数生效', () {
      final image = img.Image(width: 100, height: 100);
      img.fill(image, color: img.ColorRgb8(255, 255, 255));
      final Uint8List png = Uint8List.fromList(img.encodePng(image));

      final Uint8List? out = compressJpeg(png, quality: 30);
      expect(out, isNotNull);
      expect(img.findDecoderForData(out!), isA<img.JpegDecoder>());
    });

    test('无效数据返回 null', () {
      expect(compressJpeg(Uint8List.fromList([1, 2, 3, 4, 5])), isNull);
    });
  });

  group('PhotoService', () {
    late Directory rootDir;
    late PhotoService service;

    setUp(() async {
      rootDir = await Directory.systemTemp.createTemp('wr_photo_test_');
      service = PhotoService(baseDirectory: rootDir);
    });

    tearDown(() async {
      await rootDir.delete(recursive: true);
    });

    Future<File> createSourceImage({int width = 1600, int height = 1200}) async {
      final image = img.Image(width: width, height: height);
      img.fill(image, color: img.ColorRgb8(30, 120, 200));
      final File file = File(p.join(rootDir.path, 'src_$width.png'));
      await file.writeAsBytes(img.encodePng(image));
      return file;
    }

    test('compress=true 时保存为压缩 JPEG，长边受限', () async {
      final source = await createSourceImage(width: 2400, height: 1800);
      final fileName = await service.savePickedPhoto(source.path, compress: true);

      expect(fileName, endsWith('.jpg'));
      final File saved = File(p.join(rootDir.path, PhotoService.photosDirName, fileName));
      expect(saved.existsSync(), isTrue);

      final decoded = img.decodeJpg(await saved.readAsBytes());
      expect(decoded!.width, 1920);
      expect(decoded.height, 1440);
    });

    test('compress=false 时原样复制', () async {
      final source = await createSourceImage(width: 800, height: 600);
      final sourceBytes = await source.readAsBytes();
      final fileName = await service.savePickedPhoto(source.path, compress: false);

      final File saved = File(p.join(rootDir.path, PhotoService.photosDirName, fileName));
      expect(saved.existsSync(), isTrue);
      expect(await saved.readAsBytes(), sourceBytes);
    });

    test('源文件不存在时抛出异常', () async {
      expect(
        () => service.savePickedPhoto(p.join(rootDir.path, 'missing.png'), compress: true),
        throwsA(isA<FileSystemException>()),
      );
    });

    test('deletePhoto 删除文件，文件不存在时静默', () async {
      final source = await createSourceImage();
      final fileName = await service.savePickedPhoto(source.path, compress: false);
      final File saved = File(p.join(rootDir.path, PhotoService.photosDirName, fileName));
      expect(saved.existsSync(), isTrue);

      await service.deletePhoto(fileName);
      expect(saved.existsSync(), isFalse);

      await service.deletePhoto('not_exist.jpg'); // 不应抛错
    });

    test('非法文件名被拒绝', () async {
      expect(() => service.deletePhoto('../evil.jpg'), throwsArgumentError);
      expect(() => service.photoFullPath('../evil.jpg'), throwsArgumentError);
    });

    test('photoFullPath 返回 photos 目录下的完整路径', () async {
      final full = await service.photoFullPath('a.jpg');
      expect(full, p.join(rootDir.path, PhotoService.photosDirName, 'a.jpg'));
    });
  });
}