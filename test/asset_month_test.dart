import 'package:flutter_test/flutter_test.dart';
import 'package:ledger_flutter/utils/asset_month.dart';

void main() {
  group('normalizeAssetYearMonth', () {
    test('normalizes single digit month', () {
      expect(normalizeAssetYearMonth('2026-5'), '2026-05');
    });

    test('keeps standard format', () {
      expect(normalizeAssetYearMonth('2026-05'), '2026-05');
    });

    test('rejects invalid month', () {
      expect(normalizeAssetYearMonth('2026-13'), isNull);
      expect(normalizeAssetYearMonth('2026-00'), isNull);
      expect(normalizeAssetYearMonth('abcd-05'), isNull);
    });
  });

  test('assetMonthShortLabel is safe for invalid value', () {
    expect(assetMonthShortLabel('2026-05'), '05');
    expect(assetMonthShortLabel('bad'), '--');
  });
}
