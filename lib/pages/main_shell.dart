import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/badge_provider.dart';
import '../providers/badge_seen_provider.dart';
import '../providers/bill_provider.dart';
import '../providers/keyboard_provider.dart';
import '../providers/navigation_provider.dart';
import '../providers/settings_provider.dart';
import '../services/sms_auto_bookkeeping_service.dart';
import '../theme/app_theme.dart';
import '../widgets/badge_unlock_dialog.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/calculator_keyboard.dart';
import 'billing_page.dart';
import 'chart_page.dart';
import 'discover_page.dart';
import 'home_page.dart';
import 'mine_page.dart';

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell>
    with WidgetsBindingObserver {
  static const String _logTag = '[LedgerSms][MainShell]';
  DateTime? _lastBackPress;
  static const _pages = <Widget>[
    HomePage(),
    Center(child: ChartPage()),
    BillingPage(),
    DiscoverPage(),
    MinePage(),
  ];

  /// 标记弹窗调度器是否正在/即将弹出新徽章解锁。
  /// 防止 [badgeProvider] 在窗口关闭瞬间因刷新再次触发同一批弹窗。
  bool _badgeDialogPending = false;

  /// 在弹窗显示过程中如果 [badgeProvider] 又来了新值，先在这里记一笔，
  /// 等当前一轮弹窗结束后再补一次检查，避免漏弹。
  bool _badgeRecheckQueued = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Future<void>.microtask(_initializeSmsAutoBookkeepingIfEnabled);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _syncPendingSmsTransactionsIfEnabled();
    }
  }

  /// 读取「我的」页中的短信自动记账开关；未加载完成时按默认值（true）走，
  /// 与历史行为保持兼容。
  Future<bool> _isSmsAutoEnabled() async {
    return ref.read(smsAutoBookkeepingEnabledProvider.future);
  }

  Future<void> _initializeSmsAutoBookkeepingIfEnabled() async {
    if (!await _isSmsAutoEnabled()) {
      debugPrint('$_logTag sms auto bookkeeping disabled, skip init');
      return;
    }
    await _initializeSmsAutoBookkeeping();
  }

  Future<void> _syncPendingSmsTransactionsIfEnabled() async {
    if (!await _isSmsAutoEnabled()) {
      debugPrint('$_logTag sms auto bookkeeping disabled, skip resume sync');
      return;
    }
    await _syncPendingSmsTransactions();
  }

  Future<void> _initializeSmsAutoBookkeeping() async {
    final granted = await SmsAutoBookkeepingService.ensurePermissions();
    debugPrint('$_logTag sms permissions granted=$granted');
    await _syncPendingSmsTransactions();
  }

  /// 与 [badgeSeenProvider] 比对，把新解锁的徽章弹窗依次展示出来。
  ///
  /// 首次启动（seen 未初始化）只会被静默播种：把当前已获得的徽章批量
  /// 写入 seen 但不弹任何窗，避免老用户升级到本功能时被一堆弹窗轰炸。
  Future<void> _maybeShowBadgeUnlock(BadgeData data) async {
    if (_badgeDialogPending) {
      // 当前还在弹窗调度中，标记待会儿再检查一次
      _badgeRecheckQueued = true;
      return;
    }

    _badgeDialogPending = true;
    try {
      // 在循环中处理：如果弹窗过程中又有新数据进来，结束后再跑一轮
      var current = data;
      do {
        _badgeRecheckQueued = false;
        await _runOneUnlockRound(current);
        if (!mounted) return;
        // 取最新数据用于下一轮校验
        final latest = ref.read(badgeProvider).value;
        if (latest == null) break;
        current = latest;
      } while (_badgeRecheckQueued);
    } finally {
      _badgeDialogPending = false;
    }
  }

  Future<void> _runOneUnlockRound(BadgeData data) async {
    final achievedItems = <BadgeAchievement>[];
    final achievedNames = <String>{};
    for (final section in data.sections) {
      for (final b in section.badges) {
        if (b.achieved) {
          achievedItems.add(b);
          achievedNames.add(b.rule.name);
        }
      }
    }

    final newlyNames = await ref
        .read(badgeSeenProvider.notifier)
        .registerCurrentlyAchieved(achievedNames);
    if (newlyNames.isEmpty) return;
    if (!mounted) return;

    // 保留对应 BadgeAchievement 的展示顺序（与 sections 顺序一致）
    final newlyBadges = [
      for (final b in achievedItems)
        if (newlyNames.contains(b.rule.name)) b,
    ];
    if (newlyBadges.isEmpty) return;

    await showBadgeUnlockDialog(context, newlyBadges);
  }

  Future<void> _syncPendingSmsTransactions() async {
    final currentMonth = ref.read(selectedMonthProvider);
    debugPrint('$_logTag sync pending sms start, currentMonth=$currentMonth');
    final result = await SmsAutoBookkeepingService.syncPendingTransactions();
    debugPrint(
      '$_logTag sync pending sms insertedCount=${result.insertedCount}, months=${result.insertedMonths}',
    );
    if (!mounted || result.insertedCount <= 0) {
      return;
    }
    if (result.insertedMonths.isNotEmpty &&
        !result.insertedMonths.contains(currentMonth)) {
      final latestMonth = result.insertedMonths.last;
      debugPrint(
        '$_logTag switch selectedMonth from $currentMonth to $latestMonth for sms record visibility',
      );
      ref.read(selectedMonthProvider.notifier).setMonth(latestMonth);
    }
    ref.invalidate(billListProvider);
    ref.invalidate(monthlySummaryProvider);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('已自动记账 ${result.insertedCount} 笔记录'),
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(navigationProvider);
    final kb = ref.watch(keyboardProvider);

    // 在「我的」页里切换短信自动记账开关时：
    // - 关 → 开：立即触发权限申请 + 一次同步，无需重启 App
    // - 开 → 关：不做任何事，仅停止后续同步触发
    ref.listen<AsyncValue<bool>>(smsAutoBookkeepingEnabledProvider, (prev, next) {
      final wasOn = prev?.value ?? false;
      final isOn = next.value ?? false;
      if (!wasOn && isOn) {
        debugPrint('$_logTag sms auto bookkeeping toggled ON, kick off init');
        _initializeSmsAutoBookkeeping();
      }
    });

    // 监听徽章数据变化：每次账单变更后 [badgeProvider] 都会被重建，这里
    // 在新数据到达时检测「这次又获得了哪些过去没看过的徽章」并依次弹窗提示。
    ref.listen<AsyncValue<BadgeData>>(badgeProvider, (prev, next) {
      final data = next.value;
      if (data == null) return;
      _maybeShowBadgeUnlock(data);
    });

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        // 1. 键盘可见 → 先收起键盘
        if (kb.visible) {
          ref.read(keyboardProvider.notifier).hide();
          return;
        }
        // 2. 双击返回退出
        final now = DateTime.now();
        if (_lastBackPress != null &&
            now.difference(_lastBackPress!) < const Duration(seconds: 2)) {
          // 允许退出
          SystemNavigator.pop();
          return;
        }
        _lastBackPress = now;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('再按一次退出'),
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      child: Stack(
        children: [
          Scaffold(
            resizeToAvoidBottomInset: false,
            body: IndexedStack(index: currentIndex, children: _pages),
            bottomNavigationBar: currentIndex == 2
                ? null
                : BottomNavBar(
                    currentIndex: currentIndex,
                    onTap: (index) => ref.read(navigationProvider.notifier).setTab(index),
                  ),
            floatingActionButton: currentIndex == 2
                ? null
                : SizedBox(
              width: 58,
              height: 58,
              child: FloatingActionButton(
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  ref.read(navigationProvider.notifier).setTab(2);
                },
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                child: const Icon(Icons.add, size: 32, color: Colors.white),
              ),
            ),
            floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
          ),
          // 键盘覆盖层：在 Scaffold 之上，贴屏幕底部，可下拉关闭
          if (kb.visible && kb.onComplete != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: GestureDetector(
                onVerticalDragEnd: (details) {
                  if (details.primaryVelocity != null && details.primaryVelocity! > 300) {
                    ref.read(keyboardProvider.notifier).hide();
                  }
                },
                child: Material(
                  child: _MeasuredKeyboard(
                    onHeightChanged: (h) => ref.read(keyboardProvider.notifier).updateHeight(h),
                    child: CalculatorKeyboard(
                      categoryName: kb.categoryName,
                      categoryIconPath: kb.categoryIconPath,
                      initialAmount: kb.initialAmount,
                      initialNote: kb.initialNote,
                      initialDate: kb.initialDate,
                      onComplete: kb.onComplete!,
                      onClose: () => ref.read(keyboardProvider.notifier).hide(),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// 测量子 widget 高度并回调
class _MeasuredKeyboard extends StatefulWidget {
  const _MeasuredKeyboard({required this.child, required this.onHeightChanged});
  final Widget child;
  final ValueChanged<double> onHeightChanged;

  @override
  State<_MeasuredKeyboard> createState() => _MeasuredKeyboardState();
}

class _MeasuredKeyboardState extends State<_MeasuredKeyboard> {
  final _key = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
  }

  void _measure() {
    final box = _key.currentContext?.findRenderObject() as RenderBox?;
    if (box != null) widget.onHeightChanged(box.size.height);
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
    return SizedBox(key: _key, child: widget.child);
  }
}
