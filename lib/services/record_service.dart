import '../db/weight_record_repository.dart';
import '../models/weight_record.dart';
import 'photo_service.dart';

/// 记录保存服务：负责「照片保存/压缩 + 数据库写入」的完整流程。
///
/// 数据库写入失败时会清理已保存的照片文件，避免遗留孤儿文件。
class RecordService {
  RecordService({
    WeightRecordRepository? repository,
    PhotoService? photoService,
  })  : _repository = repository ?? DatabaseWeightRecordRepository(),
        _photoService = photoService ?? PhotoService();

  final WeightRecordRepository _repository;
  final PhotoService _photoService;

  /// 保存一条体重记录。
  ///
  /// [photoPath] 为已选择照片的源路径，可为 null（无照片）；
  /// [compress] 仅在带照片时生效。
  Future<void> save({
    required double weightKg,
    required DateTime recordedAt,
    String? photoPath,
    required bool compress,
  }) async {
    String? photoFileName;
    if (photoPath != null) {
      photoFileName = await _photoService.savePickedPhoto(
        photoPath,
        compress: compress,
      );
    }

    final WeightRecord record = WeightRecord(
      weightKg: weightKg,
      recordedAt: recordedAt,
      photoPath: photoFileName,
      compressed: compress && photoFileName != null,
    );

    try {
      await _repository.insert(record);
    } catch (_) {
      if (photoFileName != null) {
        await _photoService.deletePhoto(photoFileName);
      }
      rethrow;
    }
  }
}
