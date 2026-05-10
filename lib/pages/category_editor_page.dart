import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/account_data.dart';
import '../models/category_entry.dart';
import '../providers/category_provider.dart';
import '../theme/app_theme.dart';
import '../utils/icon_helper.dart';

/// 添加/编辑（自定义）类别面板（图2、图3）
///
/// 通过 [showCategoryEditorSheet] 以底部 sheet 形式弹出，顶部留出一段空间
/// 让上一页（类别设置页）的黄色头部仍能透出来，符合截图样式。
///
/// 内容布局：
///  - 顶部一行：[取消] / [标题] / [完成]
///  - 当前选中图标的圆形预览
///  - 类别名称输入框（最多 4 个汉字 / 8 个英文字符）
///  - 按 [addCategoryJson] 分组的图标网格
///
/// 编辑模式下传入 [editing]，标题变成"编辑..."且预填初始值。
Future<void> showCategoryEditorSheet({
  required BuildContext context,
  required int inEx,
  CategoryEntry? editing,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withAlpha(60),
    isDismissible: false,
    enableDrag: false,
    builder: (ctx) {
      // 留出顶部一段高度，让上一页 header 透出来
      final topReserved = MediaQuery.of(ctx).viewPadding.top + 60;
      return Padding(
        padding: EdgeInsets.only(top: topReserved),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(0)),
          child: Material(
            color: AppColors.surface,
            child: CategoryEditorPage(inEx: inEx, editing: editing),
          ),
        ),
      );
    },
  );
}

class CategoryEditorPage extends ConsumerStatefulWidget {
  const CategoryEditorPage({super.key, required this.inEx, this.editing});

  final int inEx;
  final CategoryEntry? editing;

  @override
  ConsumerState<CategoryEditorPage> createState() => _CategoryEditorPageState();
}

class _CategoryEditorPageState extends ConsumerState<CategoryEditorPage> {
  late final TextEditingController _nameCtrl;
  int? _selectedIconId;
  bool _saving = false;
  // 重名等错误直接展示在输入框下方；之前用 SnackBar 会被 modal sheet 遮住。
  String? _nameError;

  /// 限制名称：4 个汉字（约 12 字节 utf-16） — 这里直接按"字符长度 ≤ 4"算，
  /// 表情/英文也走这个上限，比按字节算更直观。
  static const int _kMaxNameChars = 4;

  bool get _isEdit => widget.editing != null;

  /// 当前 inEx 下默认分类用到的图标 id（按 [categoryJson] 中 isDefault 的项动态推导，
  /// 而不是硬编码 0..32 / 33..37，便于以后默认分类调整时保持同步）。
  List<int> get _defaultIconIds => [
    for (final cat in categoryJson)
      if (cat.isDefault && cat.inEx == widget.inEx) cat.icon,
  ];

  @override
  void initState() {
    super.initState();
    final editing = widget.editing;
    _nameCtrl = TextEditingController(text: editing?.name ?? '');
    _selectedIconId = editing?.iconId;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final inExLabel = widget.inEx == 0 ? '支出' : '收入';
    final title = _isEdit ? '编辑$inExLabel类别' : '添加$inExLabel类别';
    final usedIconIds = _usedIconIds(listen: true);
    final selectedIconUsed =
        _selectedIconId != null && usedIconIds.contains(_selectedIconId);
    final canSubmit =
        _selectedIconId != null &&
        !selectedIconUsed &&
        _nameCtrl.text.trim().isNotEmpty;

    return SafeArea(
      top: false,
      child: Column(
        children: [
          _buildHeader(title: title, canSubmit: canSubmit),
          _buildPreview(),
          _buildNameField(),
          const SizedBox(height: 4),
          Expanded(child: _buildIconGroups(usedIconIds: usedIconIds)),
        ],
      ),
    );
  }

  Set<int> _usedIconIds({bool listen = false}) {
    final all =
        (listen
                ? ref.watch(categoryListProvider)
                : ref.read(categoryListProvider))
            .value ??
        const [];
    return {
      for (final category in all)
        if (category.inEx == widget.inEx && category.id != widget.editing?.id)
          category.iconId,
    };
  }

  Widget _buildHeader({required String title, required bool canSubmit}) {
    return SizedBox(
      height: 48,
      child: Row(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => Navigator.of(context).pop(),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                '取消',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: canSubmit && !_saving ? _onSubmit : null,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 12),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: canSubmit
                    ? AppColors.primary
                    : AppColors.primary.withAlpha(120),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Text(
                '完成',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreview() {
    final iconId = _selectedIconId;
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 12),
      child: Center(
        child: SizedBox(
          width: 60,
          height: 60,
          // 与网格中的 icon 一致：直接显示 iconS（彩色高亮），不再额外叠加
          // 一层黄色圆背景，避免视觉双层。
          child: iconId == null
              ? Container(
                  decoration: const BoxDecoration(
                    color: AppColors.remarkGray,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.image_outlined,
                    color: AppColors.textSecondary,
                    size: 28,
                  ),
                )
              : Image.asset(
                  iconPath(iconJson[iconId].iconS),
                  width: 60,
                  height: 60,
                ),
        ),
      ),
    );
  }

  Widget _buildNameField() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppColors.remarkGray,
              borderRadius: BorderRadius.circular(8),
              border: _nameError == null
                  ? null
                  : Border.all(color: const Color(0xFFE53935), width: 1),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: TextField(
              controller: _nameCtrl,
              maxLength: _kMaxNameChars,
              // 让计数器不显示，外侧已经在占位文字里说明了
              buildCounter:
                  (
                    _, {
                    required currentLength,
                    required isFocused,
                    maxLength,
                  }) => null,
              inputFormatters: [
                LengthLimitingTextInputFormatter(_kMaxNameChars),
              ],
              decoration: InputDecoration(
                border: InputBorder.none,
                isDense: true,
                hintText: '输入类别名称（不超过4个汉字）',
                hintStyle: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
                suffixIcon: _nameCtrl.text.isEmpty
                    ? null
                    : GestureDetector(
                        onTap: () => setState(() {
                          _nameCtrl.clear();
                          _nameError = null;
                        }),
                        behavior: HitTestBehavior.opaque,
                        child: const Padding(
                          padding: EdgeInsets.all(6),
                          child: Icon(
                            Icons.cancel,
                            size: 18,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                suffixIconConstraints: const BoxConstraints(maxHeight: 24),
              ),
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
              onChanged: (_) => setState(() {
                if (_nameError != null) _nameError = null;
              }),
            ),
          ),
          // 错误信息直接显示在输入框下方，避免被 modal sheet 盖住的 SnackBar 看不到。
          if (_nameError != null)
            Padding(
              padding: const EdgeInsets.only(top: 6, left: 4),
              child: Text(
                _nameError!,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFFE53935),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildIconGroups({required Set<int> usedIconIds}) {
    final defaultGroup = AddCategoryItem(
      id: '_default',
      name: '默认',
      icon: _defaultIconIds,
    );
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 16),
      child: Column(
        children: [
          // 把默认分类用到的图标作为第一组放在最前面，便于用户复用
          if (defaultGroup.icon.isNotEmpty)
            _buildOneGroup(defaultGroup, usedIconIds: usedIconIds),
          for (final group in addCategoryJson)
            _buildOneGroup(group, usedIconIds: usedIconIds),
        ],
      ),
    );
  }

  Widget _buildOneGroup(
    AddCategoryItem group, {
    required Set<int> usedIconIds,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            group.name,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
              mainAxisSpacing: 12,
              crossAxisSpacing: 4,
              childAspectRatio: 1,
            ),
            itemCount: group.icon.length,
            itemBuilder: (context, index) {
              final iconId = group.icon[index];
              final selected = iconId == _selectedIconId;
              final disabled = usedIconIds.contains(iconId);
              return _IconCell(
                iconId: iconId,
                selected: selected,
                disabled: disabled,
                onTap: disabled
                    ? null
                    : () => setState(() => _selectedIconId = iconId),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _onSubmit() async {
    final name = _nameCtrl.text.trim();
    final iconId = _selectedIconId;
    if (name.isEmpty || iconId == null) return;
    if (_usedIconIds().contains(iconId)) {
      setState(() => _nameError = '该分类图标已被使用');
      return;
    }

    setState(() {
      _saving = true;
      _nameError = null;
    });
    try {
      final notifier = ref.read(categoryListProvider.notifier);
      if (_isEdit) {
        await notifier.updateCategory(
          old: widget.editing!,
          newName: name,
          newIconId: iconId,
        );
      } else {
        await notifier.addCustom(inEx: widget.inEx, name: name, iconId: iconId);
      }
      if (!mounted) return;
      Navigator.of(context).pop();
    } on DuplicateCategoryNameError {
      if (!mounted) return;
      setState(() => _nameError = '该分类名称已存在');
    } on DuplicateCategoryIconError {
      if (!mounted) return;
      setState(() => _nameError = '该分类图标已被使用');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _IconCell extends StatelessWidget {
  const _IconCell({
    required this.iconId,
    required this.selected,
    required this.disabled,
    required this.onTap,
  });

  final int iconId;
  final bool selected;
  final bool disabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final meta = iconJson[iconId];
    // 跟记账页保持一致：图片本身带灰/黄圆形背景，未选用 icon、选中用 iconS，
    // 不再额外叠加 Container 背景或 padding，避免出现双层圆。
    final imgPath = iconPath(selected ? meta.iconS : meta.icon);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Center(
        child: Opacity(
          opacity: disabled ? 0.35 : 1,
          child: Image.asset(imgPath, width: 50, height: 50),
        ),
      ),
    );
  }
}
