import 'package:flutter_riverpod/flutter_riverpod.dart';

class NavigationNotifier extends Notifier<int> {
  int _previousTab = 0;

  @override
  int build() => 0;

  void setTab(int index) {
    if (index == state) return;
    _previousTab = state;
    state = index;
  }

  void openBillingFromCurrentTab() {
    if (state != 2) {
      _previousTab = state;
    }
    state = 2;
  }

  bool returnFromBilling() {
    if (state != 2) return false;
    state = _previousTab;
    return true;
  }
}

final navigationProvider =
    NotifierProvider<NavigationNotifier, int>(NavigationNotifier.new);
