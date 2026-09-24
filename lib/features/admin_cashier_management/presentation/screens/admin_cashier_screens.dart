import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/theme/tokens.dart';
import '../../../../shared/components/pop_icons.dart';
import '../../../../shared/components/pop_scaffold.dart';
import '../../domain/entities/cashier_account.dart';
import '../cubit/admin_cashiers_cubit.dart';

class AdminCashiersScreen extends StatefulWidget {
  const AdminCashiersScreen({
    required this.onAdd,
    required this.onOpen,
    required this.onSignOut,
    super.key,
  });
  final VoidCallback onAdd;
  final ValueChanged<String> onOpen;
  final VoidCallback onSignOut;

  @override
  State<AdminCashiersScreen> createState() => _AdminCashiersScreenState();
}

class _AdminCashiersScreenState extends State<AdminCashiersScreen> {
  @override
  void initState() {
    super.initState();
    context.read<AdminCashiersCubit>().load();
  }

  @override
  Widget build(BuildContext context) => PopScaffold(
    appBar: AppBar(
      title: const Text('Cashiers'),
      actions: [
        IconButton(
          tooltip: 'Sign out',
          onPressed: widget.onSignOut,
          icon: const Icon(PopIcons.signOut),
        ),
      ],
    ),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: widget.onAdd,
      icon: const Icon(PopIcons.addUser),
      label: const Text('Add cashier'),
    ),
    child: BlocBuilder<AdminCashiersCubit, AdminCashiersState>(
      builder: (context, state) {
        final cubit = context.read<AdminCashiersCubit>();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(PopSpace.md),
              child: Wrap(
                spacing: PopSpace.xs,
                children: [
                  _filter(
                    context,
                    'All',
                    state.filter == null,
                    () => cubit.load(),
                  ),
                  _filter(
                    context,
                    'Active',
                    state.filter == CashierAccountStatus.active,
                    () => cubit.load(filter: CashierAccountStatus.active),
                  ),
                  _filter(
                    context,
                    'Disabled',
                    state.filter == CashierAccountStatus.disabled,
                    () => cubit.load(filter: CashierAccountStatus.disabled),
                  ),
                ],
              ),
            ),
            if (state.message != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: PopSpace.md),
                child: Text(
                  state.message!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            if (state.loading && state.cashiers.isEmpty)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else if (state.cashiers.isEmpty)
              const Expanded(
                child: EmptyState(
                  title: 'No cashiers here',
                  message: 'Add a cashier or choose another filter.',
                ),
              )
            else
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => cubit.load(filter: state.filter),
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(
                      PopSpace.md,
                      0,
                      PopSpace.md,
                      100,
                    ),
                    itemCount: state.cashiers.length,
                    itemBuilder: (context, index) {
                      final cashier = state.cashiers[index];
                      return Card(
                        child: ListTile(
                          onTap: () => widget.onOpen(cashier.id),
                          leading: const Icon(PopIcons.users),
                          title: Text(
                            cashier.name,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          subtitle: Text(
                            '${cashier.email}\n${cashier.emailVerified ? _status(cashier.status) : 'Email verification required'}',
                            maxLines: 2,
                          ),
                          trailing: const Icon(PopIcons.forward),
                        ),
                      );
                    },
                  ),
                ),
              ),
          ],
        );
      },
    ),
  );

  Widget _filter(
    BuildContext context,
    String label,
    bool selected,
    VoidCallback action,
  ) => ChoiceChip(
    label: Text(label),
    selected: selected,
    onSelected: (_) => action(),
  );
}

class AddCashierScreen extends StatefulWidget {
  const AddCashierScreen({required this.onCreated, super.key});
  final ValueChanged<String> onCreated;

  @override
  State<AddCashierScreen> createState() => _AddCashierScreenState();
}

class _AddCashierScreenState extends State<AddCashierScreen> {
  final formKey = GlobalKey<FormState>();
  final name = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();
  final code = TextEditingController();
  CashierRegistration? pending;
  DateTime? resendAvailableAt;
  Timer? clock;

  @override
  void initState() {
    super.initState();
    clock = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && pending != null) setState(() {});
    });
  }

  @override
  void dispose() {
    name.dispose();
    email.dispose();
    password.dispose();
    code.dispose();
    clock?.cancel();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(formKey.currentState?.validate() ?? false)) return;
    final started = await context.read<AdminCashiersCubit>().beginRegistration(
      name: name.text,
      email: email.text,
      temporaryPassword: password.text,
    );
    if (started == null || !mounted) return;
    setState(() {
      pending = started;
      resendAvailableAt = DateTime.now().add(const Duration(minutes: 1));
    });
  }

  Future<void> _verify() async {
    final id = pending?.id;
    if (id == null) return;
    final entered = code.text.trim();
    if (!RegExp(r'^[0-9]{6}$').hasMatch(entered)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter the six-digit code.')),
      );
      return;
    }
    final account = await context.read<AdminCashiersCubit>().verifyRegistration(
      id,
      entered,
    );
    if (account == null || !mounted) return;
    if (!account.createdNow) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            account.status == CashierAccountStatus.disabled
                ? 'Email verified. Restore this cashier before they sign in.'
                : 'Existing cashier verified. The new temporary password is now required.',
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Email verified. Share the temporary password privately.',
          ),
        ),
      );
    }
    if (mounted) widget.onCreated(account.id);
  }

  Future<void> _resend() async {
    final id = pending?.id;
    if (id == null) return;
    final updated = await context.read<AdminCashiersCubit>().resendRegistration(
      id,
    );
    if (updated == null || !mounted) return;
    setState(() {
      pending = updated;
      resendAvailableAt = DateTime.now().add(const Duration(minutes: 1));
    });
  }

  @override
  Widget build(BuildContext context) => PopScaffold(
    appBar: AppBar(
      leading: const PopBackButton(),
      title: Text(pending == null ? 'Add cashier' : 'Verify cashier email'),
    ),
    child: BlocBuilder<AdminCashiersCubit, AdminCashiersState>(
      builder: (context, state) => ListView(
        padding: const EdgeInsets.all(PopSpace.lg),
        children: [
          Icon(pending == null ? PopIcons.addUser : PopIcons.users, size: 44),
          const SizedBox(height: PopSpace.md),
          Text(
            pending == null
                ? 'Give a cashier access'
                : 'Check with your cashier',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: PopSpace.xs),
          Text(
            pending == null
                ? 'We will email a six-digit code to the cashier. Ask them for it before their account is activated.'
                : 'A six-digit code was sent to ${email.text.trim()}. Ask the cashier to give you the code. The account cannot sign in until you verify it.',
          ),
          const SizedBox(height: PopSpace.lg),
          if (pending == null)
            Form(
              key: formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: name,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(labelText: 'Name'),
                    validator: (value) => (value?.trim().isNotEmpty ?? false)
                        ? null
                        : 'Enter a name.',
                  ),
                  const SizedBox(height: PopSpace.md),
                  TextFormField(
                    controller: email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email address',
                    ),
                    validator: (value) => (value?.trim().contains('@') ?? false)
                        ? null
                        : 'Enter a valid email.',
                  ),
                  const SizedBox(height: PopSpace.md),
                  _TemporaryPasswordField(controller: password),
                ],
              ),
            ),
          if (pending == null) ...[
            const SizedBox(height: PopSpace.lg),
            FilledButton(
              onPressed: state.busy ? null : _submit,
              child: Text(state.busy ? 'Sending…' : 'Send verification code'),
            ),
          ] else ...[
            TextField(
              controller: code,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              maxLength: 6,
              autofillHints: const [AutofillHints.oneTimeCode],
              decoration: const InputDecoration(labelText: 'Verification code'),
              onSubmitted: (_) => _verify(),
            ),
            const SizedBox(height: PopSpace.md),
            FilledButton(
              onPressed: state.busy ? null : _verify,
              child: Text(state.busy ? 'Verifying…' : 'Verify and add cashier'),
            ),
            const SizedBox(height: PopSpace.sm),
            TextButton(
              onPressed:
                  state.busy ||
                      (resendAvailableAt?.isAfter(DateTime.now()) ?? false)
                  ? null
                  : _resend,
              child: Text(
                (resendAvailableAt?.isAfter(DateTime.now()) ?? false)
                    ? 'Resend code in ${resendAvailableAt!.difference(DateTime.now()).inSeconds + 1}s'
                    : 'Resend code',
              ),
            ),
            TextButton(
              onPressed: state.busy
                  ? null
                  : () => setState(() {
                      pending = null;
                      code.clear();
                    }),
              child: const Text('Change email'),
            ),
          ],
          if (state.message != null) ...[
            const SizedBox(height: PopSpace.md),
            Text(
              state.message!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
        ],
      ),
    ),
  );
}

class CashierDetailScreen extends StatefulWidget {
  const CashierDetailScreen({required this.id, super.key});
  final String id;

  @override
  State<CashierDetailScreen> createState() => _CashierDetailScreenState();
}

class _CashierDetailScreenState extends State<CashierDetailScreen> {
  @override
  void initState() {
    super.initState();
    context.read<AdminCashiersCubit>().loadDetail(widget.id);
  }

  Future<void> _changeStatus(CashierAccount account) async {
    final target = account.status == CashierAccountStatus.active
        ? CashierAccountStatus.disabled
        : CashierAccountStatus.active;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          target == CashierAccountStatus.disabled
              ? 'Disable cashier?'
              : 'Restore cashier?',
        ),
        content: Text(
          target == CashierAccountStatus.disabled
              ? 'This immediately signs ${account.name} out and blocks new sign-ins.'
              : '${account.name} can sign in again with the existing login.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep as is'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              target == CashierAccountStatus.disabled ? 'Disable' : 'Restore',
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final success = await context.read<AdminCashiersCubit>().setStatus(
      account.id,
      target,
    );
    if (success && mounted) {
      _notice(
        target == CashierAccountStatus.disabled
            ? 'Cashier disabled.'
            : 'Cashier restored.',
      );
    }
  }

  Future<void> _reset(CashierAccount account) async {
    final temporaryPassword = await showDialog<String>(
      context: context,
      builder: (_) => _ResetPasswordDialog(name: account.name),
    );
    if (temporaryPassword == null || !mounted) return;
    final success = await context.read<AdminCashiersCubit>().resetPassword(
      account.id,
      temporaryPassword,
    );
    if (success && mounted) {
      _notice('Login reset. Share the temporary password privately.');
    }
  }

  void _notice(String message) =>
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));

  @override
  Widget build(BuildContext context) => PopScaffold(
    appBar: AppBar(
      leading: const PopBackButton(),
      title: const Text('Cashier details'),
    ),
    child: BlocBuilder<AdminCashiersCubit, AdminCashiersState>(
      builder: (context, state) {
        final account = state.selected?.id == widget.id ? state.selected : null;
        if (account == null) {
          return state.message == null
              ? const Center(child: CircularProgressIndicator())
              : EmptyState(
                  title: 'Could not load cashier',
                  message: state.message!,
                );
        }
        return RefreshIndicator(
          onRefresh: () =>
              context.read<AdminCashiersCubit>().loadDetail(widget.id),
          child: ListView(
            padding: const EdgeInsets.all(PopSpace.lg),
            children: [
              const Icon(PopIcons.users, size: 44),
              const SizedBox(height: PopSpace.md),
              Text(
                account.name,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              Text(account.email),
              const SizedBox(height: PopSpace.md),
              Chip(
                label: Text(
                  account.emailVerified
                      ? _status(account.status)
                      : 'Email verification required',
                ),
              ),
              if (!account.emailVerified)
                const Text(
                  'Email verification required. Use Add cashier with this email and ask the cashier for their code.',
                ),
              if (account.passwordChangeRequired)
                const Text(
                  'Waiting for cashier to replace the temporary password.',
                ),
              const SizedBox(height: PopSpace.lg),
              Text(
                'Connected sign-in methods',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: PopSpace.xs),
              Wrap(
                spacing: PopSpace.xs,
                children: account.connectedProviders
                    .map(
                      (p) => Chip(label: Text(p == 'PASSWORD' ? 'Email' : p)),
                    )
                    .toList(),
              ),
              const SizedBox(height: PopSpace.lg),
              if (account.emailVerified)
                OutlinedButton.icon(
                  onPressed: state.busy ? null : () => _reset(account),
                  icon: const Icon(PopIcons.resetLogin),
                  label: const Text('Reset login'),
                ),
              if (account.emailVerified) const SizedBox(height: PopSpace.xs),
              if (account.emailVerified)
                FilledButton.icon(
                  onPressed: state.busy ? null : () => _changeStatus(account),
                  icon: Icon(
                    account.status == CashierAccountStatus.active
                        ? PopIcons.disableUser
                        : PopIcons.restoreUser,
                  ),
                  label: Text(
                    account.status == CashierAccountStatus.active
                        ? 'Disable cashier'
                        : 'Restore cashier',
                  ),
                ),
              if (state.message != null) ...[
                const SizedBox(height: PopSpace.md),
                Text(
                  state.message!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: PopSpace.lg),
              Text(
                'Recent activity',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (account.audit.isEmpty) const Text('No account changes yet.'),
              ...account.audit.map(
                (entry) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(_auditLabel(entry.action)),
                  subtitle: Text(
                    MaterialLocalizations.of(context)
                        .formatMediumDate(entry.occurredAt),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    ),
  );
}

class _TemporaryPasswordField extends StatefulWidget {
  const _TemporaryPasswordField({required this.controller});
  final TextEditingController controller;
  @override
  State<_TemporaryPasswordField> createState() =>
      _TemporaryPasswordFieldState();
}

class _TemporaryPasswordFieldState extends State<_TemporaryPasswordField> {
  bool visible = false;
  @override
  Widget build(BuildContext context) => TextFormField(
    controller: widget.controller,
    obscureText: !visible,
    decoration: InputDecoration(
      labelText: 'Temporary password',
      suffixIcon: IconButton(
        tooltip: visible ? 'Hide password' : 'Show password',
        icon: Icon(visible ? PopIcons.hidePassword : PopIcons.showPassword),
        onPressed: () => setState(() => visible = !visible),
      ),
    ),
    validator: (value) =>
        (value?.runes.length ?? 0) >= 8 ? null : 'Use at least 8 characters.',
  );
}

class _ResetPasswordDialog extends StatefulWidget {
  const _ResetPasswordDialog({required this.name});
  final String name;
  @override
  State<_ResetPasswordDialog> createState() => _ResetPasswordDialogState();
}

class _ResetPasswordDialogState extends State<_ResetPasswordDialog> {
  final formKey = GlobalKey<FormState>();
  final password = TextEditingController();
  @override
  void dispose() {
    password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Reset login?'),
    content: Form(
      key: formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${widget.name} will be signed out and required to choose a new password.',
          ),
          const SizedBox(height: PopSpace.md),
          _TemporaryPasswordField(controller: password),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: () {
          if (formKey.currentState?.validate() ?? false) {
            Navigator.pop(context, password.text);
          }
        },
        child: const Text('Reset login'),
      ),
    ],
  );
}

String _status(CashierAccountStatus status) =>
    status == CashierAccountStatus.active ? 'Active' : 'Disabled';

String _auditLabel(String action) => switch (action) {
  'CASHIER_CREATED' => 'Cashier added',
  'CASHIER_EMAIL_VERIFIED' => 'Email verified',
  'CASHIER_DISABLED' => 'Cashier disabled',
  'CASHIER_RESTORED' => 'Cashier restored',
  'CASHIER_PASSWORD_RESET' => 'Login reset',
  'PASSWORD_CHANGED' => 'Password changed',
  'OAUTH_IDENTITY_LINKED' => 'Google connected',
  _ => 'Account updated',
};
