import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class MonthPicker extends StatefulWidget {
  const MonthPicker({
    super.key,
    required this.initialYear,
    required this.initialMonth,
  });

  final int initialYear;
  final int initialMonth;

  @override
  State<MonthPicker> createState() => _MonthPickerState();
}

class _MonthPickerState extends State<MonthPicker> {
  late FixedExtentScrollController _yearController;
  late FixedExtentScrollController _monthController;

  static const int _startYear = 2000;
  static const int _endYear = 2050;
  static const double _itemExtent = 56.0;

  late int _selectedYear;
  late int _selectedMonth;

  @override
  void initState() {
    super.initState();
    _selectedYear = widget.initialYear;
    _selectedMonth = widget.initialMonth;
    _yearController = FixedExtentScrollController(
      initialItem: _selectedYear - _startYear,
    );
    _monthController = FixedExtentScrollController(
      initialItem: _selectedMonth - 1,
    );
  }

  @override
  void dispose() {
    _yearController.dispose();
    _monthController.dispose();
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
          _buildToolbar(),
          const Divider(height: 1, color: Color(0xFFE0E0E0)),
          SizedBox(height: _itemExtent * 5, child: _buildPickerArea()),
          SizedBox(height: bottomPadding),
        ],
      ),
    );
  }

  Widget _buildToolbar() {
    return Padding(
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
          const Text(
            '选择月份',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          GestureDetector(
            onTap: () {
              final ym =
                  '$_selectedYear-${_selectedMonth.toString().padLeft(2, '0')}';
              Navigator.pop(context, ym);
            },
            child: Text(
              '确定',
              style: TextStyle(fontSize: 12, color: AppColors.primaryDark),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPickerArea() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final half = constraints.maxWidth / 2;
        final top1 = _itemExtent * 2; // 上分割线
        final top2 = _itemExtent * 3; // 下分割线
        return Stack(
          children: [
            // 年 - 上分割线
            Positioned(
              left: 108,
              right: half + 8,
              top: top1,
              child: const Divider(
                height: 3,
                color: Color(0xFFE0E0E0),
                thickness: 2,
              ),
            ),
            // 年 - 下分割线
            Positioned(
              left: 108,
              right: half + 8,
              top: top2,
              child: const Divider(
                height: 3,
                color: Color(0xFFE0E0E0),
                thickness: 2,
              ),
            ),
            // 月 - 上分割线
            Positioned(
              left: half + 8,
              right: 108,
              top: top1,
              child: const Divider(
                height: 3,
                color: Color(0xFFE0E0E0),
                thickness: 2,
              ),
            ),
            // 月 - 下分割线
            Positioned(
              left: half + 8,
              right: 108,
              top: top2,
              child: const Divider(
                height: 3,
                color: Color(0xFFE0E0E0),
                thickness: 2,
              ),
            ),
            Row(
              children: [
                const SizedBox(width: 100),
                Expanded(
                  child: _buildWheel(
                    controller: _yearController,
                    count: _endYear - _startYear + 1,
                    labelBuilder: (i) => '${_startYear + i}',
                    selectedIndex: _selectedYear - _startYear,
                    onChanged: (i) =>
                        setState(() => _selectedYear = _startYear + i),
                  ),
                ),
                Expanded(
                  child: _buildWheel(
                    controller: _monthController,
                    count: 12,
                    labelBuilder: (i) => '${i + 1}',
                    selectedIndex: _selectedMonth - 1,
                    onChanged: (i) => setState(() => _selectedMonth = i + 1),
                  ),
                ),
                const SizedBox(width: 100),
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
      itemExtent: _itemExtent,
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
