import 'dart:convert';

import '../data/account_data.dart';
import '../db/database_helper.dart';
import '../models/bill_item.dart';

/// myapp 导出的 JSON 中单条记录的结构
class _ImportedRecord {
  final String type;
  final double amount;
  final String category;
  final String note;
  final String date;
  final int iconId;

  const _ImportedRecord({
    required this.type,
    required this.amount,
    required this.category,
    required this.note,
    required this.date,
    required this.iconId,
  });

  factory _ImportedRecord.fromJson(Map<String, dynamic> json) {
    return _ImportedRecord(
      type: (json['type'] as String?) ?? 'expense',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      category: (json['category'] as String?) ?? '其他',
      note: (json['note'] as String?) ?? '',
      date: (json['date'] as String?) ?? '',
      iconId: (json['iconId'] as int?) ?? -1,
    );
  }
}

/// myapp 导出的 JSON 中分类的结构
class _ImportedCategory {
  final String name;
  final String icon;

  const _ImportedCategory({required this.name, required this.icon});
}

/// myapp 导出的 JSON 整体结构
class _ImportData {
  final int formatVersion;
  final String source;
  final String exportedAt;
  final List<_ImportedRecord> records;
  final Map<String, List<_ImportedCategory>> categories;

  const _ImportData({
    required this.formatVersion,
    required this.source,
    required this.exportedAt,
    required this.records,
    required this.categories,
  });

  factory _ImportData.fromJson(Map<String, dynamic> json) {
    final recordsRaw = (json['records'] as List<dynamic>?) ?? [];
    final catsRaw = (json['categories'] as Map<String, dynamic>?) ?? {};

    final expenseCats =
        (catsRaw['expense'] as List<dynamic>?)
            ?.map(
              (c) => _ImportedCategory(
                name: (c['name'] as String?) ?? '',
                icon: (c['icon'] as String?) ?? '',
              ),
            )
            .toList() ??
        [];
    final incomeCats =
        (catsRaw['income'] as List<dynamic>?)
            ?.map(
              (c) => _ImportedCategory(
                name: (c['name'] as String?) ?? '',
                icon: (c['icon'] as String?) ?? '',
              ),
            )
            .toList() ??
        [];

    return _ImportData(
      formatVersion: (json['formatVersion'] as int?) ?? 1,
      source: (json['source'] as String?) ?? 'unknown',
      exportedAt: (json['exportedAt'] as String?) ?? '',
      records: recordsRaw
          .map((r) => _ImportedRecord.fromJson(r as Map<String, dynamic>))
          .toList(),
      categories: {'expense': expenseCats, 'income': incomeCats},
    );
  }
}

/// 导入结果
class ImportResult {
  final int totalRecords;
  final int insertedBills;
  final int skippedBills;
  final int importedCategories;

  const ImportResult({
    required this.totalRecords,
    required this.insertedBills,
    required this.skippedBills,
    required this.importedCategories,
  });

  int get merged => insertedBills;
  int get skipped => skippedBills;
}

/// CSV 导入预览信息
class CsvImportPreview {
  final int recordCount;
  final int expenseCount;
  final int incomeCount;
  final List<String> headers;
  final List<List<String>> rows;

  const CsvImportPreview({
    required this.recordCount,
    required this.expenseCount,
    required this.incomeCount,
    required this.headers,
    required this.rows,
  });
}

/// CSV 单行记录
class _CsvRecord {
  final String type;
  final double amount;
  final String category;
  final String note;
  final String date;

  const _CsvRecord({
    required this.type,
    required this.amount,
    required this.category,
    required this.note,
    required this.date,
  });
}

/// 数据导入服务 —— 解析 myapp 导出的 JSON 并写入 ledger_flutter 数据库
/// 同时支持 CSV 导入
class ImportService {
  final DatabaseHelper _db = DatabaseHelper.instance;

  /// 解析 CSV 字符串，返回预览信息
  CsvImportPreview previewFromCsv(String csvString) {
    final lines = _parseCsvLines(csvString);
    if (lines.isEmpty) {
      return const CsvImportPreview(
        recordCount: 0,
        expenseCount: 0,
        incomeCount: 0,
        headers: [],
        rows: [],
      );
    }

    final headers = lines.first.map(_normalizeHeader).toList();
    final rows = lines.skip(1).where((row) => !_isEmptyRow(row)).toList();

    int expenseCount = 0;
    int incomeCount = 0;
    for (final row in rows) {
      final typeRaw = _getFieldByAliases(row, headers, _typeFieldAliases);
      final type = _normalizeType(typeRaw);
      if (type == 'expense') {
        expenseCount++;
      } else {
        incomeCount++;
      }
    }

    return CsvImportPreview(
      recordCount: rows.length,
      expenseCount: expenseCount,
      incomeCount: incomeCount,
      headers: headers,
      rows: rows,
    );
  }

  /// 执行 CSV 导入
  Future<ImportResult> importFromCsv(String csvString) async {
    final lines = _parseCsvLines(csvString);
    if (lines.isEmpty) {
      return const ImportResult(
        totalRecords: 0,
        insertedBills: 0,
        skippedBills: 0,
        importedCategories: 0,
      );
    }

    final headers = lines.first.map(_normalizeHeader).toList();
    final records = <_CsvRecord>[];

    for (final line in lines.skip(1)) {
      if (_isEmptyRow(line)) continue;

      // 支持中英文字段名，并兼容常见导出表头。
      final typeRaw = _getFieldByAliases(line, headers, _typeFieldAliases);
      final type = _normalizeType(typeRaw);
      final amountStr = _getFieldByAliases(line, headers, _amountFieldAliases);
      final date = _getFieldByAliases(line, headers, _dateFieldAliases);
      final category = _getFieldByAliases(
        line,
        headers,
        _categoryFieldAliases,
      );
      final note = _getFieldByAliases(line, headers, _noteFieldAliases);

      final amount = _parseAmount(amountStr) ?? 0;
      if (amount <= 0) continue;

      records.add(_CsvRecord(
        type: type,
        amount: amount,
        date: _parseDate(date),
        category: category.isEmpty ? '其他' : category,
        note: note,
      ));
    }

    int insertedBills = 0;
    int skippedBills = 0;

    // 获取已有分类
    final existingCategories = await _db.getAllCategories();
    final categoryIconByKey = <String, int>{
      for (final category in existingCategories)
        '${category.inEx}_${category.name}': category.iconId,
    };

    // 获取已有账单
    final allBills = await _db.getAllBills();
    final existingBillSignatures = allBills
        .map((b) => '${b.date}_${b.amount}_${b.category}')
        .toSet();

    final now = DateTime.now().toIso8601String();

    for (final record in records) {
      // 生成签名用于去重
      final signature = '${record.date}_${record.amount}_${record.category}';
      if (existingBillSignatures.contains(signature)) {
        skippedBills++;
        continue;
      }

      final inEx = record.type == 'income' ? 1 : 0;
      final iconId = categoryIconByKey['${inEx}_${record.category}'] ?? 0;

      final bill = BillItem(
        id: 'csv_${DateTime.now().millisecondsSinceEpoch}_$insertedBills',
        type: record.type,
        amount: record.amount,
        category: record.category,
        note: record.note,
        date: record.date,
        sortAt: record.date,
        iconId: iconId,
        createdAt: now,
        updatedAt: now,
      );

      await _db.insertBill(bill);
      insertedBills++;
      existingBillSignatures.add(signature);
    }

    return ImportResult(
      totalRecords: records.length,
      insertedBills: insertedBills,
      skippedBills: skippedBills,
      importedCategories: 0,
    );
  }

  String _normalizeType(String type) {
    final t = type.toLowerCase().trim();
    if (t == 'income' || t == '收入' || t == 'in' || t == '1') return 'income';
    if (t == '支出') return 'expense';
    return 'expense';
  }

  String _parseDate(String date) {
    // 尝试多种日期格式
    final trimmed = date.trim();
    if (trimmed.isEmpty) {
      return _currentDateString();
    }

    // YYYY年MM月DD日（鲨鱼记账格式）
    if (RegExp(r'^\d{4}年\d{1,2}月\d{1,2}日$').hasMatch(trimmed)) {
      final match = RegExp(r'^(\d{4})年(\d{1,2})月(\d{1,2})日$').firstMatch(trimmed);
      if (match != null) {
        return '${match.group(1)}-${match.group(2)!.padLeft(2, '0')}-${match.group(3)!.padLeft(2, '0')}';
      }
    }

    // YYYY-MM-DD
    if (RegExp(r'^\d{4}-\d{1,2}-\d{1,2}$').hasMatch(trimmed)) {
      final parts = trimmed.split('-');
      return '${parts[0]}-${parts[1].padLeft(2, '0')}-${parts[2].padLeft(2, '0')}';
    }

    // YYYY/MM/DD
    if (RegExp(r'^\d{4}/\d{1,2}/\d{1,2}$').hasMatch(trimmed)) {
      final parts = trimmed.split('/');
      return '${parts[0]}-${parts[1].padLeft(2, '0')}-${parts[2].padLeft(2, '0')}';
    }

    // YYYYMMDD
    if (RegExp(r'^\d{8}$').hasMatch(trimmed)) {
      return '${trimmed.substring(0, 4)}-${trimmed.substring(4, 6)}-${trimmed.substring(6, 8)}';
    }

    // 尝试直接解析
    try {
      final dt = DateTime.parse(trimmed);
      return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
    } catch (_) {
      return _currentDateString();
    }
  }

  List<List<String>> _parseCsvLines(String csvString) {
    final normalized = csvString
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .trim();
    if (normalized.isEmpty) {
      return const [];
    }
    final lines = normalized.split('\n');
    return lines.map((line) => _parseCsvLine(line)).toList();
  }

  List<String> _parseCsvLine(String line) {
    final result = <String>[];
    var current = '';
    var inQuotes = false;

    for (var i = 0; i < line.length; i++) {
      final char = line[i];
      if (char == '"') {
        if (inQuotes && i + 1 < line.length && line[i + 1] == '"') {
          current += '"';
          i++;
        } else {
          inQuotes = !inQuotes;
        }
      } else if (char == ',' && !inQuotes) {
        result.add(current.trim());
        current = '';
      } else {
        current += char;
      }
    }
    result.add(current.trim());
    return result;
  }

  bool _isEmptyRow(List<String> row) {
    return row.isEmpty || row.every((e) => e.trim().isEmpty);
  }

  String _normalizeHeader(String header) {
    return header.replaceFirst('\uFEFF', '').trim().toLowerCase();
  }

  String _getFieldByAliases(
    List<String> row,
    List<String> headers,
    List<String> fieldNames,
  ) {
    for (final fieldName in fieldNames) {
      final value = _getField(row, headers, fieldName);
      if (value.isNotEmpty) {
        return value;
      }
    }
    return '';
  }

  String _getField(List<String> row, List<String> headers, String fieldName) {
    final index = headers.indexOf(_normalizeHeader(fieldName));
    if (index < 0 || index >= row.length) return '';
    return row[index];
  }

  double? _parseAmount(String amount) {
    final normalized = amount
        .replaceAll(',', '')
        .replaceAll('¥', '')
        .replaceAll('￥', '')
        .replaceAll(RegExp(r'\s+'), '')
        .trim();
    if (normalized.isEmpty) {
      return null;
    }
    return double.tryParse(normalized);
  }

  String _currentDateString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  static const List<String> _typeFieldAliases = ['type', '收支类型', '类型'];
  static const List<String> _amountFieldAliases = ['amount', '金额', 'money'];
  static const List<String> _dateFieldAliases = ['date', '日期', '时间'];
  static const List<String> _categoryFieldAliases = [
    'category',
    '类别',
    '分类',
    '标签',
  ];
  static const List<String> _noteFieldAliases = ['note', '备注', '说明', '描述'];

  /// 解析 JSON 字符串
  _ImportData _parseJson(String jsonString) {
    final map = jsonDecode(jsonString) as Map<String, dynamic>;
    return _ImportData.fromJson(map);
  }

  /// 执行导入
  Future<ImportResult> importFromJson(String jsonString) async {
    final data = _parseJson(jsonString);

    int insertedBills = 0;
    int skippedBills = 0;

    // 1. 导入分类（仅导入本地不存在的分类）
    final existingCategories = await _db.getAllCategories();
    final existingNames = existingCategories
        .map((c) => '${c.inEx}_${c.name}')
        .toSet();
    final usedIconsByInEx = <int, Set<int>>{
      0: {
        for (final category in existingCategories)
          if (category.inEx == 0) category.iconId,
      },
      1: {
        for (final category in existingCategories)
          if (category.inEx == 1) category.iconId,
      },
    };
    final categoryIconByKey = <String, int>{
      for (final category in existingCategories)
        '${category.inEx}_${category.name}': category.iconId,
    };

    int importedCategories = 0;

    // 导入支出分类
    for (final cat in data.categories['expense'] ?? []) {
      final key = '0_${cat.name}';
      if (!existingNames.contains(key)) {
        final iconId = _allocateIconId(
          inEx: 0,
          preferredIconId: _iconIdFromImport(cat.icon),
          usedIconsByInEx: usedIconsByInEx,
        );
        await _db.insertCategory(
          inEx: 0,
          name: cat.name,
          iconId: iconId,
          isCustom: true,
        );
        importedCategories++;
        existingNames.add(key);
        categoryIconByKey[key] = iconId;
      }
    }

    // 导入收入分类
    for (final cat in data.categories['income'] ?? []) {
      final key = '1_${cat.name}';
      if (!existingNames.contains(key)) {
        final iconId = _allocateIconId(
          inEx: 1,
          preferredIconId: _iconIdFromImport(cat.icon),
          usedIconsByInEx: usedIconsByInEx,
        );
        await _db.insertCategory(
          inEx: 1,
          name: cat.name,
          iconId: iconId,
          isCustom: true,
        );
        importedCategories++;
        existingNames.add(key);
        categoryIconByKey[key] = iconId;
      }
    }

    // 2. 导入账单
    final allBills = await _db.getAllBills();
    final existingBillIds = allBills.map((b) => b.id).toSet();
    final now = DateTime.now().toIso8601String();

    for (final record in data.records) {
      // 生成唯一 ID：用原数据特征 + 时间戳
      final id =
          'import_${record.date}_${record.amount}_${record.category}_${insertedBills + skippedBills}';

      if (existingBillIds.contains(id)) {
        skippedBills++;
        continue;
      }

      final inEx = record.type == 'income' ? 1 : 0;
      final categoryIconId =
          categoryIconByKey['${inEx}_${record.category}'] ??
          _validIconId(record.iconId) ??
          _allocateIconId(
            inEx: inEx,
            preferredIconId: null,
            usedIconsByInEx: usedIconsByInEx,
            reserve: false,
          );

      final bill = BillItem(
        id: id,
        type: record.type,
        amount: record.amount,
        category: record.category,
        note: record.note,
        date: record.date,
        sortAt: record.date,
        iconId: categoryIconId,
        createdAt: now,
        updatedAt: now,
      );

      await _db.insertBill(bill);
      insertedBills++;
      existingBillIds.add(id);
    }

    return ImportResult(
      totalRecords: data.records.length,
      insertedBills: insertedBills,
      skippedBills: skippedBills,
      importedCategories: importedCategories,
    );
  }

  /// 仅解析并返回预览信息（不执行导入）
  ImportPreview previewFromJson(String jsonString) {
    final data = _parseJson(jsonString);
    return ImportPreview(
      formatVersion: data.formatVersion,
      source: data.source,
      exportedAt: data.exportedAt,
      recordCount: data.records.length,
      expenseCategories: data.categories['expense']?.length ?? 0,
      incomeCategories: data.categories['income']?.length ?? 0,
    );
  }

  int? _iconIdFromImport(String rawIcon) {
    final raw = rawIcon.trim();
    if (raw.isEmpty) return null;
    final numericId = int.tryParse(raw);
    if (numericId != null) return _validIconId(numericId);

    final normalized = raw.replaceAll('\\', '/');
    final fileName = normalized.split('/').last;
    for (final icon in iconJson) {
      final candidates = [icon.icon, icon.iconL, icon.iconS];
      if (candidates.any((path) {
        final normalizedPath = path.replaceAll('\\', '/');
        return normalizedPath == normalized ||
            normalizedPath.split('/').last == fileName;
      })) {
        return icon.id;
      }
    }
    return null;
  }

  int? _validIconId(int iconId) {
    if (iconId < 0 || iconId >= iconJson.length) return null;
    return iconJson[iconId].id;
  }

  int _allocateIconId({
    required int inEx,
    required int? preferredIconId,
    required Map<int, Set<int>> usedIconsByInEx,
    bool reserve = true,
  }) {
    final usedIcons = usedIconsByInEx.putIfAbsent(inEx, () => <int>{});
    final preferred = _validIconId(preferredIconId ?? -1);
    if (preferred != null && !usedIcons.contains(preferred)) {
      if (reserve) usedIcons.add(preferred);
      return preferred;
    }

    for (final candidate in _iconCandidatesForImport()) {
      if (!usedIcons.contains(candidate)) {
        if (reserve) usedIcons.add(candidate);
        return candidate;
      }
    }

    return preferred ?? (inEx == 1 ? 37 : 32);
  }

  Iterable<int> _iconCandidatesForImport() sync* {
    for (final group in addCategoryJson) {
      for (final iconId in group.icon) {
        if (_validIconId(iconId) != null) yield iconId;
      }
    }
    for (final icon in iconJson) {
      yield icon.id;
    }
  }
}

/// 导入预览信息
class ImportPreview {
  final int formatVersion;
  final String source;
  final String exportedAt;
  final int recordCount;
  final int expenseCategories;
  final int incomeCategories;

  const ImportPreview({
    required this.formatVersion,
    required this.source,
    required this.exportedAt,
    required this.recordCount,
    required this.expenseCategories,
    required this.incomeCategories,
  });
}
