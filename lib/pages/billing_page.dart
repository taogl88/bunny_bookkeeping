import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/account_data.dart';
import '../models/bill_item.dart';
import '../models/category_entry.dart';
import '../providers/bill_provider.dart';
import '../providers/category_provider.dart';
import '../providers/keyboard_provider.dart';
import '../providers/navigation_provider.dart';
import '../theme/app_theme.dart';
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

  String get _currentType => _tabController.index == 0 ? 'expense' : 'income';

  List<CategoryEntry> _categoriesForCurrentTab() {
    final all = ref.read(categoryListProvider).value ?? const <CategoryEntry>[];
    final inEx = _tabController.index == 0 ? 0 : 1;
    return [
      for (final c in all)
        if (c.inEx == inEx) c,
    ];
  }

  void _handleTabChange() {
    if (_suppressTabSync || _tabController.index == _lastTabIndex) return;
    _lastTabIndex = _tabController.index;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _selectDefaultCategoryForCurrentTab();
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

  void _resetState() {
    ref.read(keyboardProvider.notifier).hide();
    ref.read(editingBillProvider.notifier).clear();
    setState(() {
      _selectedIconId = null;
      _suppressTabSync = true;
      _tabController.index = 0;
      _lastTabIndex = 0;
      _suppressTabSync = false;
    });
  }

  void _selectDefaultCategoryForCurrentTab() {
    final categories = _categoriesForCurrentTab();
    if (categories.isEmpty) {
      setState(() => _selectedIconId = null);
      return;
    }
    _selectCategory(categories.first, showKeyboardWhenHidden: false);
  }

  void _onCategoryTap(CategoryEntry cat) {
    _selectCategory(cat, showKeyboardWhenHidden: true);
  }

  void _selectCategory(
    CategoryEntry cat, {
    required bool showKeyboardWhenHidden,
  }) {
    final editing = ref.read(editingBillProvider);
    final icon = iconJson[cat.iconId];
    setState(() => _selectedIconId = cat.iconId);
    final onComplete = editing != null
        ? (double amount, String note, DateTime date) =>
              _updateBill(editing, cat, amount, note, date)
        : (double amount, String note, DateTime date) =>
              _saveBill(cat, amount, note, date);

    final kb = ref.read(keyboardProvider);
    if (kb.visible) {
      // 键盘已打开，只切换分类，保留金额/备注/日期
      ref
          .read(keyboardProvider.notifier)
          .updateCategory(
            categoryName: cat.name,
            categoryIconPath: iconPath(icon.iconS),
            onComplete: onComplete,
          );
    } else {
      if (!showKeyboardWhenHidden) return;
      ref
          .read(keyboardProvider.notifier)
          .show(
            categoryName: cat.name,
            categoryIconPath: iconPath(icon.iconS),
            initialAmount: editing?.amount,
            initialNote: editing?.note,
            initialDate: editing != null ? _billDateToDateTime(editing) : null,
            onComplete: onComplete,
          );
    }
  }

  void _openEditKeyboard(BillItem editing) {
    final isIncome = editing.type == 'income';
    _suppressTabSync = true;
    _tabController.index = isIncome ? 1 : 0;
    _lastTabIndex = _tabController.index;
    _suppressTabSync = false;
    setState(() => _selectedIconId = editing.iconId);

    final all = ref.read(categoryListProvider).value ?? const [];
    final inEx = isIncome ? 1 : 0;
    final cat = all.firstWhere(
      (c) => c.inEx == inEx && c.iconId == editing.iconId,
      orElse: () => all.firstWhere(
        (c) => c.inEx == inEx,
        orElse: () => CategoryEntry(
          id: -1,
          inEx: inEx,
          name: editing.category,
          iconId: editing.iconId,
          isCustom: false,
          sortOrder: 0,
          createdAt: '',
          updatedAt: '',
        ),
      ),
    );
    final icon = iconJson[cat.iconId];
    final editDate = _billDateToDateTime(editing);

    ref
        .read(keyboardProvider.notifier)
        .show(
          categoryName: cat.name,
          categoryIconPath: iconPath(icon.iconS),
          initialAmount: editing.amount,
          initialNote: editing.note,
          initialDate: editDate,
          onComplete: (amount, note, date) =>
              _updateBill(editing, cat, amount, note, date),
        );
  }

  void _saveBill(CategoryEntry cat, double amount, String note, DateTime date) {
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

    final bill = BillItem(
      id: id,
      type: _currentType,
      amount: amount,
      category: cat.name,
      note: note,
      date: dateStr,
      sortAt: nowStr,
      iconId: cat.iconId,
      createdAt: nowStr,
      updatedAt: nowStr,
    );

    ref.read(billListProvider.notifier).add(bill);
    ref.read(keyboardProvider.notifier).hide();
    ref.read(navigationProvider.notifier).setTab(0);
  }

  void _updateBill(
    BillItem original,
    CategoryEntry cat,
    double amount,
    String note,
    DateTime date,
  ) {
    final now = DateTime.now();
    final originalDay = original.date.substring(0, 10);
    final nextDay =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final nowStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} '
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
    final isSameBillDay = originalDay == nextDay;
    final dateStr = isSameBillDay
        ? original.date
        : '$nextDay '
              '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
    final nextSortAt = isSameBillDay ? original.sortAt : nowStr;

    final updated = original.copyWith(
      type: _currentType,
      amount: amount,
      category: cat.name,
      note: note,
      date: dateStr,
      sortAt: nextSortAt,
      iconId: cat.iconId,
      updatedAt: nowStr,
    );

    ref.read(billListProvider.notifier).updateBill(updated);
    ref.read(editingBillProvider.notifier).clear();
    ref.read(keyboardProvider.notifier).hide();
    ref.read(navigationProvider.notifier).setTab(0);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<BillItem?>(editingBillProvider, (prev, next) {
      if (next != null && prev == null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _openEditKeyboard(next);
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
      decoration: BoxDecoration(color: AppColors.primary),
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
              labelStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
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

  Widget _buildGrid(List<CategoryEntry> categories) {
    final kb = ref.watch(keyboardProvider);
    // BottomAppBar 高度 64 + notch margin
    const tabBarHeight = 64.0;
    final bottomPad = kb.visible && kb.height > 0
        ? (kb.height - tabBarHeight).clamp(0.0, double.infinity)
        : 16.0;
    // 末尾追加一个「设置」格子，用于进入「类别设置」页
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
        final isSelected = _selectedIconId == cat.iconId;
        final icon = iconJson[cat.iconId];
        final imgPath = isSelected ? iconPath(icon.iconS) : iconPath(icon.icon);
        return GestureDetector(
          onTap: () => _onCategoryTap(cat),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.transparent,
                ),
                child: Center(
                  child: Image.asset(imgPath, width: 50, height: 50),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                cat.name,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
    );
  }

  void _openCategorySettings() {
    // 进入设置前先收起键盘，避免覆盖
    ref.read(keyboardProvider.notifier).hide();
    final initialInEx = _tabController.index; // 0 = expense, 1 = income
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CategorySettingsPage(initialInEx: initialInEx),
      ),
    );
  }
}

/// 「设置」格子：与其他类别一致的占位 + 一个齿轮图标
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
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFF4F4F4),
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
