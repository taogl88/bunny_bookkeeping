import 'package:flutter/material.dart';

import '../providers/badge_provider.dart';
import '../theme/app_theme.dart';
import '../utils/icon_helper.dart';

/// 依次弹出每一枚新解锁的徽章。多枚时排队展示，关闭一个再弹下一个。
///
/// 提供两种关闭方式：
///  1. 点击对话框外的半透明背景（barrierDismissible: true）
///  2. 卡片右上角的叉号按钮
Future<void> showBadgeUnlockDialog(
  BuildContext context,
  List<BadgeAchievement> newlyUnlocked,
) async {
  for (final badge in newlyUnlocked) {
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black54,
      builder: (ctx) => _BadgeUnlockDialog(badge: badge),
    );
  }
}

class _BadgeUnlockDialog extends StatelessWidget {
  const _BadgeUnlockDialog({required this.badge});

  final BadgeAchievement badge;

  @override
  Widget build(BuildContext context) {
    final imgPath = iconPath(badge.rule.iconS);
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // 卡片本体
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
                  const Text(
                    '恭喜获得新徽章',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 18),
                  // 给徽章加一圈柔和的黄色光晕背景，更有"奖励感"
                  Container(
                    width: 168,
                    height: 168,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppColors.primary.withAlpha(70),
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
                      '已达成：${badge.rule.condition}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    '再接再厉，继续记账解锁更多徽章！',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                      height: 1.5,
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
                          '好的',
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
            // 右上角叉号按钮
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
