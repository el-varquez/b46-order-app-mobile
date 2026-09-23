import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/theme/tokens.dart';
import '../../../../shared/components/pop_icons.dart';
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
        return LayoutBuilder(
          builder: (context, viewport) => SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              PopSpace.lg,
              PopSpace.xs,
              PopSpace.lg,
              PopSpace.lg,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: viewport.maxHeight - PopSpace.xs - PopSpace.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      tooltip: 'Switch theme',
                      onPressed: onToggleTheme,
                      icon: const Icon(PopIcons.theme),
                    ),
                  ),
                  SizedBox(height: viewport.maxHeight * 0.10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(PopSpace.lg),
                        decoration: BoxDecoration(
                          color: PopColors.brandRed,
                          borderRadius: BorderRadius.circular(PopRadius.lg),
                        ),
                        child: const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            B46Mark(large: true, onRedBackground: true),
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
                        icon: const Text(
                          'G',
                          style: TextStyle(fontWeight: FontWeight.w900),
                        ),
                        label: const Text('Continue with Google'),
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
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ),
  );
}

class EmailLoginScreen extends StatefulWidget {
  const EmailLoginScreen({required this.onRegister, super.key});
  final ValueChanged<String> onRegister;

  @override
  State<EmailLoginScreen> createState() => _EmailLoginScreenState();
}

class _EmailLoginScreenState extends State<EmailLoginScreen> {
  final formKey = GlobalKey<FormState>();
  final email = TextEditingController();
  final password = TextEditingController();
  bool showPassword = false;

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PopScaffold(
    appBar: AppBar(leading: const PopBackButton()),
    child: BlocBuilder<SessionCubit, SessionState>(
      builder: (context, state) => ListView(
        padding: const EdgeInsets.all(PopSpace.lg),
        children: [
          const B46Mark(),
          const SizedBox(height: PopSpace.xl),
          Text('Log in', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: PopSpace.xl),
          Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Email address'),
                const SizedBox(height: PopSpace.xs),
                TextFormField(
                  key: const Key('email-field'),
                  controller: email,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.email],
                  decoration: const InputDecoration(
                    hintText: 'Enter your email',
                  ),
                  validator: (value) => (value?.trim() ?? '').contains('@')
                      ? null
                      : 'Enter a valid email address.',
                ),
                const SizedBox(height: PopSpace.lg),
                const Text('Password'),
                const SizedBox(height: PopSpace.xs),
                TextFormField(
                  key: const Key('password-field'),
                  controller: password,
                  obscureText: !showPassword,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.password],
                  decoration: InputDecoration(
                    hintText: 'Enter your password',
                    suffixIcon: IconButton(
                      key: const Key('login-password-visibility'),
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
                  validator: (value) => (value?.isNotEmpty ?? false)
                      ? null
                      : 'Enter your password.',
                  onFieldSubmitted: (_) => _login(context),
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Password reset is not available yet.'),
                ),
              ),
              child: const Text('Forgot password?'),
            ),
          ),
          const SizedBox(height: PopSpace.lg),
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
          const SizedBox(height: PopSpace.lg),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Text("Don't have an account?"),
              TextButton(
                onPressed: () => widget.onRegister(email.text.trim()),
                child: const Text('Sign up'),
              ),
            ],
          ),
        ],
      ),
    ),
  );

  void _login(BuildContext context) {
    if (formKey.currentState?.validate() ?? false) {
      context.read<SessionCubit>().password(email.text.trim(), password.text);
    }
  }
}
