import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../data/account_data.dart';
import '../models/asset_account.dart';
import '../models/asset_snapshot.dart';
import '../models/bill_item.dart';
import '../models/bill_split.dart';
import '../models/budget_item.dart';
import '../models/category_entry.dart';
import '../utils/asset_month.dart';

class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'ledger.db');

    return openDatabase(
      path,
      version: 8,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE bills (
            id TEXT PRIMARY KEY,
            type TEXT NOT NULL,
            amount REAL NOT NULL,
            category TEXT NOT NULL,
            note TEXT NOT NULL,
            date TEXT NOT NULL,
            sort_at TEXT NOT NULL,
            icon_id INTEGER NOT NULL DEFAULT 0,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''');
        await _createBillSplitsTable(db);
        await _createBudgetsTable(db);
        await _createSettingsTable(db);
        await _createCategoriesTable(db);
        await _createAssetsTable(db);
        await _createAssetSnapshotsTable(db);
        await _seedDefaultCategories(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute(
            'ALTER TABLE bills ADD COLUMN icon_id INTEGER NOT NULL DEFAULT 0',
          );
        }
        if (oldVersion < 3) {
          await db.execute(
            "ALTER TABLE bills ADD COLUMN sort_at TEXT NOT NULL DEFAULT ''",
          );
          await db.execute("UPDATE bills SET sort_at = date WHERE sort_at = ''");
        }
        if (oldVersion < 4) {
          await _createBudgetsTable(db);
        }
        if (oldVersion < 5) {
          await _createSettingsTable(db);
        }
        if (oldVersion < 6) {
          await _createCategoriesTable(db);
          await _seedDefaultCategories(db);
        }
        if (oldVersion < 7) {
          await _createBillSplitsTable(db);
          await _backfillBillSplits(db);
        }
        if (oldVersion < 8) {
          await _createAssetsTable(db);
          await _createAssetSnapshotsTable(db);
        }
      },
      onOpen: (db) async {
        await _createBillSplitsTable(db);
        await _createAssetsTable(db);
        await _createAssetSnapshotsTable(db);
        await _backfillBillSplits(db);
      },
    );
  }

  Future<void> _createBillSplitsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS bill_splits (
        id TEXT PRIMARY KEY,
        bill_id TEXT NOT NULL,
        category TEXT NOT NULL,
        icon_id INTEGER NOT NULL,
        amount REAL NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_bill_splits_bill
      ON bill_splits(bill_id)
    ''');
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_bill_splits_icon
      ON bill_splits(icon_id)
    ''');
  }

  Future<void> _createBudgetsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS budgets (
        id TEXT PRIMARY KEY,
        period_type TEXT NOT NULL,
        period TEXT NOT NULL,
        is_total INTEGER NOT NULL,
        category TEXT NOT NULL DEFAULT '',
        icon_id INTEGER NOT NULL DEFAULT -1,
        amount REAL NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE UNIQUE INDEX IF NOT EXISTS idx_budgets_unique
      ON budgets(period_type, period, is_total, icon_id)
    ''');
  }

  Future<void> _createSettingsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
  }

  Future<void> _createCategoriesTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        in_ex INTEGER NOT NULL,
        name TEXT NOT NULL,
        icon_id INTEGER NOT NULL,
        is_custom INTEGER NOT NULL DEFAULT 0,
        sort_order INTEGER NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_categories_inex_order
      ON categories(in_ex, sort_order)
    ''');
    await db.execute('''
      CREATE UNIQUE INDEX IF NOT EXISTS idx_categories_inex_name
      ON categories(in_ex, name)
    ''');
  }

  Future<void> _createAssetsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS assets (
        id TEXT PRIMARY KEY,
        type TEXT NOT NULL,
        name TEXT NOT NULL,
        sort_order INTEGER NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE UNIQUE INDEX IF NOT EXISTS idx_assets_type_name
      ON assets(type, name)
    ''');
  }

  Future<void> _createAssetSnapshotsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS asset_snapshots (
        id TEXT PRIMARY KEY,
        asset_id TEXT NOT NULL,
        year_month TEXT NOT NULL,
        balance REAL NOT NULL,
        note TEXT NOT NULL DEFAULT '',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE UNIQUE INDEX IF NOT EXISTS idx_asset_snapshots_unique
      ON asset_snapshots(asset_id, year_month)
    ''');
  }

  Future<void> _seedDefaultCategories(Database db) async {
    final now = DateTime.now().toIso8601String();
    final batch = db.batch();
    final orderByInEx = <int, int>{};
    for (final cat in categoryJson) {
      final order = orderByInEx[cat.inEx] ?? 0;
      orderByInEx[cat.inEx] = order + 1;
      batch.insert(
        'categories',
        {
          'in_ex': cat.inEx,
          'name': cat.name,
          'icon_id': cat.icon,
          'is_custom': 0,
          'sort_order': order,
          'created_at': now,
          'updated_at': now,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<void> _backfillBillSplits(Database db) async {
    final missingRows = await db.rawQuery('''
      SELECT b.id, b.category, b.icon_id, b.amount, b.created_at, b.updated_at
      FROM bills b
      LEFT JOIN bill_splits s ON s.bill_id = b.id
      WHERE s.id IS NULL
    ''');
    if (missingRows.isEmpty) return;

    final batch = db.batch();
    for (final row in missingRows) {
      final billId = row['id'] as String;
      batch.insert(
        'bill_splits',
        {
          'id': 'split_$billId',
          'bill_id': billId,
          'category': row['category'] as String,
          'icon_id': (row['icon_id'] as num).toInt(),
          'amount': (row['amount'] as num).toDouble(),
          'created_at': row['created_at'] as String,
          'updated_at': row['updated_at'] as String,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<void> insertBill(BillItem bill) async {
    await insertBillWithSplits(bill);
  }

  Future<void> insertBillWithSplits(
    BillItem bill, {
    List<BillSplitDraft>? splits,
  }) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.insert(
        'bills',
        bill.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      await _replaceBillSplits(txn, bill, splits);
    });
  }

  Future<List<BillItem>> getAllBills() async {
    final db = await database;
    final rows = await db.query(
      'bills',
      orderBy: "substr(date, 1, 10) DESC, sort_at DESC, date DESC",
    );
    return _attachSplits(db, rows);
  }

  Future<List<BillItem>> getBillsByDateRange(String start, String end) async {
    final db = await database;
    final rows = await db.query(
      'bills',
      where: "substr(date, 1, 10) >= ? AND substr(date, 1, 10) <= ?",
      whereArgs: [start, end],
      orderBy: "substr(date, 1, 10) DESC, sort_at DESC, date DESC",
    );
    return _attachSplits(db, rows);
  }

  Future<List<BillItem>> getBillsByMonth(String yearMonth) async {
    final db = await database;
    final rows = await db.query(
      'bills',
      where: "date LIKE ?",
      whereArgs: ['$yearMonth%'],
      orderBy: "substr(date, 1, 10) DESC, sort_at DESC, date DESC",
    );
    return _attachSplits(db, rows);
  }

  Future<BillItem?> getBillById(String id) async {
    final db = await database;
    final rows = await db.query('bills', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    final items = await _attachSplits(db, rows);
    return items.first;
  }

  Future<int> updateBill(BillItem bill) async {
    return updateBillWithSplits(bill);
  }

  Future<int> updateBillWithSplits(
    BillItem bill, {
    List<BillSplitDraft>? splits,
  }) async {
    final db = await database;
    var affected = 0;
    await db.transaction((txn) async {
      affected = await txn.update(
        'bills',
        bill.toMap(),
        where: 'id = ?',
        whereArgs: [bill.id],
      );
      await _replaceBillSplits(txn, bill, splits);
    });
    return affected;
  }

  Future<int> deleteBill(String id) async {
    final db = await database;
    return db.transaction((txn) async {
      await txn.delete('bill_splits', where: 'bill_id = ?', whereArgs: [id]);
      return txn.delete('bills', where: 'id = ?', whereArgs: [id]);
    });
  }

  Future<double> getMonthlyIncome(String yearMonth) async {
    final db = await database;
    final result = await db.rawQuery(
      "SELECT COALESCE(SUM(amount), 0) as total FROM bills WHERE type = 'income' AND date LIKE ?",
      ['$yearMonth%'],
    );
    return (result.first['total'] as num).toDouble();
  }

  Future<double> getMonthlyExpense(String yearMonth) async {
    final db = await database;
    final result = await db.rawQuery(
      "SELECT COALESCE(SUM(amount), 0) as total FROM bills WHERE type = 'expense' AND date LIKE ?",
      ['$yearMonth%'],
    );
    return (result.first['total'] as num).toDouble();
  }

  Future<List<BillItem>> getBillsByYear(String year) async {
    final db = await database;
    final rows = await db.query(
      'bills',
      where: "date LIKE ?",
      whereArgs: ['$year%'],
      orderBy: "substr(date, 1, 10) DESC, sort_at DESC, date DESC",
    );
    return _attachSplits(db, rows);
  }

  Future<double> getYearlyIncome(String year) async {
    final db = await database;
    final result = await db.rawQuery(
      "SELECT COALESCE(SUM(amount), 0) as total FROM bills WHERE type = 'income' AND date LIKE ?",
      ['$year%'],
    );
    return (result.first['total'] as num).toDouble();
  }

  Future<double> getYearlyExpense(String year) async {
    final db = await database;
    final result = await db.rawQuery(
      "SELECT COALESCE(SUM(amount), 0) as total FROM bills WHERE type = 'expense' AND date LIKE ?",
      ['$year%'],
    );
    return (result.first['total'] as num).toDouble();
  }

  Future<Map<int, double>> getExpenseGroupByIconId(String datePrefix) async {
    final db = await database;
    final rows = await db.rawQuery(
      '''
      SELECT s.icon_id, COALESCE(SUM(s.amount), 0) AS total
      FROM bill_splits s
      INNER JOIN bills b ON b.id = s.bill_id
      WHERE b.type = 'expense' AND b.date LIKE ?
      GROUP BY s.icon_id
      ''',
      ['$datePrefix%'],
    );
    final result = <int, double>{};
    for (final row in rows) {
      result[(row['icon_id'] as num).toInt()] =
          (row['total'] as num).toDouble();
    }
    return result;
  }

  Future<void> insertOrReplaceBudget(BudgetItem budget) async {
    final db = await database;
    await db.insert(
      'budgets',
      budget.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<BudgetItem>> getBudgets({
    required String periodType,
    required String period,
  }) async {
    final db = await database;
    final rows = await db.query(
      'budgets',
      where: 'period_type = ? AND period = ?',
      whereArgs: [periodType, period],
    );
    return rows.map((r) => BudgetItem.fromMap(r)).toList();
  }

  Future<int> deleteBudget(String id) async {
    final db = await database;
    return db.delete('budgets', where: 'id = ?', whereArgs: [id]);
  }

  Future<String?> getSetting(String key) async {
    final db = await database;
    final rows = await db.query(
      'settings',
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first['value'] as String?;
  }

  Future<void> setSetting(String key, String value) async {
    final db = await database;
    await db.insert(
      'settings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> getTotalBillCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as cnt FROM bills');
    return (result.first['cnt'] as int?) ?? 0;
  }

  Future<List<String>> getDistinctBillDates() async {
    final db = await database;
    final rows = await db.rawQuery(
      "SELECT DISTINCT substr(date, 1, 10) AS d FROM bills ORDER BY d ASC",
    );
    return [
      for (final row in rows)
        if (row['d'] != null) row['d'] as String,
    ];
  }

  Future<Map<int, int>> getBillCountGroupByIconId() async {
    final db = await database;
    final rows = await db.rawQuery(
      '''
      SELECT s.icon_id, COUNT(*) AS cnt
      FROM bill_splits s
      GROUP BY s.icon_id
      ''',
    );
    final result = <int, int>{};
    for (final row in rows) {
      result[(row['icon_id'] as num).toInt()] = (row['cnt'] as int?) ?? 0;
    }
    return result;
  }

  Future<List<String>> getNoteSuggestions({int? iconId}) async {
    final db = await database;
    String sql;
    List<Object?> args;

    if (iconId != null) {
      sql = '''
        SELECT b.note, COUNT(*) AS cnt
        FROM bills b
        INNER JOIN bill_splits s ON b.id = s.bill_id
        WHERE b.note IS NOT NULL AND b.note != '' AND s.icon_id = ?
        GROUP BY b.note
        ORDER BY cnt DESC
        LIMIT 20
      ''';
      args = [iconId];
    } else {
      sql = '''
        SELECT b.note, COUNT(*) AS cnt
        FROM bills b
        WHERE b.note IS NOT NULL AND b.note != ''
        GROUP BY b.note
        ORDER BY cnt DESC
        LIMIT 20
      ''';
      args = [];
    }

    final rows = await db.rawQuery(sql, args);
    return [
      for (final row in rows)
        if (row['note'] != null && (row['note'] as String).isNotEmpty)
          row['note'] as String,
    ];
  }

  Future<Map<String, List<BillSplit>>> getBillSplitsByBillIds(
    List<String> billIds,
  ) async {
    if (billIds.isEmpty) return {};
    final db = await database;
    final placeholders = List.filled(billIds.length, '?').join(', ');
    final rows = await db.rawQuery(
      '''
      SELECT * FROM bill_splits
      WHERE bill_id IN ($placeholders)
      ORDER BY created_at ASC, id ASC
      ''',
      billIds,
    );
    final result = <String, List<BillSplit>>{};
    for (final row in rows) {
      final split = BillSplit.fromMap(row);
      result.putIfAbsent(split.billId, () => []).add(split);
    }
    return result;
  }

  Future<List<CategoryEntry>> getAllCategories() async {
    final db = await database;
    final rows = await db.query(
      'categories',
      orderBy: 'in_ex ASC, sort_order ASC, id ASC',
    );
    return rows.map(CategoryEntry.fromMap).toList();
  }

  Future<bool> hasCategoryWithName({
    required int inEx,
    required String name,
    int? excludeId,
  }) async {
    final db = await database;
    final args = <Object?>[inEx, name];
    var where = 'in_ex = ? AND name = ?';
    if (excludeId != null) {
      where += ' AND id != ?';
      args.add(excludeId);
    }
    final rows = await db.query(
      'categories',
      where: where,
      whereArgs: args,
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  Future<int> insertCategory({
    required int inEx,
    required String name,
    required int iconId,
    required bool isCustom,
  }) async {
    final db = await database;
    final maxRow = await db.rawQuery(
      'SELECT COALESCE(MAX(sort_order), -1) AS max_order FROM categories WHERE in_ex = ?',
      [inEx],
    );
    final nextOrder = ((maxRow.first['max_order'] as num?)?.toInt() ?? -1) + 1;
    final now = DateTime.now().toIso8601String();
    return db.insert('categories', {
      'in_ex': inEx,
      'name': name,
      'icon_id': iconId,
      'is_custom': isCustom ? 1 : 0,
      'sort_order': nextOrder,
      'created_at': now,
      'updated_at': now,
    });
  }

  Future<int> updateCategoryBasic({
    required int id,
    required String name,
    required int iconId,
  }) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    return db.update(
      'categories',
      {'name': name, 'icon_id': iconId, 'updated_at': now},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteCategory(int id) async {
    final db = await database;
    return db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> reorderCategories({
    required int inEx,
    required List<int> orderedIds,
  }) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    final batch = db.batch();
    for (var i = 0; i < orderedIds.length; i++) {
      batch.update(
        'categories',
        {'sort_order': i, 'updated_at': now},
        where: 'id = ? AND in_ex = ?',
        whereArgs: [orderedIds[i], inEx],
      );
    }
    await batch.commit(noResult: true);
  }

  Future<int> updateBillsCategoryRename({
    required String type,
    required String oldName,
    required String newName,
    required int newIconId,
  }) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    return db.transaction((txn) async {
      final affected = await txn.update(
        'bills',
        {'category': newName, 'icon_id': newIconId, 'updated_at': now},
        where: 'type = ? AND category = ?',
        whereArgs: [type, oldName],
      );
      await txn.update(
        'bill_splits',
        {'category': newName, 'icon_id': newIconId, 'updated_at': now},
        where: 'category = ?',
        whereArgs: [oldName],
      );
      return affected;
    });
  }

  Future<int> deleteBillsByTypeAndCategory({
    required String type,
    required String category,
  }) async {
    final db = await database;
    final rows = await db.query(
      'bills',
      columns: ['id'],
      where: 'type = ? AND category = ?',
      whereArgs: [type, category],
    );
    final billIds = [for (final row in rows) row['id'] as String];
    return db.transaction((txn) async {
      if (billIds.isNotEmpty) {
        final placeholders = List.filled(billIds.length, '?').join(', ');
        await txn.rawDelete(
          'DELETE FROM bill_splits WHERE bill_id IN ($placeholders)',
          billIds,
        );
      }
      return txn.delete(
        'bills',
        where: 'type = ? AND category = ?',
        whereArgs: [type, category],
      );
    });
  }

  Future<int> transferBillsCategory({
    required String type,
    required String fromCategory,
    required String toCategory,
    required int toIconId,
  }) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    return db.transaction((txn) async {
      final affected = await txn.update(
        'bills',
        {'category': toCategory, 'icon_id': toIconId, 'updated_at': now},
        where: 'type = ? AND category = ?',
        whereArgs: [type, fromCategory],
      );
      await txn.update(
        'bill_splits',
        {'category': toCategory, 'icon_id': toIconId, 'updated_at': now},
        where: 'category = ?',
        whereArgs: [fromCategory],
      );
      return affected;
    });
  }

  Future<List<AssetAccount>> getAssets() async {
    final db = await database;
    final rows = await db.query(
      'assets',
      orderBy: 'sort_order ASC, created_at ASC',
    );
    return rows.map(AssetAccount.fromMap).toList();
  }

  Future<void> insertAsset(AssetAccount asset) async {
    final db = await database;
    await db.insert('assets', asset.toMap());
  }

  Future<void> deleteAsset(String id) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('asset_snapshots', where: 'asset_id = ?', whereArgs: [id]);
      await txn.delete('assets', where: 'id = ?', whereArgs: [id]);
    });
  }

  Future<void> saveAssetSnapshot(AssetSnapshot snapshot) async {
    final db = await database;
    final normalizedMonth = normalizeAssetYearMonth(snapshot.yearMonth);
    if (normalizedMonth == null) {
      throw const FormatException('invalid_year_month');
    }
    await db.insert(
      'asset_snapshots',
      {
        ...snapshot.toMap(),
        'id': '${snapshot.assetId}_$normalizedMonth',
        'year_month': normalizedMonth,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<AssetSnapshot>> getAssetSnapshots() async {
    final db = await database;
    final rows = await db.query(
      'asset_snapshots',
      orderBy: 'year_month ASC, created_at ASC',
    );
    return rows.map(AssetSnapshot.fromMap).toList();
  }

  Future<List<AssetSnapshot>> getAssetSnapshotsByMonth(String yearMonth) async {
    final db = await database;
    final rows = await db.query(
      'asset_snapshots',
      where: 'year_month = ?',
      whereArgs: [yearMonth],
      orderBy: 'created_at ASC',
    );
    return rows.map(AssetSnapshot.fromMap).toList();
  }

  Future<List<BillItem>> _attachSplits(
    Database db,
    List<Map<String, Object?>> rows,
  ) async {
    final bills = rows.map(BillItem.fromMap).toList();
    if (bills.isEmpty) return bills;
    final splitMap = await getBillSplitsByBillIds([for (final bill in bills) bill.id]);
    return [
      for (final bill in bills)
        bill.copyWith(splits: splitMap[bill.id] ?? const []),
    ];
  }

  Future<void> _replaceBillSplits(
    Transaction txn,
    BillItem bill,
    List<BillSplitDraft>? splits,
  ) async {
    await txn.delete('bill_splits', where: 'bill_id = ?', whereArgs: [bill.id]);
    final targetSplits = _normalizeSplits(bill, splits);
    for (var i = 0; i < targetSplits.length; i++) {
      final split = targetSplits[i];
      await txn.insert('bill_splits', {
        'id': 'split_${bill.id}_$i',
        'bill_id': bill.id,
        'category': split.category,
        'icon_id': split.iconId,
        'amount': split.amount,
        'created_at': bill.createdAt,
        'updated_at': bill.updatedAt,
      });
    }
  }

  List<BillSplitDraft> _normalizeSplits(
    BillItem bill,
    List<BillSplitDraft>? splits,
  ) {
    final filtered = splits
        ?.where((item) => item.amount > 0)
        .toList(growable: false);
    if (filtered == null || filtered.isEmpty) {
      return [
        BillSplitDraft(
          category: bill.category,
          iconId: bill.iconId,
          amount: bill.amount,
        ),
      ];
    }
    return filtered;
  }
}
