import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';

import '../data/account_data.dart';
import '../providers/bill_provider.dart';
import '../providers/category_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/user_stats_provider.dart';
import '../services/import_service.dart';
import '../theme/app_theme.dart';
import '../utils/icon_helper.dart';
import 'badge_page.dart';

/// 「我的」页面
///
/// 顶部欢迎区（黄色）+ 半浮于其上的统计卡片，
/// 下方是设置区与小贴士区。设置区目前提供「短信自动记账」开关。
class MinePage extends ConsumerWidget {
  const MinePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.backgroundGray,
      body: ListView(
        padding: EdgeInsets.zero,
        children: const [
          _MineHeader(),
          SizedBox(height: 36 + 12),
          _AchievementCard(),
          SizedBox(height: 12),
          _SmsSettingCard(),
          SizedBox(height: 12),
          _ImportCard(),
          SizedBox(height: 12),
          _TipsCard(),
          SizedBox(height: 24),
          _AppFooter(),
          SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ==========================================================================
// 顶部 Header（黄色背景 + 欢迎信息）+ 统计卡片
// ==========================================================================
class _MineHeader extends ConsumerWidget {
  const _MineHeader();

  /// 统计卡片向下伸出黄色 header 的距离（同时也是 [MinePage] 主体补偿
  /// `SizedBox` 高度的依据，二者必须保持一致）。
  static const double _statsCardOffset = 36;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(userStatsProvider);
    final stats = statsAsync.value ?? UserStats.empty;

    final topPadding = MediaQuery.of(context).padding.top;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // 黄色背景：底部预留出一些空间，让统计卡片能优雅地坐落在其下沿
        Container(
          color: AppColors.primary,
          padding: EdgeInsets.only(top: topPadding),
          child: const Padding(
            padding: EdgeInsets.fromLTRB(20, 24, 20, 64),
            child: _WelcomeRow(),
          ),
        ),
        // 半浮在黄色与灰色背景交界处的统计卡片
        Positioned(
          left: 16,
          right: 16,
          bottom: -_statsCardOffset,
          child: _StatsCard(stats: stats),
        ),
      ],
    );
  }
}

class _WelcomeRow extends StatelessWidget {
  const _WelcomeRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withAlpha(180),
            border: Border.all(color: Colors.white, width: 2),
          ),
          alignment: Alignment.center,
          child: const Icon(
            Icons.savings_outlined,
            size: 30,
            color: AppColors.primaryDark,
          ),
        ),
        const SizedBox(width: 14),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '你好，记账人',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  height: 1.2,
                ),
              ),
              SizedBox(height: 6),
              Text(
                '持续记录每一笔，让金钱有迹可循',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatsCard extends StatelessWidget {
  const _StatsCard({required this.stats});

  final UserStats stats;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 1,
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 18),
        child: Row(
          children: [
            Expanded(
              child: _StatCell(
                value: stats.currentStreak,
                label: '已连续天数',
                highlighted: stats.currentStreak > 0,
              ),
            ),
            _Divider(),
            Expanded(
              child: _StatCell(value: stats.totalCount, label: '记账总笔数'),
            ),
            _Divider(),
            Expanded(
              child: _StatCell(value: stats.totalDays, label: '记账总天数'),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({
    required this.value,
    required this.label,
    this.highlighted = false,
  });

  final int value;
  final String label;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value.toString(),
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: highlighted ? AppColors.primaryDark : AppColors.textPrimary,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
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

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 32, color: AppColors.darkGray);
  }
}

// ==========================================================================
// 成就（我的徽章）入口卡片
// ==========================================================================
class _AchievementCard extends StatelessWidget {
  const _AchievementCard();

  /// 取 mineJson 中 name 为「徽章」的入口图标。
  /// 若资源被改动找不到，回退使用奖杯 icon 作为占位。
  static String? _badgeIconPath() {
    for (final group in mineJson) {
      for (final item in group) {
        if (item.name == '徽章') {
          return item.icon;
        }
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final iconAssetRaw = _badgeIconPath();
    final iconAsset = iconAssetRaw == null ? null : iconPath(iconAssetRaw);
    return _SectionCard(
      title: '成就',
      children: [
        _NavTile(
          leading: iconAsset != null
              ? Image.asset(iconAsset, width: 22, height: 22)
              : const Icon(
                  Icons.emoji_events_outlined,
                  size: 22,
                  color: AppColors.primaryDark,
                ),
          title: '我的徽章',
          subtitle: '随着记账解锁更多徽章成就',
          onTap: () {
            Navigator.of(
              context,
            ).push(MaterialPageRoute<void>(builder: (_) => const BadgePage()));
          },
        ),
      ],
    );
  }
}

// ==========================================================================
// 短信自动记账开关卡片
// ==========================================================================
class _SmsSettingCard extends ConsumerWidget {
  const _SmsSettingCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabledAsync = ref.watch(smsAutoBookkeepingEnabledProvider);
    final enabled = enabledAsync.value ?? true;
    final loading = enabledAsync.isLoading;

    return _SectionCard(
      title: '设置',
      children: [
        _SettingTile(
          icon: Icons.sms_outlined,
          title: '短信自动记账',
          subtitle: '自动识别银行/支付短信生成账单（仅 Android）',
          trailing: Switch.adaptive(
            value: enabled,
            activeThumbColor: AppColors.primaryDark,
            onChanged: loading
                ? null
                : (v) {
                    ref
                        .read(smsAutoBookkeepingEnabledProvider.notifier)
                        .setEnabled(v);
                    ScaffoldMessenger.of(context).clearSnackBars();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        duration: const Duration(milliseconds: 1500),
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: AppColors.textPrimary,
                        content: Text(v ? '已开启短信自动记账' : '已关闭短信自动记账'),
                      ),
                    );
                  },
          ),
        ),
      ],
    );
  }
}

// ==========================================================================
// 小贴士卡片
// ==========================================================================
class _TipsCard extends StatelessWidget {
  const _TipsCard();

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: '小贴士',
      children: const [
        _TipRow(text: '长按账单可以快速删除或修改'),
        _TipRow(text: '在「发现」页可以设置月度 / 年度预算'),
        _TipRow(text: '点击图表 Tab 可查看支出与收入趋势'),
        _TipRow(text: '快捷区「账单」可查看每月/每年汇总账单'),
      ],
    );
  }
}

class _TipRow extends StatelessWidget {
  const _TipRow({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6, right: 10),
            width: 5,
            height: 5,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primaryDark,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================================================
// 底部应用署名
// ==========================================================================
class _AppFooter extends StatelessWidget {
  const _AppFooter();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          const Text(
            'bunny记账',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '让记账更简单 · v1.0.0',
            style: TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary.withAlpha(160),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================================================
// 通用：区块卡片（标题 + 内容）
// ==========================================================================
class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: Material(
        elevation: 0.4,
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              const Divider(height: 1, color: Color(0xFFEEEEEE)),
              const SizedBox(height: 6),
              ...children,
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================================================
// 通用：单行可点击导航项（图标 + 标题 + 副标题 + 右侧 chevron）
// ==========================================================================
class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.leading,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final Widget leading;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: leading,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              size: 22,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================================================
// 通用：单行设置项（图标 + 标题 + 副标题 + 右侧控件）
// ==========================================================================
class _SettingTile extends StatelessWidget {
  const _SettingTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 20, color: AppColors.primaryDark),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          trailing,
        ],
      ),
    );
  }
}

// ==========================================================================
// 数据导入卡片
// ==========================================================================
class _ImportCard extends ConsumerWidget {
  const _ImportCard();

  Future<void> _pickAndImport(BuildContext context, WidgetRef ref) async {
    try {
      // 1. 选择文件
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      final jsonString = utf8.decode(file.bytes!);

      // 2. 解析预览
      final service = ImportService();
      final preview = service.previewFromJson(jsonString);

      if (!context.mounted) return;

      // 3. 显示预览确认对话框
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('导入预览'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _previewRow('数据来源', preview.source),
              _previewRow('导出时间', preview.exportedAt),
              const Divider(height: 16),
              _previewRow('账单记录', '${preview.recordCount} 条'),
              _previewRow('支出分类', '${preview.expenseCategories} 个'),
              _previewRow('收入分类', '${preview.incomeCategories} 个'),
              const SizedBox(height: 12),
              const Text(
                '⚠️ 导入将跳过已存在的重复记录。',
                style: TextStyle(fontSize: 12, color: Colors.orange),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('确认导入'),
            ),
          ],
        ),
      );

      if (confirmed != true || !context.mounted) return;

      // 4. 显示导入进度
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      // 5. 执行导入
      final importResult = await service.importFromJson(jsonString);

      if (!context.mounted) return;

      // 关闭进度对话框
      Navigator.of(context).pop();

      // 刷新所有数据 Provider，使首页/统计等页面即时显示新数据
      ref.invalidate(billListProvider);
      ref.invalidate(categoryListProvider);

      // 6. 显示导入结果
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('导入完成'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _previewRow('总记录数', '${importResult.totalRecords}'),
              _previewRow('成功导入', '${importResult.insertedBills} 条'),
              if (importResult.skippedBills > 0)
                _previewRow('跳过重复', '${importResult.skippedBills} 条'),
              if (importResult.importedCategories > 0)
                _previewRow('新增分类', '${importResult.importedCategories} 个'),
            ],
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('完成'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      // 确保进度对话框关闭
      Navigator.of(context).maybePop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('导入失败: $e'), backgroundColor: Colors.red),
      );
    }
  }

  static Widget _previewRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 70,
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _SectionCard(
      title: '数据',
      children: [
        _NavTile(
          leading: const Icon(
            Icons.file_download_outlined,
            size: 22,
            color: AppColors.primaryDark,
          ),
          title: '数据导入',
          subtitle: '从 myapp 导出的 JSON 文件导入记账数据',
          onTap: () => _pickAndImport(context, ref),
        ),
      ],
    );
  }
}
