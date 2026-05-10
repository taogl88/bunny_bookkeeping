import 'package:flutter/material.dart';

import '../data/account_data.dart';
import '../models/category_entry.dart';
import '../theme/app_theme.dart';
import '../utils/icon_helper.dart';

/// 用户在删除分类警告 sheet / 转移目标 sheet 中做出的决策。
///
/// sheet 自身不直接调用 provider notifier：因为外层警告 sheet 是
/// `ConsumerWidget`，一旦 `Navigator.pop()` 关闭它，其 `ref` 就失效了，
/// 在 await 之后再 `ref.read(...)` 是 no-op 甚至会触发"after dispose"
/// 异常，导致"点了转移目标但实际没生效"。
///
/// 这里 sheet 只回传 [CategoryDeleteAction]，由仍然 mounted 的调用方
/// （[CategorySettingsPage] 列表）用自己的 ref 去执行真正的写库操作。
class CategoryDeleteAction {
  const CategoryDeleteAction.deleteAll() : transferTo = null;
  const CategoryDeleteAction.transferTo(CategoryEntry this.transferTo);

  /// 非空表示「转移到此分类后删除」；为空表示「连同账单一起删除」。
  final CategoryEntry? transferTo;
}

/// 删除分类前的警告底部 sheet（图4）。
///
/// 提供两条出路：
///  - 「转移数据」：让用户挑一个目标分类，把当前分类下的账单全部转过去后删除；
///  - 「仍然删除」：连同账单一起删除（不可撤销）；
///  - 右上角 X 关闭。
///
/// 返回 `null` 表示用户取消了操作。
Future<CategoryDeleteAction?> showCategoryDeleteSheet({
  required BuildContext context,
  required CategoryEntry category,
  required List<CategoryEntry> siblings,
}) {
  return showModalBottomSheet<CategoryDeleteAction>(
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withAlpha(120),
    isScrollControlled: true,
    builder: (ctx) => _CategoryDeleteSheet(
      category: category,
      siblings: siblings,
    ),
  );
}

class _CategoryDeleteSheet extends StatelessWidget {
  const _CategoryDeleteSheet({
    required this.category,
    required this.siblings,
  });

  final CategoryEntry category;
  final List<CategoryEntry> siblings;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.error,
                  color: Color(0xFFE53935),
                  size: 22,
                ),
                const SizedBox(width: 8),
                const Text(
                  '警告',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                InkWell(
                  onTap: () => Navigator.of(context).pop(),
                  customBorder: const CircleBorder(),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(
                      Icons.close,
                      size: 20,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 30),
              child: Text(
                '删除"${category.name}"会同时删除该类别下的所有记账',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    label: '转移数据',
                    primary: false,
                    onTap: () => _onTransfer(context),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ActionButton(
                    label: '仍然删除',
                    primary: true,
                    onTap: () => _onDelete(context),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _onDelete(BuildContext context) {
    Navigator.of(context).pop(const CategoryDeleteAction.deleteAll());
  }

  Future<void> _onTransfer(BuildContext context) async {
    // 同 inEx 中除自己以外的备选分类
    final candidates = [
      for (final c in siblings)
        if (c.id != category.id) c,
    ];
    if (candidates.isEmpty) {
      // 没有其他分类可转：提示并保持警告 sheet 打开
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('没有其他分类可以转移'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    final target = await _pickTransferTarget(context, candidates);
    if (target == null) return;
    if (!context.mounted) return;
    Navigator.of(context).pop(CategoryDeleteAction.transferTo(target));
  }

  Future<CategoryEntry?> _pickTransferTarget(
    BuildContext context,
    List<CategoryEntry> candidates,
  ) {
    return showModalBottomSheet<CategoryEntry>(
      context: context,
      backgroundColor: Colors.transparent,
      // isScrollControlled: true 让 sheet 可以拿到超过 50% 屏幕高的空间，
      // 否则下方 ListView (maxHeight = 0.5 屏幕) + 标题 + padding + safeArea
      // 之和会顶破默认上限，触发 "bottom overflow by 56 px"。
      isScrollControlled: true,
      builder: (ctx) {
        return _TransferTargetSheet(
          fromName: category.name,
          candidates: candidates,
        );
      },
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.primary,
    required this.onTap,
  });

  final String label;
  final bool primary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: primary ? AppColors.primary : const Color(0xFFEEEEEE),
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: SizedBox(
          height: 40,
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: primary
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 选择转移目标的底部 sheet（"转移数据"按钮二段交互）
class _TransferTargetSheet extends StatelessWidget {
  const _TransferTargetSheet({
    required this.fromName,
    required this.candidates,
  });

  final String fromName;
  final List<CategoryEntry> candidates;

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    // 列表最多占视口的 50%（去掉系统底部安全区），剩余空间留给标题/padding，
    // 整个 sheet 大概 55% 屏幕高，避免顶到键盘/导航栏。
    final listMaxHeight = (mq.size.height - mq.padding.bottom) * 0.5;
    return SafeArea(
      top: false,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '将"$fromName"的账单转移到',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                InkWell(
                  onTap: () => Navigator.of(context).pop(),
                  customBorder: const CircleBorder(),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(
                      Icons.close,
                      size: 20,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: listMaxHeight),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: candidates.length,
                separatorBuilder: (_, _) => const Divider(
                  height: 0.5,
                  color: Color(0xFFEEEEEE),
                ),
                itemBuilder: (context, index) {
                  final cat = candidates[index];
                  final iconMeta = iconJson[cat.iconId];
                  return InkWell(
                    onTap: () => Navigator.of(context).pop(cat),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 32,
                            height: 32,
                            child: Image.asset(iconPath(iconMeta.icon)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              cat.name,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right,
                            color: AppColors.textSecondary,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
