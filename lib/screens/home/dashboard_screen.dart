import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/app_user.dart';
import '../../models/chore.dart';
import '../../models/expense.dart';
import '../../models/grocery_item.dart';
import '../../models/household.dart';
import '../../services/chore_service.dart';
import '../../services/expense_service.dart';
import '../../services/grocery_service.dart';

class DashboardScreen extends StatelessWidget {
  DashboardScreen({
    super.key,
    required this.appUser,
    required this.householdId,
    required this.members,
  });

  final AppUser appUser;
  final String householdId;
  final List<HouseholdMember> members;
  final _expenseService = ExpenseService();
  final _groceryService = GroceryService();
  final _choreService = ChoreService();

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(symbol: '\$');
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Hi ${appUser.displayName.split(' ').first}',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          _BalanceCard(
            householdId: householdId,
            members: members,
            currentUserId: appUser.id,
            currency: currency,
            expenseService: _expenseService,
          ),
          const SizedBox(height: 16),
          _SummaryCard(
            icon: Icons.local_grocery_store_outlined,
            title: 'Groceries to buy',
            stream: _groceryService.watchItems(householdId),
            countBuilder: (items) =>
                items.cast<GroceryItem>().where((i) => !i.bought).length,
          ),
          const SizedBox(height: 16),
          _SummaryCard(
            icon: Icons.checklist_outlined,
            title: 'Chores pending',
            stream: _choreService.watchChores(householdId),
            countBuilder: (chores) =>
                chores.cast<Chore>().where((c) => !c.completed).length,
          ),
        ],
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({
    required this.householdId,
    required this.members,
    required this.currentUserId,
    required this.currency,
    required this.expenseService,
  });

  final String householdId;
  final List<HouseholdMember> members;
  final String currentUserId;
  final NumberFormat currency;
  final ExpenseService expenseService;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Expense>>(
      stream: expenseService.watchExpenses(householdId),
      builder: (context, snapshot) {
        final expenses = snapshot.data ?? const <Expense>[];
        final balances = ExpenseService.calculateBalances(
          expenses,
          members.map((m) => m.userId).toList(),
        );
        final myBalance = balances[currentUserId] ?? 0;
        final isOwed = myBalance >= 0;
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your balance',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  isOwed
                      ? "You're owed ${currency.format(myBalance.abs())}"
                      : "You owe ${currency.format(myBalance.abs())}",
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: isOwed ? Colors.green.shade700 : Colors.red.shade700,
                  ),
                ),
                const SizedBox(height: 12),
                ...members.where((m) => m.userId != currentUserId).map((
                  member,
                ) {
                  final theirBalance = balances[member.userId] ?? 0;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text(
                      '${member.displayName}: ${theirBalance >= 0 ? "+" : ""}${currency.format(theirBalance)}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SummaryCard<T> extends StatelessWidget {
  const _SummaryCard({
    required this.icon,
    required this.title,
    required this.stream,
    required this.countBuilder,
  });

  final IconData icon;
  final String title;
  final Stream<List<T>> stream;
  final int Function(List<T> items) countBuilder;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<T>>(
      stream: stream,
      builder: (context, snapshot) {
        final count = snapshot.hasData ? countBuilder(snapshot.data!) : 0;
        return Card(
          child: ListTile(
            leading: Icon(icon),
            title: Text(title),
            trailing: Text(
              '$count',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
        );
      },
    );
  }
}
