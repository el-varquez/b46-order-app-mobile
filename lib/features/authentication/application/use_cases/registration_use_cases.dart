import '../../domain/entities/session.dart';
import '../../domain/repositories/registration_repository.dart';

final class BeginRegistration {
  const BeginRegistration(this.repository);
  final RegistrationRepository repository;
  Future<RegistrationAttempt> call(
    String name,
    String email,
    String password,
  ) => repository.beginRegistration(name, email, password);
}

final class ResendRegistration {
  const ResendRegistration(this.repository);
  final RegistrationRepository repository;
  Future<RegistrationAttempt> call(String id) =>
      repository.resendRegistration(id);
}

final class VerifyRegistration {
  const VerifyRegistration(this.repository);
  final RegistrationRepository repository;
  Future<Session> call(String id, String code) =>
      repository.verifyRegistration(id, code);
}
