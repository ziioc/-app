import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/categories.dart';
import '../models/transaction.dart';
import '../providers/ledger_provider.dart';
import '../utils/format.dart';

/// 账单列表页：按月份、按天分组；可编辑、可删除。
class BillsPage extends StatefulWidget {
  const BillsPage({super.key});

  @override
  State<BillsPage> createState() => _BillsPageState();
}

class _BillsPageState extends State<BillsPage> {
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);

  void _shiftMonth(int delta) {
    setState(() => _month = DateTime(_month.year, _month.month + delta));
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LedgerProvider>(
      builder: (context, ledger, _) {
        final bills = ledger.ofMonth(_month);

        // 按天分组：{日期 key: 当天账单列表}。
        final Map<String, List<Transaction>> groups = {};
        for (final tx in bills) {
          groups.putIfAbsent(dayKey(tx.createdAt), () => []).add(tx);
        }
        final keys = groups.keys.toList()..sort((a, b) => b.compareTo(a));

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: () => _shiftMonth(-1),
                  ),
                  Text(
                    monthLabel(_month),
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: () => _shiftMonth(1),
                  ),
                ],
              ),
            ),
            Expanded(
              child: bills.isEmpty
                  ? const Center(
                      child: Text('这个月还没有账单',
                          style: TextStyle(color: Colors.grey)))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: keys.length,
                      itemBuilder: (context, index) {
                        final key = keys[index];
                        final list = groups[key]!;
                        final day = list.first.createdAt;
                        final dayTotal =
                            list.fold(0.0, (sum, tx) => sum + tx.amount);
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Row(
                                children: [
                                  Text(dayLabel(day),
                                      style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black54)),
                                  const Spacer(),
                                  Text('小计 ${formatAmount(dayTotal)}',
                                      style: const TextStyle(
                                          fontSize: 12, color: Colors.grey)),
                                ],
                              ),
                            ),
                            Card(
                              margin: EdgeInsets.zero,
                              child: Column(
                                children: list.map((tx) => Dismissible(
                                  key: ValueKey(tx.id!),
                                  direction: DismissDirection.endToStart,
                                  background: Container(
                                    color: Colors.redAccent,
                                    alignment: Alignment.centerRight,
                                    padding: const EdgeInsets.only(right: 20),
                                    child: const Icon(Icons.delete,
                                        color: Colors.white),
                                  ),
                                  confirmDismiss: (_) async {
                                    return showDialog<bool>(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: const Text('删除这笔账单？'),
                                        content: const Text('删除后无法恢复。'),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(ctx, false),
                                            child: const Text('取消'),
                                          ),
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(ctx, true),
                                            child: const Text('删除',
                                                style:
                                                    TextStyle(color: Colors.red)),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                  onDismissed: (_) => ledger.remove(tx.id!),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: AppCategories
                                          .colorOf(tx.category)
                                          .withValues(alpha: 0.15),
                                      child: Icon(
                                        AppCategories.iconOf(tx.category),
                                        size: 18,
                                        color: AppCategories.colorOf(tx.category),
                                      ),
                                    ),
                                    title: Text(
                                        '${tx.category} · ${tx.subCategory ?? "未细分"}'),
                                    subtitle: Text(
                                        '${formatBillTime(tx.createdAt)} · ${tx.note ?? "无备注"}'),
                                    trailing: Text(
                                      '-${formatAmount(tx.amount)}',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: Colors.redAccent),
                                    ),
                                    onTap: () => _edit(tx, ledger),
                                  ),
                                )).toList(),
                              ),
                            ),
                            const SizedBox(height: 10),
                          ],
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  /// 点账单弹出编辑框：改金额 / 改分类 / 改备注。
  void _edit(Transaction tx, LedgerProvider ledger) {
    final amountController =
        TextEditingController(text: tx.amount.toStringAsFixed(2));
    final noteController = TextEditingController(text: tx.note ?? '');
    String category = tx.category;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('编辑账单'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: amountController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: '金额'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: category,
                  items: AppCategories.primaries
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => category = value);
                  },
                  decoration: const InputDecoration(labelText: '用途分类'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: noteController,
                  decoration: const InputDecoration(labelText: '备注'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                final amount = double.tryParse(amountController.text.trim());
                if (amount == null || amount <= 0) return;
                ledger.update(tx.copyWith(
                  amount: amount,
                  category: category,
                  note: noteController.text.trim().isEmpty
                      ? null
                      : noteController.text.trim(),
                ));
                Navigator.pop(ctx);
              },
              child: const Text('保存'),
            ),
          ],
        ),
      ),
    );
  }
}
