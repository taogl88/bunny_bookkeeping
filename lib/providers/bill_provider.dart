import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../db/database_helper.dart';
import '../models/bill_item.dart';

/// 当前选中的年月，格式 "2025-11"
class SelectedMonthNotifier extends Notifier<String> {
  @override
  String build() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}';
  }

  void setMonth(String yearMonth) => state = yearMonth;
}

final selectedMonthProvider = NotifierProvider<SelectedMonthNotifier, String>(
  SelectedMonthNotifier.new,
);

/// 当月账单列表
class BillListNotifier extends AsyncNotifier<List<BillItem>> {
  final _db = DatabaseHelper.instance;

  @override
  Future<List<BillItem>> build() {
    final month = ref.watch(selectedMonthProvider);
    return _db.getBillsByMonth(month);
  }

  Future<void> add(BillItem bill) async {
    await _db.insertBill(bill);
    ref.invalidateSelf();
  }

  Future<void> updateBill(BillItem bill) async {
    await _db.updateBill(bill);
    ref.invalidateSelf();
  }

  Future<void> remove(String id) async {
    await _db.deleteBill(id);
    ref.invalidateSelf();
  }
}

final billListProvider =
    AsyncNotifierProvider<BillListNotifier, List<BillItem>>(
      BillListNotifier.new,
    );

/// 正在编辑的账单（null 表示新建模式）
class EditingBillNotifier extends Notifier<BillItem?> {
  @override
  BillItem? build() => null;

  void set(BillItem? bill) => state = bill;
  void clear() => state = null;
}

final editingBillProvider =
    NotifierProvider<EditingBillNotifier, BillItem?>(EditingBillNotifier.new);

/// 当月收支汇总
class MonthlySummary {
  final double income;
  final double expense;
  const MonthlySummary({required this.income, required this.expense});
}

class MonthlySummaryNotifier extends AsyncNotifier<MonthlySummary> {
  final _db = DatabaseHelper.instance;

  @override
  Future<MonthlySummary> build() async {
    final month = ref.watch(selectedMonthProvider);
    // 监听账单列表变化，自动刷新汇总
    ref.watch(billListProvider);
    final income = await _db.getMonthlyIncome(month);
    final expense = await _db.getMonthlyExpense(month);
    return MonthlySummary(income: income, expense: expense);
  }
}

final monthlySummaryProvider =
    AsyncNotifierProvider<MonthlySummaryNotifier, MonthlySummary>(
      MonthlySummaryNotifier.new,
    );
