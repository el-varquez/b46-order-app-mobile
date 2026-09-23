import 'package:flutter/material.dart';

import '../../../../app/theme/tokens.dart';
import '../../../../shared/components/pop_icons.dart';
import '../../../../shared/components/pop_scaffold.dart';

class AdminPlaceholderScreen extends StatelessWidget {
  const AdminPlaceholderScreen({required this.onSignOut, super.key});
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) => PopScaffold(
    appBar: AppBar(
      title: const Text('Admin'),
      actions: [
        IconButton(onPressed: onSignOut, icon: const Icon(PopIcons.signOut)),
      ],
    ),
    child: const Padding(
      padding: EdgeInsets.all(PopSpace.xl),
      child: EmptyState(
        title: 'Cashier management is next',
        message: 'Account creation, disable, and restore arrive in the planned Admin phase.',
      ),
    ),
  );
}
