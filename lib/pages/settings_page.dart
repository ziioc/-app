import 'package:flutter/material.dart';

import '../data/categories.dart';
import '../services/payment_monitor.dart';

/// 设置页（V1）：权限状态、分类一览、关于说明。
/// 分类自定义、数据导出等放到 V2。
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool? _granted;

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    final granted = await PaymentMonitor.isAccessGranted;
    if (mounted) setState(() => _granted = granted);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('自动记账',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.notifications_active_outlined),
              title: const Text('通知读取权限'),
              subtitle: Text(
                _granted == null
                    ? '检查中…'
                    : (_granted! ? '已开启，支付后可自动提醒' : '未开启，无法自动感知支付'),
              ),
              trailing: _granted == true
                  ? const Icon(Icons.check_circle, color: Colors.green)
                  : TextButton(
                      onPressed: () async {
                        await PaymentMonitor.openAccessSettings();
                        _checkPermission();
                      },
                      child: const Text('去开启'),
                    ),
            ),
          ),
          const SizedBox(height: 20),
          const Text('支出分类（V1 预置）',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: AppCategories.primaries
                    .map((c) => Chip(
                          avatar: Icon(AppCategories.iconOf(c),
                              size: 14, color: AppCategories.colorOf(c)),
                          label: Text(c),
                        ))
                    .toList(),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text('关于',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                '随手账 V1.0.0\n'
                '账单只保存在你的手机本机，不上传、不联网。\n'
                '分类自定义、数据导出、云同步计划后续版本提供。',
                style: TextStyle(height: 1.7, color: Colors.black54, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
