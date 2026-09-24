import 'dart:convert';

import '../../domain/entities/session.dart';

final class SessionModel {
  const SessionModel(this.session);
  final Session session;

  factory SessionModel.fromData(Map<String, dynamic> data) {
    return SessionModel(
      Session(
        accessToken: data['access_token'] as String,
        accessTokenExpiresAt: DateTime.parse(
          data['access_token_expires_at'] as String,
        ).toUtc(),
        refreshToken: data['refresh_token'] as String,
        refreshTokenExpiresAt: DateTime.parse(
          data['refresh_token_expires_at'] as String,
        ).toUtc(),
        user: userFromData(data['user'] as Map<String, dynamic>),
      ),
    );
  }

  static AppUser userFromData(Map<String, dynamic> user) => AppUser(
    id: user['user_id'] as String,
    name: user['name'] as String,
    email: user['email'] as String,
    role: switch (user['role']) {
      'CUSTOMER' => UserRole.customer,
      'CASHIER' => UserRole.cashier,
      'ADMIN' => UserRole.admin,
      _ => throw const FormatException('Unknown role'),
    },
    active: user['status'] == 'ACTIVE',
    passwordChangeRequired: user['password_change_required'] == true,
  );

  factory SessionModel.decode(String value) =>
      SessionModel.fromData(jsonDecode(value) as Map<String, dynamic>);

  String encode() => jsonEncode({
    'access_token': session.accessToken,
    'access_token_expires_at': session.accessTokenExpiresAt.toIso8601String(),
    'refresh_token': session.refreshToken,
    'refresh_token_expires_at': session.refreshTokenExpiresAt.toIso8601String(),
    'user': {
      'user_id': session.user.id,
      'name': session.user.name,
      'email': session.user.email,
      'role': session.user.role.name.toUpperCase(),
      'status': session.user.active ? 'ACTIVE' : 'DISABLED',
      'password_change_required': session.user.passwordChangeRequired,
    },
  });
}
