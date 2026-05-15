import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledger_flutter/models/asset_account.dart';
import 'package:ledger_flutter/models/asset_snapshot.dart';
import 'package:ledger_flutter/pages/asset_page.dart';
import 'package:ledger_flutter/providers/asset_provider.dart';
import 'package:ledger_flutter/theme/app_theme.dart';

void main() {
  testWidgets('asset page snackbar helper shows message without framework exception', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Builder(
            builder: (context) => FilledButton(
              onPressed: () {
                AssetPage.showMessageForTest(
                  ScaffoldMessenger.maybeOf(context),
                  '资产已保存',
                );
              },
              child: const Text('触发'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('触发'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('资产已保存'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('asset bottom sheets can open, input and close without exceptions', (
    tester,
  ) async {
    final asset = AssetAccount(
      id: 'asset_1',
      type: 'bank',
      name: '招商银行',
      sortOrder: 0,
      createdAt: '2026-05-01 00:00:00',
      updatedAt: '2026-05-01 00:00:00',
    );

    final snapshot = AssetSnapshot(
      id: 'asset_1_2026-05',
      assetId: 'asset_1',
      yearMonth: '2026-05',
      balance: 1000,
      note: '期初',
      createdAt: '2026-05-01 00:00:00',
      updatedAt: '2026-05-01 00:00:00',
    );

    final dashboard = AssetDashboardData(
      assets: [asset],
      snapshots: [snapshot],
      monthlyPoints: const [
        AssetMonthPoint(yearMonth: '2026-05', totalBalance: 1000),
      ],
      selectedMonthDetails: [
        AssetSnapshotDetail(asset: asset, snapshot: snapshot),
      ],
      selectedMonthTypeSummaries: const [
        AssetTypeSummary(
          type: 'bank',
          totalBalance: 1000,
          accountCount: 1,
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          assetDashboardProvider.overrideWith(
            () => _FakeAssetDashboardNotifier(dashboard),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const AssetPage(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    await tester.tap(find.text('新增资产'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '我的银行卡');
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();

    expect(find.text('资产已保存'), findsOneWidget);
    expect(find.text('资产名称'), findsNothing);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('记录余额'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), '2026-06');
    await tester.enterText(find.byType(TextField).at(1), '2500');
    await tester.enterText(find.byType(TextField).at(2), '月末资产');
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();

    expect(find.text('余额已记录'), findsOneWidget);
    expect(find.text('资产账户'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

class _FakeAssetDashboardNotifier extends AssetDashboardNotifier {
  _FakeAssetDashboardNotifier(this.data);

  final AssetDashboardData data;

  @override
  Future<AssetDashboardData> build() async => data;

  @override
  Future<void> addAsset({
    required String type,
    required String name,
  }) async {}

  @override
  Future<void> saveSnapshot({
    required String assetId,
    required String yearMonth,
    required double balance,
    String note = '',
  }) async {}
}
