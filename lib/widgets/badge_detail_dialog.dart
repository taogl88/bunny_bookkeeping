import 'package:flutter/material.dart';

import '../providers/badge_provider.dart';
import '../theme/app_theme.dart';
import '../utils/icon_helper.dart';

/// 在徽章页点击徽章时弹出的详情。
///
/// - 已获得：彩色徽章图 + "已获得"标签 + "已达成 xxx" 描述；
/// - 未获得：灰色徽章图 + "未获得"标签 + "达成 xxx 即可解锁" 描述。
///
/// 关闭方式：点击对话框外的半透明背景，或卡片右上角的叉号按钮。
Future<void> showBadgeDetailDialog(
  BuildContext context,
  BadgeAchievement badge,
) async {
  await showDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black54,
    builder: (ctx) => _BadgeDetailDialog(badge: badge),
  );
}

class _BadgeDetailDialog extends StatelessWidget {
  const _BadgeDetailDialog({required this.badge});

  final BadgeAchievement badge;

  @override
  Widget build(BuildContext context) {
    final achieved = badge.achieved;
    // 已获得 → 彩色 iconS；未获得 → 灰色 icon（与徽章页保持一致）
    final imgPath = iconPath(achieved ? badge.rule.iconS : badge.rule.icon);

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              // 撑满 Stack 给的最大宽度，避免 Container 因 wrap-content 比
              // Stack 窄、X 按钮反而落在卡片外面 / 弹窗整体居中偏移。
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _StatusChip(achieved: achieved),
                  const SizedBox(height: 18),
                  Container(
                    width: 168,
                    height: 168,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          (achieved
                                  ? AppColors.primary
                                  : AppColors.darkGray)
                              .withAlpha(60),
                          AppColors.primary.withAlpha(0),
                        ],
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Image.asset(imgPath, width: 130, height: 130),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    badge.rule.name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // 达成条件
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      achieved
                          ? '已达成：${badge.rule.condition}'
                          : '达成 ${badge.rule.condition} 即可获得',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Material(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(22),
                    child: InkWell(
                      onTap: () => Navigator.of(context).pop(),
                      borderRadius: BorderRadius.circular(22),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 36,
                          vertical: 10,
                        ),
                        child: Text(
                          '知道了',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // 右上角叉号
            Positioned(
              top: 4,
              right: 4,
              child: Material(
                color: Colors.transparent,
                shape: const CircleBorder(),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => Navigator.of(context).pop(),
                  child: const Padding(
                    padding: EdgeInsets.all(6),
                    child: Icon(
                      Icons.close,
                      size: 20,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.achieved});

  final bool achieved;

  @override
  Widget build(BuildContext context) {
    final bg = achieved ? AppColors.primary : AppColors.darkGray;
    final fg = achieved ? AppColors.textPrimary : AppColors.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        achieved ? '已获得' : '未获得',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );
  }
}
