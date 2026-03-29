import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/finance_provider.dart';
import '../models/transaction.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/common_widgets.dart';

class AddTransactionSheet extends StatefulWidget {
  final bool initialIsIncome;
  const AddTransactionSheet({super.key, this.initialIsIncome = false});

  @override
  State<AddTransactionSheet> createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends State<AddTransactionSheet> {
  late bool _isIncome;
  final _amountCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String? _category;
  DateTime _date = DateTime.now();

  @override
  void initState() {
    super.initState();
    _isIncome = widget.initialIsIncome;
    _category = _isIncome
        ? FinanceProvider.incomeCategories.first
        : FinanceProvider.expenseCategories.first;
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Color get _color => _isIncome ? AppTheme.income : AppTheme.expense;

  String get _displayAmount {
    final raw = _amountCtrl.text.replaceAll('.', '').replaceAll(',', '');
    if (raw.isEmpty) return '';
    final n = int.tryParse(raw);
    if (n == null) return raw;
    return n.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
  }

  void _save(FinanceProvider provider) {
    final rawAmount = _amountCtrl.text.replaceAll('.', '').replaceAll(',', '');
    final amount = double.tryParse(rawAmount);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa un monto válido')),
      );
      return;
    }

    final desc = _descCtrl.text.trim().isEmpty
        ? (_category ?? 'Sin descripción')
        : _descCtrl.text.trim();

    provider.addTransaction(Transaction(
      id: provider.newId(),
      accountId: provider.selectedAccount!.id,
      amount: amount,
      type: _isIncome ? 'income' : 'expense',
      category: _category ?? 'Otros',
      description: desc,
      date: _date,
    ));

    Navigator.pop(context);
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(now.year - 2),
      lastDate: now,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(primary: AppTheme.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _date = picked);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.read<FinanceProvider>();
    final categories = _isIncome
        ? FinanceProvider.incomeCategories
        : FinanceProvider.expenseCategories;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Toggle income / expense
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Theme.of(context).colorScheme.outline),
              ),
              padding: const EdgeInsets.all(4),
              child: Row(
                children: [
                  _TypeButton(
                    label: 'Gasto',
                    icon: Icons.arrow_upward,
                    selected: !_isIncome,
                    color: AppTheme.expense,
                    onTap: () {
                      setState(() {
                        _isIncome = false;
                        _category = FinanceProvider.expenseCategories.first;
                      });
                    },
                  ),
                  _TypeButton(
                    label: 'Ingreso',
                    icon: Icons.arrow_downward,
                    selected: _isIncome,
                    color: AppTheme.income,
                    onTap: () {
                      setState(() {
                        _isIncome = true;
                        _category = FinanceProvider.incomeCategories.first;
                      });
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Amount display
            GestureDetector(
              onTap: () {
                // Focus next field that shows keyboard
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                decoration: BoxDecoration(
                  color: _color.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _color.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    Text(
                      _isIncome ? '+ Ingreso' : '- Gasto',
                      style: TextStyle(color: _color.withOpacity(0.7), fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _amountCtrl.text.isEmpty
                          ? '\$0'
                          : '\$${_displayAmount}',
                      style: TextStyle(
                        color: _color,
                        fontSize: 36,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Amount text field
            TextField(
              controller: _amountCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'Monto (CLP)',
                prefixText: '\$ ',
                prefixIcon: Icon(Icons.attach_money),
              ),
            ),
            const SizedBox(height: 12),

            // Description
            TextField(
              controller: _descCtrl,
              decoration: const InputDecoration(
                labelText: 'Descripción (opcional)',
                prefixIcon: Icon(Icons.edit_outlined),
              ),
            ),
            const SizedBox(height: 12),

            // Category
            DropdownButtonFormField<String>(
              value: _category,
              decoration: const InputDecoration(
                labelText: 'Categoría',
                prefixIcon: Icon(Icons.category_outlined),
              ),
              dropdownColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              items: categories.map((c) {
                final emoji = FinanceProvider.categoryEmoji[c] ?? '💰';
                return DropdownMenuItem(
                  value: c,
                  child: Text('$emoji  $c'),
                );
              }).toList(),
              onChanged: (v) => setState(() => _category = v),
            ),
            const SizedBox(height: 12),

            // Date
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Theme.of(context).colorScheme.outline),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today_outlined,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), size: 18),
                    const SizedBox(width: 12),
                    Text(
                      Fmt.fullDate(_date),
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                    ),
                    const Spacer(),
                    Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.35), size: 18),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            PrimaryButton(
              label: _isIncome ? 'Agregar ingreso' : 'Agregar gasto',
              icon: _isIncome ? Icons.add_circle_outline : Icons.remove_circle_outline,
              color: _color,
              onPressed: () => _save(provider),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypeButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _TypeButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? color.withOpacity(0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: selected
                ? Border.all(color: color.withOpacity(0.4))
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: selected ? color : Theme.of(context).colorScheme.onSurface.withOpacity(0.35)),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: selected ? color : Theme.of(context).colorScheme.onSurface.withOpacity(0.35),
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
