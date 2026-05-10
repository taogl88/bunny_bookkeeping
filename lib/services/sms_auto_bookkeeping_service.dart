import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../data/account_data.dart';
import '../db/database_helper.dart';
import '../models/bill_item.dart';

class SmsAutoBookkeepingService {
  static const MethodChannel _channel = MethodChannel('ledger_flutter/sms');
  static const String _logTag = '[LedgerSms][SmsAutoBookkeeping]';

  static bool _isSyncing = false;

  static Future<bool> ensurePermissions() async {
    if (!Platform.isAndroid) return false;
    try {
      debugPrint('$_logTag ensurePermissions start');
      final granted = await _channel.invokeMethod<bool>('ensurePermissions');
      debugPrint('$_logTag ensurePermissions result=${granted ?? false}');
      return granted ?? false;
    } on MissingPluginException {
      debugPrint('$_logTag ensurePermissions missing plugin');
      return false;
    } on PlatformException {
      debugPrint('$_logTag ensurePermissions platform exception');
      return false;
    }
  }

  static Future<SmsSyncResult> syncPendingTransactions() async {
    if (!Platform.isAndroid) {
      debugPrint('$_logTag syncPendingTransactions skipped: non-android');
      return const SmsSyncResult();
    }
    if (_isSyncing) {
      debugPrint('$_logTag syncPendingTransactions skipped: already syncing');
      return const SmsSyncResult();
    }
    _isSyncing = true;
    try {
      debugPrint('$_logTag syncPendingTransactions start');
      final jsonText = await _channel.invokeMethod<String>(
        'getPendingTransactions',
      );
      if (jsonText == null || jsonText.isEmpty) {
        debugPrint('$_logTag syncPendingTransactions empty payload');
        return const SmsSyncResult();
      }
      debugPrint('$_logTag pending payload=$jsonText');
      final decoded = jsonDecode(jsonText);
      if (decoded is! List) {
        debugPrint('$_logTag decoded payload is not list');
        return const SmsSyncResult();
      }

      final reversed = decoded.reversed.toList();
      var insertedCount = 0;
      final insertedMonths = <String>{};
      for (var index = 0; index < reversed.length; index++) {
        final item = reversed[index];
        if (item is! Map) continue;
        final bill = _buildBillItem(Map<String, dynamic>.from(item), index);
        if (bill == null) continue;
        await DatabaseHelper.instance.insertBill(bill);
        insertedMonths.add(bill.date.substring(0, 7));
        debugPrint(
          '$_logTag inserted bill id=${bill.id}, date=${bill.date}, month=${bill.date.substring(0, 7)}, note=${bill.note}',
        );
        insertedCount++;
      }
      debugPrint('$_logTag syncPendingTransactions inserted=$insertedCount');
      return SmsSyncResult(
        insertedCount: insertedCount,
        insertedMonths: insertedMonths.toList()..sort(),
      );
    } on MissingPluginException {
      debugPrint('$_logTag syncPendingTransactions missing plugin');
      return const SmsSyncResult();
    } on PlatformException catch (e) {
      debugPrint(
        '$_logTag syncPendingTransactions platform exception=${e.message}',
      );
      return const SmsSyncResult();
    } on FormatException catch (e) {
      debugPrint('$_logTag syncPendingTransactions format exception=$e');
      return const SmsSyncResult();
    } finally {
      _isSyncing = false;
      debugPrint('$_logTag syncPendingTransactions finish: reset syncing flag');
    }
  }

  static BillItem? _buildBillItem(Map<String, dynamic> tx, int index) {
    final amountValue = tx['amount'];
    final amount = amountValue is num
        ? amountValue.toDouble()
        : double.tryParse(amountValue?.toString() ?? '');
    final type = tx['type']?.toString();
    if (amount == null ||
        amount <= 0 ||
        (type != 'expense' && type != 'income')) {
      debugPrint('$_logTag skip tx amount=$amount, type=$type, raw=$tx');
      return null;
    }
    final normalizedType = type == 'income' ? 'income' : 'expense';

    final category = _resolveCategory(
      normalizedType,
      tx['body']?.toString() ?? '',
    );
    final transactionDate = _resolveTransactionDate(
      tx['dateText']?.toString() ?? '',
      tx['timeText']?.toString() ?? '',
    );
    final now = DateTime.now();
    final nowText = _formatDateTime(now);

    return BillItem(
      id: 'sms_${now.microsecondsSinceEpoch}_$index',
      type: normalizedType,
      amount: amount,
      category: category.name,
      note: tx['note']?.toString() ?? '',
      date: _formatDateTime(transactionDate),
      sortAt: nowText,
      iconId: category.iconId,
      createdAt: nowText,
      updatedAt: nowText,
    );
  }

  static _ResolvedCategory _resolveCategory(String type, String body) {
    if (type == 'income') {
      if (_containsAny(body, const ['工资', '薪资', '代发'])) {
        return _findCategory('工资', type);
      }
      if (_containsAny(body, const ['兼职'])) {
        return _findCategory('兼职', type);
      }
      if (_containsAny(body, const ['利息', '理财', '收益', '分红'])) {
        return _findCategory('理财', type);
      }
      return _findCategory('其他', type);
    }

    if (_containsAny(body, const ['信使费', '短信费', '通讯'])) {
      return _findCategory('通讯', type);
    }
    if (_containsAny(body, const ['地铁', '公交', '高铁', '车票', '打车', '加油'])) {
      return _findCategory('交通', type);
    }
    if (_containsAny(body, const ['早餐', '午餐', '晚餐', '外卖', '餐饮', '饿了么', '美团'])) {
      return _findCategory('餐饮', type);
    }
    if (_containsAny(body, const ['购物', '支付', '消费', '网上支付'])) {
      return _findCategory('购物', type);
    }
    return _findCategory('日用', type);
  }

  static _ResolvedCategory _findCategory(String name, String type) {
    final inEx = type == 'income' ? 1 : 0;
    for (final category in categoryJson) {
      if (category.name == name && category.inEx == inEx) {
        return _ResolvedCategory(name: category.name, iconId: category.icon);
      }
    }
    for (final category in categoryJson) {
      if (category.inEx == inEx) {
        return _ResolvedCategory(name: category.name, iconId: category.icon);
      }
    }
    return const _ResolvedCategory(name: '其他', iconId: 37);
  }

  static bool _containsAny(String source, List<String> keywords) {
    for (final keyword in keywords) {
      if (source.contains(keyword)) {
        return true;
      }
    }
    return false;
  }

  static DateTime _resolveTransactionDate(String dateText, String timeText) {
    final now = DateTime.now();
    final dateMatch = RegExp(r'^(\d{1,2})月(\d{1,2})日$').firstMatch(dateText);
    if (dateMatch == null) {
      return now;
    }

    final month = int.tryParse(dateMatch.group(1) ?? '');
    final day = int.tryParse(dateMatch.group(2) ?? '');
    if (month == null || day == null) {
      return now;
    }

    final timeMatch = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(timeText);
    final hour = int.tryParse(timeMatch?.group(1) ?? '') ?? 0;
    final minute = int.tryParse(timeMatch?.group(2) ?? '') ?? 0;

    var candidate = DateTime(now.year, month, day, hour, minute);
    if (candidate.isAfter(now.add(const Duration(days: 3)))) {
      candidate = DateTime(now.year - 1, month, day, hour, minute);
    }
    return candidate;
  }

  static String _formatDateTime(DateTime dateTime) {
    final month = dateTime.month.toString().padLeft(2, '0');
    final day = dateTime.day.toString().padLeft(2, '0');
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final second = dateTime.second.toString().padLeft(2, '0');
    return '${dateTime.year}-$month-$day $hour:$minute:$second';
  }
}

class _ResolvedCategory {
  final String name;
  final int iconId;

  const _ResolvedCategory({required this.name, required this.iconId});
}

class SmsSyncResult {
  final int insertedCount;
  final List<String> insertedMonths;

  const SmsSyncResult({this.insertedCount = 0, this.insertedMonths = const []});
}
