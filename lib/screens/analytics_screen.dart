import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/finance_provider.dart';
import '../providers/theme_provider.dart';
import '../models/budget.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/common_widgets.dart';

// ─── Palette for pie slices ───────────────────────────────────────────────────
const _sliceColors = [
  Color(0xFF7C3AED), Color(0xFF2563EB), Color(0xFF059669), Color(0xFFDB2777),
  Color(0xFFD97706), Color(0xFF0891B2), Color(0xFFDC2626), Color(0xFF65A30D),
  Color(0xFF9333EA), Color(0xFF0284C7), Color(0xFF16A34A),
];

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});
  @override State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> with SingleTickerProviderStateMixin {
  late TabController _tab;
  int _touchedIndex = -1;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _tab.addListener(() => setState(() {}));
  }

  @override
  void dispose() { _tab.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final pv = context.watch<FinanceProvider>();
    final isDark = context.watch<ThemeProvider>().isDark;
    final top = MediaQuery.of(context).padding.top;
    final bord = isDark ? AppTheme.darkBorder : AppTheme.lightBorder;
    final surf = isDark ? AppTheme.darkSurface : AppTheme.lightSurface;
    final bg   = isDark ? AppTheme.darkBg     : AppTheme.lightBg;

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
                Text('Análisis', style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.darkSurfaceAlt : AppTheme.lightSurfaceAlt,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: bord),
                  ),
                  child: TabBar(
                    controller: _tab,
                    dividerColor: Colors.transparent,
                    indicator: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.primary.withOpacity(0.4)),
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    labelColor: AppTheme.primary,
                    unselectedLabelColor: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                    labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    tabs: const [
                      Tab(text: '📊  Gastos'),
                      Tab(text: '💰  Presupuesto'),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tab,
              children: [
                _PieTab(touchedIndex: _touchedIndex, onTouch: (i) => setState(() => _touchedIndex = i)),
                _BudgetTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Pie chart tab ────────────────────────────────────────────────────────────

class _PieTab extends StatelessWidget {
  final int touchedIndex;
  final Function(int) onTouch;
  const _PieTab({required this.touchedIndex, required this.onTouch});

  @override
  Widget build(BuildContext context) {
    final pv = context.watch<FinanceProvider>();
    final isDark = context.watch<ThemeProvider>().isDark;
    final data = pv.expensesByCategory;
    final total = data.values.fold(0.0, (a, b) => a + b);
    final entries = data.entries.toList();

    if (total == 0) {
      return Center(
        child: EmptyState(
          emoji: '📊',
          title: 'Sin gastos este mes',
          subtitle: 'Agrega gastos para ver el desglose por categoría',
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      children: [
        // Pie chart card
        GlassCard(
          child: Column(
            children: [
              Row(
                children: [
                  Text('Distribución de gastos', style: Theme.of(context).textTheme.titleMedium),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.expense.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Total: ${Fmt.money(total)}',
                      style: const TextStyle(color: AppTheme.expense, fontSize: 11, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 220,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 55,
                    pieTouchData: PieTouchData(
                      touchCallback: (event, response) {
                        if (response != null && response.touchedSection != null) {
                          onTouch(response.touchedSection!.touchedSectionIndex);
                        } else {
                          onTouch(-1);
                        }
                      },
                    ),
                    sections: List.generate(entries.length, (i) {
                      final isTouched = i == touchedIndex;
                      final color = _sliceColors[i % _sliceColors.length];
                      final pct = entries[i].value / total;
                      return PieChartSectionData(
                        color: color,
                        value: entries[i].value,
                        radius: isTouched ? 72 : 58,
                        showTitle: pct > 0.07,
                        title: Fmt.percent(pct),
                        titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white),
                      );
                    }),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              // Center label when touched
              if (touchedIndex >= 0 && touchedIndex < entries.length)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    '${FinanceProvider.categoryEmoji[entries[touchedIndex].key] ?? "💰"}  ${entries[touchedIndex].key}  —  ${Fmt.money(entries[touchedIndex].value)}',
                    style: TextStyle(
                      color: _sliceColors[touchedIndex % _sliceColors.length],
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Legend / breakdown list
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Detalle por categoría', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 14),
              ...List.generate(entries.length, (i) {
                final e = entries[i];
                final color = _sliceColors[i % _sliceColors.length];
                final pct = e.value / total;
                final emoji = FinanceProvider.categoryEmoji[e.key] ?? '💰';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 10, height: 10,
                            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
                          ),
                          const SizedBox(width: 8),
                          Text(emoji, style: const TextStyle(fontSize: 14)),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(e.key, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 13)),
                          ),
                          Text(Fmt.money(e.value), style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 13)),
                          const SizedBox(width: 8),
                          Text(Fmt.percent(pct), style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: pct,
                          minHeight: 5,
                          backgroundColor: color.withOpacity(0.12),
                          valueColor: AlwaysStoppedAnimation(color),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Budget tab ───────────────────────────────────────────────────────────────

class _BudgetTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final pv = context.watch<FinanceProvider>();
    final budgets = pv.filteredBudgets;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      children: [
        // Summary
        if (budgets.isNotEmpty) ...[
          _BudgetSummaryCard(budgets: budgets),
          const SizedBox(height: 16),
        ],
        // Add button
        OutlinedButton.icon(
          onPressed: () => _showAddBudget(context),
          icon: const Icon(Icons.add, size: 16),
          label: const Text('Agregar límite de presupuesto'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppTheme.primary,
            side: const BorderSide(color: AppTheme.primary),
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
        const SizedBox(height: 16),
        if (budgets.isEmpty)
          EmptyState(
            emoji: '💰',
            title: 'Sin presupuestos',
            subtitle: 'Define límites por categoría para controlar tus gastos',
          )
        else
          ...budgets.map((b) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _BudgetCard(budget: b),
          )),
      ],
    );
  }

  void _showAddBudget(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _AddBudgetSheet(),
    );
  }
}

// ─── Budget summary card ──────────────────────────────────────────────────────

class _BudgetSummaryCard extends StatelessWidget {
  final List<Budget> budgets;
  const _BudgetSummaryCard({required this.budgets});

  @override
  Widget build(BuildContext context) {
    final pv = context.watch<FinanceProvider>();
    int overBudget = 0;
    int onTrack = 0;
    for (final b in budgets) {
      final spent = pv.spentInCategory(b.category);
      if (spent > b.limitAmount) overBudget++;
      else onTrack++;
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: AppTheme.purpleGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: AppTheme.primary.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 6))],
      ),
      child: Row(
        children: [
          Expanded(child: _StatItem(label: 'Presupuestos', value: '${budgets.length}', icon: '📋')),
          Container(width: 1, height: 36, color: Colors.white24),
          Expanded(child: _StatItem(label: 'Al día', value: '$onTrack', icon: '✅')),
          Container(width: 1, height: 36, color: Colors.white24),
          Expanded(child: _StatItem(label: 'Excedidos', value: '$overBudget', icon: overBudget > 0 ? '⚠️' : '—')),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label, value, icon;
  const _StatItem({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(icon, style: const TextStyle(fontSize: 18)),
      const SizedBox(height: 4),
      Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18)),
      Text(label, style: const TextStyle(color: Colors.white60, fontSize: 10)),
    ],
  );
}

// ─── Individual budget card ───────────────────────────────────────────────────

class _BudgetCard extends StatelessWidget {
  final Budget budget;
  const _BudgetCard({required this.budget});

  @override
  Widget build(BuildContext context) {
    final pv = context.read<FinanceProvider>();
    final isDark = context.watch<ThemeProvider>().isDark;
    final spent = pv.spentInCategory(budget.category);
    final ratio = (spent / budget.limitAmount).clamp(0.0, 1.5);
    final isOver = spent > budget.limitAmount;
    final isWarning = !isOver && ratio > 0.8;
    final color = Color(budget.colorValue);
    final statusColor = isOver ? AppTheme.expense : isWarning ? const Color(0xFFD97706) : AppTheme.income;
    final emoji = FinanceProvider.categoryEmoji[budget.category] ?? '💰';
    final remaining = budget.limitAmount - spent;
    final bord = isDark ? AppTheme.darkBorder : AppTheme.lightBorder;
    final surfAlt = isDark ? AppTheme.darkSurfaceAlt : AppTheme.lightSurfaceAlt;

    return Dismissible(
      key: Key(budget.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => pv.deleteBudget(budget.id),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(color: AppTheme.expense.withOpacity(0.15), borderRadius: BorderRadius.circular(18)),
        child: const Icon(Icons.delete_outline, color: AppTheme.expense),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isOver ? AppTheme.expense.withOpacity(0.05) : surfAlt,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: isOver ? AppTheme.expense.withOpacity(0.3) : bord),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
                  child: Center(child: Text(emoji, style: const TextStyle(fontSize: 20))),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(budget.category, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 14)),
                      Text('Límite: ${Fmt.money(budget.limitAmount)}', style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      Fmt.money(spent),
                      style: TextStyle(color: statusColor, fontWeight: FontWeight.w700, fontSize: 15),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isOver ? '¡Excedido!' : isWarning ? '⚠ Cuidado' : '✓ Al día',
                        style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),
            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: ratio.clamp(0.0, 1.0),
                minHeight: 8,
                backgroundColor: color.withOpacity(0.1),
                valueColor: AlwaysStoppedAnimation(statusColor),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  isOver
                      ? '⚠ Excediste por ${Fmt.money(spent - budget.limitAmount)}'
                      : 'Disponible: ${Fmt.money(remaining)}',
                  style: TextStyle(fontSize: 11, color: statusColor, fontWeight: FontWeight.w500),
                ),
                const Spacer(),
                Text(
                  '${Fmt.percent(ratio.clamp(0.0, 1.0))} usado',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Add budget sheet ─────────────────────────────────────────────────────────

class _AddBudgetSheet extends StatefulWidget {
  const _AddBudgetSheet();
  @override State<_AddBudgetSheet> createState() => _AddBudgetSheetState();
}

class _AddBudgetSheetState extends State<_AddBudgetSheet> {
  String _category = FinanceProvider.expenseCategories.first;
  final _amountCtrl = TextEditingController();
  int _colorValue = 0xFF7C3AED;

  @override
  void dispose() { _amountCtrl.dispose(); super.dispose(); }

  void _save(FinanceProvider pv) {
    final amount = double.tryParse(_amountCtrl.text.replaceAll('.', ''));
    if (amount == null || amount <= 0) return;
    pv.addBudget(Budget(
      id: pv.newId(), accountId: pv.selectedAccount!.id,
      category: _category, limitAmount: amount, colorValue: _colorValue,
    ));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final pv = context.read<FinanceProvider>();
    final isDark = context.watch<ThemeProvider>().isDark;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            Center(child: Container(width: 40, height: 4,
              decoration: BoxDecoration(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            Text('Nuevo presupuesto', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _category,
              decoration: const InputDecoration(labelText: 'Categoría', prefixIcon: Icon(Icons.category_outlined)),
              dropdownColor: isDark ? AppTheme.darkSurfaceAlt : AppTheme.lightSurfaceAlt,
              items: FinanceProvider.expenseCategories.map((c) =>
                DropdownMenuItem(value: c, child: Text('${FinanceProvider.categoryEmoji[c] ?? "💰"}  $c'))).toList(),
              onChanged: (v) => setState(() => _category = v!),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _amountCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Límite mensual (CLP)',
                prefixText: '\$ ',
                prefixIcon: Icon(Icons.track_changes_outlined),
              ),
            ),
            const SizedBox(height: 12),
            Text('Color', style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 8),
            Row(
              children: FinanceProvider.budgetColors.map((cv) {
                final sel = cv == _colorValue;
                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: GestureDetector(
                    onTap: () => setState(() => _colorValue = cv),
                    child: Container(
                      width: 30, height: 30,
                      decoration: BoxDecoration(
                        color: Color(cv), shape: BoxShape.circle,
                        border: Border.all(color: sel ? Colors.white : Colors.transparent, width: 2.5),
                        boxShadow: sel ? [BoxShadow(color: Color(cv).withOpacity(0.5), blurRadius: 8)] : null,
                      ),
                      child: sel ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            PrimaryButton(
              label: 'Crear presupuesto',
              icon: Icons.savings_outlined,
              color: Color(_colorValue),
              onPressed: () => _save(pv),
            ),
          ],
        ),
      ),
    );
  }
}
