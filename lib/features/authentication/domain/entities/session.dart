enum UserRole { customer, cashier, admin }

enum OAuthProvider { google }

final class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.active,
    this.passwordChangeRequired = false,
  });

  final String id;
  final String name;
  final String email;
  final UserRole role;
  final bool active;
  final bool passwordChangeRequired;
}

final class Session {
  const Session({
    required this.accessToken,
    required this.accessTokenExpiresAt,
    required this.refreshToken,
    required this.refreshTokenExpiresAt,
    required this.user,
  });

  final String accessToken;
  final DateTime accessTokenExpiresAt;
  final String refreshToken;
  final DateTime refreshTokenExpiresAt;
  final AppUser user;
}
