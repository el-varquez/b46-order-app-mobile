enum CashierAccountStatus { active, disabled }

final class CashierRegistration {
  const CashierRegistration({required this.id, required this.expiresAt});
  final String id;
  final DateTime expiresAt;
}

final class CashierAuditEntry {
  const CashierAuditEntry({
    required this.action,
    required this.result,
    required this.occurredAt,
  });
  final String action;
  final String result;
  final DateTime occurredAt;
}

final class CashierAccount {
  const CashierAccount({
    required this.id,
    required this.name,
    required this.email,
    required this.status,
    required this.passwordChangeRequired,
    required this.emailVerified,
    required this.connectedProviders,
    this.createdNow = false,
    this.audit = const [],
  });

  final String id;
  final String name;
  final String email;
  final CashierAccountStatus status;
  final bool passwordChangeRequired;
  final bool emailVerified;
  final List<String> connectedProviders;
  final bool createdNow;
  final List<CashierAuditEntry> audit;
}
