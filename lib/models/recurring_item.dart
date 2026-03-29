class RecurringItem {
  final String id;
  final String accountId;
  final double amount;
  final String type; // 'income' | 'expense'
  final String category;
  final String description;
  final int dayOfMonth;
  bool isActive;

  RecurringItem({
    required this.id,
    required this.accountId,
    required this.amount,
    required this.type,
    required this.category,
    required this.description,
    required this.dayOfMonth,
    this.isActive = true,
  });

  bool get isIncome => type == 'income';
  bool get isExpense => type == 'expense';

  Map<String, dynamic> toJson() => {
    'id': id,
    'accountId': accountId,
    'amount': amount,
    'type': type,
    'category': category,
    'description': description,
    'dayOfMonth': dayOfMonth,
    'isActive': isActive,
  };

  factory RecurringItem.fromJson(Map<String, dynamic> json) => RecurringItem(
    id: json['id'],
    accountId: json['accountId'],
    amount: (json['amount'] as num).toDouble(),
    type: json['type'],
    category: json['category'],
    description: json['description'],
    dayOfMonth: json['dayOfMonth'],
    isActive: json['isActive'] ?? true,
  );
}
