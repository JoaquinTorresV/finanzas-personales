import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/finance_provider.dart';
import '../models/savings_goal.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/common_widgets.dart';

class SavingsScreen extends StatelessWidget {
  const SavingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final pv = context.watch<FinanceProvider>();
    final top = MediaQuery.of(context).padding.top;
    final goals = pv.filteredSavings;
    final totalSaved = goals.fold(0.0, (s, g) => s + g.currentAmount);
    final totalTarget = goals.fold(0.0, (s, g) => s + g.targetAmount);
    final completedCount = goals.where((g) => g.isCompleted).length;

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
                      Text('Ahorros', style: Theme.of(context).textTheme.headlineMedium),
                      const Spacer(),
                      IconButton(
                        onPressed: () => _showAddGoal(context),
                        icon: const Icon(Icons.add_circle_outline),
                        color: AppTheme.primaryLight,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Total savings card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: AppTheme.savingsGradient,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.savings.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Total ahorrado',
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          Fmt.money(totalSaved),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -1.5,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            _InfoChip(
                              label: '${goals.length} metas',
                              icon: Icons.flag_outlined,
                            ),
                            const SizedBox(width: 8),
                            _InfoChip(
                              label: '$completedCount completadas',
                              icon: Icons.check_circle_outline,
                            ),
                            const SizedBox(width: 8),
                            if (totalTarget > 0)
                              _InfoChip(
                                label: Fmt.percent(totalTarget > 0 ? totalSaved / totalTarget : 0),
                                icon: Icons.percent,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                if (goals.isEmpty)
                  EmptyState(
                    emoji: '🏦',
                    title: 'Sin metas de ahorro',
                    subtitle: 'Crea tu primera meta para alcanzar tus objetivos financieros',
                    actionLabel: 'Crear meta',
                    onAction: () => _showAddGoal(context),
                  )
                else
                  ...goals.map((goal) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _GoalCard(goal: goal),
                  )),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddGoal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _AddGoalSheet(),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final IconData icon;
  const _InfoChip({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white70),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  final SavingsGoal goal;
  const _GoalCard({required this.goal});

  @override
  Widget build(BuildContext context) {
    final pv = context.read<FinanceProvider>();
    final color = Color(goal.colorValue);

    return Dismissible(
      key: Key(goal.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => pv.deleteSavingsGoal(goal.id),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppTheme.expense.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(Icons.delete_outline, color: AppTheme.expense),
      ),
      child: GlassCard(
        borderColor: goal.isCompleted ? color.withOpacity(0.5) : Theme.of(context).colorScheme.outline,
        gradient: goal.isCompleted
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [color.withOpacity(0.15), Theme.of(context).colorScheme.surface],
              )
            : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(goal.icon, style: const TextStyle(fontSize: 28)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            goal.name,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(width: 8),
                          if (goal.isCompleted)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '✓ Completada',
                                style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w700),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Meta: ${Fmt.money(goal.targetAmount)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      Fmt.money(goal.currentAmount),
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      Fmt.percent(goal.progress),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),
            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: goal.progress,
                minHeight: 8,
                backgroundColor: color.withOpacity(0.12),
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                if (!goal.isCompleted)
                  Text(
                    'Faltan ${Fmt.money(goal.remaining)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                const Spacer(),
                if (!goal.isCompleted)
                  GestureDetector(
                    onTap: () => _showAddFunds(context, goal),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: color.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add, size: 14, color: color),
                          const SizedBox(width: 4),
                          Text(
                            'Abonar',
                            style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ],
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

  void _showAddFunds(BuildContext context, SavingsGoal goal) {
    final ctrl = TextEditingController();
    bool discountFromBalance = true;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) => AlertDialog(
          title: Text('Abonar a ${goal.name}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: ctrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Monto (CLP)', prefixText: '\$ '),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Theme.of(context).colorScheme.outline),
                ),
                child: CheckboxListTile(
                  value: discountFromBalance,
                  onChanged: (v) => setStateDialog(() => discountFromBalance = v ?? true),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: const Text('Descontar del balance del mes'),
                  subtitle: const Text('Se registrará como gasto en la cuenta.'),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () {
                final amount = double.tryParse(ctrl.text);
                if (amount != null && amount > 0) {
                  context.read<FinanceProvider>().addToSavings(
                        goal.id,
                        amount,
                        discountFromBalance: discountFromBalance,
                      );
                  Navigator.pop(ctx);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Color(goal.colorValue)),
              child: const Text('Abonar', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Add Goal Sheet ───────────────────────────────────────────────────────────

class _AddGoalSheet extends StatefulWidget {
  const _AddGoalSheet();

  @override
  State<_AddGoalSheet> createState() => _AddGoalSheetState();
}

class _AddGoalSheetState extends State<_AddGoalSheet> {
  final _nameCtrl = TextEditingController();
  final _targetCtrl = TextEditingController();
  final _initialCtrl = TextEditingController();
  String _selectedIcon = '🎯';
  int _selectedColor = 0xFF3B82F6;
  bool _discountInitialFromBalance = true;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _targetCtrl.dispose();
    _initialCtrl.dispose();
    super.dispose();
  }

  void _save(FinanceProvider pv) {
    final name = _nameCtrl.text.trim();
    final target = double.tryParse(_targetCtrl.text.replaceAll('.', ''));
    if (name.isEmpty || target == null || target <= 0) return;

    final initial = double.tryParse(_initialCtrl.text.replaceAll('.', '')) ?? 0.0;

    pv.addSavingsGoal(SavingsGoal(
      id: pv.newId(),
      accountId: pv.selectedAccount!.id,
      name: name,
      targetAmount: target,
      currentAmount: initial,
      colorValue: _selectedColor,
      icon: _selectedIcon,
    ), discountInitialFromBalance: _discountInitialFromBalance);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final pv = context.read<FinanceProvider>();
    final color = Color(_selectedColor);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Nueva meta de ahorro', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            // Icon selector
            Text('Ícono', style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 8),
            SizedBox(
              height: 52,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: FinanceProvider.savingsIcons.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final ic = FinanceProvider.savingsIcons[i];
                  final sel = ic == _selectedIcon;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedIcon = ic),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: sel ? color.withOpacity(0.2) : Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: sel ? color : Theme.of(context).colorScheme.outline),
                      ),
                      child: Center(child: Text(ic, style: const TextStyle(fontSize: 20))),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            // Color selector
            Text('Color', style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 8),
            Row(
              children: FinanceProvider.accountColors.map((c) {
                final cv = c['value'] as int;
                final sel = cv == _selectedColor;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedColor = cv),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Color(cv),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: sel ? Colors.white : Colors.transparent,
                          width: 2.5,
                        ),
                        boxShadow: sel
                            ? [BoxShadow(color: Color(cv).withOpacity(0.5), blurRadius: 8)]
                            : null,
                      ),
                      child: sel ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Nombre de la meta',
                prefixIcon: Icon(Icons.flag_outlined),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _targetCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Monto objetivo (CLP)',
                prefixText: '\$ ',
                prefixIcon: Icon(Icons.track_changes),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _initialCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Ya tengo ahorrado (opcional)',
                prefixText: '\$ ',
                prefixIcon: Icon(Icons.savings_outlined),
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Theme.of(context).colorScheme.outline),
              ),
              child: CheckboxListTile(
                value: _discountInitialFromBalance,
                onChanged: (v) => setState(() => _discountInitialFromBalance = v ?? true),
                dense: true,
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: const Text('¿Ese ahorro sale del balance mensual?'),
                subtitle: const Text('Si activas esto, se descontará como gasto de la cuenta.'),
              ),
            ),
            const SizedBox(height: 20),
            PrimaryButton(
              label: 'Crear meta',
              icon: Icons.flag,
              color: color,
              onPressed: () => _save(pv),
            ),
          ],
        ),
      ),
    );
  }
}
