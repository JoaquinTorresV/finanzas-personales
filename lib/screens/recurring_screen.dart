import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/finance_provider.dart';
import '../models/recurring_item.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/common_widgets.dart';

class RecurringScreen extends StatelessWidget {
  const RecurringScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final pv = context.watch<FinanceProvider>();
    final top = MediaQuery.of(context).padding.top;
    final items = pv.filteredRecurring;
    final expenses = items.where((r) => r.isExpense).toList();
    final incomes = items.where((r) => r.isIncome).toList();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              padding: EdgeInsets.fromLTRB(20, top + 16, 20, 16),
              color: Theme.of(context).scaffoldBackgroundColor,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('Recurrentes', style: Theme.of(context).textTheme.headlineMedium),
                      const Spacer(),
                      IconButton(
                        onPressed: () => _showAddRecurring(context),
                        icon: const Icon(Icons.add_circle_outline),
                        color: AppTheme.primaryLight,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Summary card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: AppTheme.purpleGradient,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _SummaryItem(
                            label: 'Gastos/mes',
                            amount: pv.monthlyRecurringExpenses,
                            color: AppTheme.expenseLight,
                          ),
                        ),
                        Container(width: 1, height: 36, color: Colors.white24),
                        Expanded(
                          child: _SummaryItem(
                            label: 'Ingresos/mes',
                            amount: pv.monthlyRecurringIncome,
                            color: AppTheme.incomeLight,
                          ),
                        ),
                        Container(width: 1, height: 36, color: Colors.white24),
                        Expanded(
                          child: _SummaryItem(
                            label: 'Items activos',
                            amount: items.where((r) => r.isActive).length.toDouble(),
                            color: Colors.white,
                            isCurrency: false,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Apply button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _applyRecurring(context, pv),
                      icon: const Icon(Icons.sync, size: 16),
                      label: const Text('Registrar recurrentes de este mes'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primaryLight,
                        side: const BorderSide(color: AppTheme.primary),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                if (items.isEmpty)
                  EmptyState(
                    emoji: '🔄',
                    title: 'Sin items recurrentes',
                    subtitle: 'Agrega tus suscripciones y gastos fijos mensuales',
                    actionLabel: 'Agregar recurrente',
                    onAction: () => _showAddRecurring(context),
                  )
                else ...[
                  if (expenses.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const SectionHeader(title: '📤 Gastos recurrentes'),
                    const SizedBox(height: 8),
                    ...expenses.map((r) => _RecurringTile(item: r)),
                  ],
                  if (incomes.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    const SectionHeader(title: '📥 Ingresos recurrentes'),
                    const SizedBox(height: 8),
                    ...incomes.map((r) => _RecurringTile(item: r)),
                  ],
                ],
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _applyRecurring(BuildContext context, FinanceProvider pv) async {
    final count = await pv.applyRecurring();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(count > 0
          ? '✅ $count transacciones registradas'
          : 'ℹ️ Ya estaban registradas este mes'),
      backgroundColor: count > 0 ? AppTheme.income : AppTheme.surfaceHigh,
    ));
  }

  void _showAddRecurring(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _AddRecurringSheet(),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  final bool isCurrency;

  const _SummaryItem({
    required this.label,
    required this.amount,
    required this.color,
    this.isCurrency = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          isCurrency ? Fmt.money(amount) : amount.toInt().toString(),
          style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 15),
        ),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 10)),
      ],
    );
  }
}

class _RecurringTile extends StatelessWidget {
  final RecurringItem item;
  const _RecurringTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final pv = context.read<FinanceProvider>();
    final color = item.isIncome ? AppTheme.income : AppTheme.expense;
    final emoji = FinanceProvider.categoryEmoji[item.category] ?? '💰';

    return Dismissible(
      key: Key(item.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => pv.deleteRecurringItem(item.id),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: AppTheme.expense.withOpacity(0.15),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.delete_outline, color: AppTheme.expense),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: item.isActive ? Theme.of(context).colorScheme.surfaceContainerHighest : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: item.isActive ? color.withOpacity(0.2) : Theme.of(context).colorScheme.outline,
          ),
        ),
        child: Row(
          children: [
            Opacity(
              opacity: item.isActive ? 1 : 0.5,
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(emoji, style: const TextStyle(fontSize: 20)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Opacity(
                opacity: item.isActive ? 1 : 0.5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.description,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 13),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            item.category,
                            style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Día ${item.dayOfMonth} de cada mes',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${item.isIncome ? '+' : '-'}${Fmt.money(item.amount)}',
                  style: TextStyle(
                    color: item.isActive ? color : Theme.of(context).colorScheme.onSurface.withOpacity(0.35),
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: () => pv.toggleRecurring(item.id),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: item.isActive
                          ? AppTheme.income.withOpacity(0.1)
                          : Theme.of(context).colorScheme.onSurface.withOpacity(0.35).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      item.isActive ? 'Activo' : 'Pausado',
                      style: TextStyle(
                        fontSize: 10,
                        color: item.isActive ? AppTheme.income : Theme.of(context).colorScheme.onSurface.withOpacity(0.35),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Add Recurring Sheet ──────────────────────────────────────────────────────

class _AddRecurringSheet extends StatefulWidget {
  const _AddRecurringSheet();

  @override
  State<_AddRecurringSheet> createState() => _AddRecurringSheetState();
}

class _AddRecurringSheetState extends State<_AddRecurringSheet> {
  bool _isExpense = true;
  final _amountCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String? _category;
  int _day = 1;

  @override
  void initState() {
    super.initState();
    _category = FinanceProvider.expenseCategories.first;
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Color get _color => _isExpense ? AppTheme.expense : AppTheme.income;

  void _save(FinanceProvider pv) {
    final amount = double.tryParse(_amountCtrl.text.replaceAll('.', ''));
    if (amount == null || amount <= 0) return;
    final desc = _descCtrl.text.trim();
    if (desc.isEmpty) return;

    pv.addRecurringItem(RecurringItem(
      id: pv.newId(),
      accountId: pv.selectedAccount!.id,
      amount: amount,
      type: _isExpense ? 'expense' : 'income',
      category: _category ?? 'Otros',
      description: desc,
      dayOfMonth: _day,
    ));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final pv = context.read<FinanceProvider>();
    final cats = _isExpense ? FinanceProvider.expenseCategories : FinanceProvider.incomeCategories;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Nuevo recurrente', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            // Type toggle
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() {
                      _isExpense = true;
                      _category = FinanceProvider.expenseCategories.first;
                    }),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _isExpense ? AppTheme.expense.withOpacity(0.15) : Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _isExpense ? AppTheme.expense.withOpacity(0.4) : Theme.of(context).colorScheme.outline),
                      ),
                      child: Center(
                        child: Text('↑ Gasto', style: TextStyle(color: _isExpense ? AppTheme.expense : Theme.of(context).colorScheme.onSurface.withOpacity(0.35), fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() {
                      _isExpense = false;
                      _category = FinanceProvider.incomeCategories.first;
                    }),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: !_isExpense ? AppTheme.income.withOpacity(0.15) : Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: !_isExpense ? AppTheme.income.withOpacity(0.4) : Theme.of(context).colorScheme.outline),
                      ),
                      child: Center(
                        child: Text('↓ Ingreso', style: TextStyle(color: !_isExpense ? AppTheme.income : Theme.of(context).colorScheme.onSurface.withOpacity(0.35), fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descCtrl,
              decoration: const InputDecoration(
                labelText: 'Nombre (ej: YouTube Premium)',
                prefixIcon: Icon(Icons.label_outline),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _amountCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Monto mensual (CLP)',
                prefixText: '\$ ',
                prefixIcon: Icon(Icons.attach_money),
              ),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: _category,
              decoration: const InputDecoration(labelText: 'Categoría', prefixIcon: Icon(Icons.category_outlined)),
              dropdownColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              items: cats.map((c) => DropdownMenuItem(value: c, child: Text('${FinanceProvider.categoryEmoji[c] ?? '💰'}  $c'))).toList(),
              onChanged: (v) => setState(() => _category = v),
            ),
            const SizedBox(height: 10),
            // Day selector
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Día del mes: $_day', style: Theme.of(context).textTheme.bodyMedium),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: _color,
                    thumbColor: _color,
                    overlayColor: _color.withOpacity(0.2),
                    inactiveTrackColor: Theme.of(context).colorScheme.outline,
                  ),
                  child: Slider(
                    value: _day.toDouble(),
                    min: 1,
                    max: 28,
                    divisions: 27,
                    onChanged: (v) => setState(() => _day = v.round()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            PrimaryButton(
              label: 'Guardar recurrente',
              icon: Icons.repeat,
              color: _color,
              onPressed: () => _save(pv),
            ),
          ],
        ),
      ),
    );
  }
}
