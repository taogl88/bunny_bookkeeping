import 'dart:convert';
import '../db/database_helper.dart';

class BackupService {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<BackupData> exportToJson() async {
    final db = await _dbHelper.database;

    final bills = await db.query('bills', orderBy: 'date DESC');
    final categories = await db.query('categories');
    final budgets = await db.query('budgets');
    final assets = await db.query('assets');
    final assetSnapshots = await db.query('asset_snapshots', orderBy: 'year_month DESC');
    final billSplits = await db.query('bill_splits');

    return BackupData(
      formatVersion: 1,
      source: 'bunny_bookkeeping',
      exportedAt: DateTime.now().toIso8601String(),
      bills: bills,
      categories: categories,
      budgets: budgets,
      assets: assets,
      assetSnapshots: assetSnapshots,
      billSplits: billSplits,
    );
  }

  String toJsonString(BackupData data) {
    return const JsonEncoder.withIndent('  ').convert({
      'formatVersion': data.formatVersion,
      'source': data.source,
      'exportedAt': data.exportedAt,
      'bills': data.bills,
      'categories': data.categories,
      'budgets': data.budgets,
      'assets': data.assets,
      'assetSnapshots': data.assetSnapshots,
      'billSplits': data.billSplits,
    });
  }

  BackupImportResult importFromJson(String jsonStr) {
    try {
      final json = jsonDecode(jsonStr) as Map<String, dynamic>;

      final formatVersion = json['formatVersion'] as int?;
      if (formatVersion == null || formatVersion > 1) {
        return BackupImportResult(
          success: false,
          error: '不支持的数据格式版本: $formatVersion',
        );
      }

      final bills = (json['bills'] as List<dynamic>?) ?? [];
      final categories = (json['categories'] as List<dynamic>?) ?? [];
      final budgets = (json['budgets'] as List<dynamic>?) ?? [];
      final assets = (json['assets'] as List<dynamic>?) ?? [];
      final assetSnapshots = (json['assetSnapshots'] as List<dynamic>?) ?? [];
      final billSplits = (json['billSplits'] as List<dynamic>?) ?? [];

      return BackupImportResult(
        success: true,
        billsCount: bills.length,
        categoriesCount: categories.length,
        budgetsCount: budgets.length,
        assetsCount: assets.length,
        assetSnapshotsCount: assetSnapshots.length,
        billSplitsCount: billSplits.length,
      );
    } catch (e) {
      return BackupImportResult(success: false, error: e.toString());
    }
  }
}

class BackupData {
  final int formatVersion;
  final String source;
  final String exportedAt;
  final List<Map<String, dynamic>> bills;
  final List<Map<String, dynamic>> categories;
  final List<Map<String, dynamic>> budgets;
  final List<Map<String, dynamic>> assets;
  final List<Map<String, dynamic>> assetSnapshots;
  final List<Map<String, dynamic>> billSplits;

  BackupData({
    required this.formatVersion,
    required this.source,
    required this.exportedAt,
    required this.bills,
    required this.categories,
    required this.budgets,
    required this.assets,
    required this.assetSnapshots,
    required this.billSplits,
  });
}

class BackupImportResult {
  final bool success;
  final String? error;
  final int billsCount;
  final int categoriesCount;
  final int budgetsCount;
  final int assetsCount;
  final int assetSnapshotsCount;
  final int billSplitsCount;

  BackupImportResult({
    required this.success,
    this.error,
    this.billsCount = 0,
    this.categoriesCount = 0,
    this.budgetsCount = 0,
    this.assetsCount = 0,
    this.assetSnapshotsCount = 0,
    this.billSplitsCount = 0,
  });
}