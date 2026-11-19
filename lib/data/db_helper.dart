import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart' hide Transaction;

import '../models/transaction.dart';

/// 本地数据库帮助类（SQLite）。
///
/// 采用懒加载单例：第一次用到数据库时才打开，之后复用同一个连接。
/// 所有账单都存在手机本机，V1 不联网、不上传。
class DbHelper {
  DbHelper._();
  static final DbHelper instance = DbHelper._();

  static const String _dbName = 'auto_ledger.db';
  static const int _dbVersion = 1;
  static const String _table = 'transactions';

  Database? _db;

  Future<Database> get database async {
    final db = _db;
    if (db != null && db.isOpen) return db;
    _db = await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final dir = await getDatabasesPath();
    final path = join(dir, _dbName);
    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $_table (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            amount REAL NOT NULL,
            category TEXT NOT NULL,
            sub_category TEXT,
            source TEXT NOT NULL DEFAULT 'manual',
            note TEXT,
            created_at INTEGER NOT NULL
          )
        ''');
        // 常用查询建索引：按时间倒序查账单会更快。
        await db.execute(
          'CREATE INDEX idx_created_at ON $_table (created_at DESC)',
        );
      },
    );
  }

  /// 新增一笔账单，返回新记录的主键。
  Future<int> insert(Transaction tx) async {
    final db = await database;
    return db.insert(_table, tx.toMap()..remove('id'));
  }

  /// 更新一笔账单（改金额、改分类等）。
  Future<int> update(Transaction tx) async {
    final db = await database;
    return db.update(
      _table,
      tx.toMap(),
      where: 'id = ?',
      whereArgs: [tx.id],
    );
  }

  /// 删除一笔账单。
  Future<int> delete(int id) async {
    final db = await database;
    return db.delete(_table, where: 'id = ?', whereArgs: [id]);
  }

  /// 取出全部账单，按时间倒序（最新的在前）。
  Future<List<Transaction>> queryAll() async {
    final db = await database;
    final rows = await db.query(_table, orderBy: 'created_at DESC');
    return rows.map(Transaction.fromMap).toList();
  }

  /// 查询某个月（含起止时间戳）的账单。
  Future<List<Transaction>> queryByMonth(DateTime month) async {
    final db = await database;
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 1);
    final rows = await db.query(
      _table,
      where: 'created_at >= ? AND created_at < ?',
      whereArgs: [start.millisecondsSinceEpoch, end.millisecondsSinceEpoch],
      orderBy: 'created_at DESC',
    );
    return rows.map(Transaction.fromMap).toList();
  }

  /// 统计某个月每个一级分类的支出合计，供首页和统计页用。
  /// 返回 map：{分类名: 金额合计}。
  Future<Map<String, double>> sumByCategory(DateTime month) async {
    final db = await database;
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 1);
    final rows = await db.rawQuery(
      '''
      SELECT category, SUM(amount) AS total
      FROM $_table
      WHERE created_at >= ? AND created_at < ?
      GROUP BY category
      ORDER BY total DESC
      ''',
      [start.millisecondsSinceEpoch, end.millisecondsSinceEpoch],
    );
    return {
      for (final row in rows)
        row['category'] as String: (row['total'] as num).toDouble(),
    };
  }
}
