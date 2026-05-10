import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/account_data.dart';
import '../models/bill_item.dart';
import '../providers/bill_provider.dart';
import '../providers/budget_provider.dart';
import '../providers/keyboard_provider.dart';
import '../providers/navigation_provider.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../utils/icon_helper.dart';
import '../widgets/month_picker.dart';

class BookkeepingCalendarPage extends ConsumerStatefulWidget {
  const BookkeepingCalendarPage({super.key});

  @override
  ConsumerState<BookkeepingCalendarPage> createState() =>
      _BookkeepingCalendarPageState();
}

class _BookkeepingCalendarPageState
    extends ConsumerState<BookkeepingCalendarPage> {
  static const _incomeColor = Color(0xFF15936F);
  static const _expenseColor = Color(0xFFD9566D);
  static const _overBudgetFill = Color(0xFFFFEEF5);
  static const _underBudgetFill = Color(0xFFEAF8F4);
  static const _overBudgetDot = Color(0xFFFFC7DD);
  static const _underBudgetDot = Color(0xFFCDEFE5);

  DateTime? _selectedDate;
  String? _activeMenuBillId;

  @override
  void initState() {
    super.initState();
    final month = ref.read(selectedMonthProvider);
    _selectedDate = _defaultSelectedDate(_parseMonth(month));
  }

  @override
  Widget build(BuildContext context) {
    final month = ref.watch(selectedMonthProvider);
    final visibleMonth = _parseMonth(month);
    final billsAsync = ref.watch(billListProvider);
    final monthlyBudgetAsync = ref.watch(monthlyTotalBudgetProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Column(
        children: [
          _buildHeader(context, visibleMonth),
          Expanded(
            child: billsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('加载失败: $e')),
              data: (bills) => _buildContent(
                visibleMonth: visibleMonth,
                bills: bills,
                totalBudget: monthlyBudgetAsync.value ?? 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, DateTime visibleMonth) {
    return Container(
      color: AppColors.primary,
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 56,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned(
                left: 2,
                top: 0,
                bottom: 0,
                child: IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back, size: 30),
                  color: AppColors.textPrimary,
                  tooltip: '返回',
                ),
              ),
              Center(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _pickMonth(visibleMonth),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 10,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(width: 10),
                        Text(
                          '${visibleMonth.year}年${visibleMonth.month}月',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const Icon(
                          Icons.arrow_drop_down,
                          size: 24,
                          color: AppColors.textPrimary,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 14,
                top: 0,
                bottom: 0,
                child: Center(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _jumpToToday,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 10,
                      ),
                      child: Text(
                        '今天',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
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

  Widget _buildContent({
    required DateTime visibleMonth,
    required List<BillItem> bills,
    required double totalBudget,
  }) {
    final data = _CalendarData.fromBills(bills);
    final selectedDate = _selectedForMonth(visibleMonth);
    final selectedDay = _formatDay(selectedDate);
    final selectedBills = data.billsByDay[selectedDay] ?? const <BillItem>[];
    final selectedSummary =
        data.summaryByDay[selectedDay] ?? const _DaySummary();
    final daysInMonth = DateUtils.getDaysInMonth(
      visibleMonth.year,
      visibleMonth.month,
    );
    final hasBudget = totalBudget > 0;
    final dailyBudget = hasBudget ? totalBudget / daysInMonth : 0.0;

    return Column(
      children: [
        _buildCalendarPanel(
          visibleMonth: visibleMonth,
          data: data,
          selectedDate: selectedDate,
          hasBudget: hasBudget,
          dailyBudget: dailyBudget,
        ),
        if (hasBudget)
          _buildBudgetLegend(dailyBudget)
        else
          const SizedBox(height: 12),
        Container(height: 8, color: AppColors.backgroundGray),
        Expanded(
          child: _buildSelectedDayDetails(
            day: selectedDate,
            bills: selectedBills,
            summary: selectedSummary,
          ),
        ),
      ],
    );
  }

  Widget _buildCalendarPanel({
    required DateTime visibleMonth,
    required _CalendarData data,
    required DateTime selectedDate,
    required bool hasBudget,
    required double dailyBudget,
  }) {
    final days = _calendarDaysForMonth(visibleMonth);
    final weekCount = days.length ~/ 7;
    final rowHeight = weekCount > 5 ? 64.0 : 72.0;

    return Container(
      color: AppColors.surface,
      child: Column(
        children: [
          const SizedBox(height: 12),
          _buildWeekHeader(),
          SizedBox(
            height: rowHeight * weekCount,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final cellWidth = (constraints.maxWidth - 16) / 7;
                return GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: days.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    childAspectRatio: cellWidth / rowHeight,
                  ),
                  itemBuilder: (context, index) {
                    final day = days[index];
                    final dayKey = _formatDay(day);
                    final summary =
                        data.summaryByDay[dayKey] ?? const _DaySummary();
                    return _CalendarDayCell(
                      date: day,
                      summary: summary,
                      isCurrentMonth: _sameMonth(day, visibleMonth),
                      isSelected: _sameDay(day, selectedDate),
                      isToday: _sameDay(day, DateTime.now()),
                      hasBudget: hasBudget,
                      dailyBudget: dailyBudget,
                      incomeColor: _incomeColor,
                      expenseColor: _expenseColor,
                      overBudgetFill: _overBudgetFill,
                      underBudgetFill: _underBudgetFill,
                      onTap: _sameMonth(day, visibleMonth)
                          ? () => setState(() => _selectedDate = day)
                          : null,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekHeader() {
    const weekdays = ['一', '二', '三', '四', '五', '六', '日'];
    return SizedBox(
      height: 32,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            for (final weekday in weekdays)
              Expanded(
                child: Center(
                  child: Text(
                    weekday,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetLegend(double dailyBudget) {
    return Container(
      height: 48,
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '日均预算：${formatAmount(dailyBudget)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          _LegendItem(color: _overBudgetDot, label: '超出预算'),
          const SizedBox(width: 8),
          _LegendItem(color: _underBudgetDot, label: '未超出预算'),
        ],
      ),
    );
  }

  Widget _buildSelectedDayDetails({
    required DateTime day,
    required List<BillItem> bills,
    required _DaySummary summary,
  }) {
    final sortedBills = [...bills]..sort(_compareBillsDesc);

    return Container(
      color: AppColors.surface,
      child: Column(
        children: [
          _buildSelectedDayHeader(day, summary),
          Expanded(
            child: sortedBills.isEmpty
                ? Center(
                    child: Text(
                      '暂无账单',
                      style: TextStyle(
                        color: AppColors.textSecondary.withAlpha(170),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).padding.bottom + 96,
                    ),
                    itemCount: sortedBills.length,
                    itemBuilder: (context, index) {
                      final bill = sortedBills[index];
                      return Column(
                        children: [
                          _billTile(context, ref, bill),
                          if (index < sortedBills.length - 1)
                            const Divider(
                              height: 1,
                              indent: 72,
                              color: Color(0xFFF2F2F2),
                            ),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedDayHeader(DateTime day, _DaySummary summary) {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: Color(0xFFF2F2F2))),
      ),
      child: Row(
        children: [
          Text(
            _formatDetailDay(day),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF8F8F8F),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _summaryText(summary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF8F8F8F),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _billTile(BuildContext context, WidgetRef ref, BillItem bill) {
    final prefix = bill.type == 'expense' ? '-' : '+';
    final isMenuActive = _activeMenuBillId == bill.id;
    final title = bill.note.trim().isNotEmpty
        ? bill.note.trim()
        : bill.category;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onLongPressStart: (details) =>
          _showBillMenu(context, ref, details.globalPosition, bill),
      child: AnimatedContainer(
        duration: isMenuActive
            ? Duration.zero
            : const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: isMenuActive
              ? AppColors.primaryLight
              : AppColors.primaryLight.withAlpha(0),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        child: Row(
          children: [
            bill.iconId >= 0 && bill.iconId < iconJson.length
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
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '$prefix${formatAmount(bill.amount)}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showBillMenu(
    BuildContext context,
    WidgetRef ref,
    Offset position,
    BillItem bill,
  ) async {
    setState(() => _activeMenuBillId = bill.id);
    final value = await showMenu<String>(
      context: context,
      color: Colors.white,
      menuPadding: EdgeInsets.zero,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx + 1,
        position.dy + 1,
      ),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      items: const [
        PopupMenuItem(
          value: 'delete',
          height: 30,
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Text('删除', style: TextStyle(fontSize: 14)),
        ),
        PopupMenuItem(
          value: 'edit',
          height: 30,
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Text('修改', style: TextStyle(fontSize: 14)),
        ),
      ],
    );
    if (!mounted || !context.mounted) return;

    if (_activeMenuBillId == bill.id) {
      setState(() => _activeMenuBillId = null);
    }
    if (value == 'delete') {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: Colors.white,
          title: const Text('确认删除'),
          content: Text('确定要删除「${bill.category}」￥${bill.amount} 的记账记录吗？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('删除'),
            ),
          ],
        ),
      );
      if (confirmed == true) {
        await ref.read(billListProvider.notifier).remove(bill.id);
      }
    } else if (value == 'edit') {
      ref.read(editingBillProvider.notifier).set(bill);
      ref.read(keyboardProvider.notifier).hide();
      ref.read(navigationProvider.notifier).setTab(2);
      if (context.mounted) Navigator.of(context).pop();
    }
  }

  Future<void> _pickMonth(DateTime visibleMonth) async {
    final result = await showModalBottomSheet<String>(
      context: context,
      builder: (_) => MonthPicker(
        initialYear: visibleMonth.year,
        initialMonth: visibleMonth.month,
      ),
    );
    if (result == null || !mounted) return;

    final pickedMonth = _parseMonth(result);
    setState(() => _selectedDate = _defaultSelectedDate(pickedMonth));
    ref.read(selectedMonthProvider.notifier).setMonth(result);
  }

  void _jumpToToday() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    setState(() => _selectedDate = today);
    ref.read(selectedMonthProvider.notifier).setMonth(_formatMonth(today));
  }

  DateTime _selectedForMonth(DateTime visibleMonth) {
    final selected = _selectedDate;
    if (selected != null && _sameMonth(selected, visibleMonth)) {
      return DateTime(selected.year, selected.month, selected.day);
    }
    return _defaultSelectedDate(visibleMonth);
  }

  DateTime _defaultSelectedDate(DateTime visibleMonth) {
    final now = DateTime.now();
    if (now.year == visibleMonth.year && now.month == visibleMonth.month) {
      return DateTime(now.year, now.month, now.day);
    }
    return DateTime(visibleMonth.year, visibleMonth.month, 1);
  }

  List<DateTime> _calendarDaysForMonth(DateTime visibleMonth) {
    final firstDay = DateTime(visibleMonth.year, visibleMonth.month, 1);
    final daysInMonth = DateUtils.getDaysInMonth(
      visibleMonth.year,
      visibleMonth.month,
    );
    final leadingDays = firstDay.weekday - 1;
    final rawCellCount = leadingDays + daysInMonth;
    final cellCount = math.max(35, ((rawCellCount + 6) ~/ 7) * 7);
    final startDay = firstDay.subtract(Duration(days: leadingDays));
    return List.generate(
      cellCount,
      (index) => DateTime(startDay.year, startDay.month, startDay.day + index),
    );
  }

  int _compareBillsDesc(BillItem a, BillItem b) {
    final dayCompare = _billDay(b).compareTo(_billDay(a));
    if (dayCompare != 0) return dayCompare;
    final sortCompare = b.sortAt.compareTo(a.sortAt);
    if (sortCompare != 0) return sortCompare;
    return b.date.compareTo(a.date);
  }

  String _summaryText(_DaySummary summary) {
    if (summary.income > 0 && summary.expense > 0) {
      return '收入：${formatAmount(summary.income)}    支出：${formatAmount(summary.expense)}';
    }
    if (summary.income > 0) return '收入：${formatAmount(summary.income)}';
    if (summary.expense > 0) return '支出：${formatAmount(summary.expense)}';
    return '';
  }

  String _formatDetailDay(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$month月$day日 ${_weekdayName(date)}';
  }

  String _weekdayName(DateTime date) {
    const names = ['星期一', '星期二', '星期三', '星期四', '星期五', '星期六', '星期日'];
    return names[date.weekday - 1];
  }

  String _billDay(BillItem bill) {
    final date = bill.date.trim();
    if (date.length >= 10) return date.substring(0, 10);
    return date;
  }

  DateTime _parseMonth(String value) {
    final year = int.tryParse(value.substring(0, 4)) ?? DateTime.now().year;
    final month = int.tryParse(value.substring(5, 7)) ?? DateTime.now().month;
    return DateTime(year, month, 1);
  }

  String _formatMonth(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}';
  }

  String _formatDay(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  bool _sameMonth(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month;

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

class _CalendarDayCell extends StatelessWidget {
  const _CalendarDayCell({
    required this.date,
    required this.summary,
    required this.isCurrentMonth,
    required this.isSelected,
    required this.isToday,
    required this.hasBudget,
    required this.dailyBudget,
    required this.incomeColor,
    required this.expenseColor,
    required this.overBudgetFill,
    required this.underBudgetFill,
    required this.onTap,
  });

  final DateTime date;
  final _DaySummary summary;
  final bool isCurrentMonth;
  final bool isSelected;
  final bool isToday;
  final bool hasBudget;
  final double dailyBudget;
  final Color incomeColor;
  final Color expenseColor;
  final Color overBudgetFill;
  final Color underBudgetFill;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final hasBudgetFill = isCurrentMonth && hasBudget && summary.hasBills;
    final isOverBudget = summary.expense > dailyBudget;
    final backgroundColor = hasBudgetFill
        ? (isOverBudget ? overBudgetFill : underBudgetFill)
        : Colors.transparent;
    final borderColor = isSelected
        ? AppColors.textPrimary
        : (isToday ? const Color(0xFFE2E2E2) : Colors.transparent);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 5),
        decoration: BoxDecoration(
          color: backgroundColor,
          border: Border.all(color: borderColor, width: isSelected ? 1.2 : 1),
          borderRadius: BorderRadius.circular(3),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isToday ? '今天' : '${date.day}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: isToday ? 12 : 13,
                fontWeight: FontWeight.w800,
                height: 1,
                color: isCurrentMonth
                    ? AppColors.textPrimary
                    : const Color(0xFFB6B6B6),
              ),
            ),
            const SizedBox(height: 2),
            _AmountLine(
              text: summary.income > 0
                  ? '+${formatAmount(summary.income)}'
                  : '',
              color: incomeColor,
              enabled: isCurrentMonth,
            ),
            _AmountLine(
              text: summary.expense > 0
                  ? '-${formatAmount(summary.expense)}'
                  : '',
              color: expenseColor,
              enabled: isCurrentMonth,
            ),
          ],
        ),
      ),
    );
  }
}

class _AmountLine extends StatelessWidget {
  const _AmountLine({
    required this.text,
    required this.color,
    required this.enabled,
  });

  final String text;
  final Color color;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 13,
      child: text.isEmpty
          ? const SizedBox.shrink()
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  text,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    height: 1,
                    color: enabled ? color : const Color(0xFFB6B6B6),
                  ),
                ),
              ),
            ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _CalendarData {
  const _CalendarData({required this.billsByDay, required this.summaryByDay});

  final Map<String, List<BillItem>> billsByDay;
  final Map<String, _DaySummary> summaryByDay;

  factory _CalendarData.fromBills(List<BillItem> bills) {
    final billsByDay = <String, List<BillItem>>{};
    final summaryByDay = <String, _DaySummary>{};

    for (final bill in bills) {
      final day = bill.date.length >= 10
          ? bill.date.substring(0, 10)
          : bill.date;
      billsByDay.putIfAbsent(day, () => <BillItem>[]).add(bill);
      final old = summaryByDay[day] ?? const _DaySummary();
      summaryByDay[day] = bill.type == 'income'
          ? old.copyWith(income: old.income + bill.amount, count: old.count + 1)
          : old.copyWith(
              expense: old.expense + bill.amount,
              count: old.count + 1,
            );
    }

    return _CalendarData(billsByDay: billsByDay, summaryByDay: summaryByDay);
  }
}

class _DaySummary {
  const _DaySummary({this.income = 0, this.expense = 0, this.count = 0});

  final double income;
  final double expense;
  final int count;

  bool get hasBills => count > 0;

  _DaySummary copyWith({double? income, double? expense, int? count}) {
    return _DaySummary(
      income: income ?? this.income,
      expense: expense ?? this.expense,
      count: count ?? this.count,
    );
  }
}
