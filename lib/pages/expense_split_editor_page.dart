import 'package:flutter/material.dart';

import '../models/bill_split.dart';
import '../models/category_entry.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../utils/icon_helper.dart';
import '../data/account_data.dart';

class ExpenseSplitEditorResult {
  final List<BillSplitDraft> splits;
  final String note;
  final DateTime date;

  const ExpenseSplitEditorResult({
    required this.splits,
    required this.note,
    required this.date,
  });

  double get totalAmount =>
      splits.fold<double>(0, (sum, item) => sum + item.amount);
}

class ExpenseSplitEditorPage extends StatefulWidget {
  const ExpenseSplitEditorPage({
    super.key,
    required this.categories,
    this.initialSplits = const [],
    this.initialNote,
    this.initialDate,
  });

  final List<CategoryEntry> categories;
  final List<BillSplitDraft> initialSplits;
  final String? initialNote;
  final DateTime? initialDate;

  @override
  State<ExpenseSplitEditorPage> createState() => _ExpenseSplitEditorPageState();
}

class _ExpenseSplitEditorPageState extends State<ExpenseSplitEditorPage> {
  late final Map<int, TextEditingController> _controllers;
  late final TextEditingController _noteController;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _controllers = {
      for (final category in widget.categories)
        category.iconId: TextEditingController(
          text: _initialAmountText(category.iconId),
        ),
    };
    _noteController = TextEditingController(text: widget.initialNote ?? '');
    _selectedDate = widget.initialDate ?? DateTime.now();
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    _noteController.dispose();
    super.dispose();
  }

  String _initialAmountText(int iconId) {
    for (final split in widget.initialSplits) {
      if (split.iconId == iconId) {
        return formatAmount(split.amount);
      }
    }
    return '';
  }

  double get _totalAmount {
    var total = 0.0;
    for (final controller in _controllers.values) {
      total += double.tryParse(controller.text.trim()) ?? 0;
    }
    return total;
  }

  List<BillSplitDraft> _buildSplits() {
    final result = <BillSplitDraft>[];
    for (final category in widget.categories) {
      final amount = double.tryParse(
        _controllers[category.iconId]!.text.trim(),
      );
      if (amount != null && amount > 0) {
        result.add(
          BillSplitDraft(
            category: category.name,
            iconId: category.iconId,
            amount: amount,
          ),
        );
      }
    }
    return result;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      locale: const Locale('zh', 'CN'),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _submit() {
    final splits = _buildSplits();
    if (splits.isEmpty) return;
    Navigator.of(context).pop(
      ExpenseSplitEditorResult(
        splits: splits,
        note: _noteController.text.trim(),
        date: _selectedDate,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        title: const Text('分类金额'),
        actions: [
          TextButton(
            onPressed: _submit,
            child: const Text('完成'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppColors.surfaceStrong),
            ),
            child: Row(
              children: [
                const Text(
                  '总金额',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                buildAmountText(
                  value: _totalAmount,
                  integerStyle: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                  decimalStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppColors.surfaceStrong),
            ),
            child: Column(
              children: [
                for (final category in widget.categories) ...[
                  _SplitRow(
                    category: category,
                    controller: _controllers[category.iconId]!,
                    onChanged: (_) => setState(() {}),
                  ),
                  if (category != widget.categories.last)
                    const Divider(height: 20),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppColors.surfaceStrong),
            ),
            child: Column(
              children: [
                GestureDetector(
                  onTap: _pickDate,
                  behavior: HitTestBehavior.opaque,
                  child: Row(
                    children: [
                      const Text(
                        '日期',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.chevron_right_rounded),
                    ],
                  ),
                ),
                const Divider(height: 24),
                TextField(
                  controller: _noteController,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: '备注',
                    isCollapsed: true,
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SplitRow extends StatelessWidget {
  const _SplitRow({
    required this.category,
    required this.controller,
    required this.onChanged,
  });

  final CategoryEntry category;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final icon = iconJson[category.iconId];
    return Row(
      children: [
        Image.asset(iconPath(icon.iconL), width: 32, height: 32),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            category.name,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ),
        SizedBox(
          width: 120,
          child: TextField(
            controller: controller,
            onChanged: onChanged,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textAlign: TextAlign.right,
            decoration: const InputDecoration(
              hintText: '0.00',
              border: InputBorder.none,
              isCollapsed: true,
            ),
          ),
        ),
      ],
    );
  }
}
