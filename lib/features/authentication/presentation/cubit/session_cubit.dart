import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/app_failure.dart';
import '../../application/use_cases/session_use_cases.dart';
import '../../domain/entities/session.dart';

enum SessionStatus { restoring, signedOut, authenticating, authenticated }

final class SessionState extends Equatable {
  const SessionState({required this.status, this.session, this.message});

  const SessionState.restoring() : this(status: SessionStatus.restoring);
  const SessionState.signedOut({String? message})
    : this(status: SessionStatus.signedOut, message: message);
  const SessionState.authenticating()
    : this(status: SessionStatus.authenticating);
  const SessionState.authenticated(Session session)
    : this(status: SessionStatus.authenticated, session: session);

  final SessionStatus status;
  final Session? session;
  final String? message;

  @override
  List<Object?> get props => [status, session, message];
}

final class SessionCubit extends Cubit<SessionState> {
  SessionCubit({
    required RestoreSession restoreSession,
    required PasswordLogin passwordLogin,
    required OAuthLogin oauthLogin,
    required SignOut signOut,
    ChangeOwnPassword? changePassword,
  }) : _restoreSession = restoreSession,
       _passwordLogin = passwordLogin,
       _oauthLogin = oauthLogin,
       _signOut = signOut,
       _changePassword = changePassword,
       super(const SessionState.restoring());

  final RestoreSession _restoreSession;
  final PasswordLogin _passwordLogin;
  final OAuthLogin _oauthLogin;
  final SignOut _signOut;
  final ChangeOwnPassword? _changePassword;

  Future<String?> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    final action = _changePassword;
    if (action == null) return 'Password change is unavailable.';
    try {
      final updated = await action(currentPassword, newPassword);
      emit(SessionState.authenticated(updated));
      return null;
    } on AppFailure catch (failure) {
      return failure.message;
    } on Object {
      return 'Could not change your password. Please try again.';
    }
  }

  Future<void> restore() async {
    try {
      final session = await _restoreSession();
      emit(
        session == null
            ? const SessionState.signedOut()
            : SessionState.authenticated(session),
      );
    } on Object {
      emit(
        const SessionState.signedOut(
          message: 'Your session could not be restored. Please sign in.',
        ),
      );
    }
  }

  Future<void> password(String email, String password) =>
      _authenticate(() => _passwordLogin(email, password));

  Future<void> oauth(OAuthProvider provider) =>
      _authenticate(() => _oauthLogin(provider));

  void acceptVerifiedRegistration(Session session) {
    if (!isClosed) emit(SessionState.authenticated(session));
  }

  Future<void> _authenticate(Future<Session> Function() action) async {
    if (state.status == SessionStatus.authenticating) return;
    emit(const SessionState.authenticating());
    try {
      final session = await action();
      if (!session.user.active) {
        emit(
          const SessionState.signedOut(message: 'This account is disabled.'),
        );
        return;
      }
      emit(SessionState.authenticated(session));
    } on AppFailure catch (failure) {
      emit(
        SessionState.signedOut(
          message: failure.code == FailureCode.cancelled
              ? null
              : failure.message,
        ),
      );
    } on Object {
      emit(
        const SessionState.signedOut(
          message: 'Sign in failed. Please try again.',
        ),
      );
    }
  }

  Future<void> logout() async {
    await _signOut();
    emit(const SessionState.signedOut());
  }

  void sessionInvalidated() {
    if (!isClosed) {
      emit(
        const SessionState.signedOut(
          message: 'Your session expired. Please sign in again.',
        ),
      );
    }
  }
}
