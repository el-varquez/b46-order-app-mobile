import 'dart:async';

import 'package:b46_order_app_mobile/core/errors/app_failure.dart';
import 'package:b46_order_app_mobile/features/authentication/application/use_cases/registration_use_cases.dart';
import 'package:b46_order_app_mobile/features/authentication/domain/entities/session.dart';
import 'package:b46_order_app_mobile/features/authentication/domain/repositories/registration_repository.dart';
import 'package:b46_order_app_mobile/features/authentication/presentation/cubit/registration_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'verification hands the normal session to shared authentication',
    () async {
      final repository = _RegistrationRepository();
      Session? authenticated;
      final cubit = RegistrationCubit(
        begin: BeginRegistration(repository),
        resend: ResendRegistration(repository),
        verify: VerifyRegistration(repository),
        onVerified: (session) => authenticated = session,
      );
      addTearDown(cubit.close);

      expect(
        await cubit.begin(' Customer ', ' NEW@Example.com ', 'password-1234'),
        isTrue,
      );
      expect(repository.name, 'Customer');
      expect(repository.email, 'NEW@Example.com');
      expect(cubit.state.status, RegistrationStatus.awaitingCode);
      expect(cubit.state.registrationId, 'attempt-1');
      expect(authenticated, isNull);

      expect(await cubit.verify('123456'), isTrue);
      expect(repository.verifiedCode, '123456');
      expect(cubit.state.status, RegistrationStatus.complete);
      expect(authenticated?.user.role, UserRole.customer);
      expect(authenticated?.accessToken, 'access');
    },
  );

  test('duplicate begin taps only submit one registration attempt', () async {
    final repository = _RegistrationRepository();
    final pending = Completer<RegistrationAttempt>();
    repository.pending = pending;
    final cubit = RegistrationCubit(
      begin: BeginRegistration(repository),
      resend: ResendRegistration(repository),
      verify: VerifyRegistration(repository),
      onVerified: (_) {},
    );
    addTearDown(cubit.close);

    final first = cubit.begin('A', 'a@example.com', 'password-1234');
    expect(await cubit.begin('A', 'a@example.com', 'password-1234'), isFalse);
    expect(repository.beginCount, 1);
    pending.complete(
      RegistrationAttempt(id: 'attempt-1', expiresAt: DateTime.utc(2030)),
    );
    expect(await first, isTrue);
  });

  test('registration failure includes the server request reference', () async {
    final repository = _RegistrationRepository()
      ..failure = const AppFailure(
        FailureCode.invalidRequest,
        'Enter a valid email address.',
        requestId: 'request-123',
      );
    final cubit = RegistrationCubit(
      begin: BeginRegistration(repository),
      resend: ResendRegistration(repository),
      verify: VerifyRegistration(repository),
      onVerified: (_) {},
    );
    addTearDown(cubit.close);

    expect(await cubit.begin('Customer', 'bad@localhost', 'abcdefgh'), isFalse);
    expect(
      cubit.state.message,
      'Enter a valid email address.\nReference: request-123',
    );
  });
}

final class _RegistrationRepository implements RegistrationRepository {
  String? name;
  String? email;
  String? verifiedCode;
  int beginCount = 0;
  Completer<RegistrationAttempt>? pending;
  AppFailure? failure;

  @override
  Future<RegistrationAttempt> beginRegistration(
    String name,
    String email,
    String password,
  ) {
    beginCount++;
    this.name = name;
    this.email = email;
    if (failure != null) return Future.error(failure!);
    return pending?.future ??
        Future.value(
          RegistrationAttempt(id: 'attempt-1', expiresAt: DateTime.utc(2030)),
        );
  }

  @override
  Future<RegistrationAttempt> resendRegistration(String registrationId) async =>
      RegistrationAttempt(id: registrationId, expiresAt: DateTime.utc(2030));

  @override
  Future<Session> verifyRegistration(String registrationId, String code) async {
    verifiedCode = code;
    return Session(
      accessToken: 'access',
      accessTokenExpiresAt: DateTime.utc(2030),
      refreshToken: 'refresh',
      refreshTokenExpiresAt: DateTime.utc(2031),
      user: const AppUser(
        id: 'customer-1',
        name: 'Customer',
        email: 'new@example.com',
        role: UserRole.customer,
        active: true,
      ),
    );
  }
}
