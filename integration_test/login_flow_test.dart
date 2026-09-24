import 'package:b46_order_app_mobile/app/theme/app_theme.dart';
import 'package:b46_order_app_mobile/features/authentication/application/use_cases/session_use_cases.dart';
import 'package:b46_order_app_mobile/features/authentication/domain/entities/session.dart';
import 'package:b46_order_app_mobile/features/authentication/domain/repositories/session_repository.dart';
import 'package:b46_order_app_mobile/features/authentication/presentation/cubit/session_cubit.dart';
import 'package:b46_order_app_mobile/features/authentication/presentation/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('email choice opens through the shared login screen', (
    tester,
  ) async {
    var selected = false;
    final repository = _FakeSessionRepository();
    await tester.pumpWidget(
      BlocProvider(
        create: (_) => SessionCubit(
          restoreSession: RestoreSession(repository),
          passwordLogin: PasswordLogin(repository),
          oauthLogin: OAuthLogin(repository),
          signOut: SignOut(repository),
        ),
        child: MaterialApp(
          theme: AppTheme.light,
          home: LoginScreen(onEmail: () => selected = true),
        ),
      ),
    );
    await tester.tap(find.text('Continue with email'));
    expect(selected, isTrue);
  });
}

final class _FakeSessionRepository implements SessionRepository {
  @override
  Future<Session> changePassword(String currentPassword, String newPassword) =>
      throw UnimplementedError();
  @override
  Session? get current => null;
  @override
  Future<Session> loginWithOAuth(OAuthProvider provider) =>
      throw UnimplementedError();
  @override
  Future<Session> loginWithPassword(String email, String password) =>
      throw UnimplementedError();
  @override
  Future<void> logout() async {}
  @override
  Future<bool> refresh() async => false;
  @override
  Future<Session?> restore() async => null;
}
