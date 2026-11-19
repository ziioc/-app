import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/categories.dart';
import '../providers/ledger_provider.dart';
import '../services/payment_monitor.dart';
import '../utils/format.dart';
import '../widgets/category_picker_sheet.dart';
import 'bills_page.dart';
import 'settings_page.dart';
import 'stats_page.dart';

/// 主壳：底部三个 Tab + 右下角「记一笔」按钮。
///
/// 同时负责监听「待归类的支付」：无论是 App 内还是从通知点进来，
/// 收到就弹出分类小窗。
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  StreamSubscription<PendingPayment>? _subscription;

  @override
  void initState() {
    super.initState();
    // App 没打开时点了通知：先处理缓存里的那一笔。
    final cached = PendingPaymentStore.take();
    if (cached != null) _openPicker(cached);

    // App 正在运行时收到新支付，也自动弹小窗。
    _subscription = PendingPaymentStore.stream.listen(_openPicker);
  }

  void _openPicker(PendingPayment payment) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showCategoryPicker(
        context,
        amount: payment.amount,
        source: payment.source,
      );
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('随手账'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: '设置',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsPage()),
              );
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          HomeTab(),
          BillsPage(),
          StatsPage(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showCategoryPicker(context, amount: 0, source: ''),
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: const Color(0xFF3F7DE0),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: '首页'),
          BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long_outlined), label: '账单'),
          BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart_outlined), label: '统计'),
        ],
      ),
    );
  }
}

/// 首页内容：本月总额 + 分类占比 + 最近账单。
class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<LedgerProvider>(
      builder: (context, ledger, _) {
        if (ledger.loading) {
          return const Center(child: CircularProgressIndicator());
        }

        final sums = ledger.categorySums;
        final sorted = sums.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        final recent = ledger.transactions.take(5).toList();

        return RefreshIndicator(
          onRefresh: ledger.load,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _TotalCard(total: ledger.monthTotal, month: DateTime.now()),
              const SizedBox(height: 20),
              const Text('本月分类',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              if (sums.isEmpty)
                _emptyCard('还没有账单，支付后点通知即可记账')
              else
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      children: sorted.take(6).map((entry) {
                        final ratio = ledger.monthTotal == 0
                            ? 0.0
                            : entry.value / ledger.monthTotal;
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 7),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    AppCategories.iconOf(entry.key),
                                    size: 16,
                                    color: AppCategories.colorOf(entry.key),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(entry.key,
                                      style: const TextStyle(fontSize: 13)),
                                  const Spacer(),
                                  Text(formatAmount(entry.value),
                                      style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600)),
                                ],
                              ),
                              const SizedBox(height: 5),
                              LinearProgressIndicator(
                                value: ratio,
                                backgroundColor: Colors.grey.shade200,
                                color: AppCategories.colorOf(entry.key),
                                minHeight: 5,
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              const SizedBox(height: 20),
              const Text('最近账单',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              if (recent.isEmpty)
                _emptyCard('暂无记录')
              else
                Card(
                  child: Column(
                    children: recent.map((tx) => ListTile(
                      leading: CircleAvatar(
                        backgroundColor:
                            AppCategories.colorOf(tx.category).withValues(alpha: 0.15),
                        child: Icon(AppCategories.iconOf(tx.category),
                            size: 18,
                            color: AppCategories.colorOf(tx.category)),
                      ),
                      title: Text(tx.subCategory ?? tx.category),
                      subtitle: Text(formatBillTime(tx.createdAt)),
                      trailing: Text(
                        '-${formatAmount(tx.amount)}',
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, color: Colors.redAccent),
                      ),
                    )).toList(),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

Widget _emptyCard(String text) => Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Text(text, style: const TextStyle(color: Colors.grey)),
        ),
      ),
    );

class _TotalCard extends StatelessWidget {
  final double total;
  final DateTime month;

  const _TotalCard({required this.total, required this.month});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFF3F7DE0),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${monthLabel(month)} · 总支出',
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 8),
          Text(
            formatAmount(total),
            style: const TextStyle(
                color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
