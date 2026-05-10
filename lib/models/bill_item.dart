class BillItem {
  final String id;
  final String type; // 'expense' | 'income'
  final double amount;
  final String category;
  final String note;
  final String date;      // yyyy-MM-dd HH:mm:ss 账单发生时间
  final String sortAt;    // yyyy-MM-dd HH:mm:ss 列表排序时间
  final int iconId;       // 对应 iconJson 中的 id
  final String createdAt; // yyyy-MM-dd HH:mm:ss 记录创建时间
  final String updatedAt; // yyyy-MM-dd HH:mm:ss 记录最后更新时间

  const BillItem({
    required this.id,
    required this.type,
    required this.amount,
    required this.category,
    required this.note,
    required this.date,
    required this.sortAt,
    required this.iconId,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'amount': amount,
      'category': category,
      'note': note,
      'date': date,
      'sort_at': sortAt,
      'icon_id': iconId,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  factory BillItem.fromMap(Map<String, dynamic> map) {
    return BillItem(
      id: map['id'] as String,
      type: map['type'] as String,
      amount: (map['amount'] as num).toDouble(),
      category: map['category'] as String,
      note: map['note'] as String,
      date: map['date'] as String,
      sortAt: (map['sort_at'] as String?) ?? (map['date'] as String),
      iconId: map['icon_id'] as int,
      createdAt: map['created_at'] as String,
      updatedAt: map['updated_at'] as String,
    );
  }

  BillItem copyWith({
    String? id,
    String? type,
    double? amount,
    String? category,
    String? note,
    String? date,
    String? sortAt,
    int? iconId,
    String? createdAt,
    String? updatedAt,
  }) {
    return BillItem(
      id: id ?? this.id,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      note: note ?? this.note,
      date: date ?? this.date,
      sortAt: sortAt ?? this.sortAt,
      iconId: iconId ?? this.iconId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
