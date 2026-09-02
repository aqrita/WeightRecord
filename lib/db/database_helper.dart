import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/weight_record.dart';

/// SQLite 数据库访问层。
///
/// 表结构：
///   weight_records(id INTEGER PRIMARY KEY AUTOINCREMENT,
///                  weight_kg REAL NOT NULL,
///                  recorded_at INTEGER NOT NULL,
///                  photo_path TEXT,
///                  compressed INTEGER NOT NULL DEFAULT 0)
class DatabaseHelper {
  /// 应用内使用的单例。
  static final DatabaseHelper instance = DatabaseHelper();

  /// 指定数据库文件路径（默认使用系统数据库目录，测试时可注入）。
  final String? overridePath;

  DatabaseHelper({this.overridePath});

  static const String _dbFileName = 'weight_records.db';
  static const int _dbVersion = 1;
  static const String _tableName = 'weight_records';

  Database? _db;

  Future<Database> get database async {
    _db ??= await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final String path =
        overridePath ?? p.join(await getDatabasesPath(), _dbFileName);
    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: (Database db, int version) async {
        await db.execute('''
          CREATE TABLE $_tableName(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            weight_kg REAL NOT NULL,
            recorded_at INTEGER NOT NULL,
            photo_path TEXT,
            compressed INTEGER NOT NULL DEFAULT 0
          )
        ''');
      },
    );
  }

  /// 新增一条记录，返回新记录的自增 id。
  Future<int> insert(WeightRecord record) async {
    final Database db = await database;
    return db.insert(_tableName, record.toMap());
  }

  /// 按时间返回全部记录；默认倒序（最新在前）。
  Future<List<WeightRecord>> getAll({bool ascending = false}) async {
    final Database db = await database;
    final List<Map<String, Object?>> rows = await db.query(
      _tableName,
      orderBy: 'recorded_at ${ascending ? 'ASC' : 'DESC'}',
    );
    return rows.map(WeightRecord.fromMap).toList();
  }

  /// 按 id 查询单条记录，不存在时返回 null。
  Future<WeightRecord?> getById(int id) async {
    final Database db = await database;
    final List<Map<String, Object?>> rows = await db.query(
      _tableName,
      where: 'id = ?',
      whereArgs: <Object?>[id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return WeightRecord.fromMap(rows.first);
  }

  /// 删除指定 id 的记录，返回受影响行数。
  Future<int> delete(int id) async {
    final Database db = await database;
    return db.delete(_tableName, where: 'id = ?', whereArgs: <Object?>[id]);
  }

  /// 关闭数据库连接（测试用）。
  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}