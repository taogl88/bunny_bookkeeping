import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../data/account_data.dart';
import '../models/bill_item.dart';
import '../models/budget_item.dart';
import '../models/category_entry.dart';

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
      version: 6,
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
        await _createBudgetsTable(db);
        await _createSettingsTable(db);
        await _createCategoriesTable(db);
        await _seedDefaultCategories(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE bills ADD COLUMN icon_id INTEGER NOT NULL DEFAULT 0');
        }
        if (oldVersion < 3) {
          await db.execute("ALTER TABLE bills ADD COLUMN sort_at TEXT NOT NULL DEFAULT ''");
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
      },
    );
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

  /// 把 [categoryJson] 中的默认类别写入 categories 表，作为初始数据。
  /// 同一 in_ex 内按 [categoryJson] 出现顺序作为 sort_order。
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

  /// 插入一条账单
  Future<void> insertBill(BillItem bill) async {
    final db = await database;
    await db.insert('bills', bill.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// 查询所有账单，按日期倒序
  Future<List<BillItem>> getAllBills() async {
    final db = await database;
    final rows = await db.query(
      'bills',
      orderBy: "substr(date, 1, 10) DESC, sort_at DESC, date DESC",
    );
    return rows.map((r) => BillItem.fromMap(r)).toList();
  }

  /// 按日期范围查询账单 (start/end 格式: "2026-03-01")
  Future<List<BillItem>> getBillsByDateRange(String start, String end) async {
    final db = await database;
    final rows = await db.query(
      'bills',
      where: "substr(date, 1, 10) >= ? AND substr(date, 1, 10) <= ?",
      whereArgs: [start, end],
      orderBy: "substr(date, 1, 10) DESC, sort_at DESC, date DESC",
    );
    return rows.map((r) => BillItem.fromMap(r)).toList();
  }

  /// 按月查询账单 (yearMonth 格式: "2026-03")
  Future<List<BillItem>> getBillsByMonth(String yearMonth) async {
    final db = await database;
    final rows = await db.query(
      'bills',
      where: "date LIKE ?",
      whereArgs: ['$yearMonth%'],
      orderBy: "substr(date, 1, 10) DESC, sort_at DESC, date DESC",
    );
    return rows.map((r) => BillItem.fromMap(r)).toList();
  }

  /// 根据 id 查询单条账单
  Future<BillItem?> getBillById(String id) async {
    final db = await database;
    final rows = await db.query('bills', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return BillItem.fromMap(rows.first);
  }

  /// 更新账单
  Future<int> updateBill(BillItem bill) async {
    final db = await database;
    return db.update('bills', bill.toMap(),
        where: 'id = ?', whereArgs: [bill.id]);
  }

  /// 删除账单
  Future<int> deleteBill(String id) async {
    final db = await database;
    return db.delete('bills', where: 'id = ?', whereArgs: [id]);
  }

  /// 查询某月收入总额
  Future<double> getMonthlyIncome(String yearMonth) async {
    final db = await database;
    final result = await db.rawQuery(
      "SELECT COALESCE(SUM(amount), 0) as total FROM bills WHERE type = 'income' AND date LIKE ?",
      ['$yearMonth%'],
    );
    return (result.first['total'] as num).toDouble();
  }

  /// 查询某月支出总额
  Future<double> getMonthlyExpense(String yearMonth) async {
    final db = await database;
    final result = await db.rawQuery(
      "SELECT COALESCE(SUM(amount), 0) as total FROM bills WHERE type = 'expense' AND date LIKE ?",
      ['$yearMonth%'],
    );
    return (result.first['total'] as num).toDouble();
  }

  /// 按年查询账单 (year 格式: "2026")
  Future<List<BillItem>> getBillsByYear(String year) async {
    final db = await database;
    final rows = await db.query(
      'bills',
      where: "date LIKE ?",
      whereArgs: ['$year%'],
      orderBy: "substr(date, 1, 10) DESC, sort_at DESC, date DESC",
    );
    return rows.map((r) => BillItem.fromMap(r)).toList();
  }

  /// 查询某年收入总额
  Future<double> getYearlyIncome(String year) async {
    final db = await database;
    final result = await db.rawQuery(
      "SELECT COALESCE(SUM(amount), 0) as total FROM bills WHERE type = 'income' AND date LIKE ?",
      ['$year%'],
    );
    return (result.first['total'] as num).toDouble();
  }

  /// 查询某年支出总额
  Future<double> getYearlyExpense(String year) async {
    final db = await database;
    final result = await db.rawQuery(
      "SELECT COALESCE(SUM(amount), 0) as total FROM bills WHERE type = 'expense' AND date LIKE ?",
      ['$year%'],
    );
    return (result.first['total'] as num).toDouble();
  }

  /// 按分类（icon_id）分组的支出汇总
  ///
  /// [datePrefix] 为日期前缀，月份传 'YYYY-MM'，年度传 'YYYY'
  /// 返回 `Map<icon_id, 支出总额>`
  Future<Map<int, double>> getExpenseGroupByIconId(String datePrefix) async {
    final db = await database;
    final rows = await db.rawQuery(
      "SELECT icon_id, COALESCE(SUM(amount), 0) as total FROM bills "
      "WHERE type = 'expense' AND date LIKE ? GROUP BY icon_id",
      ['$datePrefix%'],
    );
    final result = <int, double>{};
    for (final row in rows) {
      result[row['icon_id'] as int] = (row['total'] as num).toDouble();
    }
    return result;
  }

  /// 写入或替换一条预算记录
  Future<void> insertOrReplaceBudget(BudgetItem budget) async {
    final db = await database;
    await db.insert(
      'budgets',
      budget.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// 查询某 period 下的所有预算（包括总预算与分类预算）
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

  /// 删除一条预算记录
  Future<int> deleteBudget(String id) async {
    final db = await database;
    return db.delete('budgets', where: 'id = ?', whereArgs: [id]);
  }

  /// 读取一条本地设置；不存在返回 null
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

  /// 写入一条本地设置（已存在则覆盖）
  Future<void> setSetting(String key, String value) async {
    final db = await database;
    await db.insert(
      'settings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// 账单总条数
  Future<int> getTotalBillCount() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as cnt FROM bills',
    );
    return (result.first['cnt'] as int?) ?? 0;
  }

  /// 所有账单 distinct 的 yyyy-MM-dd 日期，按升序
  Future<List<String>> getDistinctBillDates() async {
    final db = await database;
    final rows = await db.rawQuery(
      "SELECT DISTINCT substr(date, 1, 10) AS d FROM bills "
      "ORDER BY d ASC",
    );
    return [
      for (final row in rows)
        if (row['d'] != null) row['d'] as String,
    ];
  }

  /// 各 icon_id 对应的账单笔数（不区分收支），用于徽章成就判定。
  /// 返回 `Map<icon_id, 笔数>`
  Future<Map<int, int>> getBillCountGroupByIconId() async {
    final db = await database;
    final rows = await db.rawQuery(
      'SELECT icon_id, COUNT(*) AS cnt FROM bills GROUP BY icon_id',
    );
    final result = <int, int>{};
    for (final row in rows) {
      result[row['icon_id'] as int] = (row['cnt'] as int?) ?? 0;
    }
    return result;
  }

  // ============================ categories ============================

  /// 全量类别，按 (in_ex, sort_order) 升序。
  Future<List<CategoryEntry>> getAllCategories() async {
    final db = await database;
    final rows = await db.query(
      'categories',
      orderBy: 'in_ex ASC, sort_order ASC, id ASC',
    );
    return rows.map(CategoryEntry.fromMap).toList();
  }

  /// 根据 (in_ex, name) 唯一索引检查是否已经存在；
  /// [excludeId] 用于编辑场景下排除自己。
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

  /// 插入新类别（一般是自定义类别），自动放在该 in_ex 列表末尾。
  /// 返回新类别的 id。
  Future<int> insertCategory({
    required int inEx,
    required String name,
    required int iconId,
    required bool isCustom,
  }) async {
    final db = await database;
    final maxRow = await db.rawQuery(
      'SELECT COALESCE(MAX(sort_order), -1) AS max_order '
      'FROM categories WHERE in_ex = ?',
      [inEx],
    );
    final nextOrder =
        ((maxRow.first['max_order'] as num?)?.toInt() ?? -1) + 1;
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

  /// 更新类别基础字段（name / icon_id）。
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

  /// 删除类别（仅删 categories 行，不动 bills）。
  Future<int> deleteCategory(int id) async {
    final db = await database;
    return db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }

  /// 按当前列表顺序写入 sort_order，仅更新该 inEx 下的类别。
  ///
  /// [orderedIds] 必须是该 inEx 下完整且不重复的 id 序列。
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

  /// 更新该 (type, oldName) 下所有账单的分类名 / 图标，用于"编辑分类"
  /// 时同步带过去。
  Future<int> updateBillsCategoryRename({
    required String type,
    required String oldName,
    required String newName,
    required int newIconId,
  }) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    return db.update(
      'bills',
      {'category': newName, 'icon_id': newIconId, 'updated_at': now},
      where: 'type = ? AND category = ?',
      whereArgs: [type, oldName],
    );
  }

  /// 删除某分类下的全部账单（用于"仍然删除"分支）。
  Future<int> deleteBillsByTypeAndCategory({
    required String type,
    required String category,
  }) async {
    final db = await database;
    return db.delete(
      'bills',
      where: 'type = ? AND category = ?',
      whereArgs: [type, category],
    );
  }

  /// 把 (type, fromCategory) 的账单批量转移到 (toCategory, toIconId)。
  /// 用于"转移数据"分支。
  Future<int> transferBillsCategory({
    required String type,
    required String fromCategory,
    required String toCategory,
    required int toIconId,
  }) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    return db.update(
      'bills',
      {'category': toCategory, 'icon_id': toIconId, 'updated_at': now},
      where: 'type = ? AND category = ?',
      whereArgs: [type, fromCategory],
    );
  }
}
