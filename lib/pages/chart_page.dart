import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/account_data.dart';
import '../db/database_helper.dart';
import '../models/bill_item.dart';
import '../providers/chart_provider.dart';
import '../providers/navigation_provider.dart';
import '../theme/app_theme.dart';
import '../utils/icon_helper.dart';

class ChartPage extends ConsumerStatefulWidget {
  const ChartPage({super.key});
  @override
  ConsumerState<ChartPage> createState() => _ChartPageState();
}

class _ChartPageState extends ConsumerState<ChartPage> {
  List<BillItem> _bills = [];
  Map<String, double> _prevPeriodByCategory = {};
  final Map<ChartPeriod, String?> _expandedCategoryByPeriod = {
    ChartPeriod.week: null,
    ChartPeriod.month: null,
    ChartPeriod.year: null,
  };
  bool _loading = true;
  _CategoryDrilldownSort _categoryDrilldownSort = _CategoryDrilldownSort.amount;

  List<_CategorySlice> _categorySlicesForBill(BillItem bill) {
    if (bill.type == 'expense' && bill.splits.isNotEmpty) {
      return [
        for (final split in bill.splits)
          _CategorySlice(
            category: split.category,
            iconId: split.iconId,
            amount: split.amount,
          ),
      ];
    }
    return [
      _CategorySlice(
        category: bill.category,
        iconId: bill.iconId,
        amount: bill.amount,
      ),
    ];
  }

  Set<String> _categoriesOfBills(List<BillItem> bills) {
    final result = <String>{};
    for (final bill in bills) {
      for (final slice in _categorySlicesForBill(bill)) {
        result.add(slice.category);
      }
    }
    return result;
  }

  /// 计算让 idx 居中的 scroll offset，clamp 到实际 maxScrollExtent
  double _calcPickerOffset(
    int idx,
    int itemCount,
    double itemW,
    double screenW,
  ) {
    final maxScroll = (itemCount * itemW - screenW).clamp(0.0, double.infinity);
    return (idx * itemW - screenW / 2 + itemW / 2).clamp(0.0, maxScroll);
  }

  ScrollController _weekScrollCtrl = ScrollController();
  ScrollController _monthScrollCtrl = ScrollController();
  ScrollController _yearScrollCtrl = ScrollController();
  bool _pickerScrolling = false;

  @override
  void initState() {
    super.initState();
    // 初始化各controller的initialScrollOffset，让第一帧就在正确位置
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initScrollControllers();
      Future.microtask(_loadData);
    });
  }

  /// 重置所有时间选择器到当前日期
  void _resetToNow() {
    ref.invalidate(selectedWeekProvider);
    ref.invalidate(selectedChartMonthProvider);
    ref.invalidate(selectedYearProvider);
    _initScrollControllers();
    _loadData();
  }

  
  void _initScrollControllers() {
    final screenW = MediaQuery.of(context).size.width;
    final double itemW = screenW / 5;

    // 周
    final currentWeekLabel = weekInfoOf(DateTime.now()).label;
    final weeks = generateWeekList();
    final wIdx = weeks.indexWhere((w) => w.label == currentWeekLabel);
    debugPrint(
      '[ChartInit] week: label=$currentWeekLabel idx=$wIdx total=${weeks.length}',
    );
    if (wIdx >= 0) {
      final offset = _calcPickerOffset(wIdx, weeks.length, itemW, screenW);
      _weekScrollCtrl.dispose();
      _weekScrollCtrl = ScrollController(initialScrollOffset: offset);
    }

    // 月
    final now = DateTime.now();
    final currentMonth = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    final months = generateMonthList();
    final mIdx = months.indexOf(currentMonth);
    if (mIdx >= 0) {
      final offset = _calcPickerOffset(mIdx, months.length, itemW, screenW);
      _monthScrollCtrl.dispose();
      _monthScrollCtrl = ScrollController(initialScrollOffset: offset);
    }

    // 年
    final currentYear = '${now.year}';
    final years = generateYearList();
    final yIdx = years.indexOf(currentYear);
    if (yIdx >= 0) {
      final offset = _calcPickerOffset(yIdx, years.length, itemW, screenW);
      _yearScrollCtrl.dispose();
      _yearScrollCtrl = ScrollController(initialScrollOffset: offset);
    }
    setState(() {});
  }

  @override
  void dispose() {
    _weekScrollCtrl.dispose();
    _monthScrollCtrl.dispose();
    _yearScrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final showBlockingLoading = _bills.isEmpty;
    if (showBlockingLoading) {
      setState(() => _loading = true);
    }
    final period = ref.read(chartPeriodProvider);
    final type = ref.read(chartTypeProvider);
    final db = DatabaseHelper.instance;
    List<BillItem> bills = [];
    List<BillItem> prevBills = [];
    switch (period) {
      case ChartPeriod.week:
        final w = ref.read(selectedWeekProvider);
        final start =
            '${w.startDate.year}-${w.startDate.month.toString().padLeft(2, '0')}-${w.startDate.day.toString().padLeft(2, '0')}';
        final end =
            '${w.endDate.year}-${w.endDate.month.toString().padLeft(2, '0')}-${w.endDate.day.toString().padLeft(2, '0')}';
        bills = await db.getBillsByDateRange(start, end);
        // 上一周
        final prevStart = w.startDate.subtract(const Duration(days: 7));
        final prevEnd = w.endDate.subtract(const Duration(days: 7));
        final ps =
            '${prevStart.year}-${prevStart.month.toString().padLeft(2, '0')}-${prevStart.day.toString().padLeft(2, '0')}';
        final pe =
            '${prevEnd.year}-${prevEnd.month.toString().padLeft(2, '0')}-${prevEnd.day.toString().padLeft(2, '0')}';
        prevBills = await db.getBillsByDateRange(ps, pe);
      case ChartPeriod.month:
        final m = ref.read(selectedChartMonthProvider);
        bills = await db.getBillsByMonth(m);
        // 上一月
        final parts = m.split('-');
        final dt = DateTime(int.parse(parts[0]), int.parse(parts[1]) - 1, 1);
        final prevM = '${dt.year}-${dt.month.toString().padLeft(2, '0')}';
        prevBills = await db.getBillsByMonth(prevM);
      case ChartPeriod.year:
        final y = ref.read(selectedYearProvider);
        bills = await db.getBillsByYear(y);
        // 上一年
        final prevY = '${int.parse(y) - 1}';
        prevBills = await db.getBillsByYear(prevY);
    }
    // 按分类汇总上一周期数据
    final prevMap = <String, double>{};
    for (final b in prevBills.where((b) => b.type == type)) {
      for (final slice in _categorySlicesForBill(b)) {
        prevMap[slice.category] = (prevMap[slice.category] ?? 0) + slice.amount;
      }
    }
    if (mounted) {
      setState(() {
        _bills = bills;
        _prevPeriodByCategory = prevMap;
        final availableCategories = _categoriesOfBills(
          bills.where((bill) => bill.type == type).toList(),
        );
        final expandedCategory = _expandedCategoryByPeriod[period];
        if (expandedCategory != null &&
            !availableCategories.contains(expandedCategory)) {
          _expandedCategoryByPeriod[period] = null;
        }
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // 切入图表页时重置到当前日期
    ref.listen(navigationProvider, (prev, next) {
      if (next == 1 && prev != 1) _resetToNow();
    });
    ref.listen(chartPeriodProvider, (_, _) => _loadData());
    ref.listen(selectedWeekProvider, (_, _) => _loadData());
    ref.listen(selectedChartMonthProvider, (_, _) => _loadData());
    ref.listen(selectedYearProvider, (_, _) => _loadData());
    ref.listen(chartTypeProvider, (_, _) => setState(() {}));

    final type = ref.watch(chartTypeProvider);
    final period = ref.watch(chartPeriodProvider);
    final categoryDrilldown = ref.watch(chartDrilldownProvider);
    final filtered = _bills.where((b) => b.type == type).toList();
    final total = filtered.fold<double>(0, (s, b) => s + b.amount);

    // 用于动画切换的唯一key
    String periodKey;
    switch (period) {
      case ChartPeriod.week:
        periodKey = 'w_${ref.watch(selectedWeekProvider).label}';
      case ChartPeriod.month:
        periodKey = 'm_${ref.watch(selectedChartMonthProvider)}';
      case ChartPeriod.year:
        periodKey = 'y_${ref.watch(selectedYearProvider)}';
    }

    // 如果有分类跳转，显示分类详情页
    if (categoryDrilldown != null) {
      return Scaffold(
        backgroundColor: AppColors.surface,
        body: _buildCategoryDetailPage(
          type,
          period,
          filtered,
          total,
          categoryDrilldown,
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildHeader(type),
          _buildPeriodTabs(period),
          _buildPeriodSelector(period),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    switchInCurve: Curves.easeOut,
                    switchOutCurve: Curves.easeIn,
                    child: ListView(
                      key: ValueKey(periodKey + type),
                      padding: EdgeInsets.zero,
                      children: [
                        _buildSummaryAndChart(total, filtered, period),
                        _buildRankingList(filtered, total, type, period),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // ==================== 分类详情页（鲨鱼记账风格）====================
  Widget _buildCategoryDetailPage(
    String type,
    ChartPeriod period,
    List<BillItem> allFilteredBills,
    double total,
    String category,
  ) {
    final categoryEntries = <_CategoryBillEntry>[];
    for (final bill in allFilteredBills) {
      if (bill.splits.isNotEmpty) {
        for (final split in bill.splits) {
          if (split.category == category) {
            categoryEntries.add(_CategoryBillEntry(bill: bill, amount: split.amount));
          }
        }
        continue;
      }
      if (bill.category == category) {
        categoryEntries.add(_CategoryBillEntry(bill: bill, amount: bill.amount));
      }
    }

    final categoryBills = [for (final entry in categoryEntries) entry.bill];
    final sortedEntries = [...categoryEntries]..sort((a, b) {
      if (_categoryDrilldownSort == _CategoryDrilldownSort.amount) {
        final amountCompare = b.amount.compareTo(a.amount);
        if (amountCompare != 0) return amountCompare;
        final timeCompare = _compareBillDateDesc(b.bill, a.bill);
        if (timeCompare != 0) return timeCompare;
        return b.bill.id.compareTo(a.bill.id);
      }
      final sortCompare = _compareBillDateDesc(b.bill, a.bill);
      if (sortCompare != 0) return sortCompare;
      return b.bill.id.compareTo(a.bill.id);
    });

    return Column(
      children: [
        Container(
          color: AppColors.primary,
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 8,
            bottom: 12,
          ),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _categoryDrilldownSort = _CategoryDrilldownSort.amount;
                      });
                      ref.read(chartDrilldownProvider.notifier).close();
                    },
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 48),
                  ),
                  Expanded(
                    child: Text(
                      category,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ],
          ),
        ),
        _buildPeriodTabs(period),
        _buildPeriodSelector(period),
        Expanded(
          child: sortedEntries.isEmpty
              ? const Center(child: Text('暂无数据'))
              : Column(
                  children: [
                    // 折线图
                    _buildCategoryLineChart(categoryBills, period),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(0, 4, 0, 16),
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                            child: Row(
                              children: [
                                const Text(
                                  '支出排行榜',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Spacer(),
                                _buildDrilldownSortSegmented(),
                              ],
                            ),
                          ),
                          ..._buildDrilldownRankRows(
                            entries: sortedEntries,
                            categoryName: category,
                            categoryTotal: categoryEntries.fold<double>(
                              0,
                              (sum, entry) => sum + entry.amount,
                            ),
                          ),
                          const SizedBox(height: 80),
                        ],
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildDrilldownSortSegmented() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(18),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildDrilldownSortChip(
            label: '金额',
            selected: _categoryDrilldownSort == _CategoryDrilldownSort.amount,
            onTap: () => setState(() {
              _categoryDrilldownSort = _CategoryDrilldownSort.amount;
            }),
          ),
          _buildDrilldownSortChip(
            label: '时间',
            selected: _categoryDrilldownSort == _CategoryDrilldownSort.time,
            onTap: () => setState(() {
              _categoryDrilldownSort = _CategoryDrilldownSort.time;
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildDrilldownSortChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  int _compareBillDateDesc(BillItem left, BillItem right) {
    final leftTime = _billDateTimestamp(left);
    final rightTime = _billDateTimestamp(right);
    return leftTime.compareTo(rightTime);
  }

  int _billDateTimestamp(BillItem bill) {
    final date = DateTime.tryParse(bill.date);
    if (date != null) {
      return date.microsecondsSinceEpoch;
    }
    return 0;
  }

  int _calcDivisor(ChartPeriod period) {
    switch (period) {
      case ChartPeriod.week:
        return 7;
      case ChartPeriod.month:
        final parts = ref.read(selectedChartMonthProvider).split('-');
        return DateTime(int.parse(parts[0]), int.parse(parts[1]) + 1, 0).day;
      case ChartPeriod.year:
        return 12;
    }
  }

  Widget _buildBillTile(BillItem bill) {
    final icon = bill.iconId >= 0 && bill.iconId < iconJson.length
        ? iconJson[bill.iconId]
        : null;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          if (icon != null)
            Image.asset(iconPath(icon.iconL), width: 36, height: 36)
          else
            const Icon(Icons.receipt, size: 36, color: AppColors.textSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              bill.note.isNotEmpty ? bill.note : bill.category,
              style: const TextStyle(fontSize: 14),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            '-${bill.amount.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildDrilldownRankRows({
    required List<_CategoryBillEntry> entries,
    required String categoryName,
    required double categoryTotal,
  }) {
    final maxAmount = entries.isNotEmpty ? entries.first.amount : 1.0;
    return [
      for (var index = 0; index < entries.length; index++) ...[
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: _buildRankRow(
            iconBoxSize: 30,
            iconPadding: 3,
            titleFontSize: 12,
            percentageFontSize: 10,
            amountFontSize: 11.5,
            progressHeight: 4,
            icon: _buildDrilldownIcon(entries[index].bill.iconId),
            title: entries[index].note.trim().isEmpty
                ? categoryName
                : entries[index].note.trim(),
            percentageText:
                '${(categoryTotal > 0 ? entries[index].amount / categoryTotal * 100 : 0).toStringAsFixed(1)}%',
            amountText: _fmtAmount(entries[index].amount),
            ratio: maxAmount > 0 ? entries[index].amount / maxAmount : 0.0,
            thirdLineText: _billDateLabel(entries[index].bill.date),
          ),
        ),
        if (index != entries.length - 1)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Divider(
              height: 1,
              thickness: 0.4,
              color: Colors.black.withValues(alpha: 0.06),
            ),
          ),
      ],
    ];
  }

  Widget _buildDrilldownIcon(int iconId) {
    if (iconId >= 0 && iconId < iconJson.length) {
      return Image.asset(
        iconPath(iconJson[iconId].iconL),
        errorBuilder: (_, _, _) => const Icon(
          Icons.category_outlined,
          size: 16,
          color: Colors.black38,
        ),
      );
    }
    return const Icon(
      Icons.category_outlined,
      size: 16,
      color: Colors.black38,
    );
  }

  // ==================== 分类折线图 ====================
  Widget _buildCategoryLineChart(List<BillItem> bills, ChartPeriod period) {
    // 构建数据点
    final dataMap = <int, double>{};
    int xCount;
    String Function(int) labelFn;

    // 计算总金额和平均值
    final total = bills.fold<double>(0, (s, b) => s + b.amount);
    int divisor;
    switch (period) {
      case ChartPeriod.week:
        divisor = 7;
      case ChartPeriod.month:
        final parts = ref.read(selectedChartMonthProvider).split('-');
        divisor = DateTime(int.parse(parts[0]), int.parse(parts[1]) + 1, 0).day;
      case ChartPeriod.year:
        divisor = 12;
    }
    final avg = divisor > 0 ? total / divisor : 0.0;

    switch (period) {
      case ChartPeriod.week:
        xCount = 7;
        final w = ref.read(selectedWeekProvider);
        for (final b in bills) {
          final d = DateTime.tryParse(b.date);
          if (d == null) continue;
          final idx = d.difference(w.startDate).inDays;
          if (idx >= 0 && idx < 7) {
            dataMap[idx] = (dataMap[idx] ?? 0) + b.amount;
          }
        }
        labelFn = (i) {
          final d = w.startDate.add(Duration(days: i));
          return '${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
        };
      case ChartPeriod.month:
        final parts = ref.read(selectedChartMonthProvider).split('-');
        xCount = DateTime(int.parse(parts[0]), int.parse(parts[1]) + 1, 0).day;
        for (final b in bills) {
          final d = DateTime.tryParse(b.date);
          if (d == null) continue;
          dataMap[d.day - 1] = (dataMap[d.day - 1] ?? 0) + b.amount;
        }
        labelFn = (i) => '${i + 1}';
      case ChartPeriod.year:
        xCount = 12;
        for (final b in bills) {
          final d = DateTime.tryParse(b.date);
          if (d == null) continue;
          dataMap[d.month - 1] = (dataMap[d.month - 1] ?? 0) + b.amount;
        }
        labelFn = (i) => '${i + 1}月';
    }

    final spots = <FlSpot>[];
    double maxY = 0;
    for (int i = 0; i < xCount; i++) {
      final v = dataMap[i] ?? 0;
      spots.add(FlSpot(i.toDouble(), v));
      if (v > maxY) maxY = v;
    }
    final hasData = maxY > 0;
    final chartMaxY = hasData ? maxY * 1.15 : 100.0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 汇总标签
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '总支出：${total.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '平均：${avg.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.black54,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: 120,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 20,
                      interval: xCount <= 7 ? 1 : (xCount <= 12 ? 1 : 1),
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= xCount) return const SizedBox();
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            labelFn(idx),
                            style: const TextStyle(fontSize: 9, color: Colors.black38),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: (xCount - 1).toDouble(),
                minY: 0,
                maxY: chartMaxY,
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    curveSmoothness: 0.3,
                    color: AppColors.primary,
                    barWidth: 2,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: hasData,
                      getDotPainter: (spot, percent, barData, index) =>
                          FlDotCirclePainter(
                        radius: 3,
                        color: Colors.white,
                        strokeWidth: 1.5,
                        strokeColor: AppColors.primary,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: hasData,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.primary.withValues(alpha: 0.35),
                          AppColors.primary.withValues(alpha: 0.05),
                        ],
                      ),
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

  // ==================== 顶部标题 ====================
  Widget _buildHeader(String type) {
    final label = type == 'expense' ? '支出' : '收入';
    return Container(
      color: AppColors.primary,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 12,
        bottom: 10,
      ),
      child: Center(
        child: GestureDetector(
          onTap: () {
            ref
                .read(chartTypeProvider.notifier)
                .set(type == 'expense' ? 'income' : 'expense');
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(width: 22),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Icon(Icons.arrow_drop_down, size: 22),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== 周/月/年 Tab ====================
  Widget _buildPeriodTabs(ChartPeriod period) {
    const labels = {
      ChartPeriod.week: '周',
      ChartPeriod.month: '月',
      ChartPeriod.year: '年',
    };
    var tabRadius = BorderRadius.zero;
    if (period == ChartPeriod.week) {
      tabRadius = BorderRadius.only(
        topLeft: Radius.circular(4),
        bottomLeft: Radius.circular(4),
      );
    } else if (period == ChartPeriod.year) {
      tabRadius = BorderRadius.only(
        topRight: Radius.circular(4),
        bottomRight: Radius.circular(4),
      );
    }

    return Container(
      color: AppColors.primary,
      padding: const EdgeInsets.fromLTRB(24, 6, 24, 12),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black87),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: ChartPeriod.values.map((p) {
            final sel = p == period;
            return Expanded(
              child: GestureDetector(
                onTap: () {
                  if (p == period) return;
                  setState(() {
                    _expandedCategoryByPeriod[period] = null;
                  });
                  // 重建controller，让选中日期居中显示
                  final screenW = MediaQuery.of(context).size.width;
                  final double itemW = screenW / 5;
                  switch (p) {
                    case ChartPeriod.week:
                      final weeks = generateWeekList();
                      final cur = ref.read(selectedWeekProvider).label;
                      final idx = weeks.indexWhere((w) => w.label == cur);
                      final offset = idx >= 0
                          ? _calcPickerOffset(idx, weeks.length, itemW, screenW)
                          : 0.0;
                      _weekScrollCtrl.dispose();
                      _weekScrollCtrl = ScrollController(
                        initialScrollOffset: offset,
                      );
                    case ChartPeriod.month:
                      final months = generateMonthList();
                      final cur = ref.read(selectedChartMonthProvider);
                      final idx = months.indexOf(cur);
                      final offset = idx >= 0
                          ? _calcPickerOffset(
                              idx,
                              months.length,
                              itemW,
                              screenW,
                            )
                          : 0.0;
                      _monthScrollCtrl.dispose();
                      _monthScrollCtrl = ScrollController(
                        initialScrollOffset: offset,
                      );
                    case ChartPeriod.year:
                      final years = generateYearList();
                      final cur = ref.read(selectedYearProvider);
                      final idx = years.indexOf(cur);
                      final offset = idx >= 0
                          ? _calcPickerOffset(idx, years.length, itemW, screenW)
                          : 0.0;
                      _yearScrollCtrl.dispose();
                      _yearScrollCtrl = ScrollController(
                        initialScrollOffset: offset,
                      );
                  }
                  ref.read(chartPeriodProvider.notifier).set(p);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  decoration: BoxDecoration(
                    color: sel ? Colors.black87 : Colors.transparent,
                    borderRadius: tabRadius,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    labels[p]!,
                    style: TextStyle(
                      color: sel ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ==================== 横向时间选择器 ====================
  Widget _buildPeriodSelector(ChartPeriod period) {
    final now = DateTime.now();
    switch (period) {
      case ChartPeriod.week:
        final weeks = generateWeekList();
        final cur = ref.watch(selectedWeekProvider).label;
        final thisWeekLabel = weekInfoOf(now).label;
        final lastWeekLabel = weekInfoOf(
          now.subtract(const Duration(days: 7)),
        ).label;
        return _horizontalPicker(
          controller: _weekScrollCtrl,
          items: weeks.map((w) => w.label).toList(),
          selected: cur,
          displayOverrides: {thisWeekLabel: '本周', lastWeekLabel: '上周'},
          onTap: (label) {
            final w = weeks.firstWhere((w) => w.label == label);
            ref.read(selectedWeekProvider.notifier).set(w);
          },
        );
      case ChartPeriod.month:
        final months = generateMonthList();
        final cur = ref.watch(selectedChartMonthProvider);
        final thisMonth = '${now.year}-${now.month.toString().padLeft(2, '0')}';
        final prevDt = DateTime(now.year, now.month - 1, 1);
        final lastMonth =
            '${prevDt.year}-${prevDt.month.toString().padLeft(2, '0')}';
        return _horizontalPicker(
          controller: _monthScrollCtrl,
          items: months.map((m) => '$m月').toList(),
          selected: '$cur月',
          displayOverrides: {'$thisMonth月': '本月', '$lastMonth月': '上月'},
          onTap: (label) => ref
              .read(selectedChartMonthProvider.notifier)
              .set(label.replaceAll('月', '')),
        );
      case ChartPeriod.year:
        final years = generateYearList();
        final cur = ref.watch(selectedYearProvider);
        final thisYear = '${now.year}年';
        final lastYear = '${now.year - 1}年';
        return _horizontalPicker(
          controller: _yearScrollCtrl,
          items: years.map((y) => '$y年').toList(),
          selected: '$cur年',
          displayOverrides: {thisYear: '今年', lastYear: '去年'},
          onTap: (label) => ref
              .read(selectedYearProvider.notifier)
              .set(label.replaceAll('年', '')),
        );
    }
  }

  Widget _horizontalPicker({
    required ScrollController controller,
    required List<String> items,
    required String selected,
    required ValueChanged<String> onTap,
    Map<String, String> displayOverrides = const {},
  }) {
    final screenW = MediaQuery.of(context).size.width;
    final double itemW = screenW / 5;
    return Container(
      color: AppColors.primary.withValues(alpha: 0.25),
      height: 38,
      child: ListView.builder(
        key: ValueKey(controller.hashCode),
        controller: controller,
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        itemBuilder: (_, i) {
          final isSel = !_pickerScrolling && items[i] == selected;
          final displayText = displayOverrides[items[i]] ?? items[i];
          return GestureDetector(
            onTap: () {
              if (items[i] == selected) return;
              setState(() => _pickerScrolling = true);
              final target = (i * itemW - screenW / 2 + itemW / 2).clamp(
                0.0,
                controller.position.maxScrollExtent,
              );
              controller
                  .animateTo(
                    target,
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                  )
                  .then((_) {
                    if (mounted) {
                      _pickerScrolling = false;
                      onTap(items[i]);
                    }
                  });
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Expanded(
                  child: SizedBox(
                    width: itemW,
                    child: Center(
                      child: Text(
                        displayText,
                        overflow: TextOverflow.visible,
                        softWrap: false,
                        style: TextStyle(
                          fontSize: isSel ? 11 : 10,
                          fontWeight: isSel
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: isSel ? Colors.black87 : Colors.black45,
                        ),
                      ),
                    ),
                  ),
                ),
                if (isSel)
                  Container(
                    width: 65,
                    height: 3,
                    decoration: const BoxDecoration(color: Colors.black87),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ==================== 汇总 + 折线图 ====================
  Widget _buildSummaryAndChart(
    double total,
    List<BillItem> filtered,
    ChartPeriod period,
  ) {
    // 计算平均值
    int divisor;
    switch (period) {
      case ChartPeriod.week:
        divisor = 7;
      case ChartPeriod.month:
        final parts = ref.read(selectedChartMonthProvider).split('-');
        divisor = DateTime(int.parse(parts[0]), int.parse(parts[1]) + 1, 0).day;
      case ChartPeriod.year:
        divisor = 12;
    }
    final avg = divisor > 0 ? total / divisor : 0.0;
    final typeLabel = ref.read(chartTypeProvider) == 'expense' ? '支出' : '收入';

    // 构建数据点
    final dataMap = <int, double>{};
    int xCount;
    String Function(int) labelFn;

    switch (period) {
      case ChartPeriod.week:
        xCount = 7;
        final w = ref.read(selectedWeekProvider);
        for (final b in filtered) {
          final d = DateTime.tryParse(b.date);
          if (d == null) continue;
          final idx = d.difference(w.startDate).inDays;
          if (idx >= 0 && idx < 7)
            dataMap[idx] = (dataMap[idx] ?? 0) + b.amount;
        }
        labelFn = (i) {
          final d = w.startDate.add(Duration(days: i));
          return '${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
        };
      case ChartPeriod.month:
        final parts = ref.read(selectedChartMonthProvider).split('-');
        final dt = DateTime(int.parse(parts[0]), int.parse(parts[1]), 1);
        xCount = DateTime(int.parse(parts[0]), int.parse(parts[1]) + 1, 0).day;
        // 月视图：按天聚合
        for (final b in filtered) {
          final d = DateTime.tryParse(b.date);
          if (d == null) continue;
          dataMap[d.day - 1] = (dataMap[d.day - 1] ?? 0) + b.amount;
        }
        labelFn = (i) => '${i + 1}';
      case ChartPeriod.year:
        xCount = 12;
        for (final b in filtered) {
          final d = DateTime.tryParse(b.date);
          if (d == null) {
            continue;
          }
          dataMap[d.month - 1] = (dataMap[d.month - 1] ?? 0) + b.amount;
        }
        labelFn = (i) => '${i + 1}月';
    }

    final spots = <FlSpot>[];
    double maxY = 0;
    for (int i = 0; i < xCount; i++) {
      final v = dataMap[i] ?? 0;
      spots.add(FlSpot(i.toDouble(), v));
      if (v > maxY) maxY = v;
    }
    final hasData = maxY > 0;
    final chartMaxY = hasData ? maxY * 1.15 : 100.0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 汇总
          Text(
            '总$typeLabel：${total.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '平均值：${avg.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 11,
              color: Colors.black54,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          // 折线图 + 右侧最大值标签
          SizedBox(
            height: 160,
            child: LayoutBuilder(
              builder: (context, constraints) {
                // 计算maxY横线在图表中的Y位置，用于对齐标签
                // 图表区域高度 = SizedBox高度 - top padding - bottom reserved(22)
                final double topPad = 8;
                final chartAreaH = 180.0 - topPad - 22;
                final maxYRatio = hasData ? maxY / chartMaxY : 0.0;
                final maxYTop = topPad + chartAreaH * (1 - maxYRatio);
                return Stack(
                  children: [
                    // 最大值标签（右侧，和maxY横线对齐）
                    if (hasData)
                      Positioned(
                        right: 0,
                        top: maxYTop - 24,
                        child: Text(
                          maxY.toStringAsFixed(2),
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.black45,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    // 折线图
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: LineChart(
                        LineChartData(
                          minX: -0.3,
                          maxX: (xCount - 1).toDouble() + 0.3,
                          minY: 0,
                          maxY: chartMaxY,
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                            horizontalInterval: hasData ? maxY : chartMaxY,
                            getDrawingHorizontalLine: (value) {
                              return FlLine(
                                color: Colors.grey.shade300,
                                strokeWidth: 1.2,
                              );
                            },
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
                                reservedSize: 22,
                                interval: 1,
                                getTitlesWidget: (value, meta) {
                                  final i = value.toInt();
                                  if (value != i.toDouble()) {
                                    return const SizedBox.shrink();
                                  }
                                  if (i < 0 || i >= xCount) {
                                    return const SizedBox.shrink();
                                  }
                                  if (period == ChartPeriod.month &&
                                      xCount > 15) {
                                    if (i % 5 != 0 && i != xCount - 1) {
                                      return const SizedBox.shrink();
                                    }
                                  }
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      labelFn(i),
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: Colors.black45,
                                        fontWeight: FontWeight.w500,
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
                              isCurved: false,
                              color: Colors.grey.shade500,
                              barWidth: 1.2,
                              dotData: FlDotData(
                                show: true,
                                getDotPainter: (spot, _, _, _) {
                                  final hasVal = spot.y > 0;
                                  return FlDotCirclePainter(
                                    radius: hasVal ? 4 : 2.5,
                                    color: hasVal
                                        ? AppColors.primary
                                        : Colors.grey.shade300,
                                    strokeWidth: hasVal ? 1.5 : 0.8,
                                    strokeColor: hasVal
                                        ? Colors.grey.shade600
                                        : Colors.grey.shade400,
                                  );
                                },
                              ),
                              belowBarData: BarAreaData(
                                show: hasData,
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    AppColors.primary.withValues(alpha: 0.35),
                                    AppColors.primary.withValues(alpha: 0.05),
                                  ],
                                ),
                              ),
                            ),
                          ],
                          lineTouchData: LineTouchData(
                            touchCallback:
                                (
                                  FlTouchEvent event,
                                  LineTouchResponse? response,
                                ) {
                                  if (event is FlTapUpEvent &&
                                      response?.lineBarSpots != null &&
                                      response!.lineBarSpots!.isNotEmpty) {
                                    final spot = response.lineBarSpots!.first;
                                    final idx = spot.x.toInt();
                                    if (idx >= 0 &&
                                        idx < xCount &&
                                        dataMap[idx] != null &&
                                        dataMap[idx]! > 0) {
                                      final topBills = _getTopBillsForSpot(
                                        idx,
                                        filtered,
                                        period,
                                      );
                                      if (topBills.isNotEmpty) {
                                        _showTopBillsSheet(
                                          context,
                                          topBills,
                                          idx,
                                          period,
                                          typeLabel,
                                        );
                                      }
                                    }
                                  }
                                },
                            touchTooltipData: LineTouchTooltipData(
                              getTooltipItems: (spots) => spots
                                  .map(
                                    (s) => LineTooltipItem(
                                      s.y.toStringAsFixed(2),
                                      const TextStyle(
                                        fontSize: 12,
                                        color: Colors.white,
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 2),
          const Divider(height: 1, thickness: 0.5),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  // ==================== 排行榜 ====================
  Widget _buildRankingList(
    List<BillItem> filtered,
    double total,
    String type,
    ChartPeriod period,
  ) {
    final map = <String, _RankItem>{};
    final billsByCategory = <String, List<_CategoryBillEntry>>{};
    for (final b in filtered) {
      for (final slice in _categorySlicesForBill(b)) {
        final entry = map.putIfAbsent(
          slice.category,
          () => _RankItem(category: slice.category, iconId: slice.iconId),
        );
        entry.amount += slice.amount;
        billsByCategory.putIfAbsent(slice.category, () => []).add(
              _CategoryBillEntry(bill: b, amount: slice.amount),
            );
      }
    }
    final list = map.values.toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));
    final maxAmt = list.isNotEmpty ? list.first.amount : 1.0;
    final typeLabel = type == 'expense' ? '支出' : '收入';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
          child: Text(
            '$typeLabel排行榜',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
        ),
        if (list.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 48),
            child: Center(
              child: Text(
                '暂无数据',
                style: TextStyle(color: Colors.black38, fontSize: 14),
              ),
            ),
          ),
        ...list.map((item) {
          final pct = total > 0 ? item.amount / total * 100 : 0.0;
          final ratio = maxAmt > 0 ? item.amount / maxAmt : 0.0;
          final icon = item.iconId < iconJson.length
              ? iconJson[item.iconId]
              : null;
          final isExpanded = _expandedCategoryByPeriod[period] == item.category;
          final childBills = [
            ...(billsByCategory[item.category] ?? const <_CategoryBillEntry>[])
          ]
                ..sort((a, b) {
                  final amountCompare = b.amount.compareTo(a.amount);
                  if (amountCompare != 0) return amountCompare;
                  final sortCompare = b.bill.sortAt.compareTo(a.bill.sortAt);
                  if (sortCompare != 0) return sortCompare;
                  return b.bill.date.compareTo(a.bill.date);
                });
          final topChildBills = childBills.take(20).toList();
          // 涨跌对比
          final prevAmt = _prevPeriodByCategory[item.category];
          Widget? trendIcon;
          if (prevAmt != null && prevAmt > 0) {
            final isUp = item.amount > prevAmt;
            final isDown = item.amount < prevAmt;
            // 支出：上升红色，下降绿色；收入：上升绿色，下降红色
            final upColor = type == 'expense'
                ? const Color(0xFFFF6B6B)
                : const Color(0xFF4CAF50);
            final downColor = type == 'expense'
                ? const Color(0xFF4CAF50)
                : const Color(0xFFFF6B6B);
            if (isUp) {
              trendIcon = _trendBadge(Icons.arrow_upward, upColor);
            } else if (isDown) {
              trendIcon = _trendBadge(Icons.arrow_downward, downColor);
            }
          }
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              decoration: BoxDecoration(
                color: isExpanded
                    ? AppColors.primaryLight.withValues(alpha: 0.85)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () {
                        ref.read(chartDrilldownProvider.notifier).open(item.category);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        child: _buildRankRow(
                          icon: icon != null
                              ? Image.asset(
                                  iconPath(icon.iconL),
                                  errorBuilder: (_, _, _) => const Icon(
                                    Icons.category_outlined,
                                    size: 20,
                                    color: Colors.black38,
                                  ),
                                )
                              : const Icon(
                                  Icons.category_outlined,
                                  size: 20,
                                  color: Colors.black38,
                                ),
                          title: item.category,
                          percentageText: '${pct.toStringAsFixed(1)}%',
                          amountText: _fmtAmount(item.amount),
                          ratio: ratio,
                          trendIcon: trendIcon,
                        ),
                      ),
                    ),
                  ),
                  if (isExpanded) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Divider(
                        height: 1,
                        thickness: 0.6,
                        color: Colors.black.withValues(alpha: 0.08),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 6, 12, 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(bottom: 8),
                            child: Text(
                              '类别排行榜（前20）',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.black54,
                              ),
                            ),
                          ),
                          ..._buildChildRankRows(
                            childBills: topChildBills,
                            categoryTotal: item.amount,
                            icon: icon,
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 80),
      ],
    );
  }

  List<Widget> _buildChildRankRows({
    required List<_CategoryBillEntry> childBills,
    required double categoryTotal,
    required dynamic icon,
  }) {
    final maxChildAmount = childBills.isNotEmpty
        ? childBills.first.amount
        : 1.0;
    return [
      for (var index = 0; index < childBills.length; index++) ...[
        _buildRankRow(
          iconBoxSize: 30,
          iconPadding: 3,
          titleFontSize: 12,
          percentageFontSize: 10,
          amountFontSize: 11.5,
          progressHeight: 4,
          icon: icon != null
              ? Image.asset(
                  iconPath(icon.iconL),
                  errorBuilder: (_, _, _) => const Icon(
                    Icons.category_outlined,
                    size: 16,
                    color: Colors.black38,
                  ),
                )
              : const Icon(
                  Icons.category_outlined,
                  size: 16,
                  color: Colors.black38,
                ),
          title: _noteLabel(childBills[index].note),
          percentageText:
              '${(categoryTotal > 0 ? childBills[index].amount / categoryTotal * 100 : 0).toStringAsFixed(1)}%',
          amountText: _fmtAmount(childBills[index].amount),
          ratio: maxChildAmount > 0
              ? childBills[index].amount / maxChildAmount
              : 0.0,
          thirdLineText: _billDateLabel(childBills[index].bill.date),
        ),
        if (index != childBills.length - 1)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Divider(
              height: 1,
              thickness: 0.4,
              color: Colors.black.withValues(alpha: 0.06),
            ),
          ),
      ],
    ];
  }

  Widget _buildRankRow({
    required Widget icon,
    required String title,
    required String percentageText,
    required String amountText,
    required double ratio,
    Widget? trendIcon,
    double iconBoxSize = 36,
    double titleFontSize = 13,
    double percentageFontSize = 11,
    double amountFontSize = 12.5,
    double progressHeight = 5,
    double iconPadding = 4,
    String? thirdLineText,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: iconBoxSize,
          height: iconBoxSize,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(iconBoxSize >= 36 ? 8 : 7),
          ),
          child: Padding(padding: EdgeInsets.all(iconPadding), child: icon),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (trendIcon != null) ...[
                    trendIcon,
                    const SizedBox(width: 4),
                  ],
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: titleFontSize,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    percentageText,
                    style: TextStyle(
                      fontSize: percentageFontSize,
                      color: Colors.black38,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    amountText,
                    style: TextStyle(
                      fontSize: amountFontSize,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: ratio.clamp(0.0, 1.0),
                  minHeight: progressHeight,
                  backgroundColor: Colors.grey.shade100,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppColors.primary,
                  ),
                ),
              ),
              if (thirdLineText != null) ...[
                const SizedBox(height: 5),
                Text(
                  thirdLineText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.left,
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: Colors.black45,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _trendBadge(IconData iconData, Color color) {
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      child: Icon(iconData, size: 10, color: Colors.white),
    );
  }

  // ==================== 点击数据点：当日 Top3 账单 ====================
  List<BillItem> _getTopBillsForSpot(
    int spotIdx,
    List<BillItem> filtered,
    ChartPeriod period,
  ) {
    String datePrefix;
    switch (period) {
      case ChartPeriod.week:
        final w = ref.read(selectedWeekProvider);
        final d = w.startDate.add(Duration(days: spotIdx));
        datePrefix =
            '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      case ChartPeriod.month:
        final parts = ref.read(selectedChartMonthProvider).split('-');
        final day = (spotIdx + 1).toString().padLeft(2, '0');
        datePrefix = '${parts[0]}-${parts[1]}-$day';
      case ChartPeriod.year:
        final y = ref.read(selectedYearProvider);
        datePrefix = '$y-${(spotIdx + 1).toString().padLeft(2, '0')}';
    }
    final dayBills = filtered
        .where((b) => b.date.startsWith(datePrefix))
        .toList();
    dayBills.sort((a, b) => b.amount.compareTo(a.amount));
    return dayBills.take(3).toList();
  }

  void _showTopBillsSheet(
    BuildContext context,
    List<BillItem> topBills,
    int spotIdx,
    ChartPeriod period,
    String typeLabel,
  ) {
    String dateLabel;
    switch (period) {
      case ChartPeriod.week:
        final w = ref.read(selectedWeekProvider);
        final d = w.startDate.add(Duration(days: spotIdx));
        dateLabel = '${d.month}月${d.day}日';
      case ChartPeriod.month:
        final parts = ref.read(selectedChartMonthProvider).split('-');
        dateLabel = '${int.parse(parts[1])}月${spotIdx + 1}日';
      case ChartPeriod.year:
        dateLabel = '${spotIdx + 1}月';
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 标题行
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '$dateLabel $typeLabel Top${topBills.length}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '共 ${topBills.fold<double>(0, (s, b) => s + b.amount).toStringAsFixed(2)} 元',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 12),
                // 账单列表
                ...List.generate(topBills.length, (i) {
                  final bill = topBills[i];
                  final icon = bill.iconId < iconJson.length
                      ? iconJson[bill.iconId]
                      : null;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        // 排名
                        SizedBox(
                          width: 22,
                          child: Text(
                            '${i + 1}.',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: i == 0
                                  ? AppColors.primary
                                  : Colors.black54,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // 类别图标
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight.withValues(
                              alpha: 0.3,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: icon != null
                              ? Padding(
                                  padding: const EdgeInsets.all(5),
                                  child: Image.asset(
                                    iconPath(icon.iconL),
                                    errorBuilder: (_, _, _) => const Icon(
                                      Icons.category_outlined,
                                      size: 18,
                                      color: Colors.black45,
                                    ),
                                  ),
                                )
                              : const Icon(
                                  Icons.category_outlined,
                                  size: 18,
                                  color: Colors.black45,
                                ),
                        ),
                        const SizedBox(width: 10),
                        // 类别 + 备注 + 日期
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                bill.category,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (_noteLabel(bill.note) != '无备注')
                                Text(
                                  _noteLabel(bill.note),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              Text(
                                _billDateLabel(bill.date),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade400,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // 金额
                        Text(
                          '${_fmtAmount(bill.amount)} 元',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  String _fmtAmount(double v) {
    if (v == v.roundToDouble() && v < 100000) return v.toInt().toString();
    if (v >= 100000) return v.toStringAsFixed(0);
    return v.toStringAsFixed(v >= 1000 ? 1 : 2);
  }

  String _noteLabel(String note) {
    final trimmed = note.trim();
    return trimmed.isEmpty ? '无备注' : trimmed;
  }

  String _billDateLabel(String date) {
    final trimmed = date.trim();
    if (trimmed.length >= 10) return trimmed.substring(0, 10);
    return trimmed;
  }
}

class _RankItem {
  final String category;
  final int iconId;
  double amount = 0;
  _RankItem({required this.category, required this.iconId});
}

class _CategorySlice {
  final String category;
  final int iconId;
  final double amount;

  const _CategorySlice({
    required this.category,
    required this.iconId,
    required this.amount,
  });
}

class _CategoryBillEntry {
  final BillItem bill;
  final double amount;

  const _CategoryBillEntry({
    required this.bill,
    required this.amount,
  });

  String get note => bill.note;
}

enum _CategoryDrilldownSort { amount, time }

// ==================== 分类详情弹窗 ====================
class _CategoryDrilldownSheet extends ConsumerWidget {
  final String category;
  final ChartPeriod period;
  final List<BillItem> bills;
  final VoidCallback onClose;

  const _CategoryDrilldownSheet({
    required this.category,
    required this.period,
    required this.bills,
    required this.onClose,
  });

  String get _periodLabel {
    switch (period) {
      case ChartPeriod.week:
        return '本周';
      case ChartPeriod.month:
        return '本月';
      case ChartPeriod.year:
        return '今年';
    }
  }

  String get _periodShortLabel {
    switch (period) {
      case ChartPeriod.week:
        return '周';
      case ChartPeriod.month:
        return '月';
      case ChartPeriod.year:
        return '年';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final total = bills.fold<double>(0, (s, b) => s + b.amount);
    final sortedBills = [...bills]..sort((a, b) => b.date.compareTo(a.date));

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppColors.surfaceStrong, width: 0.5),
              ),
            ),
            child: Row(
              children: [
                Text(
                  category,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '$_periodLabel ${bills.length} 笔',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: onClose,
                  icon: const Icon(Icons.close),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _buildPeriodChip(ref, '周', ChartPeriod.week),
                const SizedBox(width: 8),
                _buildPeriodChip(ref, '月', ChartPeriod.month),
                const SizedBox(width: 8),
                _buildPeriodChip(ref, '年', ChartPeriod.year),
              ],
            ),
          ),
          const Divider(height: 1),
          Flexible(
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: sortedBills.length,
              itemBuilder: (context, index) {
                final bill = sortedBills[index];
                return _buildBillRow(bill);
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: AppColors.surfaceStrong, width: 0.5),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '合计',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  total.toStringAsFixed(2),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodChip(WidgetRef ref, String label, ChartPeriod targetPeriod) {
    final isSelected = period == targetPeriod;
    return GestureDetector(
      onTap: () {
        final now = DateTime.now();
        switch (targetPeriod) {
          case ChartPeriod.week:
            ref.read(selectedWeekProvider.notifier).set(weekInfoOf(now));
            ref.read(chartPeriodProvider.notifier).set(ChartPeriod.week);
          case ChartPeriod.month:
            ref.read(selectedChartMonthProvider.notifier).set(
                '${now.year}-${now.month.toString().padLeft(2, '0')}');
            ref.read(chartPeriodProvider.notifier).set(ChartPeriod.month);
          case ChartPeriod.year:
            ref.read(selectedYearProvider.notifier).set(now.year.toString());
            ref.read(chartPeriodProvider.notifier).set(ChartPeriod.year);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.primaryLight,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          '${label}视图',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildBillRow(BillItem bill) {
    final icon = bill.iconId >= 0 && bill.iconId < iconJson.length
        ? iconJson[bill.iconId]
        : null;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          if (icon != null)
            Image.asset(iconPath(icon.iconL), width: 32, height: 32)
          else
            const Icon(Icons.receipt, size: 32, color: AppColors.textSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bill.note.isNotEmpty ? bill.note : bill.category,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  bill.date.split(' ')[0],
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          Text(
            '-${bill.amount.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}
