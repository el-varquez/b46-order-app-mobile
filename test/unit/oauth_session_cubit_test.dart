import 'package:b46_order_app_mobile/core/errors/app_failure.dart';
import 'package:b46_order_app_mobile/features/authentication/application/use_cases/session_use_cases.dart';
import 'package:b46_order_app_mobile/features/authentication/domain/entities/session.dart';
import 'package:b46_order_app_mobile/features/authentication/domain/repositories/session_repository.dart';
import 'package:b46_order_app_mobile/features/authentication/presentation/cubit/session_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('canceling a provider prompt returns quietly to shared login', () async {
    final repository = _CancelingRepository();
    final cubit = SessionCubit(
      restoreSession: RestoreSession(repository),
      passwordLogin: PasswordLogin(repository),
      oauthLogin: OAuthLogin(repository),
      signOut: SignOut(repository),
    );
    addTearDown(cubit.close);

    await cubit.oauth(OAuthProvider.google);

    expect(cubit.state.status, SessionStatus.signedOut);
    expect(cubit.state.message, isNull);
  });
}

final class _CancelingRepository implements SessionRepository {
  @override
  Future<Session> changePassword(String currentPassword, String newPassword) =>
      throw UnimplementedError();
  @override
  Session? get current => null;
  @override
  Future<Session> loginWithOAuth(OAuthProvider provider) =>
      throw const AppFailure(FailureCode.cancelled, '');
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
