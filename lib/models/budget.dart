class Budget {
  final String id;
  final String accountId;
  final String category;
  final double limitAmount;
  final int colorValue;

  const Budget({
    required this.id,
    required this.accountId,
    required this.category,
    required this.limitAmount,
    required this.colorValue,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'accountId': accountId,
    'category': category,
    'limitAmount': limitAmount,
    'colorValue': colorValue,
  };

  factory Budget.fromJson(Map<String, dynamic> json) => Budget(
    id: json['id'],
    accountId: json['accountId'],
    category: json['category'],
    limitAmount: (json['limitAmount'] as num).toDouble(),
    colorValue: json['colorValue'],
  );
}
