import 'package:image_picker/image_picker.dart';

/// 已选择的照片（仅保留路径，方便测试注入）。
class PickedPhoto {
  final String path;
  const PickedPhoto(this.path);
}

/// 照片选择器抽象，便于测试注入。
abstract class PhotoPicker {
  /// 选择一张照片；用户取消时返回 null。
  Future<PickedPhoto?> pick({required bool fromCamera});
}

/// 基于 image_picker 的实现。
class ImagePickerPhotoPicker implements PhotoPicker {
  final ImagePicker _picker = ImagePicker();

  @override
  Future<PickedPhoto?> pick({required bool fromCamera}) async {
    final XFile? file = await _picker.pickImage(
      source: fromCamera ? ImageSource.camera : ImageSource.gallery,
    );
    return file == null ? null : PickedPhoto(file.path);
  }
}