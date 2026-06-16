import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/app_user.dart';
import '../../models/expense.dart';
import '../../models/household.dart';
import '../../services/expense_service.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({
    super.key,
    required this.appUser,
    required this.householdId,
    required this.members,
  });

  final AppUser appUser;
  final String householdId;
  final List<HouseholdMember> members;

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  final _expenseService = ExpenseService();

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(symbol: '\$');
    return Scaffold(
      body: StreamBuilder<List<Expense>>(
        stream: _expenseService.watchExpenses(widget.householdId),
        builder: (context, snapshot) {
          final expenses = snapshot.data ?? const <Expense>[];
          if (expenses.isEmpty) {
            return const Center(child: Text('No expenses yet. Add one below.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 80),
            itemCount: expenses.length,
            itemBuilder: (context, index) {
              final expense = expenses[index];
              final paidByName = widget.members.nameFor(expense.paidBy);
              return Dismissible(
                key: ValueKey(expense.id),
                background: Container(color: Colors.red),
                direction: DismissDirection.endToStart,
                onDismissed: (_) => _expenseService.deleteExpense(
                  widget.householdId,
                  expense.id,
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(
                      currency.format(expense.amount).substring(0, 1),
                    ),
                  ),
                  title: Text(expense.description),
                  subtitle: Text(
                    '$paidByName paid ${currency.format(expense.amount)} • '
                    'split ${expense.splitAmong.length} ways '
                    '(${currency.format(expense.shareAmount)} each)',
                  ),
                  trailing: Checkbox(
                    value: expense.settled,
                    onChanged: (value) => _expenseService.setSettled(
                      widget.householdId,
                      expense.id,
                      value ?? false,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddExpenseDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddExpenseDialog(BuildContext context) {
    final descriptionController = TextEditingController();
    final amountController = TextEditingController();
    String paidBy = widget.appUser.id;
    final splitAmong = widget.members.map((m) => m.userId).toSet();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Add expense'),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                      ),
                    ),
                    TextField(
                      controller: amountController,
                      decoration: const InputDecoration(labelText: 'Amount'),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: paidBy,
                      decoration: const InputDecoration(labelText: 'Paid by'),
                      items: widget.members
                          .map(
                            (m) => DropdownMenuItem(
                              value: m.userId,
                              child: Text(m.displayName),
                            ),
                          )
                          .toList(),
                      onChanged: (value) =>
                          setDialogState(() => paidBy = value ?? paidBy),
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Split among',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                    ),
                    ...widget.members.map((member) {
                      return CheckboxListTile(
                        title: Text(member.displayName),
                        value: splitAmong.contains(member.userId),
                        onChanged: (checked) => setDialogState(() {
                          if (checked ?? false) {
                            splitAmong.add(member.userId);
                          } else {
                            splitAmong.remove(member.userId);
                          }
                        }),
                      );
                    }),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () async {
                    final amount = double.tryParse(amountController.text);
                    if (descriptionController.text.trim().isEmpty ||
                        amount == null ||
                        splitAmong.isEmpty) {
                      return;
                    }
                    await _expenseService.addExpense(
                      householdId: widget.householdId,
                      description: descriptionController.text.trim(),
                      amount: amount,
                      paidBy: paidBy,
                      splitAmong: splitAmong.toList(),
                    );
                    if (context.mounted) Navigator.of(context).pop();
                  },
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
