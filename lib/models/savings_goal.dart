class SavingsGoal {
  const SavingsGoal({
    this.id,
    required this.name,
    required this.targetAmount,
    required this.savedAmount,
    required this.deadline,
    required this.createdAt,
  });

  final int? id;
  final String name;
  final double targetAmount;
  final double savedAmount;
  final DateTime deadline;
  final DateTime createdAt;

  double get progress => targetAmount <= 0 ? 0 : savedAmount / targetAmount;

  double get remainingAmount => targetAmount - savedAmount;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'target_amount': targetAmount,
      'saved_amount': savedAmount,
      'deadline': deadline.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory SavingsGoal.fromMap(Map<String, dynamic> map) {
    return SavingsGoal(
      id: map['id'] as int?,
      name: map['name'] as String,
      targetAmount: (map['target_amount'] as num).toDouble(),
      savedAmount: (map['saved_amount'] as num).toDouble(),
      deadline: DateTime.parse(map['deadline'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
