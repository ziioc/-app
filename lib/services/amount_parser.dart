/// 从支付成功通知里「抠」出金额，并识别来源。
///
/// 微信、支付宝的支付通知文案格式不完全固定，所以这里做多级匹配：
/// 先找带货币符号或「元/块」的数字，再退而找带两位小数的数字。
class AmountParser {
  static const String wechatPackage = 'com.tencent.mm';
  static const String alipayPackage = 'com.eg.android.AlipayGphone';

  /// 判断这条通知是不是我们关心的支付来源。
  static bool isPaymentSource(String packageName) {
    return packageName == wechatPackage ||
        packageName.toLowerCase().contains('alipay');
  }

  /// 把包名翻译成界面上显示的中文来源名。
  static String sourceLabel(String packageName) {
    if (packageName == wechatPackage) return '微信支付';
    if (packageName.toLowerCase().contains('alipay')) return '支付宝';
    return '其他支付';
  }

  /// 尝试从通知标题+正文里解析金额，解析不到返回 null。
  static double? parse(String text) {
    if (text.trim().isEmpty) return null;

    // 第一优先：¥38.50 / 38.50元 / 38.5块 这类明确带单位的写法。
    final strong = RegExp(
      r'[¥￥]\s*(\d{1,7}(?:\.\d{1,2})?)|(\d{1,7}(?:\.\d{1,2})?)\s*(?:元|块)',
    );
    for (final match in strong.allMatches(text)) {
      final raw = match.group(1) ?? match.group(2);
      final value = raw == null ? null : double.tryParse(raw);
      if (value != null && value > 0) return value;
    }

    // 第二优先：任何带两位小数的数字（金额通常长这样）。
    final weak = RegExp(r'(?<!\d)(\d{1,7}\.\d{2})(?!\d)');
    final weakMatch = weak.firstMatch(text);
    if (weakMatch != null) {
      final value = double.tryParse(weakMatch.group(1)!);
      if (value != null && value > 0) return value;
    }

    return null;
  }
}
