import 'package:flutter/material.dart';

import '../services/payment_monitor.dart';
import 'home_page.dart';

/// 首次启动的引导页：告诉用户为什么要读通知，并引导去系统设置授权。
class GuidePage extends StatelessWidget {
  const GuidePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.receipt_long, size: 80, color: Color(0xFF3F7DE0)),
              const SizedBox(height: 28),
              const Text(
                '开启自动记账',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text(
                '随手账会在你微信 / 支付宝支付成功后，\n'
                '自动弹出提醒。你只需点一下、选个分类，\n'
                '账单就记好了，不用手动填金额。',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, height: 1.7, color: Colors.black54),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF4E5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  '需要「通知读取权限」才能感知支付。\n'
                  '本 App 只在本机解析金额，不上传任何账单数据。',
                  style: TextStyle(fontSize: 13, height: 1.6, color: Colors.brown),
                ),
              ),
              const SizedBox(height: 36),
              FilledButton(
                onPressed: () => PaymentMonitor.openAccessSettings(),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text('去授权', style: TextStyle(fontSize: 16)),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const HomePage()),
                  );
                },
                child: const Text('我已开启，进入 App'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
