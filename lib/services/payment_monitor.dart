import 'dart:async';

import 'package:flutter/services.dart';

/// 一笔「待归类」的支付：金额已经解析出来，但用户还没选分类。
class PendingPayment {
  final double amount;
  final String source; // wechat / alipay
  final DateTime detectedAt;

  const PendingPayment({
    required this.amount,
    required this.source,
    required this.detectedAt,
  });
}

/// 待归类支付的全局中转站。
///
/// 通知可能出现在 App 未打开的时候：用户点通知后 App 才启动，
/// 此时首页还没开始监听。用 _pending 缓存住这笔支付，首页 initState
/// 时先 take() 一次，就不会漏掉。
class PendingPaymentStore {
  static PendingPayment? _pending;
  static final StreamController<PendingPayment> _controller =
      StreamController<PendingPayment>.broadcast();

  static Stream<PendingPayment> get stream => _controller.stream;

  static void emit(PendingPayment payment) {
    _pending = payment;
    _controller.add(payment);
  }

  /// 取出并清空缓存的待归类支付；没有则返回 null。
  static PendingPayment? take() {
    final payment = _pending;
    _pending = null;
    return payment;
  }
}

/// 与安卓原生层通信：监听支付通知、检查/打开通知读取权限。
///
/// 原生侧通过 EventChannel("auto_ledger/notifications") 把每条
/// 微信/支付宝通知的 {package,title,text,time} 推过来；
/// 通过 MethodChannel("auto_ledger/native") 提供权限查询与跳转设置。
class PaymentMonitor {
  static const EventChannel _eventChannel =
      EventChannel('auto_ledger/notifications');
  static const MethodChannel _methodChannel =
      MethodChannel('auto_ledger/native');

  static Stream<dynamic> get notificationStream =>
      _eventChannel.receiveBroadcastStream();

  /// 查询用户是否已授予「通知读取权限」。
  static Future<bool> get isAccessGranted async {
    final result = await _methodChannel
        .invokeMethod<bool>('isNotificationAccessGranted');
    return result ?? false;
  }

  /// 打开系统的「通知使用权」设置页，让用户手动开启。
  static Future<void> openAccessSettings() async {
    await _methodChannel.invokeMethod('openNotificationAccessSettings');
  }
}
