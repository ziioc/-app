import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/categories.dart';
import '../models/transaction.dart';
import '../providers/ledger_provider.dart';
import '../services/amount_parser.dart';

/// 点击通知后弹出的「选择用途」小窗（底部弹层）。
///
/// 顶部金额已经预填、可修改；选一级分类后展开二级分类；
/// 点保存即写入账本。手动记账时传入金额 0，由用户自己填。
class CategoryPickerSheet extends StatefulWidget {
  final double initialAmount;
  final String source;

  const CategoryPickerSheet({
    super.key,
    required this.initialAmount,
    required this.source,
  });

  @override
  State<CategoryPickerSheet> createState() => _CategoryPickerSheetState();
}

class _CategoryPickerSheetState extends State<CategoryPickerSheet> {
  late final TextEditingController _amountController;
  final TextEditingController _noteController = TextEditingController();
  String? _primary;
  String? _secondary;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.initialAmount > 0
          ? widget.initialAmount.toStringAsFixed(2)
          : '',
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _save() {
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      _tip('请填写正确的金额');
      return;
    }
    if (_primary == null) {
      _tip('请先选一个用途分类');
      return;
    }

    final tx = Transaction(
      amount: amount,
      category: _primary!,
      subCategory: _secondary,
      source: widget.source.isEmpty ? 'manual' : widget.source,
      note: _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim(),
      createdAt: DateTime.now(),
    );
    context.read<LedgerProvider>().add(tx);
    Navigator.of(context).pop(true);
    _tip('已记入账本');
  }

  void _tip(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sourceLabel = widget.source.isEmpty
        ? '手动记账'
        : AmountParser.sourceLabel(widget.source);

    return Padding(
      // 键盘弹出时整体上移，避免输入框被挡住。
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '这笔钱花在哪了？',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              '来源：$sourceLabel',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 16),

            // 金额输入框：预填支付通知里解析到的金额，用户可改。
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF3F7DE0)),
              decoration: InputDecoration(
                prefixText: '¥ ',
                prefixStyle: const TextStyle(fontSize: 20, color: Color(0xFF3F7DE0)),
                filled: true,
                fillColor: const Color(0xFFF0F5FF),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
            const SizedBox(height: 18),

            // 一级分类网格。
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 0.9,
              ),
              itemCount: AppCategories.primaries.length,
              itemBuilder: (context, index) {
                final name = AppCategories.primaries[index];
                final selected = _primary == name;
                final color = AppCategories.colorOf(name);
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _primary = name;
                      _secondary = null; // 换一级分类时清掉旧的二级选择
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: selected ? color.withValues(alpha: 0.15) : Colors.grey.shade50,
                      border: Border.all(
                        color: selected ? color : Colors.grey.shade200,
                        width: selected ? 1.5 : 1,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(AppCategories.iconOf(name),
                            size: 22, color: selected ? color : Colors.grey.shade600),
                        const SizedBox(height: 6),
                        Text(
                          name,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            color: selected ? color : Colors.black87,
                            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            // 选中一级分类后，展开二级分类供细选。
            if (_primary != null) ...[
              const SizedBox(height: 16),
              Text(
                '${_primary!} · 细分（可不选）',
                style: const TextStyle(fontSize: 13, color: Colors.black54),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: AppCategories.data[_primary!]!.map((sub) {
                  final selected = _secondary == sub;
                  return ChoiceChip(
                    label: Text(sub),
                    selected: selected,
                    onSelected: (_) {
                      setState(() => _secondary = selected ? null : sub);
                    },
                    selectedColor: const Color(0xFFDCE9FF),
                  );
                }).toList(),
              ),
            ],

            const SizedBox(height: 16),
            TextField(
              controller: _noteController,
              decoration: InputDecoration(
                labelText: '备注（可不填）',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
            const SizedBox(height: 18),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text('取消'),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    onPressed: _save,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text('保存'),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 快捷调用：弹出分类小窗，返回 true 表示保存成功。
Future<bool?> showCategoryPicker(
  BuildContext context, {
  required double amount,
  required String source,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => CategoryPickerSheet(initialAmount: amount, source: source),
  );
}
