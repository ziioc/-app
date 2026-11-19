import 'dart:convert';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// 通知栏弹窗服务，基于 flutter_local_notifications 插件。
///
/// 职责：
/// 1. 初始化插件、创建安卓通知渠道（Android 8+ 必须有渠道才能发通知）；
/// 2. 弹出「检测到一笔支出」的提醒；
/// 3. 用户点击通知后，把 payload（金额+来源）交给上层去打开分类小窗。
class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const String channelId = 'payment_reminder';
  static const String channelName = '支付记账提醒';
  static const String channelDesc = '支付完成后提醒你归类这笔支出';

  /// 应用启动时调用一次。onTap 会在用户点击通知时回调，参数是 JSON 字符串。
  static Future<void> initialize({
    required void Function(String payload) onTap,
  }) async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload != null) onTap(payload);
      },
    );

    // 创建高优先级通知渠道，让通知以横幅形式弹出。
    const channel = AndroidNotificationChannel(
      channelId,
      channelName,
      description: channelDesc,
      importance: Importance.high,
    );
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  /// 弹一条支付提醒通知。
  ///
  /// [id] 用时间戳取模，保证连续多笔支付的通知不会互相覆盖。
  /// [payload] 里带上金额和来源，点击通知时原样回传。
  static Future<void> showPaymentReminder({
    required int id,
    required double amount,
    required String source,
  }) async {
    final payload = jsonEncode({'amount': amount, 'source': source});

    await _plugin.show(
      id,
      '检测到一笔支出 ¥${amount.toStringAsFixed(2)}',
      '花在哪了？点这里选分类',
      NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelName,
          channelDescription: channelDesc,
          importance: Importance.high,
          priority: Priority.high,
          autoCancel: true,
        ),
      ),
      payload: payload,
    );
  }
}
