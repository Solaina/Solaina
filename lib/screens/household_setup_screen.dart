import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../services/auth_service.dart';
import '../services/household_service.dart';

class HouseholdSetupScreen extends StatefulWidget {
  const HouseholdSetupScreen({super.key, required this.appUser});

  final AppUser appUser;

  @override
  State<HouseholdSetupScreen> createState() => _HouseholdSetupScreenState();
}

class _HouseholdSetupScreenState extends State<HouseholdSetupScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _createNameController = TextEditingController();
  final _joinCodeController = TextEditingController();
  final _authService = AuthService();
  final _householdService = HouseholdService();
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _createNameController.dispose();
    _joinCodeController.dispose();
    super.dispose();
  }

  Future<void> _createHousehold() async {
    if (_createNameController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Enter a household name.');
      return;
    }
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });
    try {
      final householdId = await _householdService.createHousehold(
        name: _createNameController.text.trim(),
        userId: widget.appUser.id,
        displayName: widget.appUser.displayName,
      );
      await _authService.setHouseholdId(widget.appUser.id, householdId);
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _joinHousehold() async {
    if (_joinCodeController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Enter an invite code.');
      return;
    }
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });
    try {
      final householdId = await _householdService.joinHousehold(
        inviteCode: _joinCodeController.text.trim(),
        userId: widget.appUser.id,
        displayName: widget.appUser.displayName,
      );
      await _authService.setHouseholdId(widget.appUser.id, householdId);
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Set up your household'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Create new'),
            Tab(text: 'Join existing'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _authService.signOut(),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildCreateTab(), _buildJoinTab()],
      ),
    );
  }

  Widget _buildCreateTab() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Start a brand new household and invite the other three '
            'people once it is created.',
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _createNameController,
            decoration: const InputDecoration(labelText: 'Household name'),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 12),
            Text(
              _errorMessage!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _isSubmitting ? null : _createHousehold,
            child: const Text('Create household'),
          ),
        ],
      ),
    );
  }

  Widget _buildJoinTab() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Ask a housemate for their invite code to join their '
            'household.',
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _joinCodeController,
            decoration: const InputDecoration(labelText: 'Invite code'),
            textCapitalization: TextCapitalization.characters,
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 12),
            Text(
              _errorMessage!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _isSubmitting ? null : _joinHousehold,
            child: const Text('Join household'),
          ),
        ],
      ),
    );
  }
}
