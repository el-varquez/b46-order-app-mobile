import '../entities/session.dart';

final class RegistrationAttempt {
  const RegistrationAttempt({required this.id, required this.expiresAt});
  final String id;
  final DateTime expiresAt;
}

abstract interface class RegistrationRepository {
  Future<RegistrationAttempt> beginRegistration(
    String name,
    String email,
    String password,
  );
  Future<RegistrationAttempt> resendRegistration(String registrationId);
  Future<Session> verifyRegistration(String registrationId, String code);
}
