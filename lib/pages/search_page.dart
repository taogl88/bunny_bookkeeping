import 'package:flutter/material.dart';

import '../data/account_data.dart';
import '../db/database_helper.dart';
import '../models/bill_item.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../utils/icon_helper.dart';
import '../widgets/date_picker.dart';

enum _SearchField { all, category, note, amount }

enum _EntryFilter { all, income, expense }

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _queryCtrl = TextEditingController();
  late final Future<List<BillItem>> _billsFuture;

  bool _filterOpen = false;

  _SearchField _activeSearchField = _SearchField.all;
  _EntryFilter _activeEntryFilter = _EntryFilter.all;
  bool _activeCustomTime = false;
  DateTime? _activeStartDate;
  DateTime? _activeEndDate;

  _SearchField _tempSearchField = _SearchField.all;
  _EntryFilter _tempEntryFilter = _EntryFilter.all;
  bool _tempCustomTime = false;
  DateTime? _tempStartDate;
  DateTime? _tempEndDate;

  @override
  void initState() {
    super.initState();
    _billsFuture = DatabaseHelper.instance.getAllBills();
  }

  @override
  void dispose() {
    _queryCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: AppColors.surface,
      body: Column(
        children: [
          _buildSearchHeader(),
          Expanded(
            child: FutureBuilder<List<BillItem>>(
              future: _billsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('加载失败: ${snapshot.error}'));
                }
                final bills = snapshot.data ?? const <BillItem>[];
                return Stack(
                  children: [
                    Positioned.fill(child: _buildResults(bills)),
                    if (_filterOpen) _buildFilterOverlay(),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchHeader() {
    return Container(
      color: AppColors.primary,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 12),
                      const Icon(Icons.search, size: 22, color: Colors.black87),
                      InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: _toggleFilter,
                        child: SizedBox(
                          height: 40,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(width: 6),
                              const Text(
                                '筛选',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              Icon(
                                _filterOpen
                                    ? Icons.arrow_drop_up
                                    : Icons.arrow_drop_down,
                                size: 20,
                                color: Colors.black87,
                              ),
                              const SizedBox(width: 4),
                            ],
                          ),
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 20,
                        color: const Color(0xFFE2E2E2),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _queryCtrl,
                          textInputAction: TextInputAction.search,
                          onChanged: (_) => setState(() {}),
                          decoration: const InputDecoration(
                            isCollapsed: true,
                            border: InputBorder.none,
                            hintText: '搜索类别/标签/备注/金额',
                            hintStyle: TextStyle(
                              fontSize: 13,
                              color: Color(0xFFAAAAAA),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      if (_queryCtrl.text.isNotEmpty)
                        GestureDetector(
                          onTap: () {
                            _queryCtrl.clear();
                            setState(() {});
                          },
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 10),
                            child: Icon(
                              Icons.cancel,
                              size: 20,
                              color: Color(0xFFB7B7B7),
                            ),
                          ),
                        )
                      else
                        const SizedBox(width: 10),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => Navigator.of(context).pop(),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 2, vertical: 8),
                  child: Text(
                    '取消',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterOverlay() {
    return Positioned.fill(
      child: Column(
        children: [
          Material(
            color: Colors.white,
            elevation: 2,
            child: _buildFilterPanel(),
          ),
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => setState(() => _filterOpen = false),
              child: Container(color: Colors.black.withAlpha(150)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterPanel() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 22, 16, 18),
          child: Column(
            children: [
              _buildFilterRow(
                label: '类型',
                children: [
                  _buildChoice(
                    label: '不限',
                    value: _SearchField.all,
                    groupValue: _tempSearchField,
                    onSelected: (value) => _tempSearchField = value,
                  ),
                  _buildChoice(
                    label: '类别',
                    value: _SearchField.category,
                    groupValue: _tempSearchField,
                    onSelected: (value) => _tempSearchField = value,
                  ),
                  _buildChoice(
                    label: '备注',
                    value: _SearchField.note,
                    groupValue: _tempSearchField,
                    onSelected: (value) => _tempSearchField = value,
                  ),
                  _buildChoice(
                    label: '金额',
                    value: _SearchField.amount,
                    groupValue: _tempSearchField,
                    onSelected: (value) => _tempSearchField = value,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildFilterRow(
                label: '收支',
                children: [
                  _buildChoice(
                    label: '不限',
                    value: _EntryFilter.all,
                    groupValue: _tempEntryFilter,
                    onSelected: (value) => _tempEntryFilter = value,
                  ),
                  _buildChoice(
                    label: '收入',
                    value: _EntryFilter.income,
                    groupValue: _tempEntryFilter,
                    onSelected: (value) => _tempEntryFilter = value,
                  ),
                  _buildChoice(
                    label: '支出',
                    value: _EntryFilter.expense,
                    groupValue: _tempEntryFilter,
                    onSelected: (value) => _tempEntryFilter = value,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildFilterRow(
                label: '时间',
                children: [
                  _buildChoice(
                    label: '不限',
                    value: false,
                    groupValue: _tempCustomTime,
                    onSelected: (value) {
                      _tempCustomTime = value;
                      if (!value) {
                        _tempStartDate = null;
                        _tempEndDate = null;
                      }
                    },
                  ),
                  _buildChoice(
                    label: '自定义',
                    value: true,
                    groupValue: _tempCustomTime,
                    onSelected: (value) => _tempCustomTime = value,
                  ),
                ],
              ),
              if (_tempCustomTime) ...[
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.only(left: 78),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildDateButton(
                          text: _tempStartDate == null
                              ? '开始时间'
                              : _formatDate(_tempStartDate!),
                          selected: _tempStartDate != null,
                          onTap: () => _pickDate(isStart: true),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          '-',
                          style: TextStyle(fontSize: 18, color: Colors.black87),
                        ),
                      ),
                      Expanded(
                        child: _buildDateButton(
                          text: _tempEndDate == null
                              ? '结束时间'
                              : _formatDate(_tempEndDate!),
                          selected: _tempEndDate != null,
                          onTap: () => _pickDate(isStart: false),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        const Divider(height: 1, color: Color(0xFFEDEDED)),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            children: [
              Expanded(child: _buildResetButton()),
              const SizedBox(width: 16),
              Expanded(
                child: _buildPanelButton(
                  label: '确定',
                  color: AppColors.primary,
                  textColor: Colors.black87,
                  onTap: _applyFilters,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFilterRow({
    required String label,
    required List<Widget> children,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 62,
          height: 36,
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
          ),
        ),
        Expanded(
          child: Row(
            spacing: 8,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildChoice<T>({
    required String label,
    required T value,
    required T groupValue,
    required ValueChanged<T> onSelected,
  }) {
    final selected = value == groupValue;
    return GestureDetector(
      onTap: () => setState(() => onSelected(value)),
      child: Container(
        constraints: const BoxConstraints(minWidth: 58),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : const Color(0xFFF6F7F9),
          borderRadius: BorderRadius.circular(18),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.black87 : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildDateButton({
    required String text,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        height: 36,
        decoration: BoxDecoration(
          color: const Color(0xFFF6F7F9),
          borderRadius: BorderRadius.circular(18),
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.black87 : const Color(0xFF9DA3A6),
          ),
        ),
      ),
    );
  }

  Widget _buildResetButton() {
    final isAllDefault =
        _tempSearchField == _SearchField.all &&
        _tempEntryFilter == _EntryFilter.all &&
        !_tempCustomTime;
    return _buildPanelButton(
      label: '重置',
      color: isAllDefault ? const Color(0xFFEDEFF2) : Colors.black87,
      textColor: isAllDefault ? const Color(0xFF9DA3A6) : Colors.white,
      onTap: _resetFilters,
    );
  }

  Widget _buildPanelButton({
    required String label,
    required Color color,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(5),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: textColor,
          ),
        ),
      ),
    );
  }

  Widget _buildResults(List<BillItem> bills) {
    final results = _filterBills(bills);
    if (results.isEmpty) {
      return _buildEmptyState();
    }

    final grouped = <String, List<BillItem>>{};
    for (final bill in results) {
      final day = _billDay(bill);
      grouped.putIfAbsent(day, () => []).add(bill);
    }
    final days = grouped.keys.toList();

    return Column(
      children: [
        _buildSummaryBar(results),
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).padding.bottom + 12,
            ),
            itemCount: days.length,
            itemBuilder: (context, index) {
              final day = days[index];
              final items = grouped[day]!;
              return Column(
                children: [
                  _buildDayHeader(day, items),
                  ...items.map(_buildBillTile),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryBar(List<BillItem> results) {
    return Container(
      height: 36,
      color: const Color(0xFFFFF9E8),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      alignment: Alignment.centerLeft,
      child: Text(
        _summaryText(results),
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: Color(0xFF4A3523),
        ),
      ),
    );
  }

  Widget _buildDayHeader(String day, List<BillItem> items) {
    final income = items
        .where((bill) => bill.type == 'income')
        .fold<double>(0, (sum, bill) => sum + bill.amount);
    final expense = items
        .where((bill) => bill.type == 'expense')
        .fold<double>(0, (sum, bill) => sum + bill.amount);

    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFF2F2F2))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            _formatChineseDay(day),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF9A9A9A),
            ),
          ),
          Flexible(
            child: Text(
              _daySummaryText(income: income, expense: expense),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF9A9A9A),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBillTile(BillItem bill) {
    final isExpense = bill.type == 'expense';
    final title = bill.note.trim().isNotEmpty
        ? bill.note.trim()
        : bill.category;
    return Container(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 8),
      color: Colors.white,
      child: Row(
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: Center(
              child: bill.iconId >= 0 && bill.iconId < iconJson.length
                  ? Image.asset(
                      iconPath(iconJson[bill.iconId].iconL),
                      width: 36,
                      height: 36,
                      errorBuilder: (_, _, _) => const Icon(
                        Icons.receipt,
                        size: 36,
                        color: AppColors.textSecondary,
                      ),
                    )
                  : const Icon(
                      Icons.receipt,
                      size: 36,
                      color: AppColors.textSecondary,
                    ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '${isExpense ? '-' : '+'}${formatAmount(bill.amount)}',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.receipt_long_outlined, size: 58, color: Color(0xFFD0D0D0)),
          SizedBox(height: 8),
          Text(
            '暂无数据',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFFB8B8B8),
            ),
          ),
        ],
      ),
    );
  }

  List<BillItem> _filterBills(List<BillItem> bills) {
    final query = _queryCtrl.text.trim().toLowerCase();
    final hasTimeFilter =
        _activeCustomTime &&
        (_activeStartDate != null || _activeEndDate != null);
    final hasCriteria =
        query.isNotEmpty ||
        _activeEntryFilter != _EntryFilter.all ||
        hasTimeFilter;
    if (!hasCriteria) return const <BillItem>[];

    final results = bills.where((bill) {
      if (_activeEntryFilter == _EntryFilter.income && bill.type != 'income') {
        return false;
      }
      if (_activeEntryFilter == _EntryFilter.expense &&
          bill.type != 'expense') {
        return false;
      }

      if (hasTimeFilter) {
        final day = _billDay(bill);
        if (_activeStartDate != null &&
            day.compareTo(_formatDate(_activeStartDate!)) < 0) {
          return false;
        }
        if (_activeEndDate != null &&
            day.compareTo(_formatDate(_activeEndDate!)) > 0) {
          return false;
        }
      }

      if (query.isEmpty) return true;
      return _matchesQuery(bill, query);
    }).toList()..sort(_compareBillDesc);

    return results;
  }

  bool _matchesQuery(BillItem bill, String query) {
    bool contains(String value) => value.toLowerCase().contains(query);

    switch (_activeSearchField) {
      case _SearchField.category:
        return contains(bill.category);
      case _SearchField.note:
        return contains(bill.note);
      case _SearchField.amount:
        return _amountMatches(bill.amount, query);
      case _SearchField.all:
        return contains(bill.category) ||
            contains(bill.note) ||
            _amountMatches(bill.amount, query);
    }
  }

  bool _amountMatches(double amount, String query) {
    final candidates = <String>{
      formatAmount(amount),
      amount.toStringAsFixed(2),
      amount.toString(),
    };
    return candidates.any((value) => value.toLowerCase().contains(query));
  }

  int _compareBillDesc(BillItem a, BillItem b) {
    final dayCompare = _billDay(b).compareTo(_billDay(a));
    if (dayCompare != 0) return dayCompare;
    final sortCompare = b.sortAt.compareTo(a.sortAt);
    if (sortCompare != 0) return sortCompare;
    return b.date.compareTo(a.date);
  }

  void _toggleFilter() {
    FocusScope.of(context).unfocus();
    setState(() {
      if (_filterOpen) {
        _filterOpen = false;
        return;
      }
      _tempSearchField = _activeSearchField;
      _tempEntryFilter = _activeEntryFilter;
      _tempCustomTime = _activeCustomTime;
      _tempStartDate = _activeStartDate;
      _tempEndDate = _activeEndDate;
      _filterOpen = true;
    });
  }

  void _applyFilters() {
    setState(() {
      _activeSearchField = _tempSearchField;
      _activeEntryFilter = _tempEntryFilter;
      _activeCustomTime = _tempCustomTime;
      _activeStartDate = _tempCustomTime ? _tempStartDate : null;
      _activeEndDate = _tempCustomTime ? _tempEndDate : null;
      _filterOpen = false;
    });
  }

  void _resetFilters() {
    setState(() {
      _activeSearchField = _SearchField.all;
      _activeEntryFilter = _EntryFilter.all;
      _activeCustomTime = false;
      _activeStartDate = null;
      _activeEndDate = null;
      _tempSearchField = _SearchField.all;
      _tempEntryFilter = _EntryFilter.all;
      _tempCustomTime = false;
      _tempStartDate = null;
      _tempEndDate = null;
    });
  }

  Future<void> _pickDate({required bool isStart}) async {
    final initialDate = isStart
        ? (_tempStartDate ?? _tempEndDate ?? DateTime.now())
        : (_tempEndDate ?? _tempStartDate ?? DateTime.now());
    final result = await showModalBottomSheet<DateTime>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => DatePicker(initialDate: initialDate),
    );
    if (result == null || !mounted) return;

    final picked = DateTime(result.year, result.month, result.day);
    setState(() {
      if (isStart) {
        _tempStartDate = picked;
        if (_tempEndDate != null && picked.isAfter(_tempEndDate!)) {
          _tempEndDate = picked;
        }
      } else {
        _tempEndDate = picked;
        if (_tempStartDate != null && picked.isBefore(_tempStartDate!)) {
          _tempStartDate = picked;
        }
      }
    });
  }

  String _summaryText(List<BillItem> results) {
    final income = results
        .where((bill) => bill.type == 'income')
        .fold<double>(0, (sum, bill) => sum + bill.amount);
    final expense = results
        .where((bill) => bill.type == 'expense')
        .fold<double>(0, (sum, bill) => sum + bill.amount);
    final count = results.length;

    if (income > 0 && expense > 0) {
      return '$count笔：收入 ${income.toStringAsFixed(2)}  支出 ${expense.toStringAsFixed(2)}';
    }
    if (income > 0) {
      return '$count笔收入：${income.toStringAsFixed(2)}';
    }
    return '$count笔支出：${expense.toStringAsFixed(2)}';
  }

  String _daySummaryText({required double income, required double expense}) {
    if (income > 0 && expense > 0) {
      return '收入：${formatAmount(income)}  支出：${formatAmount(expense)}';
    }
    if (income > 0) return '收入：${formatAmount(income)}';
    return '支出：${formatAmount(expense)}';
  }

  String _formatChineseDay(String day) {
    if (day.length >= 10) {
      return '${day.substring(0, 4)}年${day.substring(5, 7)}月${day.substring(8, 10)}日';
    }
    return day;
  }

  String _billDay(BillItem bill) {
    final date = bill.date.trim();
    if (date.length >= 10) return date.substring(0, 10);
    return date;
  }

  String _formatDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }
}
