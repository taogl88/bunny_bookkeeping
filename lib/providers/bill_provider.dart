import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../db/database_helper.dart';
import '../models/bill_item.dart';
import '../models/bill_split.dart';

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

class BillListNotifier extends AsyncNotifier<List<BillItem>> {
  final _db = DatabaseHelper.instance;

  @override
  Future<List<BillItem>> build() {
    final month = ref.watch(selectedMonthProvider);
    return _db.getBillsByMonth(month);
  }

  Future<void> add(BillItem bill, {List<BillSplitDraft>? splits}) async {
    await _db.insertBillWithSplits(bill, splits: splits);
    ref.invalidateSelf();
  }

  Future<void> updateBill(BillItem bill, {List<BillSplitDraft>? splits}) async {
    await _db.updateBillWithSplits(bill, splits: splits);
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

class EditingBillNotifier extends Notifier<BillItem?> {
  @override
  BillItem? build() => null;

  void set(BillItem? bill) => state = bill;
  void clear() => state = null;
}

final editingBillProvider =
    NotifierProvider<EditingBillNotifier, BillItem?>(EditingBillNotifier.new);

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

final billSplitMapProvider = FutureProvider<Map<String, List<BillSplit>>>((
  ref,
) async {
  final bills = await ref.watch(billListProvider.future);
  final ids = [for (final bill in bills) bill.id];
  return DatabaseHelper.instance.getBillSplitsByBillIds(ids);
});
