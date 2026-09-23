import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/app_failure.dart';
import '../../application/use_cases/registration_use_cases.dart';
import '../../domain/entities/session.dart';

enum RegistrationStatus {
  idle,
  requesting,
  awaitingCode,
  verifying,
  resending,
  complete,
}

final class RegistrationState extends Equatable {
  const RegistrationState({
    this.status = RegistrationStatus.idle,
    this.email = '',
    this.registrationId,
    this.expiresAt,
    this.resendAvailableAt,
    this.message,
  });

  final RegistrationStatus status;
  final String email;
  final String? registrationId;
  final DateTime? expiresAt;
  final DateTime? resendAvailableAt;
  final String? message;

  bool get busy =>
      status == RegistrationStatus.requesting ||
      status == RegistrationStatus.verifying ||
      status == RegistrationStatus.resending;

  RegistrationState copyWith({
    RegistrationStatus? status,
    String? email,
    String? registrationId,
    DateTime? expiresAt,
    DateTime? resendAvailableAt,
    String? message,
    bool clearMessage = false,
  }) => RegistrationState(
    status: status ?? this.status,
    email: email ?? this.email,
    registrationId: registrationId ?? this.registrationId,
    expiresAt: expiresAt ?? this.expiresAt,
    resendAvailableAt: resendAvailableAt ?? this.resendAvailableAt,
    message: clearMessage ? null : message ?? this.message,
  );

  @override
  List<Object?> get props => [
    status,
    email,
    registrationId,
    expiresAt,
    resendAvailableAt,
    message,
  ];
}

final class RegistrationCubit extends Cubit<RegistrationState> {
  RegistrationCubit({
    required BeginRegistration begin,
    required ResendRegistration resend,
    required VerifyRegistration verify,
    required void Function(Session) onVerified,
  }) : _begin = begin,
       _resend = resend,
       _verify = verify,
       _onVerified = onVerified,
       super(const RegistrationState());

  final BeginRegistration _begin;
  final ResendRegistration _resend;
  final VerifyRegistration _verify;
  final void Function(Session) _onVerified;

  void prefillEmail(String email) {
    if (state.busy) return;
    emit(RegistrationState(email: email.trim()));
  }

  Future<bool> begin(String name, String email, String password) async {
    if (state.busy) return false;
    emit(
      RegistrationState(
        status: RegistrationStatus.requesting,
        email: email.trim(),
      ),
    );
    try {
      final result = await _begin(name.trim(), email.trim(), password);
      emit(
        RegistrationState(
          status: RegistrationStatus.awaitingCode,
          email: email.trim(),
          registrationId: result.id,
          expiresAt: result.expiresAt,
          resendAvailableAt: DateTime.now().add(const Duration(minutes: 1)),
        ),
      );
      return true;
    } on AppFailure catch (failure) {
      emit(
        RegistrationState(email: email.trim(), message: _errorMessage(failure)),
      );
      return false;
    } on Object {
      emit(
        RegistrationState(
          email: email.trim(),
          message: 'Registration could not start. Please try again.',
        ),
      );
      return false;
    }
  }

  Future<bool> resend() async {
    final id = state.registrationId;
    if (state.busy || id == null) return false;
    emit(
      state.copyWith(status: RegistrationStatus.resending, clearMessage: true),
    );
    try {
      final result = await _resend(id);
      emit(
        state.copyWith(
          status: RegistrationStatus.awaitingCode,
          registrationId: result.id,
          expiresAt: result.expiresAt,
          resendAvailableAt: DateTime.now().add(const Duration(minutes: 1)),
          clearMessage: true,
        ),
      );
      return true;
    } on AppFailure catch (failure) {
      emit(
        state.copyWith(
          status: RegistrationStatus.awaitingCode,
          message: _errorMessage(failure),
        ),
      );
      return false;
    } on Object {
      emit(
        state.copyWith(
          status: RegistrationStatus.awaitingCode,
          message: 'Could not resend the code. Please try again.',
        ),
      );
      return false;
    }
  }

  Future<bool> verify(String code) async {
    final id = state.registrationId;
    if (state.busy || id == null) return false;
    emit(
      state.copyWith(status: RegistrationStatus.verifying, clearMessage: true),
    );
    try {
      final session = await _verify(id, code);
      emit(
        state.copyWith(status: RegistrationStatus.complete, clearMessage: true),
      );
      _onVerified(session);
      return true;
    } on AppFailure catch (failure) {
      emit(
        state.copyWith(
          status: RegistrationStatus.awaitingCode,
          message: _errorMessage(failure),
        ),
      );
      return false;
    } on Object {
      emit(
        state.copyWith(
          status: RegistrationStatus.awaitingCode,
          message: 'Verification failed. Please try again.',
        ),
      );
      return false;
    }
  }
}

String _errorMessage(AppFailure failure) {
  final requestId = failure.requestId?.trim();
  if (requestId == null || requestId.isEmpty) return failure.message;
  return '${failure.message}\nReference: $requestId';
}
