import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/app_user.dart';
import '../../models/chore.dart';
import '../../models/household.dart';
import '../../services/chore_service.dart';

class ChoresScreen extends StatefulWidget {
  const ChoresScreen({
    super.key,
    required this.appUser,
    required this.householdId,
    required this.members,
  });

  final AppUser appUser;
  final String householdId;
  final List<HouseholdMember> members;

  @override
  State<ChoresScreen> createState() => _ChoresScreenState();
}

class _ChoresScreenState extends State<ChoresScreen> {
  final _choreService = ChoreService();

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat.MMMd();
    return Scaffold(
      body: StreamBuilder<List<Chore>>(
        stream: _choreService.watchChores(widget.householdId),
        builder: (context, snapshot) {
          final chores = snapshot.data ?? const <Chore>[];
          if (chores.isEmpty) {
            return const Center(child: Text('No chores yet. Add one below.'));
          }
          final pending = chores.where((c) => !c.completed).toList();
          final completed = chores.where((c) => c.completed).toList();
          return ListView(
            padding: const EdgeInsets.only(bottom: 80),
            children: [
              ...pending.map(
                (chore) => _ChoreTile(
                  chore: chore,
                  householdId: widget.householdId,
                  members: widget.members,
                  choreService: _choreService,
                  dateFormat: dateFormat,
                ),
              ),
              if (completed.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                  child: Text(
                    'Completed',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ),
              ...completed.map(
                (chore) => _ChoreTile(
                  chore: chore,
                  householdId: widget.householdId,
                  members: widget.members,
                  choreService: _choreService,
                  dateFormat: dateFormat,
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddChoreDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddChoreDialog(BuildContext context) {
    final titleController = TextEditingController();
    String assignedTo = widget.appUser.id;
    ChoreFrequency frequency = ChoreFrequency.weekly;
    DateTime? dueDate;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Add chore'),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(labelText: 'Chore'),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: assignedTo,
                      decoration: const InputDecoration(
                        labelText: 'Assigned to',
                      ),
                      items: widget.members
                          .map(
                            (m) => DropdownMenuItem(
                              value: m.userId,
                              child: Text(m.displayName),
                            ),
                          )
                          .toList(),
                      onChanged: (value) => setDialogState(
                        () => assignedTo = value ?? assignedTo,
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<ChoreFrequency>(
                      initialValue: frequency,
                      decoration: const InputDecoration(labelText: 'Repeats'),
                      items: ChoreFrequency.values
                          .map(
                            (f) => DropdownMenuItem(
                              value: f,
                              child: Text(_frequencyLabel(f)),
                            ),
                          )
                          .toList(),
                      onChanged: (value) =>
                          setDialogState(() => frequency = value ?? frequency),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            dueDate == null
                                ? 'No due date'
                                : 'Due ${DateFormat.yMMMd().format(dueDate!)}',
                          ),
                        ),
                        TextButton(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(
                                const Duration(days: 365),
                              ),
                            );
                            if (picked != null) {
                              setDialogState(() => dueDate = picked);
                            }
                          },
                          child: const Text('Pick date'),
                        ),
                      ],
                    ),
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
                    if (titleController.text.trim().isEmpty) return;
                    await _choreService.addChore(
                      householdId: widget.householdId,
                      title: titleController.text.trim(),
                      assignedTo: assignedTo,
                      frequency: frequency,
                      dueDate: dueDate,
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

  String _frequencyLabel(ChoreFrequency frequency) {
    switch (frequency) {
      case ChoreFrequency.oneOff:
        return 'One-off';
      case ChoreFrequency.daily:
        return 'Daily';
      case ChoreFrequency.weekly:
        return 'Weekly';
      case ChoreFrequency.monthly:
        return 'Monthly';
    }
  }
}

class _ChoreTile extends StatelessWidget {
  const _ChoreTile({
    required this.chore,
    required this.householdId,
    required this.members,
    required this.choreService,
    required this.dateFormat,
  });

  final Chore chore;
  final String householdId;
  final List<HouseholdMember> members;
  final ChoreService choreService;
  final DateFormat dateFormat;

  @override
  Widget build(BuildContext context) {
    final assigneeName = members.nameFor(chore.assignedTo);
    return Dismissible(
      key: ValueKey(chore.id),
      background: Container(color: Colors.red),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => choreService.deleteChore(householdId, chore.id),
      child: CheckboxListTile(
        value: chore.completed,
        title: Text(
          chore.title,
          style: chore.completed
              ? const TextStyle(decoration: TextDecoration.lineThrough)
              : null,
        ),
        subtitle: Text(
          [
            assigneeName,
            if (chore.dueDate != null)
              'due ${dateFormat.format(chore.dueDate!)}',
          ].join(' • '),
        ),
        onChanged: (checked) =>
            choreService.setCompleted(householdId, chore.id, checked ?? false),
      ),
    );
  }
}
