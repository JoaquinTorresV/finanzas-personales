import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/account.dart';
import '../models/transaction.dart';
import '../models/recurring_item.dart';
import '../models/savings_goal.dart';

class FinanceProvider extends ChangeNotifier {
  static const _uuid = Uuid();

  List<Account> _accounts = [];
  List<Transaction> _transactions = [];
  List<RecurringItem> _recurringItems = [];
  List<SavingsGoal> _savingsGoals = [];
  String? _selectedAccountId;
  DateTime _selectedMonth = DateTime.now();
  bool _isLoading = true;

  // ─── Getters ────────────────────────────────────────────────────────────────

  List<Account> get accounts => _accounts;
  List<Transaction> get allTransactions => _transactions;
  List<RecurringItem> get allRecurringItems => _recurringItems;
  List<SavingsGoal> get allSavingsGoals => _savingsGoals;
  bool get isLoading => _isLoading;
  DateTime get selectedMonth => _selectedMonth;

  Account? get selectedAccount {
    if (_accounts.isEmpty) return null;
    try {
      return _accounts.firstWhere((a) => a.id == _selectedAccountId);
    } catch (_) {
      return _accounts.first;
    }
  }

  List<Transaction> get filteredTransactions {
    final acc = selectedAccount;
    if (acc == null) return [];
    return _transactions
        .where((t) =>
            t.accountId == acc.id &&
            t.date.year == _selectedMonth.year &&
            t.date.month == _selectedMonth.month)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  List<RecurringItem> get filteredRecurring {
    final acc = selectedAccount;
    if (acc == null) return [];
    return _recurringItems.where((r) => r.accountId == acc.id).toList();
  }

  List<SavingsGoal> get filteredSavings {
    final acc = selectedAccount;
    if (acc == null) return [];
    return _savingsGoals.where((s) => s.accountId == acc.id).toList();
  }

  double get totalIncome => filteredTransactions
      .where((t) => t.isIncome)
      .fold(0.0, (s, t) => s + t.amount);

  double get totalExpenses => filteredTransactions
      .where((t) => t.isExpense)
      .fold(0.0, (s, t) => s + t.amount);

  double get balance => totalIncome - totalExpenses;

  double get totalSaved => filteredSavings.fold(0.0, (s, g) => s + g.currentAmount);

  double get monthlyRecurringExpenses => filteredRecurring
      .where((r) => r.isExpense && r.isActive)
      .fold(0.0, (s, r) => s + r.amount);

  double get monthlyRecurringIncome => filteredRecurring
      .where((r) => r.isIncome && r.isActive)
      .fold(0.0, (s, r) => s + r.amount);

  // Returns last 6 months income/expense for chart
  List<Map<String, dynamic>> get last6MonthsData {
    final acc = selectedAccount;
    if (acc == null) return [];
    final result = <Map<String, dynamic>>[];
    for (int i = 5; i >= 0; i--) {
      final m = DateTime(DateTime.now().year, DateTime.now().month - i, 1);
      final txs = _transactions.where((t) =>
          t.accountId == acc.id &&
          t.date.year == m.year &&
          t.date.month == m.month);
      result.add({
        'month': m,
        'income': txs.where((t) => t.isIncome).fold(0.0, (s, t) => s + t.amount),
        'expense': txs.where((t) => t.isExpense).fold(0.0, (s, t) => s + t.amount),
      });
    }
    return result;
  }

  // ─── Account operations ─────────────────────────────────────────────────────

  void selectAccount(String id) {
    _selectedAccountId = id;
    notifyListeners();
    _persist();
  }

  Future<void> addAccount(Account account) async {
    _accounts.add(account);
    if (_accounts.length == 1) _selectedAccountId = account.id;
    await _persist();
    notifyListeners();
  }

  Future<void> deleteAccount(String id) async {
    _accounts.removeWhere((a) => a.id == id);
    _transactions.removeWhere((t) => t.accountId == id);
    _recurringItems.removeWhere((r) => r.accountId == id);
    _savingsGoals.removeWhere((s) => s.accountId == id);
    if (_selectedAccountId == id) {
      _selectedAccountId = _accounts.isNotEmpty ? _accounts.first.id : null;
    }
    await _persist();
    notifyListeners();
  }

  // ─── Transaction operations ──────────────────────────────────────────────────

  Future<void> addTransaction(Transaction tx) async {
    _transactions.add(tx);
    await _persist();
    notifyListeners();
  }

  Future<void> deleteTransaction(String id) async {
    _transactions.removeWhere((t) => t.id == id);
    await _persist();
    notifyListeners();
  }

  // ─── Recurring operations ────────────────────────────────────────────────────

  Future<void> addRecurringItem(RecurringItem item) async {
    _recurringItems.add(item);
    await _persist();
    notifyListeners();
  }

  Future<void> toggleRecurring(String id) async {
    final i = _recurringItems.indexWhere((r) => r.id == id);
    if (i >= 0) {
      _recurringItems[i].isActive = !_recurringItems[i].isActive;
      await _persist();
      notifyListeners();
    }
  }

  Future<void> deleteRecurringItem(String id) async {
    _recurringItems.removeWhere((r) => r.id == id);
    await _persist();
    notifyListeners();
  }

  /// Register all active recurring items as transactions for the selected month
  Future<int> applyRecurring() async {
    final acc = selectedAccount;
    if (acc == null) return 0;
    int count = 0;
    final now = _selectedMonth;

    for (final item in filteredRecurring) {
      if (!item.isActive) continue;
      final day = item.dayOfMonth.clamp(1, 28);
      final targetDate = DateTime(now.year, now.month, day);

      final alreadyApplied = _transactions.any((t) =>
          t.accountId == acc.id &&
          t.description == '${item.description} (recurrente)' &&
          t.date.year == now.year &&
          t.date.month == now.month &&
          t.isRecurring);

      if (!alreadyApplied) {
        _transactions.add(Transaction(
          id: _uuid.v4(),
          accountId: acc.id,
          amount: item.amount,
          type: item.type,
          category: item.category,
          description: '${item.description} (recurrente)',
          date: targetDate,
          isRecurring: true,
        ));
        count++;
      }
    }
    if (count > 0) {
      await _persist();
      notifyListeners();
    }
    return count;
  }

  // ─── Savings operations ──────────────────────────────────────────────────────

  Future<void> addSavingsGoal(SavingsGoal goal) async {
    _savingsGoals.add(goal);
    await _persist();
    notifyListeners();
  }

  Future<void> addToSavings(String id, double amount) async {
    final i = _savingsGoals.indexWhere((s) => s.id == id);
    if (i >= 0) {
      _savingsGoals[i] =
          _savingsGoals[i].copyWith(currentAmount: _savingsGoals[i].currentAmount + amount);
      await _persist();
      notifyListeners();
    }
  }

  Future<void> deleteSavingsGoal(String id) async {
    _savingsGoals.removeWhere((s) => s.id == id);
    await _persist();
    notifyListeners();
  }

  // ─── Month navigation ────────────────────────────────────────────────────────

  void previousMonth() {
    _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
    notifyListeners();
  }

  void nextMonth() {
    final next = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
    final now = DateTime.now();
    if (!next.isAfter(DateTime(now.year, now.month))) {
      _selectedMonth = next;
      notifyListeners();
    }
  }

  bool get canGoNext {
    final now = DateTime.now();
    return _selectedMonth.year < now.year ||
        (_selectedMonth.year == now.year && _selectedMonth.month < now.month);
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────────

  String newId() => _uuid.v4();

  // ─── Persistence ─────────────────────────────────────────────────────────────

  Future<void> load() async {
    _isLoading = true;
    notifyListeners();

    try {
      final p = await SharedPreferences.getInstance();

      void decode<T>(String key, List<T> list, T Function(Map<String, dynamic>) fromJson) {
        final raw = p.getString(key);
        if (raw != null) {
          list.addAll((jsonDecode(raw) as List).map((e) => fromJson(e as Map<String, dynamic>)));
        }
      }

      decode('accounts', _accounts, Account.fromJson);
      decode('transactions', _transactions, Transaction.fromJson);
      decode('recurring', _recurringItems, RecurringItem.fromJson);
      decode('savings', _savingsGoals, SavingsGoal.fromJson);

      _selectedAccountId = p.getString('selectedAccountId');

      if (_accounts.isEmpty) {
        final personal = Account(
          id: _uuid.v4(),
          name: 'Personal',
          icon: '👤',
          colorValue: 0xFF8B5CF6,
        );
        _accounts.add(personal);
        _selectedAccountId = personal.id;

        // Add sample recurring items
        _recurringItems.addAll([
          RecurringItem(
            id: _uuid.v4(),
            accountId: personal.id,
            amount: 15000,
            type: 'expense',
            category: 'Suscripción',
            description: 'Plan de teléfono',
            dayOfMonth: 5,
          ),
          RecurringItem(
            id: _uuid.v4(),
            accountId: personal.id,
            amount: 5000,
            type: 'expense',
            category: 'Suscripción',
            description: 'YouTube Premium',
            dayOfMonth: 10,
          ),
          RecurringItem(
            id: _uuid.v4(),
            accountId: personal.id,
            amount: 8000,
            type: 'expense',
            category: 'Suscripción',
            description: 'Claude.ai',
            dayOfMonth: 15,
          ),
        ]);

        await _persist();
      }
    } catch (e) {
      debugPrint('FinanceProvider.load error: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _persist() async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString('accounts', jsonEncode(_accounts.map((a) => a.toJson()).toList()));
      await p.setString('transactions', jsonEncode(_transactions.map((t) => t.toJson()).toList()));
      await p.setString('recurring', jsonEncode(_recurringItems.map((r) => r.toJson()).toList()));
      await p.setString('savings', jsonEncode(_savingsGoals.map((s) => s.toJson()).toList()));
      if (_selectedAccountId != null) {
        await p.setString('selectedAccountId', _selectedAccountId!);
      }
    } catch (e) {
      debugPrint('FinanceProvider._persist error: $e');
    }
  }

  // ─── Static data ─────────────────────────────────────────────────────────────

  static const List<String> expenseCategories = [
    'Suscripción',
    'Alimentación',
    'Transporte',
    'Entretenimiento',
    'Salud',
    'Educación',
    'Arriendo',
    'Servicios',
    'Ropa',
    'Tecnología',
    'Otros',
  ];

  static const List<String> incomeCategories = [
    'Freelance',
    'Agencia IA',
    'Salario',
    'Inversión',
    'Arriendo',
    'Proyecto',
    'Otros',
  ];

  static const Map<String, String> categoryEmoji = {
    'Suscripción': '📱',
    'Alimentación': '🍽️',
    'Transporte': '🚗',
    'Entretenimiento': '🎬',
    'Salud': '💊',
    'Educación': '📚',
    'Arriendo': '🏠',
    'Servicios': '⚡',
    'Ropa': '👕',
    'Tecnología': '💻',
    'Freelance': '💻',
    'Agencia IA': '🤖',
    'Salario': '💼',
    'Inversión': '📈',
    'Proyecto': '🎯',
    'Otros': '💰',
  };

  static const List<Map<String, dynamic>> accountColors = [
    {'label': 'Violeta', 'value': 0xFF8B5CF6},
    {'label': 'Azul', 'value': 0xFF3B82F6},
    {'label': 'Verde', 'value': 0xFF10B981},
    {'label': 'Rosa', 'value': 0xFFEC4899},
    {'label': 'Naranja', 'value': 0xFFF59E0B},
    {'label': 'Cian', 'value': 0xFF06B6D4},
    {'label': 'Rojo', 'value': 0xFFEF4444},
    {'label': 'Lima', 'value': 0xFF84CC16},
  ];

  static const List<String> accountIcons = [
    '👤', '🏢', '💼', '🤖', '🎨', '🌐', '🏦', '🎯', '🚀', '⭐',
  ];

  static const List<String> savingsIcons = [
    '🎯', '🏠', '✈️', '🚗', '💻', '📱', '🎓', '💍', '🌴', '🎮',
    '📷', '🎸', '⌚', '🏋️', '💰', '🌟',
  ];
}
