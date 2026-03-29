class Transaction {
  final String id;
  final String accountId;
  final double amount;
  final String type; // 'income' | 'expense'
  final String category;
  final String description;
  final DateTime date;
  final bool isRecurring;

  const Transaction({
    required this.id,
    required this.accountId,
    required this.amount,
    required this.type,
    required this.category,
    required this.description,
    required this.date,
    this.isRecurring = false,
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
    'date': date.toIso8601String(),
    'isRecurring': isRecurring,
  };

  factory Transaction.fromJson(Map<String, dynamic> json) => Transaction(
    id: json['id'],
    accountId: json['accountId'],
    amount: (json['amount'] as num).toDouble(),
    type: json['type'],
    category: json['category'],
    description: json['description'],
    date: DateTime.parse(json['date']),
    isRecurring: json['isRecurring'] ?? false,
  );
}
