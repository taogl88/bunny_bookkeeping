/// 预算条目
///
/// - [periodType] 取值 'month' / 'year'，区分月度预算与年度预算
/// - [period] 月度为 'YYYY-MM'，年度为 'YYYY'
/// - [isTotal] 为 true 时是该 period 的总预算（每个 period 唯一一条），
///   为 false 时是分类预算（按 [iconId] 区分）
/// - 分类预算固定使用支出类目（[CategoryItem.inEx] == 0）
class BudgetItem {
  final String id;
  final String periodType;
  final String period;
  final bool isTotal;
  final String category;
  final int iconId;
  final double amount;
  final String createdAt;
  final String updatedAt;

  const BudgetItem({
    required this.id,
    required this.periodType,
    required this.period,
    required this.isTotal,
    required this.category,
    required this.iconId,
    required this.amount,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'period_type': periodType,
      'period': period,
      'is_total': isTotal ? 1 : 0,
      'category': category,
      'icon_id': iconId,
      'amount': amount,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  factory BudgetItem.fromMap(Map<String, dynamic> map) {
    return BudgetItem(
      id: map['id'] as String,
      periodType: map['period_type'] as String,
      period: map['period'] as String,
      isTotal: (map['is_total'] as int) == 1,
      category: (map['category'] as String?) ?? '',
      iconId: (map['icon_id'] as int?) ?? -1,
      amount: (map['amount'] as num).toDouble(),
      createdAt: map['created_at'] as String,
      updatedAt: map['updated_at'] as String,
    );
  }

  BudgetItem copyWith({
    String? id,
    String? periodType,
    String? period,
    bool? isTotal,
    String? category,
    int? iconId,
    double? amount,
    String? createdAt,
    String? updatedAt,
  }) {
    return BudgetItem(
      id: id ?? this.id,
      periodType: periodType ?? this.periodType,
      period: period ?? this.period,
      isTotal: isTotal ?? this.isTotal,
      category: category ?? this.category,
      iconId: iconId ?? this.iconId,
      amount: amount ?? this.amount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
