import 'package:flutter/foundation.dart';

import '../data/db_helper.dart';
import '../models/transaction.dart';

/// 账本状态管理。
///
/// 页面通过 Provider 读取这里的数据；数据变化后调用 notifyListeners()
/// 让所有监听的页面自动刷新。V1 只存本机，不联网。
class LedgerProvider with ChangeNotifier {
  final DbHelper _db = DbHelper.instance;

  List<Transaction> _all = [];
  Map<String, double> _categorySums = {};
  bool _loading = true;

  List<Transaction> get transactions => _all;
  Map<String, double> get categorySums => _categorySums;
  bool get loading => _loading;

  /// 本月总支出。
  double get monthTotal =>
      _categorySums.values.fold(0.0, (sum, value) => sum + value);

  /// 加载全部数据：账单列表 + 本月分类汇总。
  Future<void> load() async {
    _loading = true;
    notifyListeners();
    try {
      _all = await _db.queryAll();
      _categorySums = await _db.sumByCategory(DateTime.now());
    } catch (e) {
      debugPrint('加载账本失败: $e');
    }
    _loading = false;
    notifyListeners();
  }

  /// 新增一笔账单并刷新。
  Future<void> add(Transaction tx) async {
    await _db.insert(tx);
    await load();
  }

  /// 更新一笔账单并刷新。
  Future<void> update(Transaction tx) async {
    if (tx.id == null) return;
    await _db.update(tx);
    await load();
  }

  /// 删除一笔账单并刷新。
  Future<void> remove(int id) async {
    await _db.delete(id);
    await load();
  }

  /// 某个月的账单（从已加载的列表里过滤，避免频繁查库）。
  List<Transaction> ofMonth(DateTime month) {
    return _all.where((tx) {
      return tx.createdAt.year == month.year &&
          tx.createdAt.month == month.month;
    }).toList();
  }
}
