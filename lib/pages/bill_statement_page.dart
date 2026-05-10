import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../db/database_helper.dart';
import '../models/bill_item.dart';
import '../providers/bill_provider.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../widgets/date_picker.dart';

class BillStatementPage extends ConsumerStatefulWidget {
  const BillStatementPage({super.key});

  @override
  ConsumerState<BillStatementPage> createState() => _BillStatementPageState();
}

class _BillStatementPageState extends ConsumerState<BillStatementPage> {
  final _db = DatabaseHelper.instance;
  late int _selectedYear;
  _StatementTab _tab = _StatementTab.month;

  @override
  void initState() {
    super.initState();
    final month = ref.read(selectedMonthProvider);
    _selectedYear = int.parse(month.substring(0, 4));
  }

  Future<_StatementData> _loadData() async {
    final bills = await _db.getAllBills();
    final years = _extractYears(bills);
    if (!years.contains(_selectedYear)) {
      years.add(_selectedYear);
      years.sort((a, b) => b.compareTo(a));
    }

    final monthRows = _buildMonthRows(bills, _selectedYear);
    final yearRows = _buildYearRows(bills);
    final selectedYearSummary = _sumRows(monthRows);
    final allYearSummary = _sumRows(yearRows);

    return _StatementData(
      years: years,
      monthRows: monthRows,
      yearRows: yearRows,
      selectedYearSummary: selectedYearSummary,
      allYearSummary: allYearSummary,
    );
  }

  List<int> _extractYears(List<BillItem> bills) {
    final years = bills
        .map((bill) => int.tryParse(bill.date.substring(0, 4)))
        .whereType<int>()
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));
    if (years.isEmpty) {
      years.add(_selectedYear);
    }
    return years;
  }

  List<_StatementRow> _buildMonthRows(List<BillItem> bills, int year) {
    final buckets = <int, _StatementSummary>{};
    final now = DateTime.now();
    final maxMonth = year == now.year ? now.month : 12;

    for (final bill in bills) {
      if (!bill.date.startsWith('$year-')) {
        continue;
      }
      final month = int.tryParse(bill.date.substring(5, 7));
      if (month == null) {
        continue;
      }
      final summary =
          buckets[month] ?? const _StatementSummary(income: 0, expense: 0);
      buckets[month] = bill.type == 'income'
          ? summary.copyWith(income: summary.income + bill.amount)
          : summary.copyWith(expense: summary.expense + bill.amount);
    }

    return List<_StatementRow>.generate(maxMonth, (index) {
      final month = maxMonth - index;
      final summary =
          buckets[month] ?? const _StatementSummary(income: 0, expense: 0);
      return _StatementRow(label: '${month}月', summary: summary);
    });
  }

  List<_StatementRow> _buildYearRows(List<BillItem> bills) {
    final buckets = <int, _StatementSummary>{};

    for (final bill in bills) {
      final year = int.tryParse(bill.date.substring(0, 4));
      if (year == null) {
        continue;
      }
      final summary =
          buckets[year] ?? const _StatementSummary(income: 0, expense: 0);
      buckets[year] = bill.type == 'income'
          ? summary.copyWith(income: summary.income + bill.amount)
          : summary.copyWith(expense: summary.expense + bill.amount);
    }

    final years = buckets.keys.toList()..sort((a, b) => b.compareTo(a));
    if (years.isEmpty) {
      years.add(_selectedYear);
      buckets[_selectedYear] = const _StatementSummary(income: 0, expense: 0);
    }

    return years
        .map(
          (year) => _StatementRow(
            label: '${year}年',
            summary:
                buckets[year] ?? const _StatementSummary(income: 0, expense: 0),
          ),
        )
        .toList();
  }

  _StatementSummary _sumRows(List<_StatementRow> rows) {
    double income = 0;
    double expense = 0;
    for (final row in rows) {
      income += row.summary.income;
      expense += row.summary.expense;
    }
    return _StatementSummary(income: income, expense: expense);
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(billListProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: FutureBuilder<_StatementData>(
          future: _loadData(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final data = snapshot.data!;
            final isMonthTab = _tab == _StatementTab.month;
            final summary =
                isMonthTab ? data.selectedYearSummary : data.allYearSummary;

            return Column(
              children: [
                _buildTopBar(data.years),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.only(
                      left: 16,
                      right: 16,
                      top: 12,
                      bottom: MediaQuery.of(context).padding.bottom + 24,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SummaryCard(
                          title: isMonthTab ? '年结余' : '总结余',
                          total: summary.balance,
                          incomeLabel: isMonthTab ? '年收入' : '总收入',
                          expenseLabel: isMonthTab ? '年支出' : '总支出',
                          income: summary.income,
                          expense: summary.expense,
                        ),
                        const SizedBox(height: 26),
                        _StatementTable(
                          tab: _tab,
                          rows: isMonthTab ? data.monthRows : data.yearRows,
                        ),
                        if (!isMonthTab) ...[
                          const SizedBox(height: 24),
                          const Center(
                            child: Text(
                              '年账单为自然年 (1.1-12.31)',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildTopBar(List<int> years) {
    final isMonthTab = _tab == _StatementTab.month;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
      child: Row(
        children: [
          SizedBox(
            width: 96,
            child: isMonthTab
                ? Align(
                    alignment: Alignment.centerLeft,
                    child: GestureDetector(
                      onTap: () => _pickYear(years),
                      behavior: HitTestBehavior.opaque,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${_selectedYear}年',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const Icon(
                            Icons.arrow_drop_down,
                            size: 24,
                            color: AppColors.textPrimary,
                          ),
                        ],
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          Expanded(child: Center(child: _buildSegmentedTabs())),
          SizedBox(
            width: 84,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // const Icon(
                //   Icons.more_horiz,
                //   size: 24,
                //   color: AppColors.textPrimary,
                // ),
                const SizedBox(width: 8),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    borderRadius: BorderRadius.circular(20),
                    splashColor: AppColors.darkGray.withAlpha(90),
                    highlightColor: AppColors.darkGray.withAlpha(35),
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(
                        Icons.radio_button_checked,
                        size: 22,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickYear(List<int> years) async {
    if (years.isEmpty) return;
    final result = await showModalBottomSheet<int>(
      context: context,
      builder: (_) => AppYearPicker(
        initialYear: _selectedYear,
        years: years,
      ),
    );
    if (result != null && mounted) {
      setState(() => _selectedYear = result);
    }
  }

  Widget _buildSegmentedTabs() {
    return Container(
      height: 34,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.textPrimary.withAlpha(80)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _SegmentTab(
            label: '月账单',
            selected: _tab == _StatementTab.month,
            onTap: () => setState(() => _tab = _StatementTab.month),
          ),
          _SegmentTab(
            label: '年账单',
            selected: _tab == _StatementTab.year,
            onTap: () => setState(() => _tab = _StatementTab.year),
          ),
        ],
      ),
    );
  }
}

enum _StatementTab { month, year }

class _StatementData {
  const _StatementData({
    required this.years,
    required this.monthRows,
    required this.yearRows,
    required this.selectedYearSummary,
    required this.allYearSummary,
  });

  final List<int> years;
  final List<_StatementRow> monthRows;
  final List<_StatementRow> yearRows;
  final _StatementSummary selectedYearSummary;
  final _StatementSummary allYearSummary;
}

class _StatementSummary {
  const _StatementSummary({
    required this.income,
    required this.expense,
  });

  final double income;
  final double expense;

  double get balance => income - expense;

  _StatementSummary copyWith({
    double? income,
    double? expense,
  }) {
    return _StatementSummary(
      income: income ?? this.income,
      expense: expense ?? this.expense,
    );
  }
}

class _StatementRow {
  const _StatementRow({
    required this.label,
    required this.summary,
  });

  final String label;
  final _StatementSummary summary;
}

class _SegmentTab extends StatelessWidget {
  const _SegmentTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 78,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF1F1F25) : Colors.transparent,
          borderRadius: label=='月账单' ? BorderRadius.only(topLeft: Radius.circular(12), bottomLeft: Radius.circular(12)) 
          : BorderRadius.only(topRight: Radius.circular(12), bottomRight: Radius.circular(12)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.total,
    required this.incomeLabel,
    required this.expenseLabel,
    required this.income,
    required this.expense,
  });

  final String title;
  final double total;
  final String incomeLabel;
  final String expenseLabel;
  final double income;
  final double expense;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -2,
            top: -8,
            child: ShaderMask(
              blendMode: BlendMode.srcIn,
              shaderCallback: (bounds) => LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  AppColors.primaryLight.withAlpha(0),
                  AppColors.primaryLight,
                ],
              ).createShader(bounds),
              child: const Icon(
                Icons.currency_yen_rounded,
                size: 96,
                color: Colors.white,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              buildAmountText(
                value: total,
                integerStyle: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  height: 1,
                ),
                decimalStyle: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  height: 1,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _CardStat(label: incomeLabel, value: income),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _CardStat(label: expenseLabel, value: expense),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

}

class _CardStat extends StatelessWidget {
  const _CardStat({
    required this.label,
    required this.value,
  });

  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(width: 4),
        Flexible(
          child: buildAmountText(
            value: value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            integerStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
            decimalStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

class _StatementTable extends StatelessWidget {
  const _StatementTable({
    required this.tab,
    required this.rows,
  });

  final _StatementTab tab;
  final List<_StatementRow> rows;

  @override
  Widget build(BuildContext context) {
    final isMonthTab = tab == _StatementTab.month;
    final title1 = isMonthTab ? '月份' : '年份';
    final title2 = isMonthTab ? '月收入' : '年收入';
    final title3 = isMonthTab ? '月支出' : '年支出';
    final title4 = isMonthTab ? '月结余' : '年结余';

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.only(
            left: 12,
            right: isMonthTab ? 8 : 12,
            bottom: 8,
          ),
          child: Row(
            children: [
              _headerCell(title1, flex: 5, align: TextAlign.left),
              _headerCell(title2),
              _headerCell(title3),
              _headerCell(title4),
              // if (isMonthTab) const SizedBox(width: 18),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
          ),
          child: Column(
            children: [
              for (int i = 0; i < rows.length; i++) ...[
                if(i == 0)
                  const Divider(height: 1, color: AppColors.darkGray),
                _StatementDataRow(
                  row: rows[i],
                  showArrow: false, //isMonthTab,
                ),
                if (i != rows.length - 1)
                  const Divider(height: 1, color: AppColors.darkGray),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _headerCell(
    String text, {
    int flex = 8,
    TextAlign align = TextAlign.center,
  }) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        textAlign: align,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _StatementDataRow extends StatelessWidget {
  const _StatementDataRow({
    required this.row,
    required this.showArrow,
  });

  final _StatementRow row;
  final bool showArrow;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: Padding(
        padding: EdgeInsets.only(
          left: 12,
          right: showArrow ? 8 : 12,
        ),
        child: Row(
          children: [
            Expanded(
              flex: 5,
              child: Text(
                row.label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            _valueCell(row.summary.income),
            _valueCell(row.summary.expense),
            _valueCell(
              row.summary.balance,
              isBalance: true,
            ),
            if (showArrow)
              const SizedBox(
                width: 18,
                child: Icon(
                  Icons.chevron_right,
                  size: 18,
                  color: AppColors.textSecondary,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _valueCell(double value, {bool isBalance = false}) {
    return Expanded(
      flex: 8,
      child: buildAmountText(
        value: value,
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        integerStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
        decimalStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}
