import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../db/database_helper.dart';
import 'bill_provider.dart';

/// 「我的」页面顶部的用户记账统计
class UserStats {
  final int totalCount;
  final int totalDays;
  final int currentStreak;

  /// 历史最长连续记账天数（用于徽章成就判定）。
  /// 与 [currentStreak] 不同的是，即使用户中断了打卡，本字段也不会回退。
  final int longestStreak;

  const UserStats({
    required this.totalCount,
    required this.totalDays,
    required this.currentStreak,
    required this.longestStreak,
  });

  static const empty = UserStats(
    totalCount: 0,
    totalDays: 0,
    currentStreak: 0,
    longestStreak: 0,
  );
}

final userStatsProvider = FutureProvider<UserStats>((ref) async {
  // 任何账单变更（增/改/删）都会通过 billListProvider 重建本 Provider
  ref.watch(billListProvider);

  final db = DatabaseHelper.instance;
  final count = await db.getTotalBillCount();
  if (count == 0) return UserStats.empty;

  final dates = await db.getDistinctBillDates();
  final dateSet = dates.toSet();
  final totalDays = dateSet.length;

  final today = DateTime.now();
  final streak = _computeStreak(dateSet, today);
  final longest = _computeLongestStreak(dates);

  return UserStats(
    totalCount: count,
    totalDays: totalDays,
    currentStreak: streak,
    longestStreak: longest,
  );
});

/// 计算「连续记账天数」：
///
/// 从今天开始向前数；今天没记的话允许从昨天起算，给一天的宽容（避免凌晨打开
/// 时连续天数立刻断掉给用户挫败感）；从起点起向前连续命中的天数即为答案。
int _computeStreak(Set<String> dateSet, DateTime today) {
  String fmt(DateTime d) =>
      '${d.year}-${_two(d.month)}-${_two(d.day)}';

  DateTime cursor = DateTime(today.year, today.month, today.day);
  if (!dateSet.contains(fmt(cursor))) {
    cursor = cursor.subtract(const Duration(days: 1));
    if (!dateSet.contains(fmt(cursor))) {
      return 0;
    }
  }
  int streak = 0;
  while (dateSet.contains(fmt(cursor))) {
    streak++;
    cursor = cursor.subtract(const Duration(days: 1));
  }
  return streak;
}

String _two(int v) => v.toString().padLeft(2, '0');

/// 计算「历史最长连续记账天数」。
///
/// 输入是 distinct 后的 yyyy-MM-dd 升序日期列表。遍历一次找到最长一段相邻
/// 日期差为 1 的连续区间长度即可。
int _computeLongestStreak(List<String> sortedDates) {
  if (sortedDates.isEmpty) return 0;
  int longest = 1;
  int current = 1;
  DateTime? last;
  for (final dateStr in sortedDates) {
    final date = DateTime.tryParse(dateStr);
    if (date == null) continue;
    if (last == null) {
      current = 1;
    } else {
      final diff = date.difference(last).inDays;
      if (diff == 1) {
        current += 1;
      } else if (diff == 0) {
        // 同一天的重复（理论上 distinct 后不会出现，做个保护）
      } else {
        current = 1;
      }
    }
    if (current > longest) longest = current;
    last = date;
  }
  return longest;
}
