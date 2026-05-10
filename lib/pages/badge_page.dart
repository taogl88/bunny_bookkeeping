import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/badge_provider.dart';
import '../theme/app_theme.dart';
import '../utils/icon_helper.dart';
import '../widgets/badge_detail_dialog.dart';

/// 徽章页：按七大分类展示徽章成就。
///
/// 资源命名约定（与 ICON_JSON 保持一致）：
///  - [BadgeRule.icon]   是默认/未获得态的图（灰色）
///  - [BadgeRule.iconS]  是高亮/已获得态的图（彩色）
///
/// 因此：已获得 → 彩色 `iconS`；未获得 → 灰色 `icon`。
///
/// 数据来自 [badgeProvider]，会跟随账单变化自动刷新。
class BadgePage extends ConsumerWidget {
  const BadgePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(badgeProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundGray,
      appBar: AppBar(
        title: const Text(
          '徽章',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: dataAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败：$e')),
        data: (data) => _BadgeList(sections: data.sections),
      ),
    );
  }
}

class _BadgeList extends StatelessWidget {
  const _BadgeList({required this.sections});

  final List<BadgeSection> sections;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 24),
      itemCount: sections.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) =>
          _BadgeSectionCard(section: sections[index]),
    );
  }
}

class _BadgeSectionCard extends StatelessWidget {
  const _BadgeSectionCard({required this.section});

  final BadgeSection section;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            title: section.title,
            achievedCount: section.achievedCount,
          ),
          const SizedBox(height: 12),
          _BadgeGrid(badges: section.badges),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.achievedCount});

  final String title;
  final int achievedCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '已获取$achievedCount枚',
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _BadgeGrid extends StatelessWidget {
  const _BadgeGrid({required this.badges});

  final List<BadgeAchievement> badges;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.82,
      ),
      itemCount: badges.length,
      itemBuilder: (context, index) => _BadgeTile(badge: badges[index]),
    );
  }
}

class _BadgeTile extends StatelessWidget {
  const _BadgeTile({required this.badge});

  final BadgeAchievement badge;

  @override
  Widget build(BuildContext context) {
    final achieved = badge.achieved;
    // 已获得 → 彩色 iconS；未获得 → 灰色 icon
    final imgPath = iconPath(achieved ? badge.rule.iconS : badge.rule.icon);
    return InkWell(
      onTap: () => showBadgeDetailDialog(context, badge),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Image.asset(
                imgPath,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              badge.rule.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: achieved
                    ? AppColors.textPrimary
                    : AppColors.textSecondary.withAlpha(140),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
