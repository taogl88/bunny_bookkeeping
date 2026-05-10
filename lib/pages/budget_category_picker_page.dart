import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/account_data.dart';
import '../models/category_entry.dart';
import '../providers/budget_provider.dart';
import '../providers/category_provider.dart';
import '../theme/app_theme.dart';
import '../utils/icon_helper.dart';
import '../widgets/budget_amount_keyboard.dart';

/// 选择分类预算所属的类目
///
/// 进入页面 → 点击某个支出类目 → 弹出预算键盘 → 输入金额并确定 →
/// 自动写入分类预算后回到“预算管家”页（连同当前页一并 pop）。
/// 关闭键盘弹窗保留在本页继续选择，右上角“取消”可关闭整页。
class BudgetCategoryPickerPage extends ConsumerStatefulWidget {
  const BudgetCategoryPickerPage({super.key});

  @override
  ConsumerState<BudgetCategoryPickerPage> createState() =>
      _BudgetCategoryPickerPageState();
}

class _BudgetCategoryPickerPageState
    extends ConsumerState<BudgetCategoryPickerPage> {
  int? _selectedIconId;

  /// 已经设置过预算的 iconId 集合，避免重复添加
  Set<int> _existingIconIds(WidgetRef ref, {bool listen = false}) {
    final data = listen
        ? ref.watch(budgetProvider).value
        : ref.read(budgetProvider).value;
    if (data == null) return const {};
    return data.categoryBudgets.map((b) => b.iconId).toSet();
  }

  Future<void> _onCategoryTap(CategoryEntry cat) async {
    if (_existingIconIds(ref).contains(cat.iconId)) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(milliseconds: 1200),
          backgroundColor: AppColors.textPrimary,
          behavior: SnackBarBehavior.floating,
          content: Text('“${cat.name}”已设置过分类预算'),
        ),
      );
      return;
    }
    setState(() => _selectedIconId = cat.iconId);

    final periodType = ref.read(budgetPeriodProvider);
    final isMonth = periodType == BudgetPeriodType.month;
    final amount = await showBudgetAmountKeyboard(
      context: context,
      title: '${isMonth ? '每月' : '每年'}${cat.name}预算',
    );
    if (!mounted) return;

    if (amount == null) {
      // 用户取消，仍停留在本页，但取消高亮态以便再次点击
      setState(() => _selectedIconId = null);
      return;
    }

    final autoUpdated = await ref
        .read(budgetProvider.notifier)
        .saveCategoryBudget(
          iconId: cat.iconId,
          category: cat.name,
          amount: amount,
        );
    if (!mounted) return;

    if (autoUpdated) {
      await _showAutoUpdateAlert();
    }
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Future<void> _showAutoUpdateAlert() {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '分类预算之和已超过总预算，将自动更新总预算',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 24),
                const Divider(height: 1, color: Color(0xFFE5E5E5)),
                SizedBox(
                  height: 44,
                  child: TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.textPrimary,
                      minimumSize: const Size.fromHeight(44),
                    ),
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text(
                      '好的',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A75FF),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(child: _buildGrid()),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final topPadding = MediaQuery.of(context).padding.top;
    return Container(
      color: AppColors.primary,
      padding: EdgeInsets.only(top: topPadding),
      height: 48 + topPadding,
      alignment: Alignment.bottomCenter,
      child: Stack(
        children: [
          const SizedBox(
            height: 48,
            width: double.infinity,
            child: Center(
              child: Text(
                '选择类别',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            child: Center(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => Navigator.of(context).pop(),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 14),
                  child: Text(
                    '取消',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid() {
    final existingSet = _existingIconIds(ref, listen: true);
    final categories = ref.watch(expenseCategoriesProvider);
    return SafeArea(
      top: false,
      child: GridView.builder(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          childAspectRatio: 0.85,
        ),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final cat = categories[index];
          final isSelected = _selectedIconId == cat.iconId;
          final disabled = existingSet.contains(cat.iconId);
          final iconMeta = iconJson[cat.iconId];
          final imgPath = isSelected
              ? iconPath(iconMeta.iconS)
              : iconPath(iconMeta.icon);
          return GestureDetector(
            onTap: () => _onCategoryTap(cat),
            child: Opacity(
              opacity: disabled ? 0.35 : 1,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(child: Image.asset(imgPath, width: 50, height: 50)),
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
            ),
          );
        },
      ),
    );
  }
}
