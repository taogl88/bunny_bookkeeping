class AssetAccount {
  final String id;
  final String type;
  final String name;
  final int sortOrder;
  final String createdAt;
  final String updatedAt;

  const AssetAccount({
    required this.id,
    required this.type,
    required this.name,
    required this.sortOrder,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'name': name,
      'sort_order': sortOrder,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  factory AssetAccount.fromMap(Map<String, dynamic> map) {
    return AssetAccount(
      id: map['id'] as String,
      type: map['type'] as String,
      name: map['name'] as String,
      sortOrder: (map['sort_order'] as num).toInt(),
      createdAt: map['created_at'] as String,
      updatedAt: map['updated_at'] as String,
    );
  }
}
