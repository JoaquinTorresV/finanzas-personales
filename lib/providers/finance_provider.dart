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

  List<Account>       _accounts       = [];
  List<Transaction>   _transactions   = [];
  List<RecurringItem> _recurringItems = [];
  List<SavingsGoal>   _savingsGoals   = [];
  List<Budget>        _budgets        = [];
  String?  _selectedAccountId;
  DateTime _selectedMonth = DateTime.now();
  bool _isLoading = true;

  // ─── Getters ─────────────────────────────────────────────────────────────────

  List<Account>       get accounts       => _accounts;
  List<Transaction>   get allTransactions => _transactions;
  List<RecurringItem> get allRecurringItems => _recurringItems;
  List<SavingsGoal>   get allSavingsGoals => _savingsGoals;
  List<Budget>        get allBudgets      => _budgets;
  bool     get isLoading     => _isLoading;
  DateTime get selectedMonth => _selectedMonth;
  bool get notificationsEnabled => _notificationsEnabled;
  bool get goalCompletedNotificationsEnabled => _goalCompletedNotificationsEnabled;
  bool get lowBalanceRecurringNotificationsEnabled =>
      _lowBalanceRecurringNotificationsEnabled;
  int get lowBalanceRecurringDaysBefore => _lowBalanceRecurringDaysBefore;

  Account? get selectedAccount {
    if (_accounts.isEmpty) return null;
    try { return _accounts.firstWhere((a) => a.id == _selectedAccountId); }
    catch (_) { return _accounts.first; }
  }

  List<Transaction> get filteredTransactions {
    final acc = selectedAccount;
    if (acc == null) return [];
    return _transactions
        .where((t) => t.accountId == acc.id &&
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

  List<Budget> get filteredBudgets {
    final acc = selectedAccount;
    if (acc == null) return [];
    return _budgets.where((b) => b.accountId == acc.id).toList();
  }

  double get totalIncome   => filteredTransactions.where((t) => t.isIncome).fold(0.0, (s, t) => s + t.amount);
  double get totalExpenses => filteredTransactions.where((t) => t.isExpense).fold(0.0, (s, t) => s + t.amount);
  double get balance       => totalIncome - totalExpenses;
  double get totalSaved    => filteredSavings.fold(0.0, (s, g) => s + g.currentAmount);

  double get monthlyRecurringExpenses => filteredRecurring.where((r) => r.isExpense && r.isActive).fold(0.0, (s, r) => s + r.amount);
  double get monthlyRecurringIncome   => filteredRecurring.where((r) => r.isIncome  && r.isActive).fold(0.0, (s, r) => s + r.amount);

  /// Expense amount for a specific category this month
  double spentInCategory(String category) => filteredTransactions
      .where((t) => t.isExpense && t.category == category)
      .fold(0.0, (s, t) => s + t.amount);

  /// Expense breakdown by category for current month
  Map<String, double> get expensesByCategory {
    final map = <String, double>{};
    for (final t in filteredTransactions.where((t) => t.isExpense)) {
      map[t.category] = (map[t.category] ?? 0) + t.amount;
    }
    return Map.fromEntries(map.entries.toList()..sort((a, b) => b.value.compareTo(a.value)));
  }

  /// Last 6 months income/expense for bar chart
  List<Map<String, dynamic>> get last6MonthsData {
    final acc = selectedAccount;
    if (acc == null) return [];
    final result = <Map<String, dynamic>>[];
    for (int i = 5; i >= 0; i--) {
      final m = DateTime(DateTime.now().year, DateTime.now().month - i, 1);
      final txs = _transactions.where((t) =>
          t.accountId == acc.id && t.date.year == m.year && t.date.month == m.month);
      result.add({
        'month': m,
        'income':  txs.where((t) => t.isIncome ).fold(0.0, (s, t) => s + t.amount),
        'expense': txs.where((t) => t.isExpense).fold(0.0, (s, t) => s + t.amount),
      });
    }
    return result;
  }

  /// Average monthly savings over last 3 months (for projection)
  double get avgMonthlySavings {
    final acc = selectedAccount;
    if (acc == null) return 0;
    double total = 0;
    int count = 0;
    for (int i = 1; i <= 3; i++) {
      final m = DateTime(DateTime.now().year, DateTime.now().month - i, 1);
      final txs = _transactions.where((t) =>
          t.accountId == acc.id && t.date.year == m.year && t.date.month == m.month);
      final inc = txs.where((t) => t.isIncome ).fold(0.0, (s, t) => s + t.amount);
      final exp = txs.where((t) => t.isExpense).fold(0.0, (s, t) => s + t.amount);
      if (inc > 0 || exp > 0) { total += (inc - exp); count++; }
    }
    return count > 0 ? total / count : 0;
  }

  /// Transactions grouped by day for calendar view
  Map<DateTime, List<Transaction>> get transactionsByDay {
    final acc = selectedAccount;
    if (acc == null) return {};
    final map = <DateTime, List<Transaction>>{};
    for (final t in _transactions.where((t) => t.accountId == acc.id)) {
      final day = DateTime(t.date.year, t.date.month, t.date.day);
      map.putIfAbsent(day, () => []).add(t);
    }
    return map;
  }

  // ─── Account ops ─────────────────────────────────────────────────────────────
  void selectAccount(String id) { _selectedAccountId = id; notifyListeners(); _persist(); }

  Future<void> addAccount(Account a) async {
    _accounts.add(a);
    if (_accounts.length == 1) _selectedAccountId = a.id;
    await _persist(); notifyListeners();
  }

  Future<void> deleteAccount(String id) async {
    _accounts.removeWhere((a) => a.id == id);
    _transactions.removeWhere((t) => t.accountId == id);
    _recurringItems.removeWhere((r) => r.accountId == id);
    _savingsGoals.removeWhere((s) => s.accountId == id);
    _budgets.removeWhere((b) => b.accountId == id);
    if (_selectedAccountId == id) _selectedAccountId = _accounts.isNotEmpty ? _accounts.first.id : null;
    await _persist(); notifyListeners();
  }

  // ─── Transaction ops ──────────────────────────────────────────────────────────
  Future<void> addTransaction(Transaction tx) async {
    _transactions.add(tx); await _persist(); notifyListeners();
  }
  Future<void> deleteTransaction(String id) async {
    _transactions.removeWhere((t) => t.id == id); await _persist(); notifyListeners();
  }

  // ─── Recurring ops ───────────────────────────────────────────────────────────
  Future<void> addRecurringItem(RecurringItem item) async {
    _recurringItems.add(item); await _persist(); notifyListeners();
  }
  Future<void> toggleRecurring(String id) async {
    final i = _recurringItems.indexWhere((r) => r.id == id);
    if (i >= 0) { _recurringItems[i].isActive = !_recurringItems[i].isActive; await _persist(); notifyListeners(); }
  }
  Future<void> deleteRecurringItem(String id) async {
    _recurringItems.removeWhere((r) => r.id == id); await _persist(); notifyListeners();
  }
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
          t.date.year == now.year && t.date.month == now.month && t.isRecurring);
      if (!alreadyApplied) {
        _transactions.add(Transaction(
          id: _uuid.v4(), accountId: acc.id, amount: item.amount,
          type: item.type, category: item.category,
          description: '${item.description} (recurrente)',
          date: targetDate, isRecurring: true,
        ));
        count++;
      }
    }
    if (count > 0) { await _persist(); notifyListeners(); }
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
    _savingsGoals.removeWhere((s) => s.id == id); await _persist(); notifyListeners();
  }

  // ─── Budget ops ───────────────────────────────────────────────────────────────
  Future<void> addBudget(Budget b) async {
    // Replace if same category already exists for this account
    _budgets.removeWhere((x) => x.accountId == b.accountId && x.category == b.category);
    _budgets.add(b);
    await _persist(); notifyListeners();
  }
  Future<void> deleteBudget(String id) async {
    _budgets.removeWhere((b) => b.id == id); await _persist(); notifyListeners();
  }

  // ─── Month nav ────────────────────────────────────────────────────────────────
  void previousMonth() {
    _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
    notifyListeners();
  }
  void nextMonth() {
    final next = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
    final now = DateTime.now();
    if (!next.isAfter(DateTime(now.year, now.month))) { _selectedMonth = next; notifyListeners(); }
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
    _isLoading = true; notifyListeners();
    try {
      final p = await SharedPreferences.getInstance();
      void decode<T>(String key, List<T> list, T Function(Map<String, dynamic>) fn) {
        final raw = p.getString(key);
        if (raw != null) list.addAll((jsonDecode(raw) as List).map((e) => fn(e as Map<String, dynamic>)));
      }
      decode('accounts',     _accounts,       Account.fromJson);
      decode('transactions', _transactions,   Transaction.fromJson);
      decode('recurring',    _recurringItems, RecurringItem.fromJson);
      decode('savings',      _savingsGoals,   SavingsGoal.fromJson);
      decode('budgets',      _budgets,        Budget.fromJson);
      _selectedAccountId = p.getString('selectedAccountId');

      _notificationsEnabled = p.getBool('notificationsEnabled') ?? true;
      _goalCompletedNotificationsEnabled =
          p.getBool('goalCompletedNotificationsEnabled') ?? true;
      _lowBalanceRecurringNotificationsEnabled =
          p.getBool('lowBalanceRecurringNotificationsEnabled') ?? true;
      _lowBalanceRecurringDaysBefore =
          (p.getInt('lowBalanceRecurringDaysBefore') ?? 2).clamp(1, 7);

      _sentGoalNotificationKeys
        ..clear()
        ..addAll(p.getStringList('sentGoalNotificationKeys') ?? const []);
      _sentRecurringNotificationKeys
        ..clear()
        ..addAll(p.getStringList('sentRecurringNotificationKeys') ?? const []);

      if (_accounts.isEmpty) {
        final personal = Account(id: _uuid.v4(), name: 'Personal', icon: '👤', colorValue: 0xFF7C3AED);
        _accounts.add(personal);
        _selectedAccountId = personal.id;
        _recurringItems.addAll([
          RecurringItem(id: _uuid.v4(), accountId: personal.id, amount: 15000, type: 'expense', category: 'Suscripción', description: 'Plan de teléfono', dayOfMonth: 5),
          RecurringItem(id: _uuid.v4(), accountId: personal.id, amount: 5000,  type: 'expense', category: 'Suscripción', description: 'YouTube Premium',  dayOfMonth: 10),
          RecurringItem(id: _uuid.v4(), accountId: personal.id, amount: 8000,  type: 'expense', category: 'Suscripción', description: 'Claude.ai',         dayOfMonth: 15),
        ]);
        _budgets.addAll([
          Budget(id: _uuid.v4(), accountId: personal.id, category: 'Alimentación', limitAmount: 200000, colorValue: 0xFF10B981),
          Budget(id: _uuid.v4(), accountId: personal.id, category: 'Suscripción',  limitAmount: 50000,  colorValue: 0xFF8B5CF6),
          Budget(id: _uuid.v4(), accountId: personal.id, category: 'Transporte',   limitAmount: 80000,  colorValue: 0xFF3B82F6),
        ]);
        await _persist();
      }
    } catch (e) { debugPrint('FinanceProvider.load error: $e'); }
    _isLoading = false; notifyListeners();
  }

  Future<void> _persist() async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString('accounts',     jsonEncode(_accounts.map((a) => a.toJson()).toList()));
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
    'Freelance','Agencia IA','Salario','Inversión','Arriendo','Proyecto','Otros',
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
    {'label':'Violeta','value':0xFF7C3AED},{'label':'Azul','value':0xFF2563EB},
    {'label':'Verde',  'value':0xFF059669},{'label':'Rosa', 'value':0xFFDB2777},
    {'label':'Naranja','value':0xFFD97706},{'label':'Cian', 'value':0xFF0891B2},
    {'label':'Rojo',   'value':0xFFDC2626},{'label':'Lima', 'value':0xFF65A30D},
  ];
  static const List<String> accountIcons = ['👤','🏢','💼','🤖','🎨','🌐','🏦','🎯','🚀','⭐'];
  static const List<String> savingsIcons = [
    '🎯','🏠','✈️','🚗','💻','📱','🎓','💍','🌴','🎮','📷','🎸','⌚','🏋️','💰','🌟',
  ];
  static const List<int> budgetColors = [
    0xFF7C3AED,0xFF2563EB,0xFF059669,0xFFDB2777,
    0xFFD97706,0xFF0891B2,0xFFDC2626,0xFF65A30D,
  ];
}
