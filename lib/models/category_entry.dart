/// 数据库中的"类别"实体，对应 `categories` 表。
///
/// 与 `account_data.dart` 中静态的 [CategoryItem] 区分：[CategoryEntry] 是
/// 动态可增删改的、可被用户重排的，并且支持「自定义类别」。
class CategoryEntry {
  final int id;

  /// 0 = 支出，1 = 收入
  final int inEx;

  final String name;

  /// 对应 ICON_JSON 中的 id
  final int iconId;

  /// 是否是用户新建的自定义类别（true → 可编辑/可删除时显示齿轮按钮）
  final bool isCustom;

  /// 排序（同一 inEx 内升序）
  final int sortOrder;

  final String createdAt;
  final String updatedAt;

  const CategoryEntry({
    required this.id,
    required this.inEx,
    required this.name,
    required this.iconId,
    required this.isCustom,
    required this.sortOrder,
    required this.createdAt,
    required this.updatedAt,
  });

  CategoryEntry copyWith({
    int? id,
    int? inEx,
    String? name,
    int? iconId,
    bool? isCustom,
    int? sortOrder,
    String? createdAt,
    String? updatedAt,
  }) {
    return CategoryEntry(
      id: id ?? this.id,
      inEx: inEx ?? this.inEx,
      name: name ?? this.name,
      iconId: iconId ?? this.iconId,
      isCustom: isCustom ?? this.isCustom,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, Object?> toMap() => {
    'id': id,
    'in_ex': inEx,
    'name': name,
    'icon_id': iconId,
    'is_custom': isCustom ? 1 : 0,
    'sort_order': sortOrder,
    'created_at': createdAt,
    'updated_at': updatedAt,
  };

  factory CategoryEntry.fromMap(Map<String, Object?> map) => CategoryEntry(
    id: (map['id'] as num).toInt(),
    inEx: (map['in_ex'] as num).toInt(),
    name: (map['name'] as String?) ?? '',
    iconId: (map['icon_id'] as num).toInt(),
    isCustom: ((map['is_custom'] as num?) ?? 0).toInt() == 1,
    sortOrder: (map['sort_order'] as num).toInt(),
    createdAt: (map['created_at'] as String?) ?? '',
    updatedAt: (map['updated_at'] as String?) ?? '',
  );
}
