class BillSplit {
  final String id;
  final String billId;
  final String category;
  final int iconId;
  final double amount;
  final String createdAt;
  final String updatedAt;

  const BillSplit({
    required this.id,
    required this.billId,
    required this.category,
    required this.iconId,
    required this.amount,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'bill_id': billId,
      'category': category,
      'icon_id': iconId,
      'amount': amount,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  factory BillSplit.fromMap(Map<String, dynamic> map) {
    return BillSplit(
      id: map['id'] as String,
      billId: map['bill_id'] as String,
      category: map['category'] as String,
      iconId: (map['icon_id'] as num).toInt(),
      amount: (map['amount'] as num).toDouble(),
      createdAt: map['created_at'] as String,
      updatedAt: map['updated_at'] as String,
    );
  }
}

class BillSplitDraft {
  final String category;
  final int iconId;
  final double amount;

  const BillSplitDraft({
    required this.category,
    required this.iconId,
    required this.amount,
  });
}
