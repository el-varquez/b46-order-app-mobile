enum FailureCode {
  cancelled,
  invalidRequest,
  unauthenticated,
  forbidden,
  accountDisabled,
  identityLinkRequired,
  invalidOAuthCredential,
  invalidOAuthIntent,
  invalidRegistration,
  registrationRateLimited,
  cartChanged,
  snapshotExpired,
  invalidTransition,
  unavailable,
  network,
  unknown,
}

final class AppFailure implements Exception {
  const AppFailure(this.code, this.message, {this.requestId});

  final FailureCode code;
  final String message;
  final String? requestId;

  @override
  String toString() => message;
}
