/// 体重记录数据模型。
class WeightRecord {
  /// 数据库自增主键，未保存时为 null。
  final int? id;

  /// 体重（公斤）。
  final double weightKg;

  /// 记录时间（保存那一刻的本地时间）。
  final DateTime recordedAt;

  /// 照片文件名（存于应用文档目录 photos/ 下），无照片时为 null。
  final String? photoPath;

  /// 保存时是否进行了压缩。
  final bool compressed;

  const WeightRecord({
    this.id,
    required this.weightKg,
    required this.recordedAt,
    this.photoPath,
    this.compressed = false,
  });

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'id': id,
      'weight_kg': weightKg,
      'recorded_at': recordedAt.millisecondsSinceEpoch,
      'photo_path': photoPath,
      'compressed': compressed ? 1 : 0,
    };
  }

  factory WeightRecord.fromMap(Map<String, Object?> map) {
    return WeightRecord(
      id: map['id'] as int?,
      weightKg: (map['weight_kg'] as num).toDouble(),
      recordedAt: DateTime.fromMillisecondsSinceEpoch(map['recorded_at'] as int),
      photoPath: map['photo_path'] as String?,
      compressed: (map['compressed'] as int) == 1,
    );
  }
}

/// 体重是否在合理输入范围内（单位：公斤）。
bool isValidWeight(double weightKg) => weightKg >= 20 && weightKg <= 300;