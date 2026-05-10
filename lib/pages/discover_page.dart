import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'bill_statement_page.dart';
import 'budget_manager_page.dart';
import '../providers/bill_provider.dart';
import '../providers/budget_provider.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';

class DiscoverPage extends ConsumerWidget {
  const DiscoverPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final month = ref.watch(selectedMonthProvider);
    final summaryAsync = ref.watch(monthlySummaryProvider);
    final monthlyBudgetAsync = ref.watch(monthlyTotalBudgetProvider);
    final monthLabel = month.substring(5);

    final income = summaryAsync.value?.income ?? 0;
    final expense = summaryAsync.value?.expense ?? 0;
    final balance = income - expense;

    final monthlyBudget = monthlyBudgetAsync.value ?? 0;
    final remainingBudget = monthlyBudget - expense;
    final safeRemaining = remainingBudget > 0 ? remainingBudget : 0.0;
    final remainingRatio = monthlyBudget <= 0
        ? 0.0
        : (safeRemaining / monthlyBudget).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: AppColors.backgroundGray,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final topColorHeight = constraints.maxHeight * 0.18;
          return Stack(
            children: [
              Column(
                children: [
                  SizedBox(
                    height: topColorHeight,
                    width: double.infinity,
                    child: const ColoredBox(color: AppColors.primary),
                  ),
                  const Expanded(
                    child: SizedBox(
                      width: double.infinity,
                      child: ColoredBox(color: AppColors.backgroundGray),
                    ),
                  ),
                ],
              ),
              Column(
                children: [
                  _DiscoverHeader(),
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        color: Colors.transparent,
                      ),
                      child: SingleChildScrollView(
                        padding: EdgeInsets.fromLTRB(
                          16,
                          0,
                          16,
                          bottomInset + 92,
                        ),
                        child: Column(
                          children: [
                            _SectionCard(
                              title: '账单',
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => const BillStatementPage(),
                                  ),
                                );
                              },
                              child: _BillOverview(
                                monthLabel: monthLabel,
                                income: income,
                                expense: expense,
                                balance: balance,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _SectionCard(
                              title: '${monthLabel}月总预算',
                              onTap: () {
                                // 进入预算管家：默认展示月预算
                                ref
                                    .read(budgetPeriodProvider.notifier)
                                    .set(BudgetPeriodType.month);
                                Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => const BudgetManagerPage(),
                                  ),
                                );
                              },
                              child: _BudgetOverview(
                                progress: remainingRatio,
                                remainingBudget: remainingBudget,
                                totalBudget: monthlyBudget,
                                expense: expense,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _DiscoverHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
        child: SizedBox(
          height: 48,
          child: Center(
            child: Text(
              '发现',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child, this.onTap});

  final String title;
  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final double borderRadius = 8;

    return Material(
      elevation: 0.5,
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(borderRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(borderRadius),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.chevron_right,
                    size: 18,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class _BillOverview extends StatelessWidget {
  const _BillOverview({
    required this.monthLabel,
    required this.income,
    required this.expense,
    required this.balance,
  });

  final String monthLabel;
  final double income;
  final double expense;
  final double balance;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 60,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  monthLabel,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(left: 4, bottom: 2),
                child: Text(
                  '月',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
        Container(width: 1, height: 44, color: AppColors.darkGray),
        const SizedBox(width: 14),
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: _MetricColumn(label: '收入', value: income),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _MetricColumn(label: '支出', value: expense),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _MetricColumn(label: '结余', value: balance),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BudgetOverview extends StatelessWidget {
  const _BudgetOverview({
    required this.progress,
    required this.remainingBudget,
    required this.totalBudget,
    required this.expense,
  });

  final double progress;
  final double remainingBudget;
  final double totalBudget;
  final double expense;

  @override
  Widget build(BuildContext context) {
    final percentText = '${(progress * 100).round()}%';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _BudgetRing(
          progress: progress,
          percentText: percentText,
          overflow: remainingBudget < 0,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            children: [
              _InfoRow(label: '剩余预算：', value: remainingBudget),
              const SizedBox(height: 12),
              _InfoRow(label: '本月预算：', value: totalBudget, dense: true),
              const SizedBox(height: 10),
              _InfoRow(label: '本月支出：', value: expense, dense: true),
            ],
          ),
        ),
      ],
    );
  }
}

class _MetricColumn extends StatelessWidget {
  const _MetricColumn({required this.label, required this.value});

  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        buildAmountText(
          value: value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          integerStyle: const TextStyle(
            fontSize: 12,
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
          decimalStyle: const TextStyle(
            fontSize: 10,
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    this.dense = false,
  });

  final String label;
  final double value;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: dense ? 12 : 14,
            fontWeight: FontWeight.w500,
            color: dense ? AppColors.textSecondary : AppColors.textPrimary,
          ),
        ),
        const Spacer(),
        buildAmountText(
          value: value,
          integerStyle: const TextStyle(
            fontSize: 15,
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
          decimalStyle: const TextStyle(
            fontSize: 13,
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _BudgetRing extends StatelessWidget {
  const _BudgetRing({
    required this.progress,
    required this.percentText,
    required this.overflow,
  });

  final double progress;
  final String percentText;
  final bool overflow;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 104,
      height: 104,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 88,
            height: 88,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 9,
              backgroundColor: AppColors.gray,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.primary,
              ),
            ),
          ),
          overflow
              ? const Text(
                  '已超支',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.red,
                    fontWeight: FontWeight.w500,
                  ),
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      '剩余',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      percentText,
                      style: const TextStyle(
                        fontSize: 17,
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
        ],
      ),
    );
  }
}
