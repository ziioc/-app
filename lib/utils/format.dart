import 'package:intl/intl.dart';

/// 金额显示成「¥38.50」。
String formatAmount(double value) => '¥${value.toStringAsFixed(2)}';

/// 账单列表里的日期显示：今天显示「今天 14:30」，否则显示「11月18日 14:30」。
String formatBillTime(DateTime time) {
  final now = DateTime.now();
  final sameDay = now.year == time.year &&
      now.month == time.month &&
      now.day == time.day;
  final hm = DateFormat('HH:mm').format(time);
  if (sameDay) return '今天 $hm';
  return '${time.month}月${time.day}日 $hm';
}

/// 按天分组用的 key：只保留年月日。
String dayKey(DateTime time) => '${time.year}-${time.month}-${time.day}';

/// 分组标题：「今天」/「昨天」/「11月16日」。
String dayLabel(DateTime time) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final thatDay = DateTime(time.year, time.month, time.day);
  final diff = today.difference(thatDay).inDays;
  if (diff == 0) return '今天';
  if (diff == 1) return '昨天';
  return '${time.month}月${time.day}日';
}

/// 顶部月份标题：「2026年11月」。
String monthLabel(DateTime month) => '${month.year}年${month.month}月';
