import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../db/database_helper.dart';

/// settings 表中各 key 的常量定义
class _SettingKeys {
  static const String smsAutoBookkeeping = 'sms_auto_bookkeeping';
  static const String amountHidden = 'amount_hidden';
}

/// 短信自动记账开关
///
/// 持久化在 sqflite 的 settings 表中。首次安装默认开启（与历史行为一致）。
class SmsAutoBookkeepingEnabledNotifier extends AsyncNotifier<bool> {
  static const bool _defaultValue = true;

  @override
  Future<bool> build() async {
    final raw = await DatabaseHelper.instance.getSetting(
      _SettingKeys.smsAutoBookkeeping,
    );
    if (raw == null) return _defaultValue;
    return raw == '1';
  }

  Future<void> setEnabled(bool enabled) async {
    state = AsyncValue.data(enabled);
    await DatabaseHelper.instance.setSetting(
      _SettingKeys.smsAutoBookkeeping,
      enabled ? '1' : '0',
    );
  }
}

final smsAutoBookkeepingEnabledProvider =
    AsyncNotifierProvider<SmsAutoBookkeepingEnabledNotifier, bool>(
      SmsAutoBookkeepingEnabledNotifier.new,
    );

class AmountHiddenNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    final raw = await DatabaseHelper.instance.getSetting(_SettingKeys.amountHidden);
    return raw == '1';
  }

  Future<void> toggle() async {
    final current = state.maybeWhen(data: (v) => v, orElse: () => false);
    final newValue = !current;
    state = AsyncValue.data(newValue);
    await DatabaseHelper.instance.setSetting(
      _SettingKeys.amountHidden,
      newValue ? '1' : '0',
    );
  }
}

final amountHiddenProvider =
    AsyncNotifierProvider<AmountHiddenNotifier, bool>(
      AmountHiddenNotifier.new,
    );
