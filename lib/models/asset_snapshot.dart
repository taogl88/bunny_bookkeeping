class AssetSnapshot {
  final String id;
  final String assetId;
  final String yearMonth;
  final double balance;
  final String note;
  final String createdAt;
  final String updatedAt;

  const AssetSnapshot({
    required this.id,
    required this.assetId,
    required this.yearMonth,
    required this.balance,
    required this.note,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'asset_id': assetId,
      'year_month': yearMonth,
      'balance': balance,
      'note': note,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  factory AssetSnapshot.fromMap(Map<String, dynamic> map) {
    return AssetSnapshot(
      id: map['id'] as String,
      assetId: map['asset_id'] as String,
      yearMonth: map['year_month'] as String,
      balance: (map['balance'] as num).toDouble(),
      note: (map['note'] as String?) ?? '',
      createdAt: map['created_at'] as String,
      updatedAt: map['updated_at'] as String,
    );
  }
}
