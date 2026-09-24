import 'package:b46_order_app_mobile/app/theme/app_theme.dart';
import 'package:b46_order_app_mobile/features/authentication/application/use_cases/session_use_cases.dart';
import 'package:b46_order_app_mobile/features/authentication/domain/entities/session.dart';
import 'package:b46_order_app_mobile/features/authentication/domain/repositories/session_repository.dart';
import 'package:b46_order_app_mobile/features/authentication/presentation/cubit/session_cubit.dart';
import 'package:b46_order_app_mobile/features/authentication/presentation/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final width in [320.0, 360.0, 375.0, 390.0, 430.0]) {
    testWidgets('login fits $width logical pixels in light and dark', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(Size(width, 760));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final repository = _SessionRepository();
      final cubit = SessionCubit(
        restoreSession: RestoreSession(repository),
        passwordLogin: PasswordLogin(repository),
        oauthLogin: OAuthLogin(repository),
        signOut: SignOut(repository),
      );
      for (final theme in [AppTheme.light, AppTheme.dark]) {
        await tester.pumpWidget(
          BlocProvider.value(
            value: cubit,
            child: MaterialApp(
              theme: theme,
              home: LoginScreen(onEmail: () {}, onToggleTheme: () {}),
            ),
          ),
        );
        await tester.pump();
        expect(find.text('Continue with Google'), findsOneWidget);
        expect(find.text('Continue with email'), findsOneWidget);
        expect(find.text('Continue with Apple'), findsNothing);
        expect(tester.takeException(), isNull);
      }
      await cubit.close();
    });
  }
}

final class _SessionRepository implements SessionRepository {
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
