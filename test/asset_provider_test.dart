import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ledger_flutter/providers/asset_provider.dart';

void main() {
  test('selected asset month notifier normalizes invalid input to current month', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final initial = container.read(selectedAssetMonthProvider);

    expect(initial, matches(RegExp(r'^\d{4}-\d{2}$')));

    container.read(selectedAssetMonthProvider.notifier).set('2026-5');
    expect(container.read(selectedAssetMonthProvider), '2026-05');

    container.read(selectedAssetMonthProvider.notifier).set('2026-13');
    expect(container.read(selectedAssetMonthProvider), initial);
  });
}
