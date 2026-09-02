import 'dart:io';
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'photo_store.dart';

/// 照片文件服务：负责照片的保存、压缩与删除。
///
/// 照片统一存放在应用文档目录的 photos/ 子目录中，数据库只存文件名。
class PhotoService implements PhotoStore {
  /// [baseDirectory] 用于测试时注入目录；为 null 时使用应用文档目录。
  PhotoService({this.baseDirectory});

  /// 根目录；为 null 时使用应用文档目录。
  final Directory? baseDirectory;

  /// photos 子目录名。
  static const String photosDirName = 'photos';

  Future<Directory> get _photosDir async {
    final Directory root =
        baseDirectory ?? await getApplicationDocumentsDirectory();
    final Directory dir = Directory(p.join(root.path, photosDirName));
    if (!dir.existsSync()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// 把已选择的照片（[sourcePath]）保存到照片目录。
  ///
  /// [compress] 为 true 时压缩（长边 ≤1920px、JPEG 质量 80）；
  /// 为 false 时原样复制。返回保存的文件名（不含目录）。
  Future<String> savePickedPhoto(
    String sourcePath, {
    required bool compress,
  }) async {
    final File source = File(sourcePath);
    if (!source.existsSync()) {
      throw FileSystemException('照片源文件不存在', sourcePath);
    }

    final Uint8List bytes = await source.readAsBytes();
    final Directory dir = await _photosDir;
    final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();

    if (compress) {
      final Uint8List? compressed = compressJpeg(bytes);
      if (compressed != null) {
        final String fileName = 'photo_$timestamp.jpg';
        final File target = File(p.join(dir.path, fileName));
        await target.writeAsBytes(compressed, flush: true);
        return fileName;
      }
      // 无法解码的图片退回原图保存。
    }

    final String ext = p.extension(sourcePath).isEmpty ? '.jpg' : p.extension(sourcePath);
    final String fileName = 'photo_$timestamp$ext';
    await source.copy(p.join(dir.path, fileName));
    return fileName;
  }

  /// 删除照片目录中的指定文件；文件不存在时静默返回。
  @override
  Future<void> deletePhoto(String fileName) async {
    if (p.basename(fileName) != fileName) {
      throw ArgumentError('非法的文件名: $fileName');
    }
    final Directory dir = await _photosDir;
    final File file = File(p.join(dir.path, fileName));
    if (await file.exists()) {
      await file.delete();
    }
  }

  /// 返回照片的完整路径（用于显示）。
  @override
  Future<String> photoFullPath(String fileName) async {
    if (p.basename(fileName) != fileName) {
      throw ArgumentError('非法的文件名: $fileName');
    }
    final Directory dir = await _photosDir;
    return p.join(dir.path, fileName);
  }
}

/// 压缩图片：等比缩放至长边不超过 [maxDimension]，按 [quality] 编码为 JPEG。
///
/// 无法解码时返回 null。
Uint8List? compressJpeg(
  Uint8List input, {
  int maxDimension = 1920,
  int quality = 80,
}) {
  final img.Image? decoded;
  try {
    decoded = img.decodeImage(input);
  } catch (_) {
    return null;
  }
  if (decoded == null) {
    return null;
  }

  img.Image output = decoded;
  final int longest = decoded.width > decoded.height ? decoded.width : decoded.height;
  if (longest > maxDimension) {
    final double scale = maxDimension / longest;
    output = img.copyResize(
      decoded,
      width: (decoded.width * scale).round(),
      height: (decoded.height * scale).round(),
    );
  }

  return Uint8List.fromList(img.encodeJpg(output, quality: quality));
}