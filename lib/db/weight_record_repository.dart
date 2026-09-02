import '../models/weight_record.dart';
import 'database_helper.dart';

/// 体重记录的数据访问接口，便于页面/服务注入与测试。
abstract class WeightRecordRepository {
  Future<int> insert(WeightRecord record);

  /// 按时间返回全部记录；[ascending] 为 true 时正序（旧到新），默认倒序。
  Future<List<WeightRecord>> getAll({bool ascending = false});

  Future<WeightRecord?> getById(int id);

  /// 删除指定记录，返回受影响行数。
  Future<int> delete(int id);
}

/// 基于 SQLite（sqflite）的默认实现。
class DatabaseWeightRecordRepository implements WeightRecordRepository {
  DatabaseWeightRecordRepository({DatabaseHelper? dbHelper})
      : _db = dbHelper ?? DatabaseHelper.instance;

  final DatabaseHelper _db;

  @override
  Future<int> insert(WeightRecord record) => _db.insert(record);

  @override
  Future<List<WeightRecord>> getAll({bool ascending = false}) =>
      _db.getAll(ascending: ascending);

  @override
  Future<WeightRecord?> getById(int id) => _db.getById(id);

  @override
  Future<int> delete(int id) => _db.delete(id);
}
