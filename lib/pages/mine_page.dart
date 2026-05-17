import 'dart:convert';
import 'dart:io' show File;

import 'package:enough_convert/enough_convert.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';

import '../data/account_data.dart';
import '../providers/bill_provider.dart';
import '../providers/category_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/user_stats_provider.dart';
import '../services/import_service.dart';
import '../services/export_service.dart';
import '../providers/backup_settings_provider.dart';
import '../services/backup_settings.dart';
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
          _SettingsCard(),
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
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFE86F51), Color(0xFFF1A987)],
            ),
          ),
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
      elevation: 0,
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(20),
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
// 设置入口卡片
// ==========================================================================
class _SettingsCard extends StatelessWidget {
  const _SettingsCard();

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: '设置',
      children: [
        _SettingTile(
          icon: Icons.settings_outlined,
          title: '设置',
          subtitle: '短信自动记账、隐藏金额等',
          trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const _SettingsPage()),
            );
          },
        ),
      ],
    );
  }
}

// ==========================================================================
// 设置二级页面
// ==========================================================================
class _SettingsPage extends ConsumerWidget {
  const _SettingsPage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabledAsync = ref.watch(smsAutoBookkeepingEnabledProvider);
    final enabled = enabledAsync.value ?? true;
    final loading = enabledAsync.isLoading;
    final amountHidden = ref.watch(amountHiddenProvider).value ?? false;
    final backupAsync = ref.watch(backupSettingsProvider);
    final backupSettings = backupAsync.value ?? const BackupSettings();

    return Scaffold(
      backgroundColor: AppColors.backgroundGray,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        title: const Text('设置'),
        elevation: 0,
      ),
      body: ListView(
        children: [
          const SizedBox(height: 12),
          _SectionCard(
            title: '记账设置',
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
              const Divider(height: 1),
              _SettingTile(
                icon: Icons.visibility_off_outlined,
                title: '隐藏金额',
                subtitle: '首页收入支出显示为 ****',
                trailing: Switch.adaptive(
                  value: amountHidden,
                  activeThumbColor: AppColors.primaryDark,
                  onChanged: (v) {
                    ref.read(amountHiddenProvider.notifier).toggle();
                    ScaffoldMessenger.of(context).clearSnackBars();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        duration: const Duration(milliseconds: 1500),
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: AppColors.textPrimary,
                        content: Text(v ? '已隐藏金额' : '已显示金额'),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _SectionCard(
            title: '云备份',
            children: [
              _SettingTile(
                icon: Icons.cloud_upload_outlined,
                title: '自动备份',
                subtitle: backupSettings.enabled
                    ? '每天凌晨3点自动备份到腾讯云'
                    : '已关闭',
                trailing: Switch(
                  value: backupSettings.enabled,
                  onChanged: (v) =>
                      ref.read(backupSettingsProvider.notifier).toggleEnabled(v),
                  activeColor: AppColors.primaryDark,
                ),
              ),
              const Divider(height: 1),
              _SettingTile(
                icon: Icons.settings_outlined,
                title: '备份设置',
                subtitle: backupSettings.isConfigured
                    ? 'SecretID: ${backupSettings.secretId?.substring(0, 8)}...'
                    : '未配置',
                trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
                onTap: () => _showBackupConfigSheet(context, ref),
              ),
              const Divider(height: 1),
              _SettingTile(
                icon: Icons.backup_outlined,
                title: '立即备份',
                subtitle: '手动触发一次备份',
                trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
                onTap: () => _runManualBackup(context, ref),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showBackupConfigSheet(BuildContext context, WidgetRef ref) {
    final settings = ref.read(backupSettingsProvider).value ?? const BackupSettings();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _BackupConfigSheet(initialSettings: settings),
    );
  }

  Future<void> _runManualBackup(BuildContext context, WidgetRef ref) async {
    final service = ref.read(manualBackupProvider);
    final settings = ref.read(backupSettingsProvider).value ?? const BackupSettings();

    if (!settings.isConfigured) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('请先配置云存储参数'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final result = await service.run();

    if (!context.mounted) return;
    Navigator.of(context).maybePop();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.success
            ? '备份成功: ${result.fileName}'
            : '备份失败: ${result.error}'),
        backgroundColor: result.success ? Colors.green : Colors.red,
      ),
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
        elevation: 0,
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
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
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
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
      ),
    );
  }
}

// ==========================================================================
// 云备份卡片
// ==========================================================================
class _BackupCard extends ConsumerWidget {
  const _BackupCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(backupSettingsProvider);
    final settingsNotifier = ref.read(backupSettingsProvider.notifier);
    final settings = settingsAsync.value ?? const BackupSettings();

    return _SectionCard(
      title: '云备份',
      children: [
        _SettingTile(
          icon: Icons.cloud_upload_outlined,
          title: '自动备份',
          subtitle: settings.enabled
              ? '每天凌晨3点自动备份到腾讯云'
              : '已关闭',
          trailing: Switch(
            value: settings.enabled,
            onChanged: (v) => settingsNotifier.toggleEnabled(v),
            activeColor: AppColors.primaryDark,
          ),
        ),
        const Divider(height: 1, indent: 56),
        _NavTile(
          leading: const Icon(
            Icons.settings_outlined,
            size: 22,
            color: AppColors.primaryDark,
          ),
          title: '备份设置',
          subtitle: settings.isConfigured
              ? 'SecretID: ${settings.secretId?.substring(0, 8)}...'
              : '未配置',
          onTap: () => _showBackupConfigSheet(context, ref),
        ),
        const Divider(height: 1, indent: 56),
        _NavTile(
          leading: const Icon(
            Icons.backup_outlined,
            size: 22,
            color: AppColors.primaryDark,
          ),
          title: '立即备份',
          subtitle: '手动触发一次备份',
          onTap: () => _runManualBackup(context, ref),
        ),
      ],
    );
  }

  void _showBackupConfigSheet(BuildContext context, WidgetRef ref) {
    final settings = ref.read(backupSettingsProvider).value ?? const BackupSettings();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _BackupConfigSheet(initialSettings: settings),
    );
  }

  Future<void> _runManualBackup(BuildContext context, WidgetRef ref) async {
    final service = ref.read(manualBackupProvider);
    final settings = ref.read(backupSettingsProvider).value ?? const BackupSettings();

    if (!settings.isConfigured) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('请先配置云存储参数'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final result = await service.run();

    if (!context.mounted) return;
    Navigator.of(context).maybePop();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.success
            ? '备份成功: ${result.fileName}'
            : '备份失败: ${result.error}'),
        backgroundColor: result.success ? Colors.green : Colors.red,
      ),
    );
  }
}

class _BackupConfigSheet extends ConsumerStatefulWidget {
  final dynamic initialSettings;

  const _BackupConfigSheet({required this.initialSettings});

  @override
  ConsumerState<_BackupConfigSheet> createState() => _BackupConfigSheetState();
}

class _BackupConfigSheetState extends ConsumerState<_BackupConfigSheet> {
  late TextEditingController _secretIdController;
  late TextEditingController _secretKeyController;
  late TextEditingController _bucketController;
  late TextEditingController _regionController;
  late TextEditingController _appIdController;
  late String _frequency;

  @override
  void initState() {
    super.initState();
    final s = widget.initialSettings;
    _secretIdController = TextEditingController(text: s.secretId ?? '');
    _secretKeyController = TextEditingController(text: s.secretKey ?? '');
    _bucketController = TextEditingController(text: s.bucket ?? '');
    _regionController = TextEditingController(text: s.region ?? '');
    _appIdController = TextEditingController(text: s.appId ?? '');
    _frequency = s.frequency;
  }

  @override
  void dispose() {
    _secretIdController.dispose();
    _secretKeyController.dispose();
    _bucketController.dispose();
    _regionController.dispose();
    _appIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            '腾讯云 COS 配置',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _secretIdController,
            decoration: const InputDecoration(
              labelText: 'SecretId',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _secretKeyController,
            decoration: const InputDecoration(
              labelText: 'SecretKey',
              border: OutlineInputBorder(),
            ),
            obscureText: true,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _bucketController,
            decoration: const InputDecoration(
              labelText: 'Bucket',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _regionController,
            decoration: const InputDecoration(
              labelText: 'Region (如 ap-guangzhou)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _appIdController,
            decoration: const InputDecoration(
              labelText: 'AppId',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          const Text('备份频率', style: TextStyle(fontSize: 14)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              _freqChip('每天', 'daily'),
              _freqChip('每周', 'weekly'),
              _freqChip('每月', 'monthly'),
            ],
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _save,
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  Widget _freqChip(String label, String value) {
    return ChoiceChip(
      label: Text(label),
      selected: _frequency == value,
      onSelected: (_) => setState(() => _frequency = value),
    );
  }

  Future<void> _save() async {
    await ref.read(backupSettingsProvider.notifier).updateCosConfig(
          secretId: _secretIdController.text.trim(),
          secretKey: _secretKeyController.text.trim(),
          bucket: _bucketController.text.trim(),
          region: _regionController.text.trim(),
          appId: _appIdController.text.trim(),
        );
    await ref.read(backupSettingsProvider.notifier).updateFrequency(_frequency);
    if (mounted) Navigator.of(context).maybePop();
  }
}

// ==========================================================================
// 数据导入卡片
// ==========================================================================
class _ImportCard extends ConsumerWidget {
  const _ImportCard();

  Future<void> _pickAndImport(BuildContext context, WidgetRef ref) async {
    try {
      // 1. 选择文件（支持 JSON 和 CSV）
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json', 'csv'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      debugPrint('Selected file: name=${file.name}, extension=${file.extension}');
      final bytes = await _readPickedFileBytes(file);
      final content = _decodeImportContent(bytes);
      final extension = file.extension?.toLowerCase() ?? '';
      final service = ImportService();

      // 2. 解析预览
      ImportPreview? jsonPreview;
      CsvImportPreview? csvPreview;
      String? previewLabel;
      String? recordCountLabel;

      if (extension == 'csv') {
        try {
          csvPreview = service.previewFromCsv(content);
          previewLabel = 'CSV 导入预览';
          recordCountLabel = '${csvPreview.recordCount} 条记录';
        } catch (e) {
          debugPrint('CSV preview error: $e');
          previewLabel = 'CSV 解析失败';
          recordCountLabel = '文件格式错误';
        }
      } else {
        jsonPreview = service.previewFromJson(content);
        previewLabel = 'JSON 导入预览';
        recordCountLabel = '${jsonPreview.recordCount} 条记录';
      }

      if (!context.mounted) return;

      // 3. 显示预览确认对话框
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(previewLabel ?? '导入预览'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (jsonPreview != null) ...[
                _previewRow('数据来源', jsonPreview.source),
                _previewRow('导出时间', jsonPreview.exportedAt),
                const Divider(height: 16),
                _previewRow('账单记录', '${jsonPreview.recordCount} 条'),
                _previewRow('支出分类', '${jsonPreview.expenseCategories} 个'),
                _previewRow('收入分类', '${jsonPreview.incomeCategories} 个'),
              ] else if (csvPreview != null) ...[
                _previewRow('CSV 预览', csvPreview.headers.join(', ')),
                const Divider(height: 16),
                _previewRow('账单记录', recordCountLabel ?? ''),
                _previewRow('支出记录', '${csvPreview.expenseCount} 条'),
                _previewRow('收入记录', '${csvPreview.incomeCount} 条'),
              ],
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
      ImportResult importResult;
      if (extension == 'csv') {
        try {
          importResult = await service.importFromCsv(content);
        } catch (e) {
          debugPrint('CSV import error: $e');
          importResult = const ImportResult(
            totalRecords: 0,
            insertedBills: 0,
            skippedBills: 0,
            importedCategories: 0,
          );
        }
      } else {
        importResult = await service.importFromJson(content);
      }

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

  static Future<List<int>> _readPickedFileBytes(PlatformFile file) async {
    final inMemoryBytes = file.bytes;
    if (inMemoryBytes != null && inMemoryBytes.isNotEmpty) {
      return inMemoryBytes;
    }

    final path = file.path;
    if (path != null && path.isNotEmpty) {
      return File(path).readAsBytes();
    }

    throw const FormatException('无法读取所选文件内容');
  }

  static String _decodeImportContent(List<int> bytes) {
    try {
      return utf8.decode(bytes);
    } on FormatException {
      try {
        return gbk.decode(bytes);
      } catch (_) {
        return latin1.decode(bytes);
      }
    }
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
          subtitle: '从 myapp 导出的 JSON/CSV 文件导入记账数据',
          onTap: () => _pickAndImport(context, ref),
        ),
        _NavTile(
          leading: const Icon(
            Icons.file_upload_outlined,
            size: 22,
            color: AppColors.primaryDark,
          ),
          title: '数据导出',
          subtitle: '导出为 JSON/CSV 文件',
          onTap: () => _showExportSheet(context, ref),
        ),
      ],
    );
  }

  void _showExportSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const _ExportSheet(),
    );
  }
}

// ==========================================================================
// 数据导出
// ==========================================================================
class _ExportSheet extends ConsumerWidget {
  const _ExportSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            '数据导出',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          ListTile(
            leading: const Icon(Icons.code, color: AppColors.primaryDark),
            title: const Text('导出为 JSON'),
            subtitle: const Text('和导入格式一致，可用于数据迁移'),
            onTap: () => _exportToDisk(context, 'json'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.table_chart, color: AppColors.primaryDark),
            title: const Text('导出为 CSV'),
            subtitle: const Text('通用表格格式，方便其他软件打开'),
            onTap: () => _exportToDisk(context, 'csv'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportToDisk(BuildContext context, String format) async {
    Navigator.of(context).maybePop();
    final service = ExportService();
    try {
      final exported = await service.exportToFile(format);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('已导出到 ${exported.path}'),
          duration: const Duration(seconds: 5),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('导出失败: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _export(BuildContext context, String format) async {
    Navigator.of(context).maybePop();
    final service = ExportService();
    try {
      final content = format == 'json'
          ? await service.exportToJsonString()
          : await service.exportToCsvString();
      final fileName = 'bunny_backup_${DateTime.now().millisecondsSinceEpoch}.$format';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('已生成 $fileName，大小 ${content.length} 字节')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('导出失败: $e'), backgroundColor: Colors.red),
      );
    }
  }
}
