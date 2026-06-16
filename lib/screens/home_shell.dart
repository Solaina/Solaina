import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../models/household.dart';
import '../services/auth_service.dart';
import '../services/household_service.dart';
import 'home/chores_screen.dart';
import 'home/dashboard_screen.dart';
import 'home/expenses_screen.dart';
import 'home/groceries_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({
    super.key,
    required this.appUser,
    required this.householdId,
  });

  final AppUser appUser;
  final String householdId;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _selectedIndex = 0;
  final _householdService = HouseholdService();
  final _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<HouseholdMember>>(
      stream: _householdService.watchMembers(widget.householdId),
      builder: (context, memberSnapshot) {
        final members = memberSnapshot.data ?? const <HouseholdMember>[];
        return StreamBuilder<Household>(
          stream: _householdService.watchHousehold(widget.householdId),
          builder: (context, householdSnapshot) {
            final household = householdSnapshot.data;
            final screens = [
              DashboardScreen(
                appUser: widget.appUser,
                householdId: widget.householdId,
                members: members,
              ),
              ExpensesScreen(
                appUser: widget.appUser,
                householdId: widget.householdId,
                members: members,
              ),
              GroceriesScreen(
                appUser: widget.appUser,
                householdId: widget.householdId,
              ),
              ChoresScreen(
                appUser: widget.appUser,
                householdId: widget.householdId,
                members: members,
              ),
            ];
            return Scaffold(
              appBar: AppBar(
                title: Text(household?.name ?? 'Solaina'),
                actions: [
                  if (household != null)
                    IconButton(
                      icon: const Icon(Icons.group_add),
                      tooltip: 'Invite code: ${household.inviteCode}',
                      onPressed: () => _showInviteCode(household.inviteCode),
                    ),
                  IconButton(
                    icon: const Icon(Icons.logout),
                    onPressed: () => _authService.signOut(),
                  ),
                ],
              ),
              body: screens[_selectedIndex],
              bottomNavigationBar: NavigationBar(
                selectedIndex: _selectedIndex,
                onDestinationSelected: (index) =>
                    setState(() => _selectedIndex = index),
                destinations: const [
                  NavigationDestination(
                    icon: Icon(Icons.home_outlined),
                    selectedIcon: Icon(Icons.home),
                    label: 'Home',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.payments_outlined),
                    selectedIcon: Icon(Icons.payments),
                    label: 'Expenses',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.local_grocery_store_outlined),
                    selectedIcon: Icon(Icons.local_grocery_store),
                    label: 'Groceries',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.checklist_outlined),
                    selectedIcon: Icon(Icons.checklist),
                    label: 'Chores',
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showInviteCode(String inviteCode) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Invite code'),
        content: Text(
          'Share this code with your housemates so they can join:\n\n$inviteCode',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
