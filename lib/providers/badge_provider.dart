import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/account_data.dart';
import '../db/database_helper.dart';
import 'bill_provider.dart';
import 'user_stats_provider.dart';

/// 徽章分类。顺序与「徽章页」分组顺序保持一致。
///
/// 各分类的获取条件：
///  - [streak]      历史最长连续记账天数 ≥ 阈值
///  - [totalDays]   累计记账天数 ≥ 阈值
///  - [totalCount]  累计记账笔数 ≥ 阈值
///  - [catering]    餐饮（icon_id=0）累计笔数 ≥ 阈值
///  - [shopping]    购物（icon_id=1）累计笔数 ≥ 阈值
///  - [travel]      旅行（icon_id=17）累计笔数 ≥ 阈值
///  - [salary]      工资（icon_id=33）累计笔数 ≥ 阈值
enum BadgeCategory {
  streak('连续打卡'),
  totalDays('累计记账天数'),
  totalCount('累计记账笔数'),
  catering('餐饮记账'),
  shopping('购物记账'),
  travel('旅行记账'),
  salary('工资');

  final String title;
  const BadgeCategory(this.title);
}

/// 单枚徽章定义：来自 [badgeJson] 的素材 + 我们补上的获取阈值与所属分类。
class BadgeRule {
  final BadgeItem item;
  final int threshold;
  final BadgeCategory category;

  const BadgeRule({
    required this.item,
    required this.threshold,
    required this.category,
  });

  String get name => item.name;
  String get icon => item.icon;
  String get iconS => item.iconS;

  /// 该徽章的「达成条件」自然语言描述。
  ///
  /// 文案规则：
  ///  - 连续打卡  → "连续记账 N 天"
  ///  - 累计天数  → "累计记账 N 天"
  ///  - 累计笔数  → "累计记账 N 笔"
  ///  - 餐饮/购物/旅行/工资 → "餐饮(等)累计记账 N 笔"
  String get condition {
    switch (category) {
      case BadgeCategory.streak:
        return '连续记账 $threshold 天';
      case BadgeCategory.totalDays:
        return '累计记账 $threshold 天';
      case BadgeCategory.totalCount:
        return '累计记账 $threshold 笔';
      case BadgeCategory.catering:
        return '餐饮累计记账 $threshold 笔';
      case BadgeCategory.shopping:
        return '购物累计记账 $threshold 笔';
      case BadgeCategory.travel:
        return '旅行累计记账 $threshold 笔';
      case BadgeCategory.salary:
        return '工资累计记账 $threshold 笔';
    }
  }
}

/// 徽章成就（含展示态）。
class BadgeAchievement {
  final BadgeRule rule;
  final bool achieved;

  const BadgeAchievement({required this.rule, required this.achieved});
}

/// 一个分类下的徽章总览（标题 + 徽章列表 + 获得数）。
class BadgeSection {
  final BadgeCategory category;
  final List<BadgeAchievement> badges;

  const BadgeSection({required this.category, required this.badges});

  String get title => category.title;
  int get achievedCount => badges.where((b) => b.achieved).length;
}

class BadgeData {
  final List<BadgeSection> sections;
  const BadgeData(this.sections);
}

// ---------------------- 阈值表 ----------------------
//
// 与 account_data.dart 中 [badgeJson] 的顺序一一对应；阈值取自 AccountJson.js
// 的注释 / name 中的数字。

const List<int> _streakThresholds = [1, 3, 7, 21, 50, 100, 200, 365, 500];
const List<int> _totalDaysThresholds = [30, 100, 365, 500, 800, 1000];
const List<int> _totalCountThresholds = [99, 333, 555, 888, 1024, 2046];
const List<int> _cateringThresholds = [15, 66, 100, 270, 500];
const List<int> _shoppingThresholds = [10, 50, 100, 200, 300];
const List<int> _travelThresholds = [1, 10, 30, 50, 100];
const List<int> _salaryThresholds = [1, 6, 12, 24, 36];

/// 各分类对应到 [badgeJson] 的索引。保持与 AccountJson.js BADGE_JSON 顺序一致。
const Map<BadgeCategory, int> _categoryToBadgeIndex = {
  BadgeCategory.streak: 0,
  BadgeCategory.totalDays: 1,
  BadgeCategory.totalCount: 2,
  BadgeCategory.catering: 3,
  BadgeCategory.shopping: 4,
  BadgeCategory.travel: 5,
  BadgeCategory.salary: 6,
};

const Map<BadgeCategory, List<int>> _categoryToThresholds = {
  BadgeCategory.streak: _streakThresholds,
  BadgeCategory.totalDays: _totalDaysThresholds,
  BadgeCategory.totalCount: _totalCountThresholds,
  BadgeCategory.catering: _cateringThresholds,
  BadgeCategory.shopping: _shoppingThresholds,
  BadgeCategory.travel: _travelThresholds,
  BadgeCategory.salary: _salaryThresholds,
};

// 各分类对应需要计数的 icon_id。-1 表示该分类不依赖单一 icon_id。
const int _cateringIconId = 0;
const int _shoppingIconId = 1;
const int _travelIconId = 17;
const int _salaryIconId = 33;

/// 拼装出某一分类的徽章规则列表（素材 + 阈值 + 分类）。
List<BadgeRule> _rulesOf(BadgeCategory category) {
  final idx = _categoryToBadgeIndex[category]!;
  final items = badgeJson[idx];
  final thresholds = _categoryToThresholds[category]!;
  // 取较短长度，避免素材与阈值数量不一致时越界。
  final n = items.length < thresholds.length ? items.length : thresholds.length;
  return [
    for (int i = 0; i < n; i++)
      BadgeRule(
        item: items[i],
        threshold: thresholds[i],
        category: category,
      ),
  ];
}

int _measureFor(
  BadgeCategory category, {
  required UserStats stats,
  required Map<int, int> iconCounts,
}) {
  switch (category) {
    case BadgeCategory.streak:
      return stats.longestStreak;
    case BadgeCategory.totalDays:
      return stats.totalDays;
    case BadgeCategory.totalCount:
      return stats.totalCount;
    case BadgeCategory.catering:
      return iconCounts[_cateringIconId] ?? 0;
    case BadgeCategory.shopping:
      return iconCounts[_shoppingIconId] ?? 0;
    case BadgeCategory.travel:
      return iconCounts[_travelIconId] ?? 0;
    case BadgeCategory.salary:
      return iconCounts[_salaryIconId] ?? 0;
  }
}

BadgeSection _buildSection(
  BadgeCategory category, {
  required UserStats stats,
  required Map<int, int> iconCounts,
}) {
  final measure = _measureFor(
    category,
    stats: stats,
    iconCounts: iconCounts,
  );
  final rules = _rulesOf(category);
  return BadgeSection(
    category: category,
    badges: [
      for (final rule in rules)
        BadgeAchievement(rule: rule, achieved: measure >= rule.threshold),
    ],
  );
}

/// 徽章页所需数据：所有分类的徽章成就状态。
final badgeProvider = FutureProvider<BadgeData>((ref) async {
  // 监听账单变化，账单一旦增删都会自动刷新徽章页
  ref.watch(billListProvider);
  final stats = await ref.watch(userStatsProvider.future);
  final iconCounts = await DatabaseHelper.instance.getBillCountGroupByIconId();

  final sections = [
    for (final category in BadgeCategory.values)
      _buildSection(category, stats: stats, iconCounts: iconCounts),
  ];
  return BadgeData(sections);
});
