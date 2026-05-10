import 'package:flutter/material.dart';

/// 格式化金额：有小数显示至多两位，整数不显示小数点
/// 例：50.0 → "50"，50.5 → "50.5"，50.55 → "50.55"，50.556 → "50.56"
String formatAmount(double amount) {
  if (amount == amount.truncateToDouble()) {
    return amount.toInt().toString();
  }
  // 保留两位小数后去掉末尾多余的0
  return amount.toStringAsFixed(2).replaceAll(RegExp(r'0+$'), '');
}

Widget buildAmountText({
  required double value,
  required TextStyle integerStyle,
  TextStyle? decimalStyle,
  TextStyle? signStyle,
  int? maxLines,
  TextOverflow? overflow,
  TextAlign? textAlign,
}) {
  final prefix = value < 0 ? '-' : '';
  final formatted = value.abs().toStringAsFixed(2);
  final parts = formatted.split('.');
  final integerPart = parts[0];
  final decimalPart = parts[1];

  return Text.rich(
    TextSpan(
      children: [
        if (prefix.isNotEmpty)
          TextSpan(
            text: prefix,
            style: signStyle ?? integerStyle,
          ),
        TextSpan(
          text: integerPart,
          style: integerStyle,
        ),
        TextSpan(
          text: '.$decimalPart',
          style: decimalStyle ?? integerStyle,
        ),
      ],
    ),
    maxLines: maxLines,
    overflow: overflow,
    textAlign: textAlign,
  );
}
