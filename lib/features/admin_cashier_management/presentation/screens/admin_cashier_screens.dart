import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/theme/tokens.dart';
import '../../../../shared/components/customer_shell.dart';
import '../../../../shared/components/pop_icons.dart';
import '../../../../shared/components/pop_scaffold.dart';
import '../../domain/entities/cashier_account.dart';
import '../cubit/admin_cashiers_cubit.dart';

class AdminCashiersScreen extends StatefulWidget {
  const AdminCashiersScreen({
    required this.onAdd,
    required this.onOpen,
    required this.onSignOut,
    required this.onToggleTheme,
    super.key,
  });
  final VoidCallback onAdd;
  final ValueChanged<String> onOpen;
  final VoidCallback onSignOut;
  final VoidCallback onToggleTheme;

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
  Widget build(BuildContext context) => CustomerTheme(
    child: PopScaffold(
      appBar: CustomerHeader(
        title: 'Cashier access',
        subtitle: 'Admin',
        action: IconButton(
          tooltip: 'Switch appearance',
          onPressed: widget.onToggleTheme,
          icon: const Icon(PopIcons.theme),
        ),
      ),
      child: BlocBuilder<AdminCashiersCubit, AdminCashiersState>(
        builder: (context, state) {
          final cubit = context.read<AdminCashiersCubit>();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (state.filter == null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 15),
                  child: Row(
                    children: [
                      Expanded(
                        child: _AdminCountCard(
                          count: state.cashiers
                              .where(
                                (cashier) =>
                                    cashier.status ==
                                    CashierAccountStatus.active,
                              )
                              .length,
                          label: 'Active',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _AdminCountCard(
                          count: state.cashiers
                              .where(
                                (cashier) =>
                                    cashier.status ==
                                    CashierAccountStatus.disabled,
                              )
                              .length,
                          label: 'Disabled',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _AdminCountCard(
                          count: state.cashiers
                              .where(
                                (cashier) =>
                                    !cashier.emailVerified ||
                                    cashier.passwordChangeRequired,
                              )
                              .length,
                          label: 'Invited',
                        ),
                      ),
                    ],
                  ),
                ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: widget.onAdd,
                    icon: const Icon(PopIcons.addUser),
                    label: const Text('Add cashier'),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Cashier accounts',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Text(
                      '${state.cashiers.length} users',
                      style: TextStyle(
                        color: CustomerPalette.muted(context),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Wrap(
                  spacing: 7,
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
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              if (state.loading && state.cashiers.isEmpty)
                const Expanded(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (state.cashiers.isEmpty)
                Expanded(
                  child: ListView(
                    children: [
                      const EmptyState(
                        title: 'No cashiers here',
                        message: 'Add a cashier or choose another filter.',
                      ),
                      _AdminSignOutButton(onPressed: widget.onSignOut),
                    ],
                  ),
                )
              else
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () => cubit.load(filter: state.filter),
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      itemCount: state.cashiers.length + 1,
                      itemBuilder: (context, index) {
                        if (index == state.cashiers.length) {
                          return _AdminSignOutButton(
                            onPressed: widget.onSignOut,
                          );
                        }
                        final cashier = state.cashiers[index];
                        return _AdminAccountCard(
                          account: cashier,
                          onTap: () => widget.onOpen(cashier.id),
                        );
                      },
                    ),
                  ),
                ),
            ],
          );
        },
      ),
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
    showCheckmark: false,
    backgroundColor: CustomerPalette.surface(context),
    selectedColor: PopColors.launchRed,
    labelStyle: TextStyle(
      color: selected ? PopColors.white : CustomerPalette.ink(context),
      fontSize: 11,
      fontWeight: FontWeight.w800,
    ),
    side: BorderSide(
      color: selected ? PopColors.launchRed : CustomerPalette.line(context),
    ),
    shape: const StadiumBorder(),
  );
}

class _AdminCountCard extends StatelessWidget {
  const _AdminCountCard({required this.count, required this.label});
  final int count;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 12),
    decoration: BoxDecoration(
      color: CustomerPalette.surface(context),
      border: Border.all(color: CustomerPalette.line(context)),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$count',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: TextStyle(color: CustomerPalette.muted(context), fontSize: 10),
        ),
      ],
    ),
  );
}

class _AdminAccountCard extends StatelessWidget {
  const _AdminAccountCard({required this.account, required this.onTap});
  final CashierAccount account;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 10),
    color: CustomerPalette.surface(context),
    elevation: 2,
    shadowColor: CustomerPalette.ink(context).withValues(alpha: 0.16),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
      side: BorderSide(color: CustomerPalette.line(context)),
    ),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              children: [
                _AdminAvatar(name: account.name),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        account.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        account.email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: CustomerPalette.muted(context),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _AdminStatusPill(account: account),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    account.connectedProviders
                        .where((provider) => provider.toUpperCase() != 'APPLE')
                        .map(_providerLabel)
                        .join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: CustomerPalette.muted(context),
                      fontSize: 11,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Manage →',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class _AdminAvatar extends StatelessWidget {
  const _AdminAvatar({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    final initials = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part.substring(0, 1).toUpperCase())
        .join();
    return CircleAvatar(
      radius: 22,
      backgroundColor: CustomerPalette.soft(context),
      child: Text(
        initials,
        style: TextStyle(
          color: CustomerPalette.ink(context),
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _AdminStatusPill extends StatelessWidget {
  const _AdminStatusPill({required this.account});
  final CashierAccount account;

  @override
  Widget build(BuildContext context) {
    final active =
        account.emailVerified &&
        !account.passwordChangeRequired &&
        account.status == CashierAccountStatus.active;
    final disabled = account.status == CashierAccountStatus.disabled;
    final color = active
        ? PopColors.success
        : disabled
        ? PopColors.authDanger
        : CustomerPalette.ink(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        disabled
            ? 'Disabled'
            : !account.emailVerified || account.passwordChangeRequired
            ? 'Invited'
            : 'Active',
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _AdminSignOutButton extends StatelessWidget {
  const _AdminSignOutButton({required this.onPressed});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 8),
    child: SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: CustomerPalette.ink(context),
          backgroundColor: CustomerPalette.surface(context),
          side: BorderSide(color: CustomerPalette.line(context)),
        ),
        child: const Text('Sign out'),
      ),
    ),
  );
}

String _providerLabel(String provider) => switch (provider.toUpperCase()) {
  'PASSWORD' => 'Email',
  'GOOGLE' => 'Google',
  _ => provider,
};

class AddCashierScreen extends StatefulWidget {
  const AddCashierScreen({
    required this.onCreated,
    required this.onToggleTheme,
    super.key,
  });
  final ValueChanged<String> onCreated;
  final VoidCallback onToggleTheme;

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
  Widget build(BuildContext context) => CustomerTheme(
    child: PopScaffold(
      appBar: CustomerHeader(
        title: pending == null ? 'Add cashier' : 'Verify cashier email',
        subtitle: 'Admin only',
        back: true,
        action: IconButton(
          tooltip: 'Switch appearance',
          onPressed: widget.onToggleTheme,
          icon: const Icon(PopIcons.theme),
        ),
      ),
      child: BlocBuilder<AdminCashiersCubit, AdminCashiersState>(
        builder: (context, state) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          children: [
            CustomerCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    pending == null ? 'Cashier details' : 'Verification code',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    pending == null
                        ? 'We will email a six-digit code to the cashier. Ask them for it before their account is activated.'
                        : 'A six-digit code was sent to ${email.text.trim()}. Ask the cashier to give you the code. The account cannot sign in until you verify it.',
                    style: TextStyle(
                      color: CustomerPalette.muted(context),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (pending == null)
                    Form(
                      key: formKey,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: name,
                            textCapitalization: TextCapitalization.words,
                            decoration: const InputDecoration(
                              labelText: 'Full name',
                              hintText: 'e.g. Mika Dela Cruz',
                            ),
                            validator: (value) =>
                                (value?.trim().isNotEmpty ?? false)
                                ? null
                                : 'Enter a name.',
                          ),
                          const SizedBox(height: PopSpace.md),
                          TextFormField(
                            controller: email,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: 'Email address',
                              hintText: 'mika@gmail.com',
                            ),
                            validator: (value) =>
                                (value?.trim().contains('@') ?? false)
                                ? null
                                : 'Enter a valid email.',
                          ),
                          const SizedBox(height: PopSpace.md),
                          _TemporaryPasswordField(controller: password),
                        ],
                      ),
                    ),
                  if (pending == null) ...[
                    const SizedBox(height: 16),
                    _AdminInfoBox(
                      title: 'Secure onboarding',
                      message: 'The cashier receives a verification code and replaces the temporary password after signing in.',
                    ),
                    const SizedBox(height: 14),
                    FilledButton(
                      onPressed: state.busy ? null : _submit,
                      child: Text(
                        state.busy ? 'Sending…' : 'Send verification code',
                      ),
                    ),
                  ] else ...[
                    TextField(
                      controller: code,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.done,
                      maxLength: 6,
                      autofillHints: const [AutofillHints.oneTimeCode],
                      decoration: const InputDecoration(
                        labelText: 'Verification code',
                      ),
                      onSubmitted: (_) => _verify(),
                    ),
                    const SizedBox(height: PopSpace.md),
                    FilledButton(
                      onPressed: state.busy ? null : _verify,
                      child: Text(
                        state.busy ? 'Verifying…' : 'Verify and add cashier',
                      ),
                    ),
                    const SizedBox(height: PopSpace.sm),
                    TextButton(
                      onPressed:
                          state.busy ||
                              (resendAvailableAt?.isAfter(DateTime.now()) ??
                                  false)
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
                    const SizedBox(height: 16),
                    Text(
                      state.message!,
                      style: const TextStyle(color: PopColors.authDanger),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'This screen creates Cashier accounts only. It cannot create another Admin.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: CustomerPalette.muted(context),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class CashierDetailScreen extends StatefulWidget {
  const CashierDetailScreen({
    required this.id,
    required this.onToggleTheme,
    super.key,
  });
  final String id;
  final VoidCallback onToggleTheme;

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
  Widget build(BuildContext context) => CustomerTheme(
    child: PopScaffold(
      appBar: CustomerHeader(
        title: 'Cashier account',
        subtitle: widget.id,
        back: true,
        action: IconButton(
          tooltip: 'Switch appearance',
          onPressed: widget.onToggleTheme,
          icon: const Icon(PopIcons.theme),
        ),
      ),
      child: BlocBuilder<AdminCashiersCubit, AdminCashiersState>(
        builder: (context, state) {
          final account = state.selected?.id == widget.id
              ? state.selected
              : null;
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
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              children: [
                _AdminHero(account: account),
                const SizedBox(height: 18),
                _AdminSectionCard(
                  title: 'Sign-in methods',
                  trailing: account.emailVerified
                      ? account.passwordChangeRequired
                            ? 'Setup pending'
                            : 'Ready'
                      : 'Invite pending',
                  child: Column(
                    children: [
                      for (final provider in const ['PASSWORD', 'GOOGLE'])
                        _AdminProviderRow(
                          provider: provider,
                          connected: account.connectedProviders.any(
                            (value) => value.toUpperCase() == provider,
                          ),
                        ),
                    ],
                  ),
                ),
                if (!account.emailVerified) ...[
                  const SizedBox(height: 12),
                  const _AdminInfoBox(
                    title: 'Email verification required',
                    message: 'Use Add cashier with this email and ask the cashier for their code.',
                  ),
                ],
                if (account.passwordChangeRequired) ...[
                  const SizedBox(height: 12),
                  const _AdminInfoBox(
                    title: 'Password change pending',
                    message: 'The cashier must replace the temporary password at sign-in.',
                  ),
                ],
                const SizedBox(height: 12),
                _AdminSectionCard(
                  title: 'Admin actions',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (account.emailVerified) ...[
                        if (account.status == CashierAccountStatus.active)
                          OutlinedButton.icon(
                            onPressed: state.busy
                                ? null
                                : () => _changeStatus(account),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: PopColors.authDanger,
                              side: const BorderSide(
                                color: PopColors.authDanger,
                              ),
                            ),
                            icon: const Icon(PopIcons.disableUser),
                            label: const Text('Disable cashier'),
                          )
                        else
                          FilledButton.icon(
                            onPressed: state.busy
                                ? null
                                : () => _changeStatus(account),
                            icon: const Icon(PopIcons.restoreUser),
                            label: const Text('Restore cashier'),
                          ),
                        const SizedBox(height: 9),
                        OutlinedButton.icon(
                          onPressed: state.busy ? null : () => _reset(account),
                          icon: const Icon(PopIcons.resetLogin),
                          label: const Text('Reset login'),
                        ),
                      ] else
                        Text(
                          'Actions become available after email verification.',
                          style: TextStyle(
                            color: CustomerPalette.muted(context),
                          ),
                        ),
                    ],
                  ),
                ),
                if (state.message != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    state.message!,
                    style: const TextStyle(color: PopColors.authDanger),
                  ),
                ],
                const SizedBox(height: 12),
                const _AdminInfoBox(
                  title: 'Account safety',
                  message: 'Disabling blocks sign-in and revokes sessions while keeping order history.',
                ),
                const SizedBox(height: 18),
                _AdminSectionCard(
                  title: 'Recent activity',
                  child: account.audit.isEmpty
                      ? Text(
                          'No account changes yet.',
                          style: TextStyle(
                            color: CustomerPalette.muted(context),
                          ),
                        )
                      : Column(
                          children: [
                            for (final entry in account.audit)
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(_auditLabel(entry.action)),
                                subtitle: Text(
                                  MaterialLocalizations.of(context)
                                      .formatMediumDate(entry.occurredAt),
                                ),
                              ),
                          ],
                        ),
                ),
              ],
            ),
          );
        },
      ),
    ),
  );
}

class _AdminHero extends StatelessWidget {
  const _AdminHero({required this.account});
  final CashierAccount account;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(17),
    decoration: const BoxDecoration(
      color: PopColors.launchRed,
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(12),
        topRight: Radius.circular(45),
        bottomLeft: Radius.circular(12),
        bottomRight: Radius.circular(12),
      ),
      boxShadow: [
        BoxShadow(color: PopColors.launchShadow, offset: Offset(7, 7)),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Cashier', style: TextStyle(color: PopColors.white)),
        const SizedBox(height: 5),
        Text(
          account.name,
          style: const TextStyle(
            color: PopColors.white,
            fontSize: 28,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 5),
        Text(account.email, style: const TextStyle(color: PopColors.white)),
      ],
    ),
  );
}

class _AdminSectionCard extends StatelessWidget {
  const _AdminSectionCard({
    required this.title,
    required this.child,
    this.trailing,
  });
  final String title;
  final Widget child;
  final String? trailing;

  @override
  Widget build(BuildContext context) => CustomerCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            if (trailing != null)
              Text(
                trailing!,
                style: TextStyle(
                  color: CustomerPalette.muted(context),
                  fontSize: 11,
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        child,
      ],
    ),
  );
}

class _AdminProviderRow extends StatelessWidget {
  const _AdminProviderRow({required this.provider, required this.connected});
  final String provider;
  final bool connected;

  @override
  Widget build(BuildContext context) {
    final label = _providerLabel(provider);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: CustomerPalette.soft(context),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              label.substring(0, 1),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                Text(
                  connected ? 'Connected' : 'Not connected',
                  style: TextStyle(
                    color: CustomerPalette.muted(context),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: connected
                  ? PopColors.success.withValues(alpha: 0.15)
                  : CustomerPalette.soft(context),
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text(
              connected ? 'On' : '—',
              style: TextStyle(
                color: connected
                    ? PopColors.success
                    : CustomerPalette.muted(context),
                fontSize: 10,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminInfoBox extends StatelessWidget {
  const _AdminInfoBox({required this.title, required this.message});
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(11),
    decoration: BoxDecoration(
      color: CustomerPalette.soft(context),
      borderRadius: BorderRadius.circular(11),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 3),
        Text(
          message,
          style: TextStyle(color: CustomerPalette.muted(context), fontSize: 11),
        ),
      ],
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
