import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// 预算输入键盘弹窗
///
/// 通过 [showBudgetAmountKeyboard] 调起。完成时通过 Navigator.pop 返回输入的金额（double）。
/// 点击右上角关闭按钮或遮罩则返回 null。
Future<double?> showBudgetAmountKeyboard({
  required BuildContext context,
  required String title,
  double? initialAmount,
}) {
  return showModalBottomSheet<double>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withAlpha(120),
    builder: (_) => BudgetAmountKeyboard(
      title: title,
      initialAmount: initialAmount,
    ),
  );
}

class BudgetAmountKeyboard extends StatefulWidget {
  const BudgetAmountKeyboard({
    super.key,
    required this.title,
    this.initialAmount,
  });

  final String title;
  final double? initialAmount;

  @override
  State<BudgetAmountKeyboard> createState() => _BudgetAmountKeyboardState();
}

class _BudgetAmountKeyboardState extends State<BudgetAmountKeyboard> {
  static const int _maxIntegerDigits = 8;
  static const int _maxDecimalDigits = 2;

  String _input = '';

  @override
  void initState() {
    super.initState();
    final initial = widget.initialAmount;
    if (initial != null && initial > 0) {
      _input = _formatInitial(initial);
    }
  }

  String _formatInitial(double v) {
    if (v == v.truncateToDouble()) return v.toInt().toString();
    return v.toStringAsFixed(2).replaceAll(RegExp(r'0+$'), '').replaceAll(
          RegExp(r'\.$'),
          '',
        );
  }

  bool get _canSubmit {
    if (_input.isEmpty) return false;
    final v = double.tryParse(_input);
    return v != null && v > 0;
  }

  void _onKey(String key) {
    setState(() {
      if (key == '⌫') {
        if (_input.isNotEmpty) {
          _input = _input.substring(0, _input.length - 1);
        }
        return;
      }
      if (key == '.') {
        if (_input.isEmpty) {
          _input = '0.';
          return;
        }
        if (!_input.contains('.')) {
          _input += '.';
        }
        return;
      }
      // 数字键
      final next = _input == '0' ? key : _input + key;
      if (_isValidNext(next)) {
        _input = next;
      }
    });
  }

  bool _isValidNext(String value) {
    final parts = value.split('.');
    final integerDigits = parts.first.length;
    if (integerDigits > _maxIntegerDigits) return false;
    if (parts.length > 1 && parts[1].length > _maxDecimalDigits) return false;
    return true;
  }

  void _onSubmit() {
    if (!_canSubmit) return;
    final v = double.tryParse(_input) ?? 0;
    if (v <= 0) return;
    Navigator.of(context).pop(v);
  }

  @override
  Widget build(BuildContext context) {
    final bottomSafe = MediaQuery.of(context).padding.bottom;
    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            _buildInputField(),
            const SizedBox(height: 22),
            _buildConfirmButton(),
            const SizedBox(height: 18),
            _buildKeyboard(),
            SizedBox(height: bottomSafe),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return SizedBox(
      height: 48,
      child: Stack(
        children: [
          Center(
            child: Text(
              widget.title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Positioned(
            right: 6,
            top: 0,
            bottom: 0,
            child: Center(
              child: Material(
                color: Colors.transparent,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.gray.withAlpha(120),
                    ),
                    child: const Icon(
                      Icons.close,
                      size: 16,
                      color: AppColors.textSecondary,
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

  Widget _buildInputField() {
    final hasInput = _input.isNotEmpty;
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 4, 20, 0),
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.remarkGray,
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.centerLeft,
      child: Text(
        hasInput ? _input : '请输入预算金额',
        style: TextStyle(
          fontSize: 15,
          fontWeight: hasInput ? FontWeight.w600 : FontWeight.w500,
          color: hasInput
              ? AppColors.textPrimary
              : AppColors.textSecondary.withAlpha(140),
        ),
      ),
    );
  }

  Widget _buildConfirmButton() {
    final enabled = _canSubmit;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 60),
      child: GestureDetector(
        onTap: enabled ? _onSubmit : null,
        child: Container(
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: enabled ? AppColors.primary : const Color(0xFFE5E5E5),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Text(
            '确定',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: enabled
                  ? AppColors.textPrimary
                  : AppColors.textSecondary.withAlpha(160),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildKeyboard() {
    return Column(
      children: [
        _buildRow(['7', '8', '9']),
        _buildRow(['4', '5', '6']),
        _buildRow(['1', '2', '3']),
        _buildRow(['.', '0', '⌫']),
      ],
    );
  }

  Widget _buildRow(List<String> keys) {
    return Row(
      children: keys.map((k) => Expanded(child: _buildKey(k))).toList(),
    );
  }

  Widget _buildKey(String label) {
    return GestureDetector(
      onTap: () => _onKey(label),
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color: const Color(0xFFEEEEEE),
            width: 0.5,
          ),
        ),
        child: label == '⌫'
            ? const Icon(
                Icons.backspace_outlined,
                size: 22,
                color: AppColors.textPrimary,
              )
            : Text(
                label,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
      ),
    );
  }
}
