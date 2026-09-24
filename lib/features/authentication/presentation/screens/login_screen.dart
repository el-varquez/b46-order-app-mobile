import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/theme/tokens.dart';
import '../../../../shared/components/pop_icons.dart';
import '../components/auth_form.dart';
import '../../domain/entities/session.dart';
import '../cubit/session_cubit.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({required this.onEmail, super.key});

  final VoidCallback onEmail;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final foreground = dark ? PopColors.cream : PopColors.ink;
    final buttonShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
    );
    return Scaffold(
      backgroundColor: dark ? PopColors.launchBackground : PopColors.cream,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: BlocBuilder<SessionCubit, SessionState>(
              builder: (context, state) {
                final loading = state.status == SessionStatus.authenticating;
                return LayoutBuilder(
                  builder: (context, viewport) => SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 42, 16, 24),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: (viewport.maxHeight - 66).clamp(
                          0,
                          double.infinity,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const _LaunchPoster(),
                          Padding(
                            padding: const EdgeInsets.only(top: 34),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                if (state.message != null) ...[
                                  Semantics(
                                    liveRegion: true,
                                    child: Text(
                                      state.message!,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(color: foreground),
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                ],
                                FilledButton(
                                  onPressed: loading
                                      ? null
                                      : () => context
                                            .read<SessionCubit>()
                                            .oauth(OAuthProvider.google),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: PopColors.launchRed,
                                    foregroundColor: PopColors.white,
                                    minimumSize: const Size.fromHeight(50),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 17,
                                      vertical: 14,
                                    ),
                                    shape: buttonShape,
                                    textStyle: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  child: const Text(
                                    'Continue with Google',
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                OutlinedButton(
                                  onPressed: loading ? null : onEmail,
                                  style: OutlinedButton.styleFrom(
                                    backgroundColor: dark
                                        ? PopColors.launchSurface
                                        : PopColors.white,
                                    foregroundColor: foreground,
                                    minimumSize: const Size.fromHeight(50),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 17,
                                      vertical: 14,
                                    ),
                                    shape: buttonShape,
                                    side: BorderSide(
                                      color: dark
                                          ? PopColors.launchOutline
                                          : PopColors.launchLightOutline,
                                    ),
                                    textStyle: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  child: const Text(
                                    'Continue with email',
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                if (loading) ...[
                                  const SizedBox(height: 14),
                                  const Center(
                                    child: CircularProgressIndicator(
                                      color: PopColors.launchRed,
                                      semanticsLabel: 'Signing in',
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 24),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _LaunchPoster extends StatelessWidget {
  const _LaunchPoster();

  @override
  Widget build(BuildContext context) {
    const shape = BorderRadius.only(
      topLeft: Radius.circular(12),
      topRight: Radius.circular(70),
      bottomLeft: Radius.circular(12),
      bottomRight: Radius.circular(12),
    );
    return DecoratedBox(
      decoration: const BoxDecoration(
        borderRadius: shape,
        boxShadow: [
          BoxShadow(color: PopColors.launchShadow, offset: Offset(10, 10)),
        ],
      ),
      child: ClipRRect(
        borderRadius: shape,
        child: ColoredBox(
          color: PopColors.launchRed,
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(26),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AuthWordmark(onRedBackground: true),
                    const SizedBox(height: 24),
                    const FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'BIG\nCRAVINGS.\nSMALL TRIP.',
                        textScaler: TextScaler.noScaling,
                        style: TextStyle(
                          color: PopColors.white,
                          fontSize: 56,
                          height: 0.92,
                          letterSpacing: -3.08,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 240),
                      child: const Text(
                        'Neighborhood essentials delivered inside Bria subdivision.',
                        style: TextStyle(
                          color: PopColors.white,
                          fontSize: 16,
                          height: 1.32,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                right: -52,
                bottom: -70,
                child: IgnorePointer(
                  child: Container(
                    width: 288,
                    height: 288,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: PopColors.white.withValues(alpha: 0.2),
                        width: 34,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
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
  Widget build(BuildContext context) => AuthFormScaffold(
    title: 'Log in',
    child: BlocBuilder<SessionCubit, SessionState>(
      builder: (context, state) => ListView(
        padding: const EdgeInsets.fromLTRB(16, 36, 16, 24),
        children: [
          const AuthWordmark(),
          const SizedBox(height: 10),
          Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const AuthFieldLabel('Email address'),
                const SizedBox(height: 6),
                TextFormField(
                  key: const Key('email-field'),
                  controller: email,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.email],
                  decoration: const InputDecoration(hintText: 'you@gmail.com'),
                  validator: (value) => (value?.trim() ?? '').contains('@')
                      ? null
                      : 'Enter a valid email address.',
                ),
                const SizedBox(height: PopSpace.lg),
                const AuthFieldLabel('Password'),
                const SizedBox(height: 6),
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
          const SizedBox(height: 10),
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
            AuthMessage(state.message!),
          ],
          const SizedBox(height: 10),
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
