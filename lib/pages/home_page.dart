import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../models/bill_item.dart';
import '../providers/bill_provider.dart';
import '../providers/budget_provider.dart';
import '../utils/format.dart';
import '../data/account_data.dart';
import '../utils/icon_helper.dart';
import '../widgets/month_picker.dart';
import '../providers/navigation_provider.dart';
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
  String? _activeMenuBillId;

  @override
  Widget build(BuildContext context) {
    final month = ref.watch(selectedMonthProvider);
    final summaryAsync = ref.watch(monthlySummaryProvider);
    final billsAsync = ref.watch(billListProvider);

    final year = month.substring(0, 4);
    final mon = month.substring(5);

    return Column(
      children: [
        _buildHeader(context, ref, year, mon, summaryAsync),
        _buildQuickActions(context, ref),
        Expanded(child: _buildTransactionList(context, ref, billsAsync)),
      ],
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

    return Container(
      color: AppColors.primary,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Column(
            children: [
              SizedBox(
                height: 32,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const Text(
                      'bunny记账',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            onPressed: () => _openSearchPage(context),
                            icon: const Icon(Icons.search, size: 22),
                            padding: EdgeInsets.symmetric(horizontal: 6),
                            constraints: const BoxConstraints(
                              minWidth: 0,
                              minHeight: 32,
                            ),
                            visualDensity: VisualDensity.compact,
                            style: IconButton.styleFrom(
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            color: AppColors.textPrimary,
                            tooltip: '搜索',
                          ),
                          SizedBox(width: 4),
                          IconButton(
                            onPressed: () => _openCalendarPage(context),
                            icon: const Icon(
                              Icons.calendar_today_outlined,
                              size: 21,
                            ),
                            padding: EdgeInsets.symmetric(horizontal: 6),
                            constraints: const BoxConstraints(
                              minWidth: 0,
                              minHeight: 32,
                            ),
                            visualDensity: VisualDensity.compact,
                            style: IconButton.styleFrom(
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            color: AppColors.textPrimary,
                            tooltip: '记账日历',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
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
                        ref
                            .read(selectedMonthProvider.notifier)
                            .setMonth(result);
                      }
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$year年',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                              month,
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                height: 1.1,
                              ),
                            ),
                            const Text(
                              '月',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Icon(Icons.arrow_drop_down, size: 20),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 1,
                    height: 40,
                    color: AppColors.textPrimary.withAlpha(60),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '收入',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          income.toStringAsFixed(2),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '支出',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          expense.toStringAsFixed(2),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
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

  Widget _buildQuickActions(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.primary, Colors.white],
          stops: [0.3, 0.8],
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(left: 12, right: 12, top: 0, bottom: 12),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppColors.textPrimary.withAlpha((255 * 0.3).floor()),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _quickActionItem(
              iconPath: 'assets/images/账单.png',
              label: '账单',
              onTap: () => _openBillStatement(context),
            ),
            _quickActionItem(
              iconPath: 'assets/images/预算.png',
              label: '预算',
              onTap: () => _openBudgetManager(context, ref),
            ),
          ],
        ),
      ),
    );
  }

  Widget _quickActionItem({
    required String iconPath,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        width: 56,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(iconPath, width: 24, height: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(fontSize: 10, color: AppColors.textPrimary),
            ),
          ],
        ),
      ),
    );
  }

  void _openBillStatement(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const BillStatementPage()));
  }

  void _openBudgetManager(BuildContext context, WidgetRef ref) {
    // 与发现页“xx月总预算”卡片保持一致：进入预算管家默认展示月预算
    ref.read(budgetPeriodProvider.notifier).set(BudgetPeriodType.month);
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const BudgetManagerPage()));
  }

  void _openSearchPage(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const SearchPage()));
  }

  void _openCalendarPage(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const BookkeepingCalendarPage()),
    );
  }

  Widget _buildTransactionList(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<BillItem>> billsAsync,
  ) {
    return billsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('加载失败: $e')),
      data: (bills) {
        if (bills.isEmpty) {
          return Container(
            color: AppColors.surface,
            // padding: const EdgeInsets.only(top: 10),
            child: Center(
              child: Text(
                '暂无账单',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
          );
        }

        final sortedBills = [...bills]
          ..sort((a, b) {
            final dayCompare = b.date
                .substring(0, 10)
                .compareTo(a.date.substring(0, 10));
            if (dayCompare != 0) return dayCompare;
            final sortCompare = b.sortAt.compareTo(a.sortAt);
            if (sortCompare != 0) return sortCompare;
            return b.date.compareTo(a.date);
          });

        // 按日期分组 (yyyy-MM-dd)
        final grouped = <String, List<BillItem>>{};
        for (final bill in sortedBills) {
          final day = bill.date.substring(0, 10);
          grouped.putIfAbsent(day, () => []).add(bill);
        }

        final days = grouped.keys.toList();

        return Container(
          color: AppColors.surface,
          // padding: const EdgeInsets.only(top: 10),
          child: ListView.builder(
            padding: EdgeInsets.zero,
            itemCount: days.length,
            itemBuilder: (context, index) {
              final day = days[index];
              final items = grouped[day]!;
              final dayExpense = items
                  .where((b) => b.type == 'expense')
                  .fold<double>(0, (sum, b) => sum + b.amount);
              final dayIncome = items
                  .where((b) => b.type == 'income')
                  .fold<double>(0, (sum, b) => sum + b.amount);

              return Column(
                children: [
                  // 日期头
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          day,
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Row(
                          children: [
                            if (dayIncome > 0)
                              Text(
                                '收入：${formatAmount(dayIncome)}  ',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            if (dayExpense > 0)
                              Text(
                                '支出：${formatAmount(dayExpense)}',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // 账单条目
                  ...items.map((bill) => _billTile(context, ref, bill)),
                  SizedBox(height: 8),
                  if (index < days.length - 1)
                    const Divider(height: 1, color: AppColors.darkGray),
                  if (index == days.length - 1) const SizedBox(height: 16),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _billTile(BuildContext context, WidgetRef ref, BillItem bill) {
    final prefix = bill.type == 'expense' ? '-' : '+';
    final isMenuActive = _activeMenuBillId == bill.id;
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Row(
          children: [
            bill.iconId >= 0 && bill.iconId < iconJson.length
                ? Image.asset(
                    iconPath(iconJson[bill.iconId].iconL),
                    width: 36,
                    height: 36,
                  )
                : Icon(Icons.receipt, size: 36, color: AppColors.textSecondary),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    bill.note.isNotEmpty ? bill.note : bill.category,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Text(
              '$prefix${formatAmount(bill.amount)}',
              style: const TextStyle(fontSize: 12),
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
      items: [
        const PopupMenuItem(
          value: 'delete',
          height: 30,
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Text('删除', style: TextStyle(fontSize: 14)),
        ),
        const PopupMenuItem(
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
        ref.read(billListProvider.notifier).remove(bill.id);
      }
    } else if (value == 'edit') {
      // 切到记账页并传入编辑数据
      debugPrint('[HomePage][edit-menu] billId=${bill.id}, type=${bill.type}');
      ref.read(editingBillProvider.notifier).set(bill);
      ref.read(navigationProvider.notifier).setTab(2);
    }
  }
}
