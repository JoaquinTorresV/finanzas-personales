import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/finance_provider.dart';
import '../providers/theme_provider.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/common_widgets.dart';
import 'add_transaction_sheet.dart';
import 'accounts_sheet.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final pv = context.watch<FinanceProvider>();

    if (pv.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppTheme.primary)),
      );
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _Header()),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _BalanceCard(),
                const SizedBox(height: 16),
                _StatsRow(),
                const SizedBox(height: 20),
                _ChartCard(),
                const SizedBox(height: 20),
                _RecentTransactions(),
              ]),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTx(context),
        child: const Icon(Icons.add, size: 26),
      ),
    );
  }

  void _showAddTx(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddTransactionSheet(),
    );
  }
}

// ─── Header ──────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final pv = context.watch<FinanceProvider>();
    final tp = context.watch<ThemeProvider>();
    final top = MediaQuery.of(context).padding.top;
    final isDark = tp.isDark;
    final surfAlt = isDark ? AppTheme.darkSurfaceAlt : AppTheme.lightSurfaceAlt;
    final bord    = isDark ? AppTheme.darkBorder     : AppTheme.lightBorder;
    final textPri = isDark ? AppTheme.darkTextPrimary   : AppTheme.lightTextPrimary;
    final textSec = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;
    final bgColor = isDark ? AppTheme.darkBg         : AppTheme.lightBg;

    return Container(
      padding: EdgeInsets.fromLTRB(20, top + 12, 20, 12),
      color: bgColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('💸', style: TextStyle(fontSize: 26)),
              const SizedBox(width: 8),
              Text('Finanzas', style: Theme.of(context).textTheme.headlineMedium),
              const Spacer(),
              // Month nav
              Container(
                decoration: BoxDecoration(
                  color: surfAlt,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: bord),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _MonthBtn(icon: Icons.chevron_left, onTap: pv.previousMonth, color: textSec),
                    Text(
                      Fmt.monthCap(pv.selectedMonth),
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textPri),
                    ),
                    _MonthBtn(
                      icon: Icons.chevron_right,
                      onTap: pv.canGoNext ? pv.nextMonth : null,
                      color: textSec,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Theme toggle
              GestureDetector(
                onTap: tp.toggle,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppTheme.primary.withOpacity(0.15)
                        : AppTheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark
                          ? AppTheme.primary.withOpacity(0.4)
                          : AppTheme.lightBorder,
                    ),
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (child, anim) =>
                        RotationTransition(turns: anim, child: FadeTransition(opacity: anim, child: child)),
                    child: Icon(
                      isDark ? Icons.wb_sunny_rounded : Icons.nightlight_round,
                      key: ValueKey(isDark),
                      size: 18,
                      color: isDark ? const Color(0xFFFBBF24) : AppTheme.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Accounts button
              GestureDetector(
                onTap: () => showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => const AccountsSheet(),
                ),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: surfAlt,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: bord),
                  ),
                  child: Icon(Icons.account_circle_outlined, size: 20, color: textSec),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Account chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: pv.accounts.map((acc) {
                final sel = acc.id == pv.selectedAccount?.id;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => pv.selectAccount(acc.id),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: sel ? acc.color.withOpacity(0.2) : surfAlt,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: sel ? acc.color.withOpacity(0.6) : bord,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(acc.icon, style: const TextStyle(fontSize: 14)),
                          const SizedBox(width: 6),
                          Text(
                            acc.name,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: sel ? acc.color : textSec,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final Color color;
  const _MonthBtn({required this.icon, this.onTap, required this.color});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Icon(icon, size: 18, color: onTap != null ? color : color.withOpacity(0.3)),
      ),
    );
  }
}

// ─── Balance Card ─────────────────────────────────────────────────────────────

class _BalanceCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final pv = context.watch<FinanceProvider>();
    final acc = pv.selectedAccount;
    final color = acc?.color ?? AppTheme.primary;
    final isPositive = pv.balance >= 0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color, Color.lerp(color, Colors.black, 0.35)!],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: color.withOpacity(0.35), blurRadius: 24, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(acc?.icon ?? '💰', style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 6),
              Text(
                acc?.name ?? 'Personal',
                style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  Fmt.monthShort(pv.selectedMonth).toUpperCase(),
                  style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text('Balance del mes', style: TextStyle(color: Colors.white60, fontSize: 12)),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              Fmt.money(pv.balance),
              style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.w700, letterSpacing: -2),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: (isPositive ? Colors.white : Colors.red.shade200).withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              isPositive ? '✓ En superávit' : '⚠ En déficit',
              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Stats Row ────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final pv = context.watch<FinanceProvider>();
    return Row(
      children: [
        StatChip(label: 'Ingresos', amount: pv.totalIncome, color: AppTheme.income, icon: Icons.south_east),
        const SizedBox(width: 10),
        StatChip(label: 'Gastos', amount: pv.totalExpenses, color: AppTheme.expense, icon: Icons.north_west),
        const SizedBox(width: 10),
        StatChip(label: 'Ahorrado', amount: pv.totalSaved, color: AppTheme.savings, icon: Icons.savings_outlined),
      ],
    );
  }
}

// ─── Chart Card ───────────────────────────────────────────────────────────────

class _ChartCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final pv = context.watch<FinanceProvider>();
    final data = pv.last6MonthsData;
    final isDark = context.watch<ThemeProvider>().isDark;

    final maxVal = data
        .expand((m) => [m['income'] as double, m['expense'] as double])
        .fold(0.0, (a, b) => a > b ? a : b);

    if (maxVal == 0) return const SizedBox();

    final gridColor = isDark ? AppTheme.darkBorder : AppTheme.lightBorder;
    final labelColor = isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Tendencia 6 meses', style: Theme.of(context).textTheme.titleMedium),
              const Spacer(),
              _Legend(color: AppTheme.income, label: 'Ingresos'),
              const SizedBox(width: 12),
              _Legend(color: AppTheme.expense, label: 'Gastos'),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 140,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxVal * 1.25,
                barTouchData: BarTouchData(enabled: false),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxVal / 2,
                  getDrawingHorizontalLine: (v) => FlLine(color: gridColor, strokeWidth: 1, dashArray: [4, 4]),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, _) {
                        final i = v.toInt();
                        if (i < 0 || i >= data.length) return const SizedBox();
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(Fmt.monthShort(data[i]['month'] as DateTime),
                              style: TextStyle(fontSize: 10, color: labelColor)),
                        );
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                barGroups: List.generate(data.length, (i) => BarChartGroupData(
                  x: i,
                  barsSpace: 3,
                  barRods: [
                    BarChartRodData(toY: data[i]['income'] as double, color: AppTheme.income.withOpacity(0.85), width: 10, borderRadius: BorderRadius.circular(4)),
                    BarChartRodData(toY: data[i]['expense'] as double, color: AppTheme.expense.withOpacity(0.85), width: 10, borderRadius: BorderRadius.circular(4)),
                  ],
                )),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  const _Legend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(width: 8, height: 8, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
      const SizedBox(width: 4),
      Text(label, style: TextStyle(fontSize: 10, color: AppTheme.isDark(context) ? AppTheme.darkTextMuted : AppTheme.lightTextMuted)),
    ],
  );
}

// ─── Recent Transactions ──────────────────────────────────────────────────────

class _RecentTransactions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final pv = context.watch<FinanceProvider>();
    final txs = pv.filteredTransactions.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Últimos movimientos',
          action: txs.isNotEmpty ? 'Ver todos' : null,
        ),
        const SizedBox(height: 12),
        if (txs.isEmpty)
          EmptyState(
            emoji: '📊',
            title: 'Sin movimientos',
            subtitle: 'Agrega tu primer ingreso o gasto para comenzar',
            actionLabel: 'Agregar ahora',
            onAction: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => const AddTransactionSheet(),
            ),
          )
        else
          ...txs.map((tx) => TransactionTile(
            tx: tx,
            onDelete: () => pv.deleteTransaction(tx.id),
          )),
      ],
    );
  }
}
