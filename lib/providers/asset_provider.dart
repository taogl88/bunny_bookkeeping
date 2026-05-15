import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../db/database_helper.dart';
import '../models/asset_account.dart';
import '../models/asset_snapshot.dart';
import '../utils/asset_month.dart';

class SelectedAssetMonthNotifier extends Notifier<String> {
  @override
  String build() {
    return currentAssetYearMonth();
  }

  void set(String value) => state = normalizeAssetYearMonth(value) ?? currentAssetYearMonth();
}

final selectedAssetMonthProvider =
    NotifierProvider<SelectedAssetMonthNotifier, String>(
      SelectedAssetMonthNotifier.new,
    );

class AssetMonthPoint {
  final String yearMonth;
  final double totalBalance;

  const AssetMonthPoint({
    required this.yearMonth,
    required this.totalBalance,
  });
}

class AssetSnapshotDetail {
  final AssetAccount asset;
  final AssetSnapshot snapshot;

  const AssetSnapshotDetail({
    required this.asset,
    required this.snapshot,
  });
}

class AssetTypeSummary {
  final String type;
  final double totalBalance;
  final int accountCount;

  const AssetTypeSummary({
    required this.type,
    required this.totalBalance,
    required this.accountCount,
  });
}

class AssetDashboardData {
  final List<AssetAccount> assets;
  final List<AssetSnapshot> snapshots;
  final List<AssetMonthPoint> monthlyPoints;
  final List<AssetSnapshotDetail> selectedMonthDetails;
  final List<AssetTypeSummary> selectedMonthTypeSummaries;

  const AssetDashboardData({
    required this.assets,
    required this.snapshots,
    required this.monthlyPoints,
    required this.selectedMonthDetails,
    required this.selectedMonthTypeSummaries,
  });
}

class AssetDashboardNotifier extends AsyncNotifier<AssetDashboardData> {
  final _db = DatabaseHelper.instance;

  @override
  Future<AssetDashboardData> build() async {
    final selectedMonth = ref.watch(selectedAssetMonthProvider);
    final assets = await _db.getAssets();
    final snapshots = await _db.getAssetSnapshots();

    final assetById = {for (final asset in assets) asset.id: asset};
    final monthlyTotals = <String, double>{};
    final details = <AssetSnapshotDetail>[];
    final typeTotals = <String, double>{};
    final typeAccounts = <String, Set<String>>{};

    for (final snapshot in snapshots) {
      monthlyTotals[snapshot.yearMonth] =
          (monthlyTotals[snapshot.yearMonth] ?? 0) + snapshot.balance;
      if (snapshot.yearMonth == selectedMonth) {
        final asset = assetById[snapshot.assetId];
        if (asset != null) {
          details.add(AssetSnapshotDetail(asset: asset, snapshot: snapshot));
          typeTotals[asset.type] = (typeTotals[asset.type] ?? 0) + snapshot.balance;
          typeAccounts.putIfAbsent(asset.type, () => <String>{}).add(asset.id);
        }
      }
    }

    final monthlyPoints = monthlyTotals.entries
        .map(
          (entry) => AssetMonthPoint(
            yearMonth: entry.key,
            totalBalance: entry.value,
          ),
        )
        .toList()
      ..sort((a, b) => a.yearMonth.compareTo(b.yearMonth));

    details.sort((a, b) => a.asset.sortOrder.compareTo(b.asset.sortOrder));
    final typeSummaries = typeTotals.entries
        .map(
          (entry) => AssetTypeSummary(
            type: entry.key,
            totalBalance: entry.value,
            accountCount: typeAccounts[entry.key]?.length ?? 0,
          ),
        )
        .toList()
      ..sort((a, b) => b.totalBalance.compareTo(a.totalBalance));

    return AssetDashboardData(
      assets: assets,
      snapshots: snapshots,
      monthlyPoints: monthlyPoints,
      selectedMonthDetails: details,
      selectedMonthTypeSummaries: typeSummaries,
    );
  }

  Future<void> addAsset({
    required String type,
    required String name,
  }) async {
    final current = state.value;
    final now = _nowStr();
    final sortOrder = current?.assets.length ?? 0;
    final asset = AssetAccount(
      id: _id('asset'),
      type: type,
      name: name,
      sortOrder: sortOrder,
      createdAt: now,
      updatedAt: now,
    );
    await _db.insertAsset(asset);
    ref.invalidateSelf();
  }

  Future<void> saveSnapshot({
    required String assetId,
    required String yearMonth,
    required double balance,
    String note = '',
  }) async {
    final normalizedMonth = normalizeAssetYearMonth(yearMonth);
    if (normalizedMonth == null) {
      throw const FormatException('invalid_year_month');
    }
    final now = _nowStr();
    final snapshot = AssetSnapshot(
      id: '${assetId}_$normalizedMonth',
      assetId: assetId,
      yearMonth: normalizedMonth,
      balance: balance,
      note: note,
      createdAt: now,
      updatedAt: now,
    );
    await _db.saveAssetSnapshot(snapshot);
    ref.invalidateSelf();
    ref.read(selectedAssetMonthProvider.notifier).set(normalizedMonth);
  }

  Future<void> deleteAsset(String id) async {
    await _db.deleteAsset(id);
    ref.invalidateSelf();
  }

  String _id(String prefix) {
    final ts = DateTime.now().millisecondsSinceEpoch;
    final rand = Random().nextInt(999999).toString().padLeft(6, '0');
    return '${prefix}_$ts$rand';
  }

  String _nowStr() {
    final now = DateTime.now();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${now.year}-${two(now.month)}-${two(now.day)} '
        '${two(now.hour)}:${two(now.minute)}:${two(now.second)}';
  }
}

final assetDashboardProvider =
    AsyncNotifierProvider<AssetDashboardNotifier, AssetDashboardData>(
      AssetDashboardNotifier.new,
    );
