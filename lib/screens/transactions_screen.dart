import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/finance_provider.dart';
import '../models/transaction.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/common_widgets.dart';
import 'add_transaction_sheet.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  String _filter = 'all'; // all | income | expense

  @override
  Widget build(BuildContext context) {
    final pv = context.watch<FinanceProvider>();
    final top = MediaQuery.of(context).padding.top;

    List<Transaction> txs = pv.filteredTransactions;
    if (_filter == 'income') txs = txs.where((t) => t.isIncome).toList();
    if (_filter == 'expense') txs = txs.where((t) => t.isExpense).toList();

    // Group by date
    final Map<String, List<Transaction>> grouped = {};
    for (final tx in txs) {
      final key = Fmt.fullDate(tx.date);
      grouped.putIfAbsent(key, () => []).add(tx);
    }
    final dates = grouped.keys.toList();

    return Scaffold(
      body: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.fromLTRB(20, top + 16, 20, 0),
            color: AppTheme.bg,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('Movimientos', style: Theme.of(context).textTheme.headlineMedium),
                    const Spacer(),
                    IconButton(
                      onPressed: () => showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => const AddTransactionSheet(),
                      ),
                      icon: const Icon(Icons.add_circle_outline),
                      color: AppTheme.primaryLight,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Summary row
                Row(
                  children: [
                    _SummaryPill(
                      label: 'Ingresos',
                      amount: pv.totalIncome,
                      color: AppTheme.income,
                    ),
                    const SizedBox(width: 8),
                    _SummaryPill(
                      label: 'Gastos',
                      amount: pv.totalExpenses,
                      color: AppTheme.expense,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Filter chips
                Row(
                  children: [
                    _FilterChip(label: 'Todos', value: 'all', current: _filter, onTap: (v) => setState(() => _filter = v)),
                    const SizedBox(width: 8),
                    _FilterChip(label: '↓ Ingresos', value: 'income', current: _filter, onTap: (v) => setState(() => _filter = v), color: AppTheme.income),
                    const SizedBox(width: 8),
                    _FilterChip(label: '↑ Gastos', value: 'expense', current: _filter, onTap: (v) => setState(() => _filter = v), color: AppTheme.expense),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
          const Divider(height: 1),

          // List
          Expanded(
            child: txs.isEmpty
                ? Center(
                    child: EmptyState(
                      emoji: '🧾',
                      title: 'Sin movimientos',
                      subtitle: 'No hay ${_filter == 'income' ? 'ingresos' : _filter == 'expense' ? 'gastos' : 'movimientos'} este mes',
                      actionLabel: 'Agregar',
                      onAction: () => showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => AddTransactionSheet(initialIsIncome: _filter == 'income'),
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
                    itemCount: dates.length,
                    itemBuilder: (context, i) {
                      final date = dates[i];
                      final dayTxs = grouped[date]!;
                      final dayTotal = dayTxs.fold(0.0, (s, t) => s + (t.isIncome ? t.amount : -t.amount));
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Row(
                              children: [
                                Text(
                                  date,
                                  style: const TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  '${dayTotal >= 0 ? '+' : ''}${Fmt.money(dayTotal)}',
                                  style: TextStyle(
                                    color: dayTotal >= 0 ? AppTheme.income : AppTheme.expense,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ...dayTxs.map((tx) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: TransactionTile(
                              tx: tx,
                              onDelete: () => context.read<FinanceProvider>().deleteTransaction(tx.id),
                            ),
                          )),
                          if (i < dates.length - 1) const SizedBox(height: 4),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _SummaryPill extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;

  const _SummaryPill({required this.label, required this.amount, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w500)),
          const SizedBox(width: 4),
          Text(
            Fmt.money(amount),
            style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final String value;
  final String current;
  final Function(String) onTap;
  final Color? color;

  const _FilterChip({
    required this.label,
    required this.value,
    required this.current,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final selected = value == current;
    final c = color ?? AppTheme.primary;
    return GestureDetector(
      onTap: () => onTap(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? c.withOpacity(0.15) : AppTheme.surfaceAlt,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? c.withOpacity(0.5) : AppTheme.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? c : AppTheme.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
