import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/account_data.dart';
import '../models/budget_item.dart';
import '../providers/budget_provider.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../utils/icon_helper.dart';
import '../widgets/budget_amount_keyboard.dart';
import 'budget_category_picker_page.dart';

/// 预算管家页面
///
/// 顶部黄色 bar：标题“月预算 ▼ / 年预算 ▼”可点击切换；
/// 主体：当未设置总预算时展示空态 + “添加预算”按钮；设置后展示总预算卡片，
/// 并支持继续添加分类预算。
class BudgetManagerPage extends ConsumerWidget {
  const BudgetManagerPage({super.key});

  String _periodLabel(BudgetData data) {
    if (data.periodType == BudgetPeriodType.month) {
      final mm = data.period.substring(5);
      final monthInt = int.tryParse(mm) ?? 0;
      final mmShown = monthInt.toString().padLeft(2, '0');
      return '$mmShown月总预算';
    }
    return '${data.period}年总预算';
  }

  String _periodPrefix(BudgetData data) =>
      data.periodType == BudgetPeriodType.month ? '每月' : '每年';

  String _expenseLabel(BudgetData data) =>
      data.periodType == BudgetPeriodType.month ? '本月支出：' : '年度支出：';

  String _budgetLabel(BudgetData data) =>
      data.periodType == BudgetPeriodType.month ? '本月预算：' : '年度预算：';

  /// 总预算菜单项中所用的“月度总 / 年度总”文字
  String _totalKindLabel(BudgetData data) =>
      data.periodType == BudgetPeriodType.month ? '月度总' : '年度总';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final periodType = ref.watch(budgetPeriodProvider);
    final dataAsync = ref.watch(budgetProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundGray,
      body: dataAsync.when(
        loading: () => Column(
          children: [
            _BudgetHeader(periodType: periodType),
            const Expanded(child: Center(child: CircularProgressIndicator())),
          ],
        ),
        error: (e, _) => Column(
          children: [
            _BudgetHeader(periodType: periodType),
            Expanded(child: Center(child: Text('加载失败: $e'))),
          ],
        ),
        data: (data) => _buildBody(context, ref, data),
      ),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref, BudgetData data) {
    final hasTotal = data.totalBudget != null;
    final bottomSafe = MediaQuery.of(context).padding.bottom;

    return Column(
      children: [
        _BudgetHeader(periodType: data.periodType),
        Expanded(
          child: hasTotal
              ? _buildLoadedContent(context, ref, data)
              : _buildEmptyState(context, ref, data),
        ),
        if (hasTotal)
          _AddCategoryBudgetButton(
            bottomSafe: bottomSafe,
            onTap: () => _onAddCategoryBudget(context, ref),
          ),
      ],
    );
  }

  // ============= 空态 =============
  Widget _buildEmptyState(BuildContext context, WidgetRef ref, BudgetData data) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 64,
            color: AppColors.textSecondary.withAlpha(100),
          ),
          const SizedBox(height: 8),
          Text(
            '暂无预算',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary.withAlpha(180),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 38),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _onAddTotalBudget(context, ref, data),
            child: Container(
              width: 200,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Text(
                '+ 添加预算',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============= 总预算 + 分类预算 =============
  Widget _buildLoadedContent(
    BuildContext context,
    WidgetRef ref,
    BudgetData data,
  ) {
    final total = data.totalBudget!;
    final categories = data.categoryBudgets;
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _TotalBudgetCard(
            title: _periodLabel(data),
            budget: total.amount,
            expense: data.totalExpense,
            budgetLabel: _budgetLabel(data),
            expenseLabel: _expenseLabel(data),
            onEdit: () => _onEditTotalBudget(context, ref, data),
          ),
          if (categories.isEmpty) ...[
            const SizedBox(height: 100),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 56,
                    color: AppColors.textSecondary.withAlpha(100),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '未设置分类预算',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary.withAlpha(180),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            const SizedBox(height: 12),
            const Padding(
              padding: EdgeInsets.fromLTRB(18, 4, 18, 8),
              child: Text(
                '分类预算',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            for (final cat in categories) ...[
              _CategoryBudgetCard(
                budget: cat,
                expense: data.expenseOf(cat.iconId),
                periodPrefix: _periodPrefix(data),
                onEdit: () => _onEditCategoryBudget(context, ref, data, cat),
              ),
              const SizedBox(height: 1),
            ],
          ],
        ],
      ),
    );
  }

  // ============= 添加 总预算（空态调起） =============
  Future<void> _onAddTotalBudget(
    BuildContext context,
    WidgetRef ref,
    BudgetData data,
  ) async {
    final amount = await showBudgetAmountKeyboard(
      context: context,
      title: '${_periodPrefix(data)}总预算',
      initialAmount: data.totalBudget?.amount,
    );
    if (amount == null) return;
    await ref.read(budgetProvider.notifier).saveTotalBudget(amount);
  }

  // ============= 编辑入口（总预算）：先弹出菜单 =============
  Future<void> _onEditTotalBudget(
    BuildContext context,
    WidgetRef ref,
    BudgetData data,
  ) async {
    final kind = _totalKindLabel(data);
    final action = await _showEditActionSheet(
      context: context,
      editLabel: '编辑$kind预算',
      deleteLabel: '删除$kind预算',
    );
    if (action == _BudgetEditAction.edit) {
      if (!context.mounted) return;
      final amount = await showBudgetAmountKeyboard(
        context: context,
        title: '${_periodPrefix(data)}总预算',
        initialAmount: data.totalBudget?.amount,
      );
      if (amount == null) return;
      await ref.read(budgetProvider.notifier).saveTotalBudget(amount);
    } else if (action == _BudgetEditAction.delete) {
      await ref.read(budgetProvider.notifier).deleteTotalBudget();
    }
  }

  // ============= 编辑入口（分类预算）：先弹出菜单 =============
  Future<void> _onEditCategoryBudget(
    BuildContext context,
    WidgetRef ref,
    BudgetData data,
    BudgetItem cat,
  ) async {
    final action = await _showEditActionSheet(
      context: context,
      editLabel: '编辑${cat.category}预算',
      deleteLabel: '删除${cat.category}预算',
    );
    if (action == _BudgetEditAction.edit) {
      if (!context.mounted) return;
      final amount = await showBudgetAmountKeyboard(
        context: context,
        title: '${_periodPrefix(data)}${cat.category}预算',
        initialAmount: cat.amount,
      );
      if (amount == null) return;
      final autoUpdated = await ref
          .read(budgetProvider.notifier)
          .saveCategoryBudget(
            iconId: cat.iconId,
            category: cat.category,
            amount: amount,
          );
      if (!context.mounted) return;
      if (autoUpdated) {
        await _showAutoUpdateAlert(context);
      }
    } else if (action == _BudgetEditAction.delete) {
      await ref.read(budgetProvider.notifier).deleteCategoryBudget(cat.id);
    }
  }

  // ============= 添加分类预算 =============
  void _onAddCategoryBudget(BuildContext context, WidgetRef ref) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const BudgetCategoryPickerPage(),
      ),
    );
  }

  Future<void> _showAutoUpdateAlert(BuildContext context) {
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
}

/// “编辑”按钮对应的底部菜单返回值
enum _BudgetEditAction { edit, delete }

/// 显示“编辑/删除/取消”底部菜单。返回 null 表示用户取消。
Future<_BudgetEditAction?> _showEditActionSheet({
  required BuildContext context,
  required String editLabel,
  required String deleteLabel,
}) {
  return showModalBottomSheet<_BudgetEditAction>(
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withAlpha(120),
    builder: (ctx) {
      return SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _BudgetActionTile(
                      label: editLabel,
                      onTap: () =>
                          Navigator.of(ctx).pop(_BudgetEditAction.edit),
                    ),
                    const Divider(height: 0.5, color: Color(0xFFEEEEEE)),
                    _BudgetActionTile(
                      label: deleteLabel,
                      destructive: true,
                      onTap: () =>
                          Navigator.of(ctx).pop(_BudgetEditAction.delete),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _BudgetActionTile(
                  label: '取消',
                  onTap: () => Navigator.of(ctx).pop(),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _BudgetActionTile extends StatelessWidget {
  const _BudgetActionTile({
    required this.label,
    required this.onTap,
    this.destructive = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 52,
          width: double.infinity,
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: destructive ? Colors.red : AppColors.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// =================================================================
// 顶部 Header
// =================================================================
class _BudgetHeader extends ConsumerWidget {
  const _BudgetHeader({required this.periodType});

  final BudgetPeriodType periodType;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topPadding = MediaQuery.of(context).padding.top;
    final isMonth = periodType == BudgetPeriodType.month;
    return Container(
      color: AppColors.primary,
      padding: EdgeInsets.only(top: topPadding),
      height: 48 + topPadding,
      alignment: Alignment.bottomCenter,
      child: Stack(
        children: [
          // 中间标题：点击切换 月/年
          Positioned.fill(
            child: Center(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _showPeriodSwitcher(context, ref),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isMonth ? '月预算' : '年预算',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.arrow_drop_down,
                        size: 22,
                        color: AppColors.textPrimary,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // 右上：关闭/返回 按钮
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            child: Center(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => Navigator.of(context).pop(),
                  borderRadius: BorderRadius.circular(20),
                  splashColor: AppColors.darkGray.withAlpha(90),
                  highlightColor: AppColors.darkGray.withAlpha(35),
                  child: const Padding(
                    padding: EdgeInsets.all(10),
                    child: Icon(
                      Icons.radio_button_checked,
                      size: 22,
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

  Future<void> _showPeriodSwitcher(BuildContext context, WidgetRef ref) async {
    final selected = await showModalBottomSheet<BudgetPeriodType>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
      ),
      builder: (ctx) {
        return SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _switcherTile(
                ctx,
                label: '月预算',
                value: BudgetPeriodType.month,
                selected: periodType == BudgetPeriodType.month,
              ),
              const Divider(height: 1, color: Color(0xFFEEEEEE)),
              _switcherTile(
                ctx,
                label: '年预算',
                value: BudgetPeriodType.year,
                selected: periodType == BudgetPeriodType.year,
              ),
              Container(height: 6, color: AppColors.backgroundGray),
              SizedBox(
                height: 50,
                child: TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    minimumSize: const Size.fromHeight(50),
                  ),
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text(
                    '取消',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
    if (selected != null) {
      ref.read(budgetPeriodProvider.notifier).set(selected);
    }
  }

  Widget _switcherTile(
    BuildContext context, {
    required String label,
    required BudgetPeriodType value,
    required bool selected,
  }) {
    return InkWell(
      onTap: () => Navigator.of(context).pop(value),
      child: Container(
        height: 50,
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: selected ? AppColors.primaryDark : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

// =================================================================
// 总预算卡片
// =================================================================
class _TotalBudgetCard extends StatelessWidget {
  const _TotalBudgetCard({
    required this.title,
    required this.budget,
    required this.expense,
    required this.budgetLabel,
    required this.expenseLabel,
    required this.onEdit,
  });

  final String title;
  final double budget;
  final double expense;
  final String budgetLabel;
  final String expenseLabel;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final remaining = budget - expense;
    final overflow = remaining < 0;
    final ratio = budget <= 0
        ? 0.0
        : (remaining > 0 ? remaining / budget : 0.0).clamp(0.0, 1.0);
    final percentText = '${(ratio * 100).round()}%';

    return Container(
      width: double.infinity,
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onEdit,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 4,
                  ),
                  child: Text(
                    '编辑',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _BudgetRing(
                ratio: ratio,
                percentText: percentText,
                overflow: overflow,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  children: [
                    _InfoRow(
                      label: '剩余预算：',
                      value: remaining,
                      large: true,
                    ),
                    const SizedBox(height: 12),
                    _InfoRow(label: budgetLabel, value: budget),
                    const SizedBox(height: 8),
                    _InfoRow(label: expenseLabel, value: expense),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// =================================================================
// 分类预算卡片
// =================================================================
class _CategoryBudgetCard extends StatelessWidget {
  const _CategoryBudgetCard({
    required this.budget,
    required this.expense,
    required this.periodPrefix,
    required this.onEdit,
  });

  final BudgetItem budget;
  final double expense;
  final String periodPrefix;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final amount = budget.amount;
    final remaining = amount - expense;
    final overflow = remaining < 0;
    final ratio = amount <= 0
        ? 0.0
        : (remaining > 0 ? remaining / amount : 0.0).clamp(0.0, 1.0);
    final percentText = '${(ratio * 100).round()}%';

    final iconMeta = (budget.iconId >= 0 && budget.iconId < iconJson.length)
        ? iconJson[budget.iconId]
        : null;

    return Container(
      width: double.infinity,
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (iconMeta != null) ...[
                Image.asset(iconPath(iconMeta.iconS), width: 20, height: 20),
                const SizedBox(width: 6),
              ],
              Text(
                budget.category,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onEdit,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 4,
                  ),
                  child: Text(
                    '编辑',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _BudgetRing(
                ratio: ratio,
                percentText: percentText,
                overflow: overflow,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  children: [
                    _InfoRow(
                      label: '剩余预算：',
                      value: remaining,
                      large: true,
                    ),
                    const SizedBox(height: 12),
                    _InfoRow(label: '预算：', value: amount),
                    const SizedBox(height: 8),
                    _InfoRow(label: '支出：', value: expense),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// =================================================================
// 圆环
// =================================================================
class _BudgetRing extends StatelessWidget {
  const _BudgetRing({
    required this.ratio,
    required this.percentText,
    required this.overflow,
  });

  final double ratio;
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
              value: overflow ? 0 : ratio,
              strokeWidth: 9,
              backgroundColor: AppColors.gray,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.primary,
              ),
            ),
          ),
          if (overflow)
            const Text(
              '已超支',
              style: TextStyle(
                fontSize: 13,
                color: Colors.red,
                fontWeight: FontWeight.w500,
              ),
            )
          else
            Column(
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

// =================================================================
// 文案行
// =================================================================
class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    this.large = false,
  });

  final String label;
  final double value;
  final bool large;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: large ? 14 : 12,
            fontWeight: large ? FontWeight.w600 : FontWeight.w500,
            color: large ? AppColors.textPrimary : AppColors.textSecondary,
          ),
        ),
        const Spacer(),
        buildAmountText(
          value: value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          integerStyle: TextStyle(
            fontSize: large ? 18 : 13,
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
          decimalStyle: TextStyle(
            fontSize: large ? 16 : 12,
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

// =================================================================
// 底部 “+ 添加分类预算” 按钮
// =================================================================
class _AddCategoryBudgetButton extends StatelessWidget {
  const _AddCategoryBudgetButton({
    required this.bottomSafe,
    required this.onTap,
  });

  final double bottomSafe;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: EdgeInsets.only(top: 4, bottom: bottomSafe + 4),
      child: SizedBox(
        height: 48,
        width: double.infinity,
        child: TextButton(
          style: TextButton.styleFrom(
            foregroundColor: AppColors.textPrimary,
            shape: const RoundedRectangleBorder(),
            backgroundColor: AppColors.surface,
          ),
          onPressed: onTap,
          child: const Text(
            '+ 添加分类预算',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
