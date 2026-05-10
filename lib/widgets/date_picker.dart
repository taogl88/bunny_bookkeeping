import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

const int _pickerStartYear = 2000;
const int _pickerEndYear = 2050;
const double _pickerItemExtent = 56.0;

class DatePicker extends StatefulWidget {
  const DatePicker({super.key, required this.initialDate});

  final DateTime initialDate;

  @override
  State<DatePicker> createState() => _DatePickerState();
}

class _DatePickerState extends State<DatePicker> {
  late FixedExtentScrollController _yearCtrl;
  late FixedExtentScrollController _monthCtrl;
  late FixedExtentScrollController _dayCtrl;

  late int _year;
  late int _month;
  late int _day;

  int get _daysInMonth => DateUtils.getDaysInMonth(_year, _month);

  @override
  void initState() {
    super.initState();
    _year = widget.initialDate.year;
    _month = widget.initialDate.month;
    _day = widget.initialDate.day;
    _yearCtrl = FixedExtentScrollController(initialItem: _year - _pickerStartYear);
    _monthCtrl = FixedExtentScrollController(initialItem: _month - 1);
    _dayCtrl = FixedExtentScrollController(initialItem: _day - 1);
  }

  @override
  void dispose() {
    _yearCtrl.dispose();
    _monthCtrl.dispose();
    _dayCtrl.dispose();
    super.dispose();
  }

  void _onYearOrMonthChanged() {
    // 修正日期不超过当月最大天数
    if (_day > _daysInMonth) {
      _day = _daysInMonth;
      _dayCtrl.jumpToItem(_day - 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 工具栏
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Text('取消', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ),
                const Text('选择日期', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                GestureDetector(
                  onTap: () => Navigator.pop(context, DateTime(_year, _month, _day)),
                  child: Text('确定', style: TextStyle(fontSize: 12, color: AppColors.primaryDark)),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE0E0E0)),
          SizedBox(
            height: _pickerItemExtent * 5,
            child: _buildPickerArea(),
          ),
          SizedBox(height: bottomPadding),
        ],
      ),
    );
  }

  Widget _buildPickerArea() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final third = constraints.maxWidth / 3;
        final top1 = _pickerItemExtent * 2;
        final top2 = _pickerItemExtent * 3;
        return Stack(
          children: [
            // 年 分割线
            Positioned(left: 16, right: third * 2 + 16, top: top1, child: const Divider(height: 1, color: Color(0xFFE0E0E0))),
            Positioned(left: 16, right: third * 2 + 16, top: top2, child: const Divider(height: 1, color: Color(0xFFE0E0E0))),
            // 月 分割线
            Positioned(left: third + 16, right: third + 16, top: top1, child: const Divider(height: 1, color: Color(0xFFE0E0E0))),
            Positioned(left: third + 16, right: third + 16, top: top2, child: const Divider(height: 1, color: Color(0xFFE0E0E0))),
            // 日 分割线
            Positioned(left: third * 2 + 16, right: 16, top: top1, child: const Divider(height: 1, color: Color(0xFFE0E0E0))),
            Positioned(left: third * 2 + 16, right: 16, top: top2, child: const Divider(height: 1, color: Color(0xFFE0E0E0))),
            Row(
              children: [
                Expanded(child: _buildWheel(
                  controller: _yearCtrl,
                  count: _pickerEndYear - _pickerStartYear + 1,
                  labelBuilder: (i) => '${_pickerStartYear + i}',
                  selectedIndex: _year - _pickerStartYear,
                  onChanged: (i) {
                    setState(() { _year = _pickerStartYear + i; _onYearOrMonthChanged(); });
                  },
                )),
                Expanded(child: _buildWheel(
                  controller: _monthCtrl,
                  count: 12,
                  labelBuilder: (i) => '${i + 1}',
                  selectedIndex: _month - 1,
                  onChanged: (i) {
                    setState(() { _month = i + 1; _onYearOrMonthChanged(); });
                  },
                )),
                Expanded(child: _buildWheel(
                  controller: _dayCtrl,
                  count: _daysInMonth,
                  labelBuilder: (i) => '${i + 1}',
                  selectedIndex: _day - 1,
                  onChanged: (i) => setState(() => _day = i + 1),
                )),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildWheel({
    required FixedExtentScrollController controller,
    required int count,
    required String Function(int) labelBuilder,
    required int selectedIndex,
    required ValueChanged<int> onChanged,
  }) {
    return ListWheelScrollView.useDelegate(
      controller: controller,
      itemExtent: _pickerItemExtent,
      perspective: 0.003,
      diameterRatio: 10,
      physics: const FixedExtentScrollPhysics(),
      onSelectedItemChanged: onChanged,
      childDelegate: ListWheelChildBuilderDelegate(
        childCount: count,
        builder: (context, index) {
          final isSelected = index == selectedIndex;
          return Center(
            child: Text(
              labelBuilder(index),
              style: TextStyle(
                fontSize: isSelected ? 18 : 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.black : const Color(0xFFBBBBBB),
              ),
            ),
          );
        },
      ),
    );
  }
}

class AppYearPicker extends StatefulWidget {
  const AppYearPicker({
    super.key,
    required this.initialYear,
    required this.years,
    this.title = '选择年份',
  });

  final int initialYear;
  final List<int> years;
  final String title;

  @override
  State<AppYearPicker> createState() => _AppYearPickerState();
}

class _AppYearPickerState extends State<AppYearPicker> {
  late final FixedExtentScrollController _yearCtrl;
  late final List<int> _years;
  late int _selectedYear;

  @override
  void initState() {
    super.initState();
    _years = [...widget.years]..sort((a, b) => b.compareTo(a));
    _selectedYear = _years.contains(widget.initialYear)
        ? widget.initialYear
        : _years.first;
    _yearCtrl = FixedExtentScrollController(
      initialItem: _years.indexOf(_selectedYear),
    );
  }

  @override
  void dispose() {
    _yearCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Text(
                    '取消',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ),
                Text(
                  widget.title,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context, _selectedYear),
                  child: Text(
                    '确定',
                    style: TextStyle(fontSize: 12, color: AppColors.primaryDark),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE0E0E0)),
          SizedBox(
            height: _pickerItemExtent * 5,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final top1 = _pickerItemExtent * 2;
                final top2 = _pickerItemExtent * 3;
                return Stack(
                  children: [
                    Positioned(
                      left: 16,
                      right: 16,
                      top: top1,
                      child: Center(
                        child: Container(
                          width: 88,
                          height: 1,
                          color: const Color(0xFFE0E0E0),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 16,
                      right: 16,
                      top: top2,
                      child: Center(
                        child: Container(
                          width: 88,
                          height: 1,
                          color: const Color(0xFFE0E0E0),
                        ),
                      ),
                    ),
                    ListWheelScrollView.useDelegate(
                      controller: _yearCtrl,
                      itemExtent: _pickerItemExtent,
                      perspective: 0.003,
                      diameterRatio: 10,
                      physics: const FixedExtentScrollPhysics(),
                      onSelectedItemChanged: (index) {
                        setState(() => _selectedYear = _years[index]);
                      },
                      childDelegate: ListWheelChildBuilderDelegate(
                        childCount: _years.length,
                        builder: (context, index) {
                          final year = _years[index];
                          final isSelected = year == _selectedYear;
                          return Center(
                            child: Text(
                              '$year',
                              style: TextStyle(
                                fontSize: isSelected ? 18 : 14,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                color: isSelected ? Colors.black : const Color(0xFFBBBBBB),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          SizedBox(height: bottomPadding),
        ],
      ),
    );
  }
}
