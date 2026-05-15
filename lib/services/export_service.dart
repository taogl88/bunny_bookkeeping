import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../db/database_helper.dart';

/// 数据导出服务 —— 导出和 ImportService 导入格式一致的 JSON/CSV
class ExportService {
  final DatabaseHelper _db = DatabaseHelper.instance;

  /// 导出为 JSON（和 myapp 导入格式一致）
  Future<String> exportToJsonString() async {
    final bills = await _db.getAllBills();
    final categories = await _db.getAllCategories();

    final expenseCats = categories
        .where((c) => c.inEx == 0)
        .map((c) => {'name': c.name, 'icon': c.iconId.toString()})
        .toList();

    final incomeCats = categories
        .where((c) => c.inEx == 1)
        .map((c) => {'name': c.name, 'icon': c.iconId.toString()})
        .toList();

    final records = bills.map((b) => {
      'type': b.type,
      'amount': b.amount,
      'category': b.category,
      'note': b.note,
      'date': b.date,
      'iconId': b.iconId,
    }).toList();

    final data = {
      'formatVersion': 1,
      'source': 'bunny_bookkeeping',
      'exportedAt': DateTime.now().toIso8601String(),
      'records': records,
      'categories': {
        'expense': expenseCats,
        'income': incomeCats,
      },
    };

    return const JsonEncoder.withIndent('  ').convert(data);
  }

  /// 导出为 CSV
  Future<String> exportToCsvString() async {
    final bills = await _db.getAllBills();
    final buffer = StringBuffer();
    buffer.writeln('日期,类型,金额,分类,备注');
    for (final bill in bills) {
      final typeLabel = bill.type == 'income' ? '收入' : '支出';
      buffer.writeln(
        '${_escapeCsvField(bill.date)},'
        '${_escapeCsvField(typeLabel)},'
        '${bill.amount},'
        '${_escapeCsvField(bill.category)},'
        '${_escapeCsvField(bill.note)}',
      );
    }
    return buffer.toString();
  }

  String _escapeCsvField(String value) {
    final escaped = value.replaceAll('"', '""');
    return '"$escaped"';
  }

  Future<ExportedFile> exportToFile(String format) async {
    final normalizedFormat = format.toLowerCase();
    if (normalizedFormat != 'json' && normalizedFormat != 'csv') {
      throw ArgumentError.value(format, 'format', 'Unsupported export format');
    }

    final content = normalizedFormat == 'json'
        ? await exportToJsonString()
        : await exportToCsvString();
    final fileName =
        'bunny_backup_${DateTime.now().millisecondsSinceEpoch}.$normalizedFormat';
    final targetDir = await _resolveExportDirectory();
    await targetDir.create(recursive: true);

    final file = File(p.join(targetDir.path, fileName));
    await file.writeAsString(content, flush: true);
    return ExportedFile(
      fileName: fileName,
      path: file.path,
      bytes: content.length,
    );
  }

  Future<Directory> _resolveExportDirectory() async {
    if (Platform.isAndroid) {
      final publicDownload = Directory('/storage/emulated/0/Download');
      try {
        if (await publicDownload.exists()) {
          final probe = File(p.join(publicDownload.path, '.bunny_export_probe'));
          await probe.writeAsString('ok', flush: true);
          if (await probe.exists()) {
            await probe.delete();
          }
          return publicDownload;
        }
      } catch (_) {
        // Fall back to app-specific external storage when Downloads is blocked.
      }

      final externalDir = await getExternalStorageDirectory();
      if (externalDir != null) {
        return Directory(p.join(externalDir.path, 'exports'));
      }
    }

    final docsDir = await getApplicationDocumentsDirectory();
    return Directory(p.join(docsDir.path, 'exports'));
  }
}

class ExportedFile {
  const ExportedFile({
    required this.fileName,
    required this.path,
    required this.bytes,
  });

  final String fileName;
  final String path;
  final int bytes;
}
