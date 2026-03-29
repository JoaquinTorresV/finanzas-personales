import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/finance_provider.dart';
import '../providers/theme_provider.dart';
import '../models/transaction.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/common_widgets.dart';
import 'add_transaction_sheet.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});
  @override State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedMonth = DateTime.now();
  DateTime? _selectedDay;

  @override
  Widget build(BuildContext context) {
    final pv = context.watch<FinanceProvider>();
    final isDark = context.watch<ThemeProvider>().isDark;
    final top = MediaQuery.of(context).padding.top;
    final bg = isDark ? AppTheme.darkBg : AppTheme.lightBg;
    final bord = isDark ? AppTheme.darkBorder : AppTheme.lightBorder;
    final surfAlt = isDark ? AppTheme.darkSurfaceAlt : AppTheme.lightSurfaceAlt;

    final txByDay = pv.transactionsByDay;

    // Selected day transactions
    final selectedTxs = _selectedDay != null
        ? (txByDay[DateTime(_selectedDay!.year, _selectedDay!.month, _selectedDay!.day)] ?? [])
        : <Transaction>[];

    return Scaffold(
      body: Column(
        children: [
          // Header
          Container(
            color: bg,
            padding: EdgeInsets.fromLTRB(20, top + 16, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('Calendario', style: Theme.of(context).textTheme.headlineMedium),
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
                // Month nav
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => setState(() => _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1)),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(color: surfAlt, borderRadius: BorderRadius.circular(10), border: Border.all(color: bord)),
                        child: Icon(Icons.chevron_left, size: 18, color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      Fmt.monthCap(_focusedMonth),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () {
                        final next = DateTime(_focusedMonth.year, _focusedMonth.month + 1);
                        final now = DateTime.now();
                        if (!next.isAfter(DateTime(now.year, now.month, now.day + 1))) {
                          setState(() => _focusedMonth = next);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(color: surfAlt, borderRadius: BorderRadius.circular(10), border: Border.all(color: bord)),
                        child: Icon(Icons.chevron_right, size: 18, color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
          // Calendar grid
          Container(
            color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            child: Column(
              children: [
                // Day headers
                Row(
                  children: ['L','M','X','J','V','S','D'].map((d) => Expanded(
                    child: Center(
                      child: Text(d, style: TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w700,
                        color: d == 'S' || d == 'D'
                            ? AppTheme.primary.withOpacity(0.7)
                            : (isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted),
                      )),
                    ),
                  )).toList(),
                ),
                const SizedBox(height: 6),
                // Days grid
                _buildCalendarGrid(txByDay, isDark),
              ],
            ),
          ),
          Container(height: 1, color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
          // Selected day transactions
          Expanded(
            child: _selectedDay == null
                ? _MonthSummary(focusedMonth: _focusedMonth, txByDay: txByDay)
                : _DayDetail(day: _selectedDay!, transactions: selectedTxs),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid(Map<DateTime, List<Transaction>> txByDay, bool isDark) {
    final firstDay = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    // Monday = 0
    int startOffset = firstDay.weekday - 1;
    final daysInMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0).day;
    final today = DateTime.now();

    final cells = <Widget>[];
    // Empty cells before first day
    for (int i = 0; i < startOffset; i++) {
      cells.add(const SizedBox());
    }
    // Day cells
    for (int d = 1; d <= daysInMonth; d++) {
      final date = DateTime(_focusedMonth.year, _focusedMonth.month, d);
      final dayTxs = txByDay[date] ?? [];
      final isToday = date.year == today.year && date.month == today.month && date.day == today.day;
      final isSelected = _selectedDay != null &&
          _selectedDay!.year == date.year &&
          _selectedDay!.month == date.month &&
          _selectedDay!.day == date.day;

      final hasIncome  = dayTxs.any((t) => t.isIncome);
      final hasExpense = dayTxs.any((t) => t.isExpense);
      final isWeekend  = date.weekday == 6 || date.weekday == 7;

      cells.add(GestureDetector(
        onTap: () => setState(() => _selectedDay = isSelected ? null : date),
        child: Container(
          margin: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.primary
                : isToday
                    ? AppTheme.primary.withOpacity(0.15)
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: isToday && !isSelected
                ? Border.all(color: AppTheme.primary.withOpacity(0.5))
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$d',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isToday || isSelected ? FontWeight.w700 : FontWeight.w400,
                  color: isSelected
                      ? Colors.white
                      : isToday
                          ? AppTheme.primary
                          : isWeekend
                              ? AppTheme.primary.withOpacity(0.7)
                              : (isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary),
                ),
              ),
              if (hasIncome || hasExpense)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (hasIncome)  _Dot(color: isSelected ? Colors.white70 : AppTheme.income),
                      if (hasExpense) _Dot(color: isSelected ? Colors.white70 : AppTheme.expense),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ));
    }

    // Pad to complete last row
    while (cells.length % 7 != 0) cells.add(const SizedBox());

    return GridView.count(
      crossAxisCount: 7,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.0,
      children: cells,
    );
  }
}

class _Dot extends StatelessWidget {
  final Color color;
  const _Dot({required this.color});
  @override
  Widget build(BuildContext context) => Container(
    width: 4, height: 4, margin: const EdgeInsets.symmetric(horizontal: 1),
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}

// ─── Month summary when no day is selected ────────────────────────────────────

class _MonthSummary extends StatelessWidget {
  final DateTime focusedMonth;
  final Map<DateTime, List<Transaction>> txByDay;
  const _MonthSummary({required this.focusedMonth, required this.txByDay});

  @override
  Widget build(BuildContext context) {
    // Build list of days with transactions in focused month, sorted
    final days = txByDay.keys
        .where((d) => d.year == focusedMonth.year && d.month == focusedMonth.month)
        .toList()
      ..sort((a, b) => b.compareTo(a));

    if (days.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('Sin movimientos este mes', style: TextStyle(color: AppTheme.darkTextMuted)),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      itemCount: days.length,
      itemBuilder: (ctx, i) {
        final day = days[i];
        final txs = txByDay[day] ?? [];
        final total = txs.fold(0.0, (s, t) => s + (t.isIncome ? t.amount : -t.amount));
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Text(Fmt.fullDate(day),
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.darkTextSecondary)),
                  const Spacer(),
                  Text(
                    '${total >= 0 ? '+' : ''}${Fmt.money(total)}',
                    style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600,
                      color: total >= 0 ? AppTheme.income : AppTheme.expense,
                    ),
                  ),
                ],
              ),
            ),
            ...txs.map((tx) => TransactionTile(tx: tx)),
            const SizedBox(height: 4),
          ],
        );
      },
    );
  }
}

// ─── Day detail when a day is selected ───────────────────────────────────────

class _DayDetail extends StatelessWidget {
  final DateTime day;
  final List<Transaction> transactions;
  const _DayDetail({required this.day, required this.transactions});

  @override
  Widget build(BuildContext context) {
    final pv = context.read<FinanceProvider>();
    final isDark = context.watch<ThemeProvider>().isDark;
    final totalIncome  = transactions.where((t) => t.isIncome ).fold(0.0, (s, t) => s + t.amount);
    final totalExpense = transactions.where((t) => t.isExpense).fold(0.0, (s, t) => s + t.amount);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Day header strip
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: AppTheme.primary.withOpacity(0.08),
          child: Row(
            children: [
              Text(
                Fmt.fullDate(day),
                style: TextStyle(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              const Spacer(),
              if (totalIncome > 0) _MiniTag(label: '+${Fmt.money(totalIncome)}', color: AppTheme.income),
              if (totalIncome > 0 && totalExpense > 0) const SizedBox(width: 6),
              if (totalExpense > 0) _MiniTag(label: '-${Fmt.money(totalExpense)}', color: AppTheme.expense),
            ],
          ),
        ),
        Expanded(
          child: transactions.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('📭', style: TextStyle(fontSize: 36)),
                      const SizedBox(height: 8),
                      Text('Sin movimientos este día',
                          style: TextStyle(color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted)),
                    ],
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                  children: transactions.map((tx) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: TransactionTile(
                      tx: tx,
                      onDelete: () => pv.deleteTransaction(tx.id),
                    ),
                  )).toList(),
                ),
        ),
      ],
    );
  }
}

class _MiniTag extends StatelessWidget {
  final String label;
  final Color color;
  const _MiniTag({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
    child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
  );
}
