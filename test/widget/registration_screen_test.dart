import 'package:b46_order_app_mobile/app/theme/app_theme.dart';
import 'package:b46_order_app_mobile/features/authentication/application/use_cases/registration_use_cases.dart';
import 'package:b46_order_app_mobile/features/authentication/application/use_cases/session_use_cases.dart';
import 'package:b46_order_app_mobile/features/authentication/domain/entities/session.dart';
import 'package:b46_order_app_mobile/features/authentication/domain/repositories/registration_repository.dart';
import 'package:b46_order_app_mobile/features/authentication/domain/repositories/session_repository.dart';
import 'package:b46_order_app_mobile/features/authentication/presentation/cubit/registration_cubit.dart';
import 'package:b46_order_app_mobile/features/authentication/presentation/cubit/session_cubit.dart';
import 'package:b46_order_app_mobile/features/authentication/presentation/screens/login_screen.dart';
import 'package:b46_order_app_mobile/features/authentication/presentation/screens/registration_screens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('email login accepts both fields and offers registration', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 650));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repository = _SessionRepository();
    final cubit = SessionCubit(
      restoreSession: RestoreSession(repository),
      passwordLogin: PasswordLogin(repository),
      oauthLogin: OAuthLogin(repository),
      signOut: SignOut(repository),
    );
    addTearDown(cubit.close);
    String? registered;
    await tester.pumpWidget(
      BlocProvider.value(
        value: cubit,
        child: MaterialApp(
          home: EmailLoginScreen(onRegister: (value) => registered = value),
        ),
      ),
    );
    await tester.enterText(
      find.byKey(const Key('email-field')),
      ' person@example.com ',
    );
    await tester.enterText(find.byKey(const Key('password-field')), 'password');
    final passwordField = find.descendant(
      of: find.byKey(const Key('password-field')),
      matching: find.byType(TextField),
    );
    expect(tester.widget<TextField>(passwordField).obscureText, isTrue);
    await tester.tap(find.byKey(const Key('login-password-visibility')));
    await tester.pump();
    expect(tester.widget<TextField>(passwordField).obscureText, isFalse);
    await tester.ensureVisible(find.widgetWithText(FilledButton, 'Log in'));
    await tester.tap(find.widgetWithText(FilledButton, 'Log in'));
    await tester.pump();
    expect(repository.lastEmail, 'person@example.com');
    expect(repository.lastPassword, 'password');
    await tester.ensureVisible(find.text('Sign up'));
    await tester.tap(find.text('Sign up'));
    expect(registered, 'person@example.com');
    expect(tester.takeException(), isNull);
  });

  for (final width in [320.0, 360.0, 390.0, 430.0]) {
    testWidgets('registration form fits $width and validates confirmation', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(Size(width, 760));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final repository = _RegistrationRepository();
      final cubit = RegistrationCubit(
        begin: BeginRegistration(repository),
        resend: ResendRegistration(repository),
        verify: VerifyRegistration(repository),
        onVerified: (_) {},
      );
      addTearDown(cubit.close);
      for (final theme in [AppTheme.light, AppTheme.dark]) {
        await tester.pumpWidget(
          BlocProvider.value(
            value: cubit,
            child: MaterialApp(
              theme: theme,
              home: RegistrationScreen(onStarted: () {}),
            ),
          ),
        );
        await tester.tap(find.byKey(const Key('register-submit')));
        await tester.pump();
        expect(
          find.text('Enter your name (up to 120 characters).'),
          findsOneWidget,
        );
        expect(repository.beginCount, 0);
        expect(tester.takeException(), isNull);
      }
    });
  }

  testWidgets('registration password visibility toggles independently', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(360, 760));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repository = _RegistrationRepository();
    final cubit = RegistrationCubit(
      begin: BeginRegistration(repository),
      resend: ResendRegistration(repository),
      verify: VerifyRegistration(repository),
      onVerified: (_) {},
    );
    addTearDown(cubit.close);
    await tester.pumpWidget(
      BlocProvider.value(
        value: cubit,
        child: MaterialApp(home: RegistrationScreen(onStarted: () {})),
      ),
    );

    final password = find.byKey(const Key('register-password'));
    final confirmation = find.byKey(const Key('register-confirm-password'));
    bool isObscured(Finder field) => tester
        .widget<TextField>(
          find.descendant(of: field, matching: find.byType(TextField)),
        )
        .obscureText;
    expect(isObscured(password), isTrue);
    expect(isObscured(confirmation), isTrue);

    await tester.tap(find.byKey(const Key('register-password-visibility')));
    await tester.pump();
    expect(isObscured(password), isFalse);
    expect(isObscured(confirmation), isTrue);

    await tester.tap(
      find.byKey(const Key('register-confirm-password-visibility')),
    );
    await tester.pump();
    expect(isObscured(password), isFalse);
    expect(isObscured(confirmation), isFalse);
  });

  testWidgets('registration accepts eight letters without other requirements', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(360, 760));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repository = _RegistrationRepository();
    final cubit = RegistrationCubit(
      begin: BeginRegistration(repository),
      resend: ResendRegistration(repository),
      verify: VerifyRegistration(repository),
      onVerified: (_) {},
    );
    addTearDown(cubit.close);
    await tester.pumpWidget(
      BlocProvider.value(
        value: cubit,
        child: MaterialApp(home: RegistrationScreen(onStarted: () {})),
      ),
    );

    await tester.enterText(find.byKey(const Key('register-name')), 'Customer');
    await tester.enterText(
      find.byKey(const Key('register-email')),
      'customer@example.com',
    );
    await tester.enterText(
      find.byKey(const Key('register-password')),
      'abcdefg',
    );
    await tester.enterText(
      find.byKey(const Key('register-confirm-password')),
      'abcdefg',
    );
    await tester.tap(find.byKey(const Key('register-submit')));
    await tester.pump();
    expect(find.text('Use at least 8 characters.'), findsOneWidget);
    expect(repository.beginCount, 0);

    await tester.enterText(
      find.byKey(const Key('register-password')),
      'abcdefgh',
    );
    await tester.enterText(
      find.byKey(const Key('register-confirm-password')),
      'abcdefgh',
    );
    await tester.tap(find.byKey(const Key('register-submit')));
    await tester.pump();
    expect(repository.beginCount, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('registration rejects an email without a domain dot locally', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(360, 760));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repository = _RegistrationRepository();
    final cubit = RegistrationCubit(
      begin: BeginRegistration(repository),
      resend: ResendRegistration(repository),
      verify: VerifyRegistration(repository),
      onVerified: (_) {},
    );
    addTearDown(cubit.close);
    await tester.pumpWidget(
      BlocProvider.value(
        value: cubit,
        child: MaterialApp(home: RegistrationScreen(onStarted: () {})),
      ),
    );

    await tester.enterText(find.byKey(const Key('register-name')), 'Customer');
    await tester.enterText(
      find.byKey(const Key('register-email')),
      'customer@localhost',
    );
    await tester.enterText(
      find.byKey(const Key('register-password')),
      'abcdefgh',
    );
    await tester.enterText(
      find.byKey(const Key('register-confirm-password')),
      'abcdefgh',
    );
    await tester.ensureVisible(find.byKey(const Key('register-submit')));
    await tester.tap(find.byKey(const Key('register-submit')));
    await tester.pump();
    expect(find.text('Enter a valid email address.'), findsOneWidget);
    expect(repository.beginCount, 0);
  });
}

final class _SessionRepository implements SessionRepository {
  @override
  Future<Session> changePassword(String currentPassword, String newPassword) =>
      throw UnimplementedError();
  String? lastEmail;
  String? lastPassword;

  @override
  Session? get current => null;

  @override
  Future<Session> loginWithPassword(String email, String password) async {
    lastEmail = email;
    lastPassword = password;
    return Session(
      accessToken: 'access',
      accessTokenExpiresAt: DateTime.utc(2030),
      refreshToken: 'refresh',
      refreshTokenExpiresAt: DateTime.utc(2030),
      user: const AppUser(
        id: 'customer-1',
        name: 'Customer',
        email: 'person@example.com',
        role: UserRole.customer,
        active: true,
      ),
    );
  }

  @override
  Future<Session> loginWithOAuth(OAuthProvider provider) =>
      throw UnimplementedError();

  @override
  Future<Session?> restore() async => null;

  @override
  Future<bool> refresh() async => false;

  @override
  Future<void> logout() async {}
}

final class _RegistrationRepository implements RegistrationRepository {
  int beginCount = 0;

  @override
  Future<RegistrationAttempt> beginRegistration(
    String name,
    String email,
    String password,
  ) async {
    beginCount++;
    return RegistrationAttempt(id: 'attempt-1', expiresAt: DateTime.utc(2030));
  }

  @override
  Future<RegistrationAttempt> resendRegistration(String registrationId) async =>
      RegistrationAttempt(id: registrationId, expiresAt: DateTime.utc(2030));

  @override
  Future<Session> verifyRegistration(String registrationId, String code) =>
      throw UnimplementedError();
}
