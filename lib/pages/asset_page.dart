import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';

import '../models/asset_account.dart';
import '../providers/asset_provider.dart';
import '../theme/app_theme.dart';
import '../utils/asset_month.dart';
import '../utils/format.dart';

class AssetPage extends ConsumerStatefulWidget {
  const AssetPage({super.key});

  @visibleForTesting
  static void showMessageForTest(
    ScaffoldMessengerState? messenger,
    String message, {
    bool isError = false,
  }) {
    if (messenger == null) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: isError ? null : AppColors.primaryDark,
        ),
      );
  }

  @override
  ConsumerState<AssetPage> createState() => _AssetPageState();
}

class _AssetPageState extends ConsumerState<AssetPage> {
  ScaffoldMessengerState? get _messenger =>
      context.findRootAncestorStateOfType<ScaffoldMessengerState>();

  @override
  Widget build(BuildContext context) {
    final dashboardAsync = ref.watch(assetDashboardProvider);
    final selectedMonth = ref.watch(selectedAssetMonthProvider);

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      body: SafeArea(
        bottom: false,
        child: dashboardAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text('加载失败: $error')),
          data: (data) {
            final totalAssets = data.selectedMonthDetails.fold<double>(
              0,
              (sum, item) => sum + item.snapshot.balance,
            );
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 120),
              children: [
                _TopBar(selectedMonth: selectedMonth),
                const SizedBox(height: 12),
                _HeroCard(
                  totalAssets: totalAssets,
                  selectedMonth: selectedMonth,
                  accountCount: data.assets.length,
                  onAddAsset: _handleAddAsset,
                  onAddSnapshot:
                      data.assets.isEmpty ? null : () => _handleAddSnapshot(data),
                ),
                const SizedBox(height: 16),
                _TypeSummaryCard(summaries: data.selectedMonthTypeSummaries),
                const SizedBox(height: 16),
                _ChartCard(
                  points: data.monthlyPoints,
                  selectedMonth: selectedMonth,
                  onSelectMonth: (yearMonth) {
                    ref.read(selectedAssetMonthProvider.notifier).set(yearMonth);
                  },
                ),
                const SizedBox(height: 16),
                _DetailCard(
                  selectedMonth: selectedMonth,
                  details: data.selectedMonthDetails,
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _handleAddAsset() async {
    final draft = await _showAddAssetSheet();
    if (!mounted || draft == null) return;

    if (draft.name.isEmpty) {
      _showMessage('请输入资产名称', isError: true);
      return;
    }

    try {
      await ref.read(assetDashboardProvider.notifier).addAsset(
            type: draft.type,
            name: draft.name,
          );
      _showMessage('资产已保存');
    } on DatabaseException catch (error) {
      final message = error.isUniqueConstraintError()
          ? '同类型资产名称已存在，请换一个名称'
          : '保存资产失败，请稍后再试';
      _showMessage(message, isError: true);
    } catch (_) {
      _showMessage('保存资产失败，请稍后再试', isError: true);
    }
  }

  Future<void> _handleAddSnapshot(AssetDashboardData data) async {
    final draft = await _showAddSnapshotSheet(data);
    if (!mounted || draft == null) return;

    if (draft.yearMonth == null) {
      _showMessage('年月格式应为 YYYY-MM', isError: true);
      return;
    }
    if (draft.balance == null) {
      _showMessage('请输入正确的余额', isError: true);
      return;
    }

    try {
      await ref.read(assetDashboardProvider.notifier).saveSnapshot(
            assetId: draft.assetId,
            yearMonth: draft.yearMonth!,
            balance: draft.balance!,
            note: draft.note,
          );
      _showMessage('余额已记录');
    } catch (_) {
      _showMessage('记录余额失败，请稍后再试', isError: true);
    }
  }

  Future<_AssetDraft?> _showAddAssetSheet() async {
    return showModalBottomSheet<_AssetDraft>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _AddAssetSheet(),
    );
  }

  Future<_SnapshotDraft?> _showAddSnapshotSheet(AssetDashboardData data) async {
    return showModalBottomSheet<_SnapshotDraft>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _AddSnapshotSheet(
        assets: data.assets,
        initialMonth: ref.read(selectedAssetMonthProvider),
      ),
    );
  }

  void _showMessage(String message, {bool isError = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      AssetPage.showMessageForTest(
        _messenger,
        message,
        isError: isError,
      );
    });
  }
}

class _AssetDraft {
  const _AssetDraft.asset({
    required this.type,
    required this.name,
  });

  final String type;
  final String name;
}

class _SnapshotDraft {
  const _SnapshotDraft({
    required this.assetId,
    required this.yearMonth,
    required this.balance,
    required this.note,
  });

  final String assetId;
  final String? yearMonth;
  final double? balance;
  final String note;
}

class _BottomSheetScaffold extends StatelessWidget {
  const _BottomSheetScaffold({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: child,
        ),
      ),
    );
  }
}

class _AddAssetSheet extends StatefulWidget {
  const _AddAssetSheet();

  @override
  State<_AddAssetSheet> createState() => _AddAssetSheetState();
}

class _AddAssetSheetState extends State<_AddAssetSheet> {
  late final TextEditingController _nameCtrl;
  String _selectedType = 'bank';

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _BottomSheetScaffold(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '新增资产',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _selectedType,
            decoration: const InputDecoration(labelText: '资产类型'),
            items: const [
              DropdownMenuItem(value: 'bank', child: Text('银行卡')),
              DropdownMenuItem(value: 'alipay', child: Text('支付宝')),
              DropdownMenuItem(value: 'wechat', child: Text('微信')),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() => _selectedType = value);
              }
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _nameCtrl,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(labelText: '资产名称'),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                FocusManager.instance.primaryFocus?.unfocus();
                Navigator.of(context).pop(
                  _AssetDraft.asset(
                    type: _selectedType,
                    name: _nameCtrl.text.trim(),
                  ),
                );
              },
              child: const Text('保存'),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddSnapshotSheet extends StatefulWidget {
  const _AddSnapshotSheet({
    required this.assets,
    required this.initialMonth,
  });

  final List<AssetAccount> assets;
  final String initialMonth;

  @override
  State<_AddSnapshotSheet> createState() => _AddSnapshotSheetState();
}

class _AddSnapshotSheetState extends State<_AddSnapshotSheet> {
  late final TextEditingController _amountCtrl;
  late final TextEditingController _noteCtrl;
  late final TextEditingController _monthCtrl;
  late String _selectedAssetId;

  @override
  void initState() {
    super.initState();
    _amountCtrl = TextEditingController();
    _noteCtrl = TextEditingController();
    _monthCtrl = TextEditingController(text: widget.initialMonth);
    _selectedAssetId = widget.assets.first.id;
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    _monthCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _BottomSheetScaffold(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '记录月度资产',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _selectedAssetId,
            decoration: const InputDecoration(labelText: '资产账户'),
            items: [
              for (final asset in widget.assets)
                DropdownMenuItem(
                  value: asset.id,
                  child: Text(asset.name),
                ),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() => _selectedAssetId = value);
              }
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _monthCtrl,
            decoration: const InputDecoration(
              labelText: '年月',
              hintText: '2026-05',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _amountCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: '余额'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _noteCtrl,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(labelText: '备注'),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                FocusManager.instance.primaryFocus?.unfocus();
                Navigator.of(context).pop(
                  _SnapshotDraft(
                    assetId: _selectedAssetId,
                    yearMonth: normalizeAssetYearMonth(_monthCtrl.text),
                    balance: double.tryParse(_amountCtrl.text.trim()),
                    note: _noteCtrl.text.trim(),
                  ),
                );
              },
              child: const Text('保存'),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.selectedMonth});

  final String selectedMonth;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          style: IconButton.styleFrom(
            backgroundColor: AppColors.surface,
            foregroundColor: AppColors.textPrimary,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '资产',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              Text(
                '$selectedMonth 月度总览',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.totalAssets,
    required this.selectedMonth,
    required this.accountCount,
    required this.onAddAsset,
    required this.onAddSnapshot,
  });

  final double totalAssets;
  final String selectedMonth;
  final int accountCount;
  final VoidCallback onAddAsset;
  final VoidCallback? onAddSnapshot;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [Color(0xFFE86F51), Color(0xFFF19C7A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x2AD1674A),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '$selectedMonth 总资产',
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.white70,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                '$accountCount 个账户',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.white70,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          buildAmountText(
            value: totalAssets,
            integerStyle: const TextStyle(
              fontSize: 30,
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
            decimalStyle: const TextStyle(
              fontSize: 18,
              color: Colors.white70,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onAddAsset,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white38),
                  ),
                  child: const Text('新增资产'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: onAddSnapshot,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primaryDark,
                  ),
                  child: const Text('记录余额'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TypeSummaryCard extends StatelessWidget {
  const _TypeSummaryCard({required this.summaries});

  final List<AssetTypeSummary> summaries;

  @override
  Widget build(BuildContext context) {
    if (summaries.isEmpty) {
      return const _EmptyCard(
        title: '账户类型',
        message: '先新增银行卡、支付宝或微信账户，这里会按类型汇总展示。',
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.surfaceStrong),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '账户类型汇总',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 14),
          for (final summary in summaries)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _assetShortLabel(summary.type),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _assetTypeName(summary.type),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          '${summary.accountCount} 个账户',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  buildAmountText(
                    value: summary.totalBalance,
                    integerStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                    decimalStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({
    required this.points,
    required this.selectedMonth,
    required this.onSelectMonth,
  });

  final List<AssetMonthPoint> points;
  final String selectedMonth;
  final ValueChanged<String> onSelectMonth;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return const _EmptyCard(
        title: '资产趋势',
        message: '先为某个月记录一笔资产余额，折线图会自动生成。',
      );
    }

    var maxY = 0.0;
    for (final point in points) {
      if (point.totalBalance > maxY) maxY = point.totalBalance;
    }
    final spots = <FlSpot>[
      for (var i = 0; i < points.length; i++)
        FlSpot(i.toDouble(), points[i].totalBalance),
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.surfaceStrong),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '按年月资产走势',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 220,
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: (points.length - 1).toDouble(),
                minY: 0,
                maxY: maxY <= 0 ? 100 : maxY * 1.15,
                lineTouchData: LineTouchData(
                  handleBuiltInTouches: true,
                  touchCallback: (event, response) {
                    final lineSpots = response?.lineBarSpots;
                    if (lineSpots != null && lineSpots.isNotEmpty) {
                      onSelectMonth(points[lineSpots.first.x.toInt()].yearMonth);
                    }
                  },
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxY <= 0 ? 25 : maxY / 4,
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 26,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= points.length) {
                          return const SizedBox.shrink();
                        }
                        final label = assetMonthShortLabel(points[index].yearMonth);
                        final selected = points[index].yearMonth == selectedMonth;
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            label,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight:
                                  selected ? FontWeight.w700 : FontWeight.w500,
                              color: selected
                                  ? AppColors.accent
                                  : AppColors.textSecondary,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    barWidth: 3,
                    color: AppColors.accent,
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.accentSoft,
                    ),
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        final active = points[index].yearMonth == selectedMonth;
                        return FlDotCirclePainter(
                          radius: active ? 5 : 3.5,
                          color: active ? AppColors.accent : Colors.white,
                          strokeWidth: 2,
                          strokeColor: AppColors.accent,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailCard extends StatelessWidget {
  const _DetailCard({
    required this.selectedMonth,
    required this.details,
  });

  final String selectedMonth;
  final List<AssetSnapshotDetail> details;

  @override
  Widget build(BuildContext context) {
    if (details.isEmpty) {
      return _EmptyCard(
        title: '$selectedMonth 账户明细',
        message: '点击折线图中的月份后，这里会显示该月按账户类型分组的资产明细。',
      );
    }

    final grouped = <String, List<AssetSnapshotDetail>>{};
    for (final detail in details) {
      grouped.putIfAbsent(detail.asset.type, () => []).add(detail);
    }
    final entries = grouped.entries.toList()
      ..sort((a, b) => _assetTypeSort(a.key).compareTo(_assetTypeSort(b.key)));

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.surfaceStrong),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$selectedMonth 账户明细',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          for (final entry in entries) ...[
            _TypeSectionHeader(
              type: entry.key,
              total: entry.value.fold<double>(
                0,
                (sum, item) => sum + item.snapshot.balance,
              ),
            ),
            const SizedBox(height: 8),
            for (final detail in entry.value)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: AppColors.accentSoft,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _assetShortLabel(detail.asset.type),
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.accent,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            detail.asset.name,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (detail.snapshot.note.isNotEmpty)
                            Text(
                              detail.snapshot.note,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                        ],
                      ),
                    ),
                    buildAmountText(
                      value: detail.snapshot.balance,
                      integerStyle: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                      decimalStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _TypeSectionHeader extends StatelessWidget {
  const _TypeSectionHeader({
    required this.type,
    required this.total,
  });

  final String type;
  final double total;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.backgroundGray,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Text(
            _assetTypeName(type),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const Spacer(),
          buildAmountText(
            value: total,
            integerStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
            decimalStyle: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({
    required this.title,
    required this.message,
  });

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.surfaceStrong),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

String _assetTypeName(String type) {
  switch (type) {
    case 'alipay':
      return '支付宝';
    case 'wechat':
      return '微信';
    default:
      return '银行卡';
  }
}

String _assetShortLabel(String type) {
  switch (type) {
    case 'alipay':
      return '支付';
    case 'wechat':
      return '微信';
    default:
      return '银行';
  }
}

int _assetTypeSort(String type) {
  switch (type) {
    case 'bank':
      return 0;
    case 'alipay':
      return 1;
    case 'wechat':
      return 2;
    default:
      return 99;
  }
}
