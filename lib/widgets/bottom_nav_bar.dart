import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

class BottomNavBar extends StatelessWidget {
  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  static const _tabs = [
    _TabInfo(
      label: '明细',
      activeIcon: 'assets/images/tabbar_detail_s@3x.png',
      inactiveIcon: 'assets/images/tabbar_detail_n@3x.png',
      index: 0,
    ),
    _TabInfo(
      label: '图表',
      activeIcon: 'assets/images/tabbar_chart_s@3x.png',
      inactiveIcon: 'assets/images/tabbar_chart_n@3x.png',
      index: 1,
    ),
    _TabInfo(
      label: '发现',
      activeIcon: 'assets/images/tabbar_discover_s@3x.png',
      inactiveIcon: 'assets/images/tabbar_discover_n@3x.png',
      index: 3,
    ),
    _TabInfo(
      label: '我的',
      activeIcon: 'assets/images/tabbar_mine_s@3x.png',
      inactiveIcon: 'assets/images/tabbar_mine_n@3x.png',
      index: 4,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.dark,
        systemNavigationBarContrastEnforced: false,
      ),
      child: BottomAppBar(
        height: 64,
        padding: EdgeInsets.zero,
        notchMargin: 6,
        shape: const CircularNotchedRectangle(),
        color: AppColors.surface,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _item(_tabs[0]),
            _item(_tabs[1]),
            _centerLabel(),
            _item(_tabs[2]),
            _item(_tabs[3]),
          ],
        ),
      ),
    );
  }

  Widget _centerLabel() {
    final color = currentIndex == 2
        ? AppColors.primaryDark
        : AppColors.textSecondary;
    return GestureDetector(
      onTap: () => onTap(2),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 56,
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text('记账', style: TextStyle(fontSize: 10, color: color)),
          ),
        ),
      ),
    );
  }

  Widget _item(_TabInfo tab) {
    final isSelected = currentIndex == tab.index;
    final color = isSelected ? AppColors.primaryDark : AppColors.textSecondary;
    final iconPath = isSelected ? tab.activeIcon : tab.inactiveIcon;
    return GestureDetector(
      onTap: () => onTap(tab.index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 56,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Image.asset(iconPath, width: 28, height: 28),
                // if (tab.index == 4)
                //   Positioned(
                //     right: -4,
                //     top: -2,
                //     child: Container(
                //       width: 8,
                //       height: 8,
                //       decoration: const BoxDecoration(
                //         color: AppColors.badge,
                //         shape: BoxShape.circle,
                //       ),
                //     ),
                //   ),
              ],
            ),
            const SizedBox(height: 2),
            Text(tab.label, style: TextStyle(fontSize: 10, color: color)),
          ],
        ),
      ),
    );
  }
}

class _TabInfo {
  final String label;
  final String activeIcon;
  final String inactiveIcon;
  final int index;
  const _TabInfo({
    required this.label,
    required this.activeIcon,
    required this.inactiveIcon,
    required this.index,
  });
}
