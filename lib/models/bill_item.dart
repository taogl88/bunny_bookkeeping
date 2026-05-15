import 'bill_split.dart';

class BillItem {
  final String id;
  final String type;
  final double amount;
  final String category;
  final String note;
  final String date;
  final String sortAt;
  final int iconId;
  final String createdAt;
  final String updatedAt;
  final List<BillSplit> splits;

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
    this.splits = const [],
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
      iconId: (map['icon_id'] as num).toInt(),
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
    List<BillSplit>? splits,
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
      splits: splits ?? this.splits,
    );
  }

  bool get hasMultipleCategories => splits.length > 1;
}
