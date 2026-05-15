import 'package:flutter_test/flutter_test.dart';
import 'package:ledger_flutter/services/import_service.dart';

void main() {
  group('ImportService CSV preview', () {
    test('supports BOM, CRLF and Chinese headers', () {
      final service = ImportService();
      const csv =
          '\uFEFF收支类型,金额,日期,类别,备注\r\n'
          '支出,"1,234.56",2026/05/15,餐饮,午饭\r\n'
          '收入,88,2026-05-16,工资,补贴\r\n';

      final preview = service.previewFromCsv(csv);

      expect(preview.recordCount, 2);
      expect(preview.expenseCount, 1);
      expect(preview.incomeCount, 1);
      expect(preview.headers.first, '收支类型');
    });

    test('supports shark-export style GBK-decoded headers', () {
      final service = ImportService();
      const csv =
          '"日期","收支类型","类别","账户","金额","备注"\n'
          '"2026年05月14日","支出","餐饮","未关联","17.5","午餐 套饭"\n'
          '"2026年05月13日","支出","交通","未关联","5.4","地铁 上下班"\n';

      final preview = service.previewFromCsv(csv);

      expect(preview.recordCount, 2);
      expect(preview.expenseCount, 2);
      expect(preview.incomeCount, 0);
      expect(preview.headers, contains('金额'));
    });
  });
}
