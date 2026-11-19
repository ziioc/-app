import 'package:flutter/material.dart';

/// 预置支出分类（V1）。
///
/// key 是一级分类名，value 是该分类下的二级分类列表。
/// 分类按大众记账习惯整理，用户可在设置页做增删改（V2 起）。
class AppCategories {
  static const Map<String, List<String>> data = {
    '餐饮美食': ['早餐', '午餐', '晚餐', '外卖', '咖啡饮品', '零食', '聚餐'],
    '交通出行': ['公交地铁', '打车', '加油', '停车', '火车高铁', '飞机', '共享单车'],
    '购物消费': ['服饰鞋包', '日用品', '数码电子', '美妆护肤', '家居'],
    '居住缴费': ['房租', '房贷', '水电燃气', '物业', '宽带'],
    '医疗健康': ['看病挂号', '药品', '体检', '健身', '保险'],
    '教育学习': ['书籍', '课程培训', '考试费', '学费'],
    '娱乐休闲': ['电影', '游戏', 'KTV', '演出', '旅游', '会员订阅'],
    '人情社交': ['红包', '礼金', '请客', '礼物'],
    '通讯': ['话费', '流量'],
    '金融转账': ['转账', '还款', '手续费'],
    '其他': ['杂项', '待归类'],
  };

  /// 一级分类名列表，供小窗网格和统计页使用。
  static List<String> get primaries => data.keys.toList();

  /// 每个一级分类配一个图标和颜色，仅用于界面展示。
  static const Map<String, IconData> icons = {
    '餐饮美食': Icons.restaurant,
    '交通出行': Icons.directions_bus,
    '购物消费': Icons.shopping_bag,
    '居住缴费': Icons.home,
    '医疗健康': Icons.local_hospital,
    '教育学习': Icons.school,
    '娱乐休闲': Icons.movie,
    '人情社交': Icons.card_giftcard,
    '通讯': Icons.phone_android,
    '金融转账': Icons.account_balance_wallet,
    '其他': Icons.more_horiz,
  };

  /// 取分类图标，找不到就用默认的「标签」图标兜底。
  static IconData iconOf(String category) => icons[category] ?? Icons.label;

  /// 分类配色，按索引循环取一组柔和色，避免界面太花。
  static Color colorOf(String category) {
    const palette = <Color>[
      Color(0xFFE27B58), // 珊瑚
      Color(0xFF4A90D9), // 蓝
      Color(0xFF8E7CC3), // 紫
      Color(0xFF5AA469), // 绿
      Color(0xFFD98C3F), // 橙
      Color(0xFFC25B8E), // 玫红
      Color(0xFF4BA3A1), // 青
      Color(0xFFB0894F), // 棕
      Color(0xFF6C7A89), // 灰蓝
      Color(0xFF9B6B43), // 褐
      Color(0xFF8A8A8A), // 灰
    ];
    final index = primaries.indexOf(category);
    return palette[index < 0 ? palette.length - 1 : index % palette.length];
  }
}
