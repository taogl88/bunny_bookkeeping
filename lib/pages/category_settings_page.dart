import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/account_data.dart';
import '../models/category_entry.dart';
import '../providers/category_provider.dart';
import '../theme/app_theme.dart';
import '../utils/icon_helper.dart';
import '../widgets/category_delete_sheet.dart';
import 'category_editor_page.dart';

/// 类别设置页（图1）
///
/// 顶部黄色 AppBar + 支出/收入 Tab；列表每一行支持：
///  - 左侧红色"删除"按钮：弹底部 sheet 警告，让用户选「转移数据」/「仍然删除」
///  - 中间图标 + 名称（自定义类别会带上"（自定义）"后缀，且名字右侧出现齿轮按钮可编辑）
///  - 右侧三杠图标：长按上下拖拽改变顺序
///
/// 底部固定 "+ 添加类别" 按钮，唤起 [CategoryEditorPage]。
class CategorySettingsPage extends ConsumerStatefulWidget {
  const CategorySettingsPage({super.key, this.initialInEx = 0});

  /// 初始展示的 Tab：0 支出 / 1 收入。从记账页设置入口进入时跟随当前 Tab。
  final int initialInEx;

  @override
  ConsumerState<CategorySettingsPage> createState() =>
      _CategorySettingsPageState();
}

class _CategorySettingsPageState extends ConsumerState<CategorySettingsPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController = TabController(
    length: 2,
    vsync: this,
    initialIndex: widget.initialInEx.clamp(0, 1),
  );

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  int get _currentInEx => _tabController.index == 0 ? 0 : 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _CategoryReorderList(inEx: 0),
                _CategoryReorderList(inEx: 1),
              ],
            ),
          ),
          _buildAddButton(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final topPadding = MediaQuery.of(context).padding.top;
    return Container(
      color: AppColors.primary,
      padding: EdgeInsets.only(top: topPadding),
      child: Column(
        children: [
          // 标题栏：返回 + 居中标题 + 右侧"重置"
          SizedBox(
            height: 48,
            child: Stack(
              children: [
                Positioned(
                  left: 4,
                  top: 0,
                  bottom: 0,
                  child: IconButton(
                    icon: const Icon(
                      Icons.arrow_back,
                      color: AppColors.textPrimary,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                const Positioned.fill(
                  child: Center(
                    child: Text(
                      '类别设置',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 4,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: TextButton(
                      onPressed: _onReset,
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.textPrimary,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        minimumSize: const Size(0, 36),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        '重置',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // 支出/收入 Tab：黑底白字 vs 透明
          Padding(
            padding: const EdgeInsets.fromLTRB(60, 0, 60, 12),
            child: _SegmentedTab(controller: _tabController),
          ),
        ],
      ),
    );
  }

  Widget _buildAddButton() {
    return Material(
      color: AppColors.surface,
      elevation: 6,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 48,
          child: InkWell(
            onTap: _onAddCategory,
            child: const Center(
              child: Text(
                '+ 添加类别',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _onAddCategory() async {
    await showCategoryEditorSheet(
      context: context,
      inEx: _currentInEx,
    );
  }

  Future<void> _onReset() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('重置默认类别'),
        content: const Text(
          '会把已被删除的默认类别按原始名称和图标加回到列表末尾；\n'
          '若名称与现有类别冲突，则跳过该默认类别。\n'
          '现有的类别不会被改动。',
          style: TextStyle(height: 1.5, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('重置'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final added = await ref
        .read(categoryListProvider.notifier)
        .restoreDefaults();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(added == 0 ? '默认类别已是完整状态' : '已恢复 $added 个默认类别'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

/// 顶部"支出 / 收入"分段切换
class _SegmentedTab extends StatelessWidget {
  const _SegmentedTab({required this.controller});

  final TabController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return Container(
          height: 36,
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(150),
            borderRadius: BorderRadius.circular(6),
          ),
          padding: const EdgeInsets.all(2),
          child: Row(
            children: [
              _segmentItem(text: '支出', index: 0),
              _segmentItem(text: '收入', index: 1),
            ],
          ),
        );
      },
    );
  }

  Widget _segmentItem({required String text, required int index}) {
    final selected = controller.index == index;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => controller.index = index,
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppColors.textPrimary : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: selected ? Colors.white : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

/// 可重排的类别列表（按 in_ex 过滤）
class _CategoryReorderList extends ConsumerWidget {
  const _CategoryReorderList({required this.inEx});

  final int inEx;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = inEx == 0
        ? ref.watch(expenseCategoriesProvider)
        : ref.watch(incomeCategoriesProvider);
    final asyncState = ref.watch(categoryListProvider);

    if (asyncState.isLoading && list.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (list.isEmpty) {
      return const Center(
        child: Text(
          '暂无类别',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    return ReorderableListView.builder(
      buildDefaultDragHandles: false,
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final cat = list[index];
        return _CategoryRow(
          key: ValueKey('cat-${cat.id}'),
          category: cat,
          dragIndex: index,
          onDelete: () => _onDelete(context, ref, cat),
          onEdit: () => _onEdit(context, cat),
        );
      },
      onReorder: (oldIndex, newIndex) async {
        if (newIndex > oldIndex) newIndex -= 1;
        final newOrder = [...list];
        final moved = newOrder.removeAt(oldIndex);
        newOrder.insert(newIndex, moved);
        await ref
            .read(categoryListProvider.notifier)
            .reorder(
              inEx: inEx,
              orderedIds: [for (final c in newOrder) c.id],
            );
      },
    );
  }

  Future<void> _onDelete(
    BuildContext context,
    WidgetRef ref,
    CategoryEntry cat,
  ) async {
    final allInEx = inEx == 0
        ? ref.read(expenseCategoriesProvider)
        : ref.read(incomeCategoriesProvider);
    final action = await showCategoryDeleteSheet(
      context: context,
      category: cat,
      siblings: allInEx,
    );
    if (action == null) return;
    final notifier = ref.read(categoryListProvider.notifier);
    final transferTo = action.transferTo;
    if (transferTo == null) {
      await notifier.deleteWithBills(cat);
    } else {
      await notifier.deleteAndTransferBills(
        category: cat,
        target: transferTo,
      );
    }
  }

  Future<void> _onEdit(BuildContext context, CategoryEntry cat) async {
    await showCategoryEditorSheet(
      context: context,
      inEx: cat.inEx,
      editing: cat,
    );
  }
}

/// 单行类别项
class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    required super.key,
    required this.category,
    required this.dragIndex,
    required this.onDelete,
    required this.onEdit,
  });

  final CategoryEntry category;
  final int dragIndex;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final iconMeta = iconJson[category.iconId];
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFF0F0F0), width: 0.5),
        ),
      ),
      child: Row(
        children: [
          // 删除按钮
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onDelete,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              child: Icon(
                Icons.remove_circle,
                color: Color(0xFFE53935),
                size: 22,
              ),
            ),
          ),
          // 图标
          SizedBox(
            width: 36,
            height: 36,
            child: Image.asset(iconPath(iconMeta.icon)),
          ),
          const SizedBox(width: 12),
          // 名称（+自定义说明）。Expanded 单独占据中间空间，把齿轮顶到右侧紧
          // 邻拖拽手柄。
          Expanded(
            child: Text(
              category.isCustom
                  ? '${category.name}（自定义）'
                  : category.name,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          // 自定义类别的齿轮按钮（贴着拖拽手柄左侧）
          if (category.isCustom)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onEdit,
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 14),
                child: Icon(
                  Icons.settings_outlined,
                  size: 20,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          // 拖拽手柄（三杠）
          ReorderableDragStartListener(
            index: dragIndex,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Icon(
                Icons.drag_handle,
                size: 22,
                color: Color(0xFFCCCCCC),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
