import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class KeyboardState {
  final bool visible;
  final double height;
  final String categoryName;
  final String categoryIconPath;
  final int? iconId;
  final double? initialAmount;
  final String? initialNote;
  final DateTime? initialDate;
  final void Function(double, String, DateTime)? onComplete;

  const KeyboardState({
    this.visible = false,
    this.height = 0,
    this.categoryName = '',
    this.categoryIconPath = '',
    this.iconId,
    this.initialAmount,
    this.initialNote,
    this.initialDate,
    this.onComplete,
  });

  KeyboardState copyWith({
    bool? visible,
    double? height,
    String? categoryName,
    String? categoryIconPath,
    int? iconId,
    double? initialAmount,
    String? initialNote,
    DateTime? initialDate,
    void Function(double, String, DateTime)? onComplete,
  }) {
    return KeyboardState(
      visible: visible ?? this.visible,
      height: height ?? this.height,
      categoryName: categoryName ?? this.categoryName,
      categoryIconPath: categoryIconPath ?? this.categoryIconPath,
      iconId: iconId ?? this.iconId,
      initialAmount: initialAmount ?? this.initialAmount,
      initialNote: initialNote ?? this.initialNote,
      initialDate: initialDate ?? this.initialDate,
      onComplete: onComplete ?? this.onComplete,
    );
  }
}

class KeyboardNotifier extends Notifier<KeyboardState> {
  @override
  KeyboardState build() => const KeyboardState();

  void show({
    required String categoryName,
    required String categoryIconPath,
    int? iconId,
    double? initialAmount,
    String? initialNote,
    DateTime? initialDate,
    required void Function(double, String, DateTime) onComplete,
  }) {
    state = KeyboardState(
      visible: true,
      categoryName: categoryName,
      categoryIconPath: categoryIconPath,
      iconId: iconId,
      initialAmount: initialAmount,
      initialNote: initialNote,
      initialDate: initialDate,
      onComplete: onComplete,
    );
  }

  void hide() => state = const KeyboardState();

  /// 仅更新分类名、图标和回调，保留键盘已有的金额/备注/日期
  void updateCategory({
    required String categoryName,
    required String categoryIconPath,
    int? iconId,
    required void Function(double, String, DateTime) onComplete,
  }) {
    state = state.copyWith(
      categoryName: categoryName,
      categoryIconPath: categoryIconPath,
      iconId: iconId,
      onComplete: onComplete,
    );
  }

  void updateHeight(double h) {
    if (state.height != h) state = state.copyWith(height: h);
  }
}

final keyboardProvider =
    NotifierProvider<KeyboardNotifier, KeyboardState>(KeyboardNotifier.new);
