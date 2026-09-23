import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/theme/tokens.dart';
import '../../../../shared/components/pop_scaffold.dart';
import '../../domain/entities/session.dart';
import '../cubit/session_cubit.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({
    required this.onEmail,
    required this.onToggleTheme,
    super.key,
  });

  final VoidCallback onEmail;
  final VoidCallback onToggleTheme;

  @override
  Widget build(BuildContext context) => PopScaffold(
    child: BlocBuilder<SessionCubit, SessionState>(
      builder: (context, state) {
        final loading = state.status == SessionStatus.authenticating;
        return ListView(
          padding: const EdgeInsets.all(PopSpace.lg),
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                tooltip: 'Switch theme',
                onPressed: onToggleTheme,
                icon: const Icon(Icons.brightness_6_outlined),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(PopSpace.lg),
              decoration: BoxDecoration(
                color: PopColors.brandRed,
                borderRadius: BorderRadius.circular(PopRadius.lg),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  B46Mark(large: true),
                  SizedBox(height: PopSpace.xl),
                  Text(
                    'BIG CRAVINGS.\nSMALL TRIP.',
                    style: TextStyle(
                      color: PopColors.white,
                      fontSize: 34,
                      height: 0.98,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: PopSpace.sm),
                  Text(
                    'Neighborhood essentials delivered inside Bria.',
                    style: TextStyle(
                      color: PopColors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: PopSpace.xl),
            if (state.message != null) ...[
              Text(state.message!, textAlign: TextAlign.center),
              const SizedBox(height: PopSpace.md),
            ],
            FilledButton.icon(
              onPressed: loading
                  ? null
                  : () => context.read<SessionCubit>().oauth(
                      OAuthProvider.google,
                    ),
              icon: const Icon(Icons.g_mobiledata),
              label: const Text('Continue with Google'),
            ),
            const SizedBox(height: PopSpace.sm),
            OutlinedButton.icon(
              onPressed: loading
                  ? null
                  : () =>
                        context.read<SessionCubit>().oauth(OAuthProvider.apple),
              icon: const Icon(Icons.apple),
              label: const Text('Continue with Apple'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
            ),
            const SizedBox(height: PopSpace.sm),
            TextButton(
              onPressed: loading ? null : onEmail,
              child: const Text('Continue with email'),
            ),
            if (loading) ...[
              const SizedBox(height: PopSpace.md),
              const Center(child: CircularProgressIndicator()),
            ],
          ],
        );
      },
    ),
  );
}

class EmailScreen extends StatefulWidget {
  const EmailScreen({required this.onContinue, super.key});
  final ValueChanged<String> onContinue;

  @override
  State<EmailScreen> createState() => _EmailScreenState();
}

class _EmailScreenState extends State<EmailScreen> {
  final controller = TextEditingController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PopScaffold(
    appBar: AppBar(title: const Text('Your email')),
    child: Padding(
      padding: const EdgeInsets.all(PopSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const B46Mark(),
          const SizedBox(height: PopSpace.xl),
          TextField(
            key: const Key('email-field'),
            controller: controller,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(labelText: 'Email address'),
            onSubmitted: _continue,
          ),
          const SizedBox(height: PopSpace.md),
          FilledButton(
            onPressed: () => _continue(controller.text),
            child: const Text('Continue'),
          ),
        ],
      ),
    ),
  );

  void _continue(String value) {
    final email = value.trim();
    if (email.contains('@')) widget.onContinue(email);
  }
}

class PasswordScreen extends StatefulWidget {
  const PasswordScreen({required this.email, super.key});
  final String email;

  @override
  State<PasswordScreen> createState() => _PasswordScreenState();
}

class _PasswordScreenState extends State<PasswordScreen> {
  final controller = TextEditingController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PopScaffold(
    appBar: AppBar(title: const Text('Enter password')),
    child: BlocBuilder<SessionCubit, SessionState>(
      builder: (context, state) => Padding(
        padding: const EdgeInsets.all(PopSpace.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const B46Mark(),
            const SizedBox(height: PopSpace.lg),
            Text(widget.email, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: PopSpace.md),
            TextField(
              key: const Key('password-field'),
              controller: controller,
              obscureText: true,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(labelText: 'Password'),
              onSubmitted: (_) => _login(context),
            ),
            const SizedBox(height: PopSpace.md),
            FilledButton(
              onPressed: state.status == SessionStatus.authenticating
                  ? null
                  : () => _login(context),
              child: const Text('Log in'),
            ),
            if (state.status == SessionStatus.authenticating) ...[
              const SizedBox(height: PopSpace.md),
              const Center(child: CircularProgressIndicator()),
            ],
            if (state.message != null) ...[
              const SizedBox(height: PopSpace.md),
              Text(state.message!, textAlign: TextAlign.center),
            ],
          ],
        ),
      ),
    ),
  );

  void _login(BuildContext context) {
    if (controller.text.isNotEmpty) {
      context.read<SessionCubit>().password(widget.email, controller.text);
    }
  }
}
