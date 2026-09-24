import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/theme/tokens.dart';
import '../../../../shared/components/pop_icons.dart';
import '../../../../shared/components/pop_scaffold.dart';
import '../cubit/session_cubit.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({required this.onSignOut, super.key});
  final VoidCallback onSignOut;

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final formKey = GlobalKey<FormState>();
  final current = TextEditingController();
  final replacement = TextEditingController();
  final confirmation = TextEditingController();
  bool busy = false;
  String? message;

  @override
  void dispose() {
    current.dispose();
    replacement.dispose();
    confirmation.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(formKey.currentState?.validate() ?? false) || busy) return;
    setState(() {
      busy = true;
      message = null;
    });
    final error = await context.read<SessionCubit>().changePassword(
      current.text,
      replacement.text,
    );
    if (mounted) {
      setState(() {
        busy = false;
        message = error;
      });
    }
  }

  @override
  Widget build(BuildContext context) => PopScaffold(
    appBar: AppBar(
      title: const Text('Secure your login'),
      actions: [
        IconButton(
          tooltip: 'Sign out',
          onPressed: widget.onSignOut,
          icon: const Icon(PopIcons.signOut),
        ),
      ],
    ),
    child: ListView(
      padding: const EdgeInsets.all(PopSpace.lg),
      children: [
        const Icon(PopIcons.resetLogin, size: 48),
        const SizedBox(height: PopSpace.md),
        Text(
          'Choose your own password',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: PopSpace.xs),
        const Text(
          'Replace the temporary password before opening cashier orders.',
        ),
        const SizedBox(height: PopSpace.lg),
        Form(
          key: formKey,
          child: Column(
            children: [
              _PasswordField(
                controller: current,
                label: 'Temporary password',
                validator: (value) => (value?.isNotEmpty ?? false)
                    ? null
                    : 'Enter your temporary password.',
              ),
              const SizedBox(height: PopSpace.md),
              _PasswordField(
                controller: replacement,
                label: 'New password',
                validator: (value) => (value?.runes.length ?? 0) >= 8
                    ? null
                    : 'Use at least 8 characters.',
              ),
              const SizedBox(height: PopSpace.md),
              _PasswordField(
                controller: confirmation,
                label: 'Confirm new password',
                validator: (value) => value == replacement.text
                    ? null
                    : 'Passwords do not match.',
              ),
            ],
          ),
        ),
        const SizedBox(height: PopSpace.lg),
        FilledButton(
          onPressed: busy ? null : _save,
          child: Text(busy ? 'Saving…' : 'Set new password'),
        ),
        if (message != null) ...[
          const SizedBox(height: PopSpace.md),
          Text(
            message!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
      ],
    ),
  );
}

class _PasswordField extends StatefulWidget {
  const _PasswordField({
    required this.controller,
    required this.label,
    required this.validator,
  });
  final TextEditingController controller;
  final String label;
  final String? Function(String?) validator;
  @override
  State<_PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<_PasswordField> {
  bool visible = false;
  @override
  Widget build(BuildContext context) => TextFormField(
    controller: widget.controller,
    obscureText: !visible,
    validator: widget.validator,
    decoration: InputDecoration(
      labelText: widget.label,
      suffixIcon: IconButton(
        tooltip: visible ? 'Hide password' : 'Show password',
        icon: Icon(visible ? PopIcons.hidePassword : PopIcons.showPassword),
        onPressed: () => setState(() => visible = !visible),
      ),
    ),
  );
}
