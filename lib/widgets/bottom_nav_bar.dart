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
      label: '账单',
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
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.dark,
        systemNavigationBarContrastEnforced: false,
      ),
      child: BottomAppBar(
        height: 76,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        notchMargin: 8,
        shape: const CircularNotchedRectangle(),
        color: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: AppColors.surfaceStrong),
            boxShadow: const [
              BoxShadow(
                color: Color(0x143A241B),
                blurRadius: 24,
                offset: Offset(0, -4),
              ),
            ],
          ),
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
      ),
    );
  }

  Widget _centerLabel() {
    final color = currentIndex == 2 ? AppColors.primary : AppColors.textSecondary;
    return GestureDetector(
      onTap: () => onTap(2),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 56,
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Text(
              '记账',
              style: TextStyle(
                fontSize: 10,
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _item(_TabInfo tab) {
    final isSelected = currentIndex == tab.index;
    final color = isSelected ? AppColors.primary : AppColors.textSecondary;
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
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primaryLight : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Image.asset(iconPath, width: 24, height: 24),
            ),
            const SizedBox(height: 2),
            Text(
              tab.label,
              style: TextStyle(
                fontSize: 10,
                color: color,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
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
