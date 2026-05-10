import 'package:flutter_riverpod/flutter_riverpod.dart';

// ==================== 时间维度枚举 ====================
enum ChartPeriod { week, month, year }

class ChartPeriodNotifier extends Notifier<ChartPeriod> {
  @override
  ChartPeriod build() => ChartPeriod.week;
  void set(ChartPeriod v) => state = v;
}

final chartPeriodProvider = NotifierProvider<ChartPeriodNotifier, ChartPeriod>(ChartPeriodNotifier.new);

class ChartTypeNotifier extends Notifier<String> {
  @override
  String build() => 'expense';
  void set(String v) => state = v;
}

final chartTypeProvider = NotifierProvider<ChartTypeNotifier, String>(ChartTypeNotifier.new);

// ==================== 周选择器 ====================
class WeekInfo {
  final String label;
  final DateTime startDate;
  final DateTime endDate;
  const WeekInfo({required this.label, required this.startDate, required this.endDate});
}

WeekInfo weekInfoOf(DateTime date) {
  final weekday = date.weekday;
  final monday = date.subtract(Duration(days: weekday - 1));
  final sunday = monday.add(const Duration(days: 6));
  final start = DateTime(monday.year, monday.month, monday.day);
  final end = DateTime(sunday.year, sunday.month, sunday.day, 23, 59, 59);
  final weekNum = _isoWeekNumber(start);
  return WeekInfo(label: '${start.year}-$weekNum周', startDate: start, endDate: end);
}

int _isoWeekNumber(DateTime date) {
  final dayOfYear = date.difference(DateTime(date.year, 1, 1)).inDays;
  final weekday = date.weekday;
  return ((dayOfYear - weekday + 10) / 7).floor();
}

class SelectedWeekNotifier extends Notifier<WeekInfo> {
  @override
  WeekInfo build() => weekInfoOf(DateTime.now());
  void set(WeekInfo v) => state = v;
}

final selectedWeekProvider = NotifierProvider<SelectedWeekNotifier, WeekInfo>(SelectedWeekNotifier.new);

List<WeekInfo> generateWeekList() {
  final now = DateTime.now();
  final list = <WeekInfo>[];
  for (int i = -52; i <= 52; i++) {
    list.add(weekInfoOf(now.add(Duration(days: i * 7))));
  }
  final seen = <String>{};
  return list.where((w) => seen.add(w.label)).toList();
}

// ==================== 月选择器 ====================
class SelectedChartMonthNotifier extends Notifier<String> {
  @override
  String build() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}';
  }
  void set(String v) => state = v;
}

final selectedChartMonthProvider = NotifierProvider<SelectedChartMonthNotifier, String>(SelectedChartMonthNotifier.new);

List<String> generateMonthList() {
  final now = DateTime.now();
  final list = <String>[];
  for (int i = -24; i <= 12; i++) {
    final d = DateTime(now.year, now.month + i, 1);
    list.add('${d.year}-${d.month.toString().padLeft(2, '0')}');
  }
  return list;
}

// ==================== 年选择器 ====================
class SelectedYearNotifier extends Notifier<String> {
  @override
  String build() => '${DateTime.now().year}';
  void set(String v) => state = v;
}

final selectedYearProvider = NotifierProvider<SelectedYearNotifier, String>(SelectedYearNotifier.new);

List<String> generateYearList() {
  final now = DateTime.now();
  final list = <String>[];
  for (int y = now.year - 5; y <= now.year + 1; y++) {
    list.add('$y');
  }
  return list;
}
