import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/account_data.dart';
import '../db/database_helper.dart';
import '../models/category_entry.dart';
import 'bill_provider.dart';

/// 全量类别列表（含支出/收入），按 (in_ex, sort_order) 升序。
///
/// 这是替换原来 `account_data.dart` 中静态 [categoryJson] 的运行时数据源；
/// 上层一般通过 [expenseCategoriesProvider] / [incomeCategoriesProvider]
/// 直接拿到对应分组。
class CategoryListNotifier extends AsyncNotifier<List<CategoryEntry>> {
  DatabaseHelper get _db => DatabaseHelper.instance;

  @override
  Future<List<CategoryEntry>> build() async {
    return _db.getAllCategories();
  }

  /// 添加一条新类别（默认 isCustom=true）。
  ///
  /// 返回新插入的 id；若同 inEx 下名称重复则抛出 [_DuplicateCategoryNameError]。
  Future<int> addCustom({
    required int inEx,
    required String name,
    required int iconId,
  }) async {
    final exists = await _db.hasCategoryWithName(inEx: inEx, name: name);
    if (exists) {
      throw const DuplicateCategoryNameError();
    }
    final categories = await _db.getAllCategories();
    if (categories.any((c) => c.inEx == inEx && c.iconId == iconId)) {
      throw const DuplicateCategoryIconError();
    }
    final id = await _db.insertCategory(
      inEx: inEx,
      name: name,
      iconId: iconId,
      isCustom: true,
    );
    ref.invalidateSelf();
    await future;
    return id;
  }

  /// 编辑类别名称 / 图标。会同步把 bills 表中相同 (type, 旧 name) 的账单
  /// 的 category 与 icon_id 一并刷新，保持数据一致。
  Future<void> updateCategory({
    required CategoryEntry old,
    required String newName,
    required int newIconId,
  }) async {
    final nameChanged = old.name != newName;
    if (nameChanged) {
      final exists = await _db.hasCategoryWithName(
        inEx: old.inEx,
        name: newName,
        excludeId: old.id,
      );
      if (exists) {
        throw const DuplicateCategoryNameError();
      }
    }
    final categories = await _db.getAllCategories();
    if (categories.any(
      (c) => c.inEx == old.inEx && c.id != old.id && c.iconId == newIconId,
    )) {
      throw const DuplicateCategoryIconError();
    }
    await _db.updateCategoryBasic(
      id: old.id,
      name: newName,
      iconId: newIconId,
    );
    final type = old.inEx == 0 ? 'expense' : 'income';
    await _db.updateBillsCategoryRename(
      type: type,
      oldName: old.name,
      newName: newName,
      newIconId: newIconId,
    );
    ref.invalidateSelf();
    // 通知账单相关 provider 刷新
    ref.invalidate(billListProvider);
    await future;
  }

  /// 删除类别 + 删除该类别下所有账单。
  Future<void> deleteWithBills(CategoryEntry category) async {
    final type = category.inEx == 0 ? 'expense' : 'income';
    await _db.deleteBillsByTypeAndCategory(
      type: type,
      category: category.name,
    );
    await _db.deleteCategory(category.id);
    ref.invalidateSelf();
    ref.invalidate(billListProvider);
    await future;
  }

  /// 删除类别，并把账单转移到指定目标类别。
  Future<void> deleteAndTransferBills({
    required CategoryEntry category,
    required CategoryEntry target,
  }) async {
    final type = category.inEx == 0 ? 'expense' : 'income';
    await _db.transferBillsCategory(
      type: type,
      fromCategory: category.name,
      toCategory: target.name,
      toIconId: target.iconId,
    );
    await _db.deleteCategory(category.id);
    ref.invalidateSelf();
    ref.invalidate(billListProvider);
    await future;
  }

  /// 把已被删除的默认分类（[categoryJson] 中 `isDefault == true` 的项）补回。
  ///
  /// 规则：
  ///  - 同 inEx 中若已经存在同名分类（无论是默认还是自定义），跳过该默认项；
  ///  - 否则按原始 `name` / `icon` 追加到当前 inEx 末尾，`is_custom = false`；
  ///  - 不影响已存在的分类排序与历史账单。
  ///
  /// 返回实际新增的条数。
  Future<int> restoreDefaults() async {
    // 走 DB 真值，避免和乐观 state 偏差。
    final cur = await _db.getAllCategories();
    final existingByInEx = <int, Set<String>>{};
    for (final c in cur) {
      existingByInEx.putIfAbsent(c.inEx, () => <String>{}).add(c.name);
    }

    var inserted = 0;
    for (final def in categoryJson) {
      if (!def.isDefault) continue;
      final names = existingByInEx.putIfAbsent(def.inEx, () => <String>{});
      if (names.contains(def.name)) continue;
      await _db.insertCategory(
        inEx: def.inEx,
        name: def.name,
        iconId: def.icon,
        isCustom: false,
      );
      names.add(def.name);
      inserted++;
    }
    if (inserted > 0) {
      ref.invalidateSelf();
      await future;
    }
    return inserted;
  }

  /// 重排某 inEx 下的全部类别。[orderedIds] 必须是该 inEx 完整顺序。
  ///
  /// 这里采用「乐观更新」：先按新顺序重写本地 state，让 UI 立刻定格在拖拽
  /// 后的位置，避免 ReorderableListView 在松手后短暂回退到旧顺序再跳到
  /// 新顺序的闪烁；写库失败时再 invalidateSelf 回滚到 DB 真相。
  Future<void> reorder({
    required int inEx,
    required List<int> orderedIds,
  }) async {
    final cur = state.value;
    if (cur != null) {
      final byId = <int, CategoryEntry>{
        for (final c in cur)
          if (c.inEx == inEx) c.id: c,
      };
      final reordered = <CategoryEntry>[];
      for (var i = 0; i < orderedIds.length; i++) {
        final c = byId[orderedIds[i]];
        if (c != null) reordered.add(c.copyWith(sortOrder: i));
      }
      final others = [for (final c in cur) if (c.inEx != inEx) c];
      final merged = [...others, ...reordered]
        ..sort((a, b) {
          final cmp = a.inEx.compareTo(b.inEx);
          if (cmp != 0) return cmp;
          return a.sortOrder.compareTo(b.sortOrder);
        });
      state = AsyncValue.data(merged);
    }
    try {
      await _db.reorderCategories(inEx: inEx, orderedIds: orderedIds);
    } catch (_) {
      ref.invalidateSelf();
      rethrow;
    }
  }
}

final categoryListProvider =
    AsyncNotifierProvider<CategoryListNotifier, List<CategoryEntry>>(
      CategoryListNotifier.new,
    );

/// 支出类别（按 sort_order 升序）。
final expenseCategoriesProvider = Provider<List<CategoryEntry>>((ref) {
  final all = ref.watch(categoryListProvider).value ?? const [];
  return [for (final c in all) if (c.inEx == 0) c];
});

/// 收入类别（按 sort_order 升序）。
final incomeCategoriesProvider = Provider<List<CategoryEntry>>((ref) {
  final all = ref.watch(categoryListProvider).value ?? const [];
  return [for (final c in all) if (c.inEx == 1) c];
});

/// 添加 / 编辑分类时遇到同 in_ex 内重名时抛出。UI 层捕获后弹 SnackBar 提示。
class DuplicateCategoryNameError implements Exception {
  const DuplicateCategoryNameError();

  @override
  String toString() => '该分类名称已存在';
}

/// 添加 / 编辑分类时，同 in_ex 下的图标不允许复用。
class DuplicateCategoryIconError implements Exception {
  const DuplicateCategoryIconError();

  @override
  String toString() => '该分类图标已被使用';
}
