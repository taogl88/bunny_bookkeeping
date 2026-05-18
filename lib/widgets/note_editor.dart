import 'dart:async';

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class NoteEditor extends StatefulWidget {
  const NoteEditor({
    super.key,
    required this.initialNote,
    required this.displayText,
    required this.categoryName,
    required this.categoryIconPath,
    required this.bottomSafeArea,
    required this.onChanged,
    this.noteSuggestions = const [],
  });

  final String initialNote;
  final String displayText;
  final String categoryName;
  final String categoryIconPath;
  final double bottomSafeArea;
  final ValueChanged<String> onChanged;
  final List<String> noteSuggestions;

  @override
  State<NoteEditor> createState() => _NoteEditorState();
}

class _NoteEditorState extends State<NoteEditor> with WidgetsBindingObserver {
  static const int _keyboardSettleDelayMs = 80;
  static const Duration _keyboardSettleDelay =
      Duration(milliseconds: _keyboardSettleDelayMs);

  late TextEditingController _controller;
  final _focusNode = FocusNode();
  Timer? _keyboardSettleTimer;
  bool _isClosing = false;
  bool _isEditorVisible = false;
  double _settledKeyboardInset = 0;
  double _lastKeyboardInset = 0;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialNote);
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _focusNode.requestFocus();
      _handleKeyboardInsetChanged(_readKeyboardInset());
    });
  }

  @override
  void dispose() {
    _keyboardSettleTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    _handleKeyboardInsetChanged(_readKeyboardInset());
  }

  @override
  Widget build(BuildContext context) {
    final sheetBottomInset = _isEditorVisible
        ? _settledKeyboardInset
        : widget.bottomSafeArea;

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              ignoring: !_isEditorVisible,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  _focusNode.unfocus();
                  _closeWithCurrentNote(reason: 'outside-tap');
                },
                child: const SizedBox.expand(),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: sheetBottomInset,
            // 不可见阶段使用 Offstage：保持子树（含 TextField/FocusNode）挂载，
            // 但跳过 paint 和合成层；同时通过 TickerMode 关停 TextField 内部的
            // 光标闪烁 ticker，让系统键盘弹出过程的第一帧渲染负载降到最小，避免
            // 卡丢首帧而导致键盘动画看起来卡顿。
            child: Offstage(
              offstage: !_isEditorVisible,
              child: TickerMode(
                enabled: _isEditorVisible,
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: _handleInternalTap,
                  child: RepaintBoundary(
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(12),
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            color: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                            child: Row(
                              children: [
                                Image.asset(
                                  widget.categoryIconPath,
                                  width: 28,
                                  height: 28,
                                ),
                                const Spacer(),
                                GestureDetector(
                                  onTap: () {
                                    _focusNode.unfocus();
                                    _closeWithCurrentNote(reason: 'done-tap');
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text(
                                      '完成',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            margin: const EdgeInsets.only(
                              left: 12,
                              right: 12,
                              bottom: 16
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0F0F0),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  '备注：',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Expanded(
                                  child: TextField(
                                    controller: _controller,
                                    focusNode: _focusNode,
                                    autofocus: true,
                                    style: const TextStyle(fontSize: 13),
                                    textInputAction: TextInputAction.done,
                                    onChanged: _handleNoteChanged,
                                    onSubmitted: (_) => _done(),
                                    decoration: InputDecoration(
                                      hintText: '点击填写备注',
                                      hintStyle: TextStyle(
                                        fontSize: 13,
                                        color: AppColors.textSecondary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      border: InputBorder.none,
                                      isDense: true,
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),
                          if (widget.noteSuggestions.isNotEmpty)
                            Container(
                              margin: const EdgeInsets.only(left: 12, right: 12, bottom: 8),
                              child: Wrap(
                                alignment: WrapAlignment.start,
                                spacing: 6,
                                runSpacing: 4,
                                children: widget.noteSuggestions.map((note) {
                                  return GestureDetector(
                                    onTap: () {
                                      _controller.text = note;
                                      _handleNoteChanged(note);
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF0F0F0),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        note,
                                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  double _readKeyboardInset() {
    final view = WidgetsBinding.instance.platformDispatcher.views.first;
    return view.viewInsets.bottom / view.devicePixelRatio;
  }

  void _handleKeyboardInsetChanged(double keyboardInset) {
    final previousKeyboardInset = _lastKeyboardInset;
    _lastKeyboardInset = keyboardInset;
    _keyboardSettleTimer?.cancel();

    if (_isEditorVisible) {
      if (keyboardInset < previousKeyboardInset - 0.5 || keyboardInset <= 0) {
        _closeWithCurrentNote(reason: 'keyboard-hide-start');
        return;
      }
      if ((keyboardInset - _settledKeyboardInset).abs() > 0.5 && mounted) {
        setState(() {
          _settledKeyboardInset = keyboardInset;
        });
      }
      return;
    }

    if (keyboardInset <= 0) {
      return;
    }

    _keyboardSettleTimer = Timer(_keyboardSettleDelay, () {
      if (!mounted || _isEditorVisible || _isClosing) {
        return;
      }
      final stableInset = _readKeyboardInset();
      if ((stableInset - _lastKeyboardInset).abs() > 0.5 || stableInset <= 0) {
        return;
      }
      setState(() {
        _settledKeyboardInset = stableInset;
        _isEditorVisible = true;
      });
    });
  }

  void _handleNoteChanged(String value) {
    widget.onChanged(value);
  }

  void _handleInternalTap() {
    if (!_focusNode.hasFocus) {
      _focusNode.requestFocus();
    }
  }

  void _closeWithCurrentNote({required String reason}) {
    if (_isClosing || !mounted) {
      return;
    }
    _isClosing = true;
    final note = _controller.text.trim();
    widget.onChanged(note);
    Navigator.pop(context, note);
  }

  void _done() {
    _closeWithCurrentNote(reason: 'submit');
  }
}
