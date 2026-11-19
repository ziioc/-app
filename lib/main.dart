import 'dart:convert';

import 'package:flutter/material.dart';

import 'app.dart';
import 'services/amount_parser.dart';
import 'services/notification_service.dart';
import 'services/payment_monitor.dart';

Future<void> main() async {
  // 用到插件和通道前必须先绑定引擎。
  WidgetsFlutterBinding.ensureInitialized();

  // 1) 初始化通知：用户点通知时，把金额和来源塞进待归类中转站。
  await NotificationService.initialize(
    onTap: (payload) {
      try {
        final map = jsonDecode(payload) as Map<String, dynamic>;
        PendingPaymentStore.emit(
          PendingPayment(
            amount: (map['amount'] as num).toDouble(),
            source: map['source'] as String? ?? '',
            detectedAt: DateTime.now(),
          ),
        );
      } catch (e) {
        debugPrint('解析通知 payload 失败: $e');
      }
    },
  );

  // 2) 监听安卓原生推过来的支付通知：解析金额 -> 弹通知提醒。
  PaymentMonitor.notificationStream.listen((event) {
    try {
      final map = Map<String, dynamic>.from(event as Map);
      final package = map['package'] as String? ?? '';
      if (!AmountParser.isPaymentSource(package)) return;

      final title = map['title'] as String? ?? '';
      final text = map['text'] as String? ?? '';
      final amount = AmountParser.parse('$title $text');
      if (amount == null) return; // 金额没解析出来就不打扰用户

      NotificationService.showPaymentReminder(
        id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        amount: amount,
        source: package,
      );
    } catch (e) {
      debugPrint('处理支付通知失败: $e');
    }
  });

  // 3) 判断是否已授权，决定起始页。
  final granted = await PaymentMonitor.isAccessGranted;

  runApp(AutoLedgerApp(startAtGuide: !granted));
}
