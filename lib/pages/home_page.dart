import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/account_data.dart';
import '../models/bill_item.dart';
import '../providers/bill_provider.dart';
import '../providers/budget_provider.dart';
import '../providers/navigation_provider.dart';
import '../providers/settings_provider.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../utils/icon_helper.dart';
import '../widgets/month_picker.dart';
import 'asset_page.dart';
import 'bill_statement_page.dart';
import 'bookkeeping_calendar_page.dart';
import 'budget_manager_page.dart';
import 'search_page.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});
  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  bool _isLoadingMonth = false;
  int? _pendingMonthDirection;
  double _dragDistance = 0;
  DateTime? _dragStartTime;
  static const double _threshold = 18;
  static const Duration _minHoldDuration = Duration(seconds: 1);

  String _nextMonth(String ym) {
    final p = ym.split('-');
    final y = int.parse(p[0]);
    final m = int.parse(p[1]);
    return m == 12 ? '${y + 1}-01' : '$y-${(m + 1).toString().padLeft(2, '0')}';
  }

  String _prevMonth(String ym) {
    final p = ym.split('-');
    final y = int.parse(p[0]);
    final m = int.parse(p[1]);
    return m == 1 ? '${y - 1}-12' : '$y-${(m - 1).toString().padLeft(2, '0')}';
  }

  Future<void> _switchMonth(bool isNext) async {
    final current = ref.read(selectedMonthProvider);
    final target = isNext ? _nextMonth(current) : _prevMonth(current);
    await _refreshData(target);
  }

  Future<void> _refreshData([String? targetMonth]) async {
    setState(() => _isLoadingMonth = true);
    _dragStartTime = null;
    if (targetMonth != null) {
      ref.read(selectedMonthProvider.notifier).setMonth(targetMonth);
    } else {
      ref.invalidate(billListProvider);
    }
    await Future.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;
    setState(() {
      _isLoadingMonth = false;
      _pendingMonthDirection = null;
      _dragDistance = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final month = ref.watch(selectedMonthProvider);
    final summaryAsync = ref.watch(monthlySummaryProvider);
    final billsAsync = ref.watch(billListProvider);
    final year = month.substring(0, 4);
    final mon = month.substring(5);

    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFCE8DF), AppColors.scaffoldBg],
        ),
      ),
      child: Column(
        children: [
          _buildHeader(context, ref, year, mon, summaryAsync),
          Expanded(child: _buildTransactionList(billsAsync)),
        ],
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    WidgetRef ref,
    String year,
    String month,
    AsyncValue<MonthlySummary> summaryAsync,
  ) {
    final income = summaryAsync.value?.income ?? 0;
    final expense = summaryAsync.value?.expense ?? 0;
    final amountHidden = ref.watch(amountHiddenProvider).value ?? false;

    return Container(
      margin: const EdgeInsets.fromLTRB(14, 6, 14, 0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE86F51), Color(0xFFF19C7A)],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x2AD1674A),
            blurRadius: 26,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 2, 16, 10),
          child: Column(
            children: [
              SizedBox(
                height: 24,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const Text(
                      'bunny记账',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            onPressed: () => _openSearchPage(context),
                            icon: const Icon(Icons.search, size: 20),
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            constraints: const BoxConstraints(
                              minWidth: 0,
                              minHeight: 24,
                            ),
                            visualDensity: VisualDensity.compact,
                            style: IconButton.styleFrom(
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            color: Colors.white,
                            tooltip: '搜索',
                          ),
                          const SizedBox(width: 2),
                          IconButton(
                            onPressed: () => _openCalendarPage(context),
                            icon: const Icon(
                              Icons.calendar_today_outlined,
                              size: 18,
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            constraints: const BoxConstraints(
                              minWidth: 0,
                              minHeight: 24,
                            ),
                            visualDensity: VisualDensity.compact,
                            style: IconButton.styleFrom(
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            color: Colors.white,
                            tooltip: '记账日历',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  GestureDetector(
                    onTap: () async {
                      final result = await showModalBottomSheet<String>(
                        context: context,
                        builder: (_) => MonthPicker(
                          initialYear: int.parse(year),
                          initialMonth: int.parse(month),
                        ),
                      );
                      if (result != null) {
                        ref.read(selectedMonthProvider.notifier).setMonth(result);
                      }
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$year年',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              month,
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                height: 1.1,
                                color: Colors.white,
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.only(bottom: 2),
                              child: Text(
                                '月',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const Icon(
                              Icons.arrow_drop_down,
                              size: 20,
                              color: Colors.white,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 1,
                    height: 36,
                    color: Colors.white24,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '收入',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          amountHidden ? '****' : income.toStringAsFixed(2),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              '支出',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white70,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              onPressed: () {
                                ref.read(amountHiddenProvider.notifier).toggle();
                              },
                              icon: Icon(
                                amountHidden
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                size: 16,
                              ),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 16,
                                minHeight: 16,
                              ),
                              visualDensity: VisualDensity.compact,
                              style: IconButton.styleFrom(
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              color: Colors.white70,
                              tooltip: amountHidden ? '显示金额' : '隐藏金额',
                            ),
                          ],
                        ),
                        Text(
                          amountHidden ? '****' : expense.toStringAsFixed(2),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _quickActionItem(String iconPath, String label, VoidCallback onTap, {bool expanded = false}) {
    final content = GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.primaryLight.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(iconPath, width: 18, height: 18),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
    return expanded ? Expanded(child: content) : content;
  }

  Widget _buildTransactionList(AsyncValue<List<BillItem>> billsAsync) {
    return billsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('加载失败: $e')),
      data: (bills) {
        final sorted = [...bills]
          ..sort((a, b) {
            final d = b.date.substring(0, 10).compareTo(a.date.substring(0, 10));
            if (d != 0) return d;
            final s = b.sortAt.compareTo(a.sortAt);
            if (s != 0) return s;
            return b.date.compareTo(a.date);
          });
        final grouped = <String, List<BillItem>>{};
        for (final bill in sorted) {
          grouped.putIfAbsent(bill.date.substring(0, 10), () => []).add(bill);
        }
        final days = grouped.keys.toList();

        return _buildBillsListViewWithOverscroll(grouped, days);
      },
    );
  }

  Widget _buildEmptyWithScroll() {
    return Center(
      child: Text(
        '暂无数据',
        style: TextStyle(
          fontSize: 14,
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildDaySection(String day, List<BillItem> items) {
    final dayExpense = items.where((b) => b.type == 'expense').fold<double>(0, (s, b) => s + b.amount);
    final dayIncome = items.where((b) => b.type == 'income').fold<double>(0, (s, b) => s + b.amount);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_formatDayWithWeekday(day), style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
              Row(children: [
                if (dayIncome > 0) Text('收入：${formatAmount(dayIncome)}', style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                if (dayExpense > 0) Text('支出：${formatAmount(dayExpense)}', style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
              ]),
            ]),
        ),
        ...items.map((bill) => _billTile(bill)),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildBillsListViewWithOverscroll(Map<String, List<BillItem>> grouped, List<String> days) {
    Timer? holdTimer;

    void reset() {
      holdTimer?.cancel();
      _dragStartTime = null;
      _dragDistance = 0;
      _pendingMonthDirection = null;
    }

    return Listener(
      onPointerDown: (_) {
        _dragStartTime = DateTime.now();
        _dragDistance = 0;
        _pendingMonthDirection = null;

        holdTimer?.cancel();
        holdTimer = Timer(_minHoldDuration, () {});
      },
      onPointerMove: (event) {
        if (_isLoadingMonth) return;
        if (_dragStartTime == null) return;

        final elapsed = DateTime.now().difference(_dragStartTime!);
        if (elapsed < _minHoldDuration) return;

        final dy = event.delta.dy;
        setState(() {
          _dragDistance += dy.abs();
          if (dy > 0) {
            _pendingMonthDirection = 1;
          } else if (dy < 0) {
            _pendingMonthDirection = -1;
          }
        });
      },
      onPointerUp: (_) {
        holdTimer?.cancel();
        if (_dragStartTime != null && _pendingMonthDirection != null && _dragDistance >= _threshold) {
          _switchMonth(_pendingMonthDirection == 1);
        }
        reset();
      },
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(14, 12, 14, 4),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
              border: Border.all(color: AppColors.surfaceStrong),
            ),
            child: Row(
              children: [
                Expanded(child: _quickActionItem('assets/images/账单.png', '账单', () => _openBillStatement(context))),
                const SizedBox(width: 8),
                Expanded(child: _quickActionItem('assets/images/预算.png', '预算', () => _openBudgetManager(context))),
                const SizedBox(width: 8),
                Expanded(child: _quickActionItem('assets/images/资产管家.png', '资产', () => _openAssetPage(context))),
              ],
            ),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.fromLTRB(14, 0, 14, 8),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(22)),
                border: Border.all(color: AppColors.surfaceStrong),
              ),
              child: days.isEmpty
                  ? _buildEmptyWithScroll()
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.zero,
                      itemCount: days.length + 1,
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return _buildMonthSwitchHint();
                        }
                        final day = days[index - 1];
                        final items = grouped[day]!;
                        return Column(
                          children: [
                            if (index > 1)
                              const Divider(height: 1, color: Color(0x0F4A3429), indent: 16, endIndent: 16),
                            _buildDaySection(day, items),
                          ],
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthSwitchHint() {
    final showSpinner = _isLoadingMonth;
    final showHint = _pendingMonthDirection != null && _dragDistance > 0;
    if (!showSpinner && !showHint) {
      return const SizedBox.shrink();
    }
    return SizedBox(
      height: 48,
      child: Center(
        child: showSpinner
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(
                _pendingMonthDirection == 1 ? '松手展示下个月' : '松手展示上个月',
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
      ),
    );
  }

  Widget _billTile(BillItem bill) {
    final prefix = bill.type == 'expense' ? '-' : '+';
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        ref.read(editingBillProvider.notifier).set(bill);
        ref.read(navigationProvider.notifier).openBillingFromCurrentTab();
      },
      onLongPress: () => _showBillActionsSheet(bill),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            bill.iconId >= 0 && bill.iconId < iconJson.length
                ? Image.asset(iconPath(iconJson[bill.iconId].iconL), width: 36, height: 36)
                : const Icon(Icons.receipt, size: 36, color: AppColors.textSecondary),
            const SizedBox(width: 16),
            Expanded(
              child: Text(bill.note.isNotEmpty ? bill.note : bill.category, overflow: TextOverflow.ellipsis),
            ),
            Text('$prefix${formatAmount(bill.amount)}'),
          ],
        ),
      ),
    );
  }

  String _weekdayLabel(DateTime date) {
    const labels = ['星期一', '星期二', '星期三', '星期四', '星期五', '星期六', '星期日'];
    return labels[date.weekday - 1];
  }

  String _formatDayWithWeekday(String day) {
    final p = day.split('-');
    final d = DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
    return '$day ${_weekdayLabel(d)}';
  }

  void _openBillStatement(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const BillStatementPage()));
  }

  void _openBudgetManager(BuildContext context) {
    ref.read(budgetPeriodProvider.notifier).set(BudgetPeriodType.month);
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const BudgetManagerPage()));
  }

  void _openAssetPage(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const AssetPage()));
  }

  void _openSearchPage(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const SearchPage()));
  }

  void _openCalendarPage(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const BookkeepingCalendarPage()));
  }

  Future<void> _showBillActionsSheet(BillItem bill) async {
    final value = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(title: const Text('修改'), onTap: () => Navigator.of(ctx).pop('edit')),
            ListTile(title: const Text('删除', style: TextStyle(color: Colors.red)), onTap: () => Navigator.of(ctx).pop('delete')),
          ],
        ),
      ),
    );
    if (!mounted) return;
    if (value == 'delete') {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('确认删除'),
          content: Text('确定要删除「${bill.category}」￥${bill.amount} 的记账记录吗？'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
            TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('删除')),
          ],
        ),
      );
      if (confirmed == true) {
        ref.read(billListProvider.notifier).remove(bill.id);
      }
    } else if (value == 'edit') {
      ref.read(editingBillProvider.notifier).set(bill);
      ref.read(navigationProvider.notifier).openBillingFromCurrentTab();
    }
  }
}
