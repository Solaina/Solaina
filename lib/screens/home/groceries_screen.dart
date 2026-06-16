import 'package:flutter/material.dart';

import '../../models/app_user.dart';
import '../../models/grocery_item.dart';
import '../../services/grocery_service.dart';

class GroceriesScreen extends StatefulWidget {
  const GroceriesScreen({
    super.key,
    required this.appUser,
    required this.householdId,
  });

  final AppUser appUser;
  final String householdId;

  @override
  State<GroceriesScreen> createState() => _GroceriesScreenState();
}

class _GroceriesScreenState extends State<GroceriesScreen> {
  final _groceryService = GroceryService();
  final _newItemController = TextEditingController();

  @override
  void dispose() {
    _newItemController.dispose();
    super.dispose();
  }

  Future<void> _addItem() async {
    final name = _newItemController.text.trim();
    if (name.isEmpty) return;
    await _groceryService.addItem(
      householdId: widget.householdId,
      name: name,
      addedBy: widget.appUser.id,
    );
    _newItemController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _newItemController,
                  decoration: const InputDecoration(
                    labelText: 'Add grocery item',
                  ),
                  onSubmitted: (_) => _addItem(),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(onPressed: _addItem, child: const Icon(Icons.add)),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<List<GroceryItem>>(
            stream: _groceryService.watchItems(widget.householdId),
            builder: (context, snapshot) {
              final items = snapshot.data ?? const <GroceryItem>[];
              if (items.isEmpty) {
                return const Center(child: Text('Grocery list is empty.'));
              }
              final unbought = items.where((i) => !i.bought).toList();
              final bought = items.where((i) => i.bought).toList();
              return ListView(
                children: [
                  ...unbought.map(
                    (item) => _GroceryTile(
                      item: item,
                      householdId: widget.householdId,
                      currentUserId: widget.appUser.id,
                      groceryService: _groceryService,
                    ),
                  ),
                  if (bought.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                      child: Text(
                        'Bought',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                    ),
                  ...bought.map(
                    (item) => _GroceryTile(
                      item: item,
                      householdId: widget.householdId,
                      currentUserId: widget.appUser.id,
                      groceryService: _groceryService,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _GroceryTile extends StatelessWidget {
  const _GroceryTile({
    required this.item,
    required this.householdId,
    required this.currentUserId,
    required this.groceryService,
  });

  final GroceryItem item;
  final String householdId;
  final String currentUserId;
  final GroceryService groceryService;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(item.id),
      background: Container(color: Colors.red),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => groceryService.deleteItem(householdId, item.id),
      child: CheckboxListTile(
        value: item.bought,
        title: Text(
          item.name,
          style: item.bought
              ? const TextStyle(decoration: TextDecoration.lineThrough)
              : null,
        ),
        onChanged: (checked) => groceryService.setBought(
          householdId,
          item.id,
          checked ?? false,
          currentUserId,
        ),
      ),
    );
  }
}
