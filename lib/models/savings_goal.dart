class SavingsGoal {
  final String id;
  final String accountId;
  final String name;
  final double targetAmount;
  double currentAmount;
  final int colorValue;
  final String icon;
  final DateTime createdAt;

  SavingsGoal({
    required this.id,
    required this.accountId,
    required this.name,
    required this.targetAmount,
    required this.currentAmount,
    required this.colorValue,
    required this.icon,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  double get progress =>
      targetAmount > 0 ? (currentAmount / targetAmount).clamp(0.0, 1.0) : 0.0;
  bool get isCompleted => currentAmount >= targetAmount;
  double get remaining => (targetAmount - currentAmount).clamp(0.0, double.infinity);

  Map<String, dynamic> toJson() => {
    'id': id,
    'accountId': accountId,
    'name': name,
    'targetAmount': targetAmount,
    'currentAmount': currentAmount,
    'colorValue': colorValue,
    'icon': icon,
    'createdAt': createdAt.toIso8601String(),
  };

  factory SavingsGoal.fromJson(Map<String, dynamic> json) => SavingsGoal(
    id: json['id'],
    accountId: json['accountId'],
    name: json['name'],
    targetAmount: (json['targetAmount'] as num).toDouble(),
    currentAmount: (json['currentAmount'] as num).toDouble(),
    colorValue: json['colorValue'],
    icon: json['icon'] ?? '🎯',
    createdAt: json['createdAt'] != null
        ? DateTime.parse(json['createdAt'])
        : DateTime.now(),
  );

  SavingsGoal copyWith({double? currentAmount}) => SavingsGoal(
    id: id,
    accountId: accountId,
    name: name,
    targetAmount: targetAmount,
    currentAmount: currentAmount ?? this.currentAmount,
    colorValue: colorValue,
    icon: icon,
    createdAt: createdAt,
  );
}
