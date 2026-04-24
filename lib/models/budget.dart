class Budget {
  const Budget({
    this.id,
    required this.name,
    required this.limitAmount,
    required this.startDate,
    required this.endDate,
    this.categoryId,
  });

  final int? id;
  final String name;
  final double limitAmount;
  final DateTime startDate;
  final DateTime endDate;
  final int? categoryId;

  Budget copyWith({
    int? id,
    String? name,
    double? limitAmount,
    DateTime? startDate,
    DateTime? endDate,
    int? categoryId,
  }) {
    return Budget(
      id: id ?? this.id,
      name: name ?? this.name,
      limitAmount: limitAmount ?? this.limitAmount,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      categoryId: categoryId ?? this.categoryId,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'limit_amount': limitAmount,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'category_id': categoryId,
    };
  }

  factory Budget.fromMap(Map<String, dynamic> map) {
    return Budget(
      id: map['id'] as int?,
      name: map['name'] as String,
      limitAmount: (map['limit_amount'] as num).toDouble(),
      startDate: DateTime.parse(map['start_date'] as String),
      endDate: DateTime.parse(map['end_date'] as String),
      categoryId: map['category_id'] as int?,
    );
  }
}
