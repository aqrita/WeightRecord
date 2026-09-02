import 'package:flutter_test/flutter_test.dart';
import 'package:weight_record/models/weight_record.dart';

void main() {
  group('WeightRecord', () {
    test('toMap/fromMap 往返一致', () {
      final record = WeightRecord(
        id: 7,
        weightKg: 65.5,
        recordedAt: DateTime(2026, 8, 31, 8, 30),
        photoPath: 'photo_20260831_083000.jpg',
        compressed: true,
      );
      final map = record.toMap();
      final restored = WeightRecord.fromMap(map);
      expect(restored.id, 7);
      expect(restored.weightKg, 65.5);
      expect(restored.recordedAt, record.recordedAt);
      expect(restored.photoPath, 'photo_20260831_083000.jpg');
      expect(restored.compressed, isTrue);
    });

    test('无照片时 photoPath 为 null，compressed 默认为 false', () {
      final record =
          WeightRecord(weightKg: 70, recordedAt: DateTime(2026, 1, 1));
      expect(record.photoPath, isNull);
      expect(record.compressed, isFalse);
      expect(WeightRecord.fromMap(record.toMap()).photoPath, isNull);
      expect(WeightRecord.fromMap(record.toMap()).compressed, isFalse);
    });

    test('weight_kg 以 num 存储时能正确转回 double', () {
      final map = <String, Object?>{
        'id': 1,
        'weight_kg': 66.6,
        'recorded_at': 1000,
        'photo_path': null,
        'compressed': 0,
      };
      final record = WeightRecord.fromMap(map);
      expect(record.weightKg, 66.6);
      expect(record.weightKg, isA<double>());
    });
  });

  group('isValidWeight', () {
    test('20-300 公斤为合理范围', () {
      expect(isValidWeight(20), isTrue);
      expect(isValidWeight(65.5), isTrue);
      expect(isValidWeight(300), isTrue);
      expect(isValidWeight(19.9), isFalse);
      expect(isValidWeight(300.1), isFalse);
      expect(isValidWeight(0), isFalse);
      expect(isValidWeight(-5), isFalse);
    });
  });
}