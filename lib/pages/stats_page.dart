import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/categories.dart';
import '../providers/ledger_provider.dart';
import '../utils/format.dart';

/// 统计页（V1 简版）：本月总支出 + 各分类金额和占比条。
/// 完整饼图、趋势图、月度对比放到 V2。
class StatsPage extends StatelessWidget {
  const StatsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<LedgerProvider>(
      builder: (context, ledger, _) {
        final sorted = ledger.categorySums.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        final total = ledger.monthTotal;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Text('本月总支出',
                        style: TextStyle(color: Colors.black54, fontSize: 13)),
                    const SizedBox(height: 6),
                    Text(
                      formatAmount(total),
                      style: const TextStyle(
                          fontSize: 30, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text('分类明细',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            if (sorted.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(
                    child: Text('暂无统计数据',
                        style: TextStyle(color: Colors.grey)),
                  ),
                ),
              )
            else
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: sorted.map((entry) {
                      final percent = total == 0
                          ? 0.0
                          : entry.value / total * 100;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(AppCategories.iconOf(entry.key),
                                    size: 18,
                                    color: AppCategories.colorOf(entry.key)),
                                const SizedBox(width: 8),
                                Text(entry.key,
                                    style: const TextStyle(fontSize: 14)),
                                const Spacer(),
                                Text(
                                  '${formatAmount(entry.value)}  ${percent.toStringAsFixed(1)}%',
                                  style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            LinearProgressIndicator(
                              value: percent / 100,
                              minHeight: 8,
                              backgroundColor: Colors.grey.shade200,
                              color: AppCategories.colorOf(entry.key),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
