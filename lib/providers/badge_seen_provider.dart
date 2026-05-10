import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../db/database_helper.dart';

const String _kSeenKey = 'badge_seen_names';
const String _kInitializedKey = 'badge_seen_initialized';

/// 用户已"看过弹窗"的徽章名单 + 是否完成首次播种。
class BadgeSeen {
  final Set<String> names;

  /// 是否已经完成首次播种。首次启动时（或本功能新发布时）我们会把当前已经
  /// 获得的徽章一次性写入并标记 [initialized] = true，避免对老用户上来就
  /// 弹一堆「恭喜获得新徽章」。
  final bool initialized;

  const BadgeSeen({required this.names, required this.initialized});

  BadgeSeen copyWith({Set<String>? names, bool? initialized}) => BadgeSeen(
    names: names ?? this.names,
    initialized: initialized ?? this.initialized,
  );

  static const empty = BadgeSeen(names: <String>{}, initialized: false);
}

/// 「已弹过解锁提示的徽章名单」持久化存储。
///
/// 之所以单独一个 provider 来管理而不是直接读 settings：
///  - 多处需要共享同一份内存里的 seen 集合（MainShell 检测 / 未来其他位置）
///  - 写入要立刻反映到状态里，避免短时间内同一徽章被弹两次
class BadgeSeenNotifier extends AsyncNotifier<BadgeSeen> {
  @override
  Future<BadgeSeen> build() async {
    final db = DatabaseHelper.instance;
    final raw = await db.getSetting(_kSeenKey);
    final init = await db.getSetting(_kInitializedKey);
    final names = (raw == null || raw.isEmpty)
        ? <String>{}
        : raw.split('\n').where((s) => s.isNotEmpty).toSet();
    return BadgeSeen(names: names, initialized: init == '1');
  }

  /// 注册当前已获得徽章名单到 seen，并返回需要触发弹窗的"新解锁"集合。
  ///
  /// 行为：
  ///  - 若 seen 尚未初始化（首次安装/老用户首次升级到本功能）：把
  ///    [currentlyAchieved] 全量写入 seen 并打上 initialized 标记，**返回空集合**
  ///    （即不弹任何窗）；
  ///  - 已初始化：返回 [currentlyAchieved] 中尚未在 seen 中的部分，并写入。
  ///
  /// 注意：内部会等待 [future] 完成，确保从数据库加载好真实的 seen 状态后
  /// 再做差集判断，避免 state 仍在 loading 时被误判为"首次播种"。
  Future<Set<String>> registerCurrentlyAchieved(
    Set<String> currentlyAchieved,
  ) async {
    final cur = await future;

    if (!cur.initialized) {
      await _persist(currentlyAchieved, initialized: true);
      state = AsyncValue.data(
        BadgeSeen(names: currentlyAchieved.toSet(), initialized: true),
      );
      return const <String>{};
    }

    final newly = currentlyAchieved.difference(cur.names);
    if (newly.isEmpty) return const <String>{};

    final merged = {...cur.names, ...newly};
    await _persist(merged, initialized: true);
    state = AsyncValue.data(BadgeSeen(names: merged, initialized: true));
    return newly;
  }

  Future<void> _persist(
    Set<String> names, {
    required bool initialized,
  }) async {
    final db = DatabaseHelper.instance;
    await db.setSetting(_kSeenKey, names.join('\n'));
    if (initialized) {
      await db.setSetting(_kInitializedKey, '1');
    }
  }
}

final badgeSeenProvider =
    AsyncNotifierProvider<BadgeSeenNotifier, BadgeSeen>(BadgeSeenNotifier.new);
