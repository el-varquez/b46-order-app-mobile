import 'package:b46_order_app_mobile/app/routing/app_router.dart';
import 'package:b46_order_app_mobile/features/authentication/domain/entities/session.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('roles cannot navigate into another role area', () {
    expect(homeForRole(UserRole.customer), '/shop');
    expect(allowedForRole(UserRole.customer, '/profile'), isTrue);
    expect(allowedForRole(UserRole.customer, '/staff/orders'), isFalse);
    expect(allowedForRole(UserRole.cashier, '/profile'), isFalse);
    expect(allowedForRole(UserRole.cashier, '/orders'), isFalse);
    expect(allowedForRole(UserRole.admin, '/shop'), isFalse);
    expect(allowedForRole(UserRole.cashier, '/staff/orders/123'), isTrue);
  });
}
