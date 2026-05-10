import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../db/database_helper.dart';
import '../models/budget_item.dart';
import 'bill_provider.dart';

/// 预算周期类型：月预算 / 年预算
enum BudgetPeriodType { month, year }

/// 当前“预算管家”页正在查看的周期类型
class BudgetPeriodNotifier extends Notifier<BudgetPeriodType> {
  @override
  BudgetPeriodType build() => BudgetPeriodType.month;

  void set(BudgetPeriodType type) => state = type;
}

final budgetPeriodProvider =
    NotifierProvider<BudgetPeriodNotifier, BudgetPeriodType>(
      BudgetPeriodNotifier.new,
    );

/// 预算管家页面所需的聚合数据
class BudgetData {
  final BudgetPeriodType periodType;
  final String period;
  final BudgetItem? totalBudget;
  final List<BudgetItem> categoryBudgets;
  final double totalExpense;
  final Map<int, double> categoryExpenses;

  const BudgetData({
    required this.periodType,
    required this.period,
    required this.totalBudget,
    required this.categoryBudgets,
    required this.totalExpense,
    required this.categoryExpenses,
  });

  /// 分类预算之和
  double get categoryBudgetsSum {
    double sum = 0;
    for (final b in categoryBudgets) {
      sum += b.amount;
    }
    return sum;
  }

  double expenseOf(int iconId) => categoryExpenses[iconId] ?? 0;
}

class BudgetNotifier extends AsyncNotifier<BudgetData> {
  final _db = DatabaseHelper.instance;

  @override
  Future<BudgetData> build() async {
    final periodType = ref.watch(budgetPeriodProvider);
    final selectedMonth = ref.watch(selectedMonthProvider);
    // 监听账单变化，自动刷新支出
    ref.watch(billListProvider);

    final period = periodType == BudgetPeriodType.month
        ? selectedMonth
        : selectedMonth.substring(0, 4);

    final periodTypeStr =
        periodType == BudgetPeriodType.month ? 'month' : 'year';

    final budgets = await _db.getBudgets(
      periodType: periodTypeStr,
      period: period,
    );

    BudgetItem? total;
    final categoryBudgets = <BudgetItem>[];
    for (final b in budgets) {
      if (b.isTotal) {
        total = b;
      } else {
        categoryBudgets.add(b);
      }
    }
    categoryBudgets.sort((a, b) => a.createdAt.compareTo(b.createdAt));

    final categoryExpenses = await _db.getExpenseGroupByIconId(period);
    final totalExpense = periodType == BudgetPeriodType.month
        ? await _db.getMonthlyExpense(period)
        : await _db.getYearlyExpense(period);

    return BudgetData(
      periodType: periodType,
      period: period,
      totalBudget: total,
      categoryBudgets: categoryBudgets,
      totalExpense: totalExpense,
      categoryExpenses: categoryExpenses,
    );
  }

  /// 保存/更新总预算
  ///
  /// 返回保存后的总预算金额
  Future<double> saveTotalBudget(double amount) async {
    final data = state.value;
    if (data == null) return 0;
    final periodType =
        data.periodType == BudgetPeriodType.month ? 'month' : 'year';
    final now = _nowStr();
    final existing = data.totalBudget;
    final budget = BudgetItem(
      id: existing?.id ?? _genId(),
      periodType: periodType,
      period: data.period,
      isTotal: true,
      category: '',
      iconId: -1,
      amount: amount,
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
    );
    await _db.insertOrReplaceBudget(budget);
    ref.invalidateSelf();
    ref.invalidate(monthlyTotalBudgetProvider);
    await future;
    return amount;
  }

  /// 保存/更新分类预算
  ///
  /// 返回 true 表示分类预算之和超过了总预算，已自动同步更新总预算
  Future<bool> saveCategoryBudget({
    required int iconId,
    required String category,
    required double amount,
  }) async {
    final data = state.value;
    if (data == null) return false;
    final periodType =
        data.periodType == BudgetPeriodType.month ? 'month' : 'year';
    final now = _nowStr();
    final existing = data.categoryBudgets.firstWhere(
      (b) => b.iconId == iconId,
      orElse: () => BudgetItem(
        id: '',
        periodType: '',
        period: '',
        isTotal: false,
        category: '',
        iconId: -1,
        amount: 0,
        createdAt: '',
        updatedAt: '',
      ),
    );
    final isNew = existing.id.isEmpty;
    final budget = BudgetItem(
      id: isNew ? _genId() : existing.id,
      periodType: periodType,
      period: data.period,
      isTotal: false,
      category: category,
      iconId: iconId,
      amount: amount,
      createdAt: isNew ? now : existing.createdAt,
      updatedAt: now,
    );
    await _db.insertOrReplaceBudget(budget);

    // 重新计算分类预算之和并与总预算对比
    double newSum = 0;
    for (final b in data.categoryBudgets) {
      if (b.iconId == iconId) continue;
      newSum += b.amount;
    }
    newSum += amount;

    final total = data.totalBudget;
    bool autoUpdated = false;
    if (total != null && newSum > total.amount) {
      final updatedTotal = total.copyWith(amount: newSum, updatedAt: now);
      await _db.insertOrReplaceBudget(updatedTotal);
      autoUpdated = true;
    }

    ref.invalidateSelf();
    ref.invalidate(monthlyTotalBudgetProvider);
    await future;
    return autoUpdated;
  }

  /// 删除当前周期下的总预算
  ///
  /// 同时连带删除该周期下已设置的全部分类预算，避免出现“无总预算却有分类预算”的悬空数据。
  Future<void> deleteTotalBudget() async {
    final data = state.value;
    if (data == null) return;
    final total = data.totalBudget;
    if (total != null) {
      await _db.deleteBudget(total.id);
    }
    for (final cat in data.categoryBudgets) {
      await _db.deleteBudget(cat.id);
    }
    ref.invalidateSelf();
    ref.invalidate(monthlyTotalBudgetProvider);
    await future;
  }

  /// 删除某条分类预算
  Future<void> deleteCategoryBudget(String id) async {
    await _db.deleteBudget(id);
    ref.invalidateSelf();
    ref.invalidate(monthlyTotalBudgetProvider);
    await future;
  }

  String _nowStr() {
    final now = DateTime.now();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${now.year}-${two(now.month)}-${two(now.day)} '
        '${two(now.hour)}:${two(now.minute)}:${two(now.second)}';
  }

  String _genId() {
    final ts = DateTime.now().millisecondsSinceEpoch;
    final rand = Random().nextInt(999999).toString().padLeft(6, '0');
    return 'budget_${ts}_$rand';
  }
}

final budgetProvider =
    AsyncNotifierProvider<BudgetNotifier, BudgetData>(BudgetNotifier.new);

/// 当前选中月份的总预算金额（供发现页等仅展示用）
///
/// 始终读取月度预算，不受预算管家页面 [budgetPeriodProvider] 切换影响。
/// 没有设置时返回 0。
final monthlyTotalBudgetProvider = FutureProvider<double>((ref) async {
  final month = ref.watch(selectedMonthProvider);
  // 让账单变更后能间接刷新（保持与其他汇总联动）
  ref.watch(billListProvider);
  final budgets = await DatabaseHelper.instance.getBudgets(
    periodType: 'month',
    period: month,
  );
  for (final b in budgets) {
    if (b.isTotal) return b.amount;
  }
  return 0;
});
