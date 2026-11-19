/// 一笔账单的数据模型。
///
/// 一条记录对应一次支出：金额、归到哪个分类、钱从哪来（支付来源）、
/// 可选备注、以及发生时间。id 为数据库自增主键，新增时为 null。
class Transaction {
  final int? id;
  final double amount;
  final String category; // 一级分类，如「餐饮美食」
  final String? subCategory; // 二级分类，如「外卖」
  final String source; // 来源：wechat / alipay / manual（手动记账）
  final String? note;
  final DateTime createdAt;

  const Transaction({
    this.id,
    required this.amount,
    required this.category,
    this.subCategory,
    this.source = 'manual',
    this.note,
    required this.createdAt,
  });

  /// 转成数据库可写入的 map（字段名与 db_helper 中的建表语句一致）。
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'category': category,
      'sub_category': subCategory,
      'source': source,
      'note': note,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }

  /// 从数据库读出的 map 还原成对象。
  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'] as int?,
      amount: (map['amount'] as num).toDouble(),
      category: map['category'] as String,
      subCategory: map['sub_category'] as String?,
      source: map['source'] as String? ?? 'manual',
      note: map['note'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
    );
  }

  /// 复制并局部修改，用于「改分类 / 改金额」时生成新对象。
  Transaction copyWith({
    int? id,
    double? amount,
    String? category,
    String? subCategory,
    String? source,
    String? note,
    DateTime? createdAt,
  }) {
    return Transaction(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      subCategory: subCategory ?? this.subCategory,
      source: source ?? this.source,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
