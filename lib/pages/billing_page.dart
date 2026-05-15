import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/account_data.dart';
import '../models/bill_item.dart';
import '../models/bill_split.dart';
import '../models/category_entry.dart';
import '../providers/bill_provider.dart';
import '../providers/category_provider.dart';
import '../providers/keyboard_provider.dart';
import '../providers/navigation_provider.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../utils/icon_helper.dart';
import 'category_settings_page.dart';

class BillingPage extends ConsumerStatefulWidget {
  const BillingPage({super.key});

  @override
  ConsumerState<BillingPage> createState() => _BillingPageState();
}

class _BillingPageState extends ConsumerState<BillingPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int? _selectedIconId;
  final Set<int> _selectedExpenseIconIds = <int>{};
  double? _expenseDraftAmount;
  String _expenseDraftNote = '';
  DateTime _expenseDraftDate = DateTime.now();
  int _lastTabIndex = 0;
  bool _suppressTabSync = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabChange);
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }

  bool get _isExpenseMode => _tabController.index == 0;

  List<CategoryEntry> _expenseCategoriesFromIds(Set<int> ids) {
    final all = ref.read(expenseCategoriesProvider);
    return [for (final cat in all) if (ids.contains(cat.iconId)) cat];
  }

  void _handleTabChange() {
    if (_suppressTabSync || _tabController.index == _lastTabIndex) return;
    _lastTabIndex = _tabController.index;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _resetLocalDraft();
    });
  }

  void _resetLocalDraft() {
    ref.read(keyboardProvider.notifier).hide();
    setState(() {
      _selectedIconId = null;
      _selectedExpenseIconIds.clear();
      _expenseDraftAmount = null;
      _expenseDraftNote = '';
      _expenseDraftDate = DateTime.now();
    });
  }

  void _resetState() {
    ref.read(editingBillProvider.notifier).clear();
    _resetLocalDraft();
    setState(() {
      _suppressTabSync = true;
      _tabController.index = 0;
      _lastTabIndex = 0;
      _suppressTabSync = false;
    });
  }

  DateTime _billDateToDateTime(BillItem bill) {
    final dateParts = bill.date.split(' ')[0].split('-');
    return DateTime(
      int.parse(dateParts[0]),
      int.parse(dateParts[1]),
      int.parse(dateParts[2]),
    );
  }

  void _onCategoryTap(CategoryEntry cat) {
    if (_isExpenseMode) {
      _toggleExpenseCategory(cat);
      return;
    }
    _openIncomeKeyboard(cat);
  }

  void _toggleExpenseCategory(CategoryEntry cat) {
    final next = <int>{..._selectedExpenseIconIds};
    if (next.contains(cat.iconId)) {
      next.remove(cat.iconId);
    } else {
      next.add(cat.iconId);
    }
    setState(() {
      _selectedExpenseIconIds
        ..clear()
        ..addAll(next);
      _selectedIconId = next.isNotEmpty ? cat.iconId : null;
    });
    _syncExpenseKeyboard();
  }

  void _syncExpenseKeyboard() {
    final categories = _expenseCategoriesFromIds(_selectedExpenseIconIds);
    if (categories.isEmpty) {
      ref.read(keyboardProvider.notifier).hide();
      return;
    }

    final editing = ref.read(editingBillProvider);
    final label = _expenseSummaryLabel(categories);
    final icon = iconJson[categories.first.iconId];
    final callback = (double amount, String note, DateTime date) {
      setState(() {
        _expenseDraftAmount = amount;
        _expenseDraftNote = note;
        _expenseDraftDate = date;
      });
      if (editing != null) {
        _updateExpenseBill(editing, amount, note, date, categories);
      } else {
        _saveExpenseBill(amount, note, date, categories);
      }
    };

    final kb = ref.read(keyboardProvider);
    if (kb.visible) {
      ref.read(keyboardProvider.notifier).updateCategory(
            categoryName: label,
            categoryIconPath: iconPath(icon.iconS),
            onComplete: callback,
          );
      return;
    }

    ref.read(keyboardProvider.notifier).show(
          categoryName: label,
          categoryIconPath: iconPath(icon.iconS),
          initialAmount: editing != null
              ? _editingSharedAmount(editing)
              : _expenseDraftAmount,
          initialNote: editing?.note ?? (_expenseDraftNote.isEmpty ? null : _expenseDraftNote),
          initialDate: editing != null ? _billDateToDateTime(editing) : _expenseDraftDate,
          onComplete: callback,
        );
  }

  double _editingSharedAmount(BillItem editing) {
    if (editing.splits.isNotEmpty) {
      return editing.splits.first.amount;
    }
    return editing.amount;
  }

  void _openIncomeKeyboard(CategoryEntry cat) {
    final editing = ref.read(editingBillProvider);
    final icon = iconJson[cat.iconId];
    setState(() => _selectedIconId = cat.iconId);
    ref.read(keyboardProvider.notifier).show(
          categoryName: cat.name,
          categoryIconPath: iconPath(icon.iconS),
          initialAmount: editing?.amount,
          initialNote: editing?.note,
          initialDate: editing != null ? _billDateToDateTime(editing) : null,
          onComplete: (amount, note, date) {
            if (editing != null) {
              _updateSingleCategoryBill(editing, cat, amount, note, date);
            } else {
              _saveSingleCategoryBill(cat, amount, note, date, type: 'income');
            }
          },
        );
  }

  void _openEditFlow(BillItem bill) {
    final isIncome = bill.type == 'income';
    _suppressTabSync = true;
    _tabController.index = isIncome ? 1 : 0;
    _lastTabIndex = _tabController.index;
    _suppressTabSync = false;

    if (isIncome) {
      final categories = ref.read(incomeCategoriesProvider);
      final cat = categories.firstWhere(
        (item) => item.iconId == bill.iconId,
        orElse: () => CategoryEntry(
          id: -1,
          inEx: 1,
          name: bill.category,
          iconId: bill.iconId,
          isCustom: false,
          sortOrder: 0,
          createdAt: '',
          updatedAt: '',
        ),
      );
      _openIncomeKeyboard(cat);
      return;
    }

    setState(() {
      _selectedExpenseIconIds
        ..clear()
        ..addAll(
          bill.splits.isNotEmpty
              ? [for (final split in bill.splits) split.iconId]
              : [bill.iconId],
        );
      _selectedIconId = _selectedExpenseIconIds.isEmpty
          ? bill.iconId
          : _selectedExpenseIconIds.first;
      _expenseDraftAmount = _editingSharedAmount(bill);
      _expenseDraftNote = bill.note;
      _expenseDraftDate = _billDateToDateTime(bill);
    });
    _syncExpenseKeyboard();
  }

  List<BillSplitDraft> _buildSameAmountExpenseSplits(
    double amount,
    List<CategoryEntry> categories,
  ) {
    return [
      for (final category in categories)
        BillSplitDraft(
          category: category.name,
          iconId: category.iconId,
          amount: amount,
        ),
    ];
  }

  String _expenseSummaryLabel(List<CategoryEntry> categories) {
    if (categories.length == 1) return categories.first.name;
    return '${categories.first.name}等${categories.length}类';
  }

  void _saveExpenseBill(
    double amount,
    String note,
    DateTime date,
    List<CategoryEntry> categories,
  ) {
    final payload = _buildBillPayload(date);
    final primary = categories.first;
    final bill = BillItem(
      id: payload.id,
      type: 'expense',
      amount: amount,
      category: _expenseSummaryLabel(categories),
      note: note,
      date: payload.date,
      sortAt: payload.sortAt,
      iconId: primary.iconId,
      createdAt: payload.createdAt,
      updatedAt: payload.updatedAt,
    );
    ref.read(billListProvider.notifier).add(
          bill,
          splits: _buildSameAmountExpenseSplits(amount, categories),
        );
    _finishSave();
  }

  void _updateExpenseBill(
    BillItem original,
    double amount,
    String note,
    DateTime date,
    List<CategoryEntry> categories,
  ) {
    final payload = _buildUpdatedBillPayload(original, date);
    final primary = categories.first;
    final updated = original.copyWith(
      type: 'expense',
      amount: amount,
      category: _expenseSummaryLabel(categories),
      note: note,
      date: payload.date,
      sortAt: payload.sortAt,
      iconId: primary.iconId,
      updatedAt: payload.updatedAt,
    );
    ref.read(billListProvider.notifier).updateBill(
          updated,
          splits: _buildSameAmountExpenseSplits(amount, categories),
        );
    _finishUpdate();
  }

  void _saveSingleCategoryBill(
    CategoryEntry cat,
    double amount,
    String note,
    DateTime date, {
    required String type,
  }) {
    final payload = _buildBillPayload(date);
    final bill = BillItem(
      id: payload.id,
      type: type,
      amount: amount,
      category: cat.name,
      note: note,
      date: payload.date,
      sortAt: payload.sortAt,
      iconId: cat.iconId,
      createdAt: payload.createdAt,
      updatedAt: payload.updatedAt,
    );
    ref.read(billListProvider.notifier).add(
          bill,
          splits: [
            BillSplitDraft(category: cat.name, iconId: cat.iconId, amount: amount),
          ],
        );
    _finishSave();
  }

  void _updateSingleCategoryBill(
    BillItem original,
    CategoryEntry cat,
    double amount,
    String note,
    DateTime date,
  ) {
    final payload = _buildUpdatedBillPayload(original, date);
    final updated = original.copyWith(
      type: 'income',
      amount: amount,
      category: cat.name,
      note: note,
      date: payload.date,
      sortAt: payload.sortAt,
      iconId: cat.iconId,
      updatedAt: payload.updatedAt,
    );
    ref.read(billListProvider.notifier).updateBill(
          updated,
          splits: [
            BillSplitDraft(category: cat.name, iconId: cat.iconId, amount: amount),
          ],
        );
    _finishUpdate();
  }

  _BillPayload _buildBillPayload(DateTime date) {
    final now = DateTime.now();
    final ts = now.millisecondsSinceEpoch;
    final rand = Random().nextInt(999999).toString().padLeft(6, '0');
    final id = '${ts}_$rand';
    final dateStr =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} '
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
    final nowStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} '
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
    return _BillPayload(
      id: id,
      date: dateStr,
      sortAt: nowStr,
      createdAt: nowStr,
      updatedAt: nowStr,
    );
  }

  _BillPayload _buildUpdatedBillPayload(BillItem original, DateTime date) {
    final now = DateTime.now();
    final originalDay = original.date.substring(0, 10);
    final nextDay =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final nowStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} '
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
    final dateStr = originalDay == nextDay
        ? original.date
        : '$nextDay '
              '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
    return _BillPayload(
      id: original.id,
      date: dateStr,
      sortAt: originalDay == nextDay ? original.sortAt : nowStr,
      createdAt: original.createdAt,
      updatedAt: nowStr,
    );
  }

  void _finishSave() {
    ref.read(keyboardProvider.notifier).hide();
    ref.read(navigationProvider.notifier).setTab(0);
    _resetState();
  }

  void _finishUpdate() {
    ref.read(editingBillProvider.notifier).clear();
    ref.read(keyboardProvider.notifier).hide();
    ref.read(navigationProvider.notifier).setTab(0);
    _resetState();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<BillItem?>(editingBillProvider, (prev, next) {
      if (next != null && prev == null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _openEditFlow(next);
        });
      }
    });

    ref.listen<int>(navigationProvider, (prev, next) {
      if (prev == 2 && next != 2) _resetState();
    });

    final expenses = ref.watch(expenseCategoriesProvider);
    final incomes = ref.watch(incomeCategoriesProvider);

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildTabBar(),
          if (_isExpenseMode) _buildExpenseHint(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [_buildGrid(expenses), _buildGrid(incomes)],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    final topPadding = MediaQuery.of(context).padding.top;
    return Container(
      alignment: Alignment.bottomCenter,
      padding: EdgeInsets.only(top: topPadding),
      height: 48 + topPadding,
      decoration: const BoxDecoration(color: AppColors.primary),
      child: Row(
        children: [
          const SizedBox(width: 40),
          const Spacer(),
          SizedBox(
            width: 150,
            child: TabBar(
              controller: _tabController,
              labelColor: Colors.black,
              unselectedLabelColor: AppColors.textSecondary,
              labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              unselectedLabelStyle:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              indicatorColor: Colors.black,
              indicatorSize: TabBarIndicatorSize.label,
              dividerHeight: 0,
              tabs: const [
                Tab(text: '支出'),
                Tab(text: '收入'),
              ],
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () {
              ref.read(editingBillProvider.notifier).clear();
              ref.read(keyboardProvider.notifier).hide();
              ref.read(navigationProvider.notifier).setTab(0);
              _resetState();
            },
            child: Text(
              '取消',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
    );
  }

  Widget _buildExpenseHint() {
    final selectedCategories = _expenseCategoriesFromIds(_selectedExpenseIconIds);
    return Container(
      width: double.infinity,
      color: AppColors.primaryLight,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            selectedCategories.isEmpty
                ? '支持多标签'
                : '已选 ${selectedCategories.length} 个标签',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (selectedCategories.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final category in selectedCategories)
                  InputChip(
                    label: Text(category.name),
                    selected: _selectedIconId == category.iconId,
                    onPressed: () {
                      setState(() => _selectedIconId = category.iconId);
                    },
                    onDeleted: () {
                      setState(() {
                        _selectedExpenseIconIds.remove(category.iconId);
                        _selectedIconId = _selectedExpenseIconIds.isNotEmpty
                            ? _selectedExpenseIconIds.first
                            : null;
                      });
                      _syncExpenseKeyboard();
                    },
                  ),
              ],
            ),
            if (_expenseDraftAmount != null) ...[
              const SizedBox(height: 8),
              Text(
                '当前金额 ${formatAmount(_expenseDraftAmount!)}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildGrid(List<CategoryEntry> categories) {
    final kb = ref.watch(keyboardProvider);
    const tabBarHeight = 64.0;
    final bottomPad = kb.visible && kb.height > 0
        ? (kb.height - tabBarHeight).clamp(0.0, double.infinity)
        : 16.0;
    final itemCount = categories.length + 1;
    return GridView.builder(
      padding: EdgeInsets.only(left: 24, right: 24, top: 16, bottom: bottomPad),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 0.85,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        if (index == categories.length) {
          return _SettingsCell(onTap: _openCategorySettings);
        }
        final cat = categories[index];
        final isSelected = _isExpenseMode
            ? _selectedExpenseIconIds.contains(cat.iconId)
            : _selectedIconId == cat.iconId;
        final icon = iconJson[cat.iconId];
        final imgPath = isSelected ? iconPath(icon.iconS) : iconPath(icon.icon);
        return GestureDetector(
          onTap: () => _onCategoryTap(cat),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? AppColors.primaryLight : Colors.transparent,
                  border: Border.all(
                    color: isSelected ? AppColors.primary : Colors.transparent,
                    width: 1.4,
                  ),
                ),
                padding: const EdgeInsets.all(4),
                child: Center(
                  child: Image.asset(imgPath, width: 50, height: 50),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                cat.name,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
    );
  }

  void _openCategorySettings() {
    ref.read(keyboardProvider.notifier).hide();
    final initialInEx = _tabController.index;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CategorySettingsPage(initialInEx: initialInEx),
      ),
    );
  }
}

class _SettingsCell extends StatelessWidget {
  const _SettingsCell({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFF4F4F4),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.settings_outlined,
              size: 26,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            '设置',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _BillPayload {
  final String id;
  final String date;
  final String sortAt;
  final String createdAt;
  final String updatedAt;

  const _BillPayload({
    required this.id,
    required this.date,
    required this.sortAt,
    required this.createdAt,
    required this.updatedAt,
  });
}
