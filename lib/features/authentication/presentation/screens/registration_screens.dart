import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/theme/tokens.dart';
import '../../../../shared/components/pop_icons.dart';
import '../components/auth_form.dart';
import '../cubit/registration_cubit.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({required this.onStarted, super.key});
  final VoidCallback onStarted;

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final formKey = GlobalKey<FormState>();
  final name = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();
  final confirmPassword = TextEditingController();
  bool showPassword = false;
  bool showConfirmPassword = false;

  @override
  void initState() {
    super.initState();
    email.text = context.read<RegistrationCubit>().state.email;
  }

  @override
  void dispose() {
    name.dispose();
    email.dispose();
    password.dispose();
    confirmPassword.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AuthFormScaffold(
    title: 'Create an account',
    child: BlocBuilder<RegistrationCubit, RegistrationState>(
      builder: (context, state) => ListView(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
        children: [
          const AuthWordmark(),
          const SizedBox(height: PopSpace.lg),
          Text(
            'Join your neighborhood store',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: PopSpace.sm),
          const Text('Create a customer account to order from B46.'),
          const SizedBox(height: PopSpace.lg),
          Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const AuthFieldLabel('Name'),
                const SizedBox(height: 6),
                TextFormField(
                  key: const Key('register-name'),
                  controller: name,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.name],
                  decoration: const InputDecoration(hintText: 'Your full name'),
                  validator: (value) =>
                      value == null ||
                          value.trim().isEmpty ||
                          value.trim().runes.length > 120
                      ? 'Enter your name (up to 120 characters).'
                      : null,
                ),
                const SizedBox(height: 23),
                const AuthFieldLabel('Email address'),
                const SizedBox(height: 6),
                TextFormField(
                  key: const Key('register-email'),
                  controller: email,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.email],
                  decoration: const InputDecoration(hintText: 'you@gmail.com'),
                  validator: (value) {
                    final entered = value?.trim() ?? '';
                    final parts = entered.split('@');
                    return parts.length == 2 &&
                            parts[0].isNotEmpty &&
                            parts[1].contains('.') &&
                            entered.runes.length <= 254
                        ? null
                        : 'Enter a valid email address.';
                  },
                ),
                const SizedBox(height: 23),
                const AuthFieldLabel('Password'),
                const SizedBox(height: 6),
                TextFormField(
                  key: const Key('register-password'),
                  controller: password,
                  obscureText: !showPassword,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.newPassword],
                  decoration: InputDecoration(
                    hintText: 'Create a password',
                    helperText: 'At least 8 characters.',
                    suffixIcon: IconButton(
                      key: const Key('register-password-visibility'),
                      tooltip: showPassword ? 'Hide password' : 'Show password',
                      icon: Icon(
                        showPassword
                            ? PopIcons.hidePassword
                            : PopIcons.showPassword,
                      ),
                      onPressed: () =>
                          setState(() => showPassword = !showPassword),
                    ),
                  ),
                  validator: (value) {
                    final length = value?.runes.length ?? 0;
                    if (length < 8) return 'Use at least 8 characters.';
                    if (length > 128) return 'Use 128 characters or fewer.';
                    return null;
                  },
                ),
                const SizedBox(height: 23),
                const AuthFieldLabel('Confirm password'),
                const SizedBox(height: 6),
                TextFormField(
                  key: const Key('register-confirm-password'),
                  controller: confirmPassword,
                  obscureText: !showConfirmPassword,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.newPassword],
                  decoration: InputDecoration(
                    hintText: 'Re-enter your password',
                    suffixIcon: IconButton(
                      key: const Key('register-confirm-password-visibility'),
                      tooltip: showConfirmPassword
                          ? 'Hide confirmation password'
                          : 'Show confirmation password',
                      icon: Icon(
                        showConfirmPassword
                            ? PopIcons.hidePassword
                            : PopIcons.showPassword,
                      ),
                      onPressed: () => setState(
                        () => showConfirmPassword = !showConfirmPassword,
                      ),
                    ),
                  ),
                  validator: (value) =>
                      value != password.text ? 'Passwords do not match.' : null,
                  onFieldSubmitted: (_) => _submit(context),
                ),
              ],
            ),
          ),
          if (state.message != null) ...[
            const SizedBox(height: PopSpace.md),
            AuthMessage(state.message!),
          ],
          const SizedBox(height: PopSpace.lg),
          FilledButton(
            key: const Key('register-submit'),
            onPressed: state.busy ? null : () => _submit(context),
            child: const Text('Create account'),
          ),
          if (state.busy) ...[
            const SizedBox(height: PopSpace.md),
            const Center(child: CircularProgressIndicator()),
          ],
        ],
      ),
    ),
  );

  Future<void> _submit(BuildContext context) async {
    if (formKey.currentState?.validate() != true) return;
    final started = await context.read<RegistrationCubit>().begin(
      name.text,
      email.text,
      password.text,
    );
    if (started && mounted) widget.onStarted();
  }
}

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({required this.onChangeEmail, super.key});
  final VoidCallback onChangeEmail;

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  final code = TextEditingController();
  Timer? clock;

  @override
  void initState() {
    super.initState();
    clock = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    clock?.cancel();
    code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AuthFormScaffold(
    title: 'Verify your email',
    child: BlocBuilder<RegistrationCubit, RegistrationState>(
      builder: (context, state) {
        final seconds =
            state.resendAvailableAt?.difference(DateTime.now()).inSeconds ?? 0;
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 36, 16, 24),
          children: [
            const AuthWordmark(),
            const SizedBox(height: PopSpace.lg),
            Text(
              'Check your inbox',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: PopSpace.sm),
            Text(
              'If this address can be registered, we sent a six-digit code to ${state.email}.',
            ),
            const SizedBox(height: PopSpace.lg),
            const AuthFieldLabel('Verification code'),
            const SizedBox(height: 6),
            TextField(
              key: const Key('verification-code'),
              controller: code,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              maxLength: 6,
              autofillHints: const [AutofillHints.oneTimeCode],
              decoration: const InputDecoration(hintText: 'Six-digit code'),
              onSubmitted: (_) => _verify(context),
            ),
            const SizedBox(height: PopSpace.md),
            FilledButton(
              key: const Key('verify-submit'),
              onPressed: state.busy ? null : () => _verify(context),
              child: const Text('Verify email'),
            ),
            const SizedBox(height: PopSpace.sm),
            TextButton(
              onPressed: state.busy || seconds > 0
                  ? null
                  : () => context.read<RegistrationCubit>().resend(),
              child: Text(
                seconds > 0 ? 'Resend code in ${seconds + 1}s' : 'Resend code',
              ),
            ),
            TextButton(
              onPressed: state.busy ? null : widget.onChangeEmail,
              child: const Text('Change email'),
            ),
            if (state.message != null) ...[
              const SizedBox(height: PopSpace.md),
              AuthMessage(state.message!),
            ],
            if (state.busy) ...[
              const SizedBox(height: PopSpace.md),
              const Center(child: CircularProgressIndicator()),
            ],
          ],
        );
      },
    ),
  );

  void _verify(BuildContext context) {
    final entered = code.text.trim();
    if (RegExp(r'^[0-9]{6}$').hasMatch(entered)) {
      context.read<RegistrationCubit>().verify(entered);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter the six-digit code.')),
      );
    }
  }
}
