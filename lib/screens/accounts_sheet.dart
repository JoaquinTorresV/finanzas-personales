import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/finance_provider.dart';
import '../models/account.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../utils/formatters.dart';

class AccountsSheet extends StatelessWidget {
  const AccountsSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final pv = context.watch<FinanceProvider>();

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      minChildSize: 0.4,
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  Text('Mis cuentas', style: Theme.of(context).textTheme.titleLarge),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () => _showAddAccount(context),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Nueva'),
                    style: TextButton.styleFrom(foregroundColor: AppTheme.primaryLight),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                controller: ctrl,
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                itemCount: pv.accounts.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  final acc = pv.accounts[i];
                  final sel = acc.id == pv.selectedAccount?.id;

                  // Compute balance for this account (current month)
                  final txs = pv.allTransactions.where((t) =>
                      t.accountId == acc.id &&
                      t.date.year == pv.selectedMonth.year &&
                      t.date.month == pv.selectedMonth.month);
                  final balance = txs.fold(
                      0.0, (s, t) => s + (t.isIncome ? t.amount : -t.amount));

                  return GestureDetector(
                    onTap: () {
                      pv.selectAccount(acc.id);
                      Navigator.pop(context);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: sel
                            ? AppTheme.gradientForColor(acc.color)
                            : null,
                        color: sel ? null : Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: sel ? acc.color.withOpacity(0.5) : Theme.of(context).colorScheme.outline,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: sel
                                  ? Colors.white.withOpacity(0.2)
                                  : acc.color.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Center(
                              child: Text(acc.icon, style: const TextStyle(fontSize: 22)),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  acc.name,
                                  style: TextStyle(
                                    color: sel ? Colors.white : Theme.of(context).colorScheme.onSurface,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Balance: ${Fmt.money(balance)}',
                                  style: TextStyle(
                                    color: sel ? Colors.white70 : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (sel)
                            const Icon(Icons.check_circle, color: Colors.white, size: 20)
                          else if (pv.accounts.length > 1)
                            GestureDetector(
                              onTap: () => _confirmDelete(context, pv, acc),
                              child: const Icon(Icons.delete_outline,
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.35), size: 20),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, FinanceProvider pv, Account acc) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Eliminar ${acc.name}'),
        content: const Text(
            'Se eliminarán todos los movimientos, recurrentes y metas de esta cuenta. ¿Continuar?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              pv.deleteAccount(acc.id);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.expense),
            child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showAddAccount(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _AddAccountSheet(),
    );
  }
}

// ─── Add Account Sheet ────────────────────────────────────────────────────────

class _AddAccountSheet extends StatefulWidget {
  const _AddAccountSheet();

  @override
  State<_AddAccountSheet> createState() => _AddAccountSheetState();
}

class _AddAccountSheetState extends State<_AddAccountSheet> {
  final _nameCtrl = TextEditingController();
  String _icon = '💼';
  int _colorValue = 0xFF8B5CF6;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  void _save(FinanceProvider pv) {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;

    pv.addAccount(Account(
      id: pv.newId(),
      name: name,
      icon: _icon,
      colorValue: _colorValue,
    ));
    Navigator.pop(context);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final pv = context.read<FinanceProvider>();

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        decoration: const BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Nueva cuenta', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            // Icon selector
            Text('Ícono', style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: FinanceProvider.accountIcons.map((ic) {
                final sel = ic == _icon;
                return GestureDetector(
                  onTap: () => setState(() => _icon = ic),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: sel ? Color(_colorValue).withOpacity(0.2) : Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: sel ? Color(_colorValue) : Theme.of(context).colorScheme.outline),
                    ),
                    child: Center(child: Text(ic, style: const TextStyle(fontSize: 20))),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 14),
            Text('Color', style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 8),
            Row(
              children: FinanceProvider.accountColors.map((c) {
                final cv = c['value'] as int;
                final sel = cv == _colorValue;
                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: GestureDetector(
                    onTap: () => setState(() => _colorValue = cv),
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: Color(cv),
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: sel ? Colors.white : Colors.transparent, width: 2.5),
                        boxShadow: sel
                            ? [BoxShadow(color: Color(cv).withOpacity(0.5), blurRadius: 8)]
                            : null,
                      ),
                      child: sel ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _nameCtrl,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Nombre de la cuenta',
                prefixIcon: Icon(Icons.account_balance_wallet_outlined),
              ),
            ),
            const SizedBox(height: 20),
            PrimaryButton(
              label: 'Crear cuenta',
              icon: Icons.add,
              color: Color(_colorValue),
              onPressed: () => _save(pv),
            ),
          ],
        ),
      ),
    );
  }
}
