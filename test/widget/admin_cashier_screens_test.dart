import 'package:b46_order_app_mobile/app/theme/app_theme.dart';
import 'package:b46_order_app_mobile/features/admin_cashier_management/application/use_cases/admin_cashier_use_cases.dart';
import 'package:b46_order_app_mobile/features/admin_cashier_management/domain/entities/cashier_account.dart';
import 'package:b46_order_app_mobile/features/admin_cashier_management/domain/repositories/admin_cashier_repository.dart';
import 'package:b46_order_app_mobile/features/admin_cashier_management/presentation/cubit/admin_cashiers_cubit.dart';
import 'package:b46_order_app_mobile/features/admin_cashier_management/presentation/screens/admin_cashier_screens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('admin list follows prototype and keeps filters on 320px', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 760));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repository = _AdminRepository();
    final admin = _cubit(repository);
    var addRequested = false;
    var signedOut = false;
    String? opened;
    await tester.pumpWidget(
      BlocProvider.value(
        value: admin,
        child: MaterialApp(
          theme: AppTheme.light,
          home: AdminCashiersScreen(
            onAdd: () => addRequested = true,
            onOpen: (id) => opened = id,
            onSignOut: () => signedOut = true,
            onToggleTheme: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Cashier access'), findsOneWidget);
    expect(find.text('Cashier accounts'), findsOneWidget);
    expect(find.text('Mika Dela Cruz'), findsOneWidget);
    expect(find.textContaining('Apple'), findsNothing);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Add cashier'));
    expect(addRequested, isTrue);
    await tester.tap(find.text('Manage →'));
    expect(opened, repository.account.id);
    await tester.tap(find.widgetWithText(ChoiceChip, 'Disabled'));
    await tester.pumpAndSettle();
    expect(admin.state.filter, CashierAccountStatus.disabled);
    expect(find.text('No cashiers here'), findsOneWidget);
    await tester.ensureVisible(find.text('Sign out'));
    await tester.tap(find.text('Sign out'));
    expect(signedOut, isTrue);
    expect(tester.takeException(), isNull);
    await admin.close();
  });

  testWidgets('add cashier preserves email verification flow', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 760));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repository = _AdminRepository();
    final admin = _cubit(repository);
    String? created;
    await tester.pumpWidget(
      BlocProvider.value(
        value: admin,
        child: MaterialApp(
          theme: AppTheme.light,
          home: AddCashierScreen(
            onCreated: (id) => created = id,
            onToggleTheme: () {},
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Cashier details'), findsOneWidget);
    expect(find.text('Secure onboarding'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.enterText(find.byType(TextFormField).at(0), 'Mika Dela Cruz');
    await tester.enterText(
      find.byType(TextFormField).at(1),
      'mika@example.com',
    );
    await tester.enterText(find.byType(TextFormField).at(2), 'temporary123');
    await tester.ensureVisible(find.text('Send verification code'));
    await tester.tap(find.text('Send verification code'));
    await tester.pump();
    expect(repository.beganRegistration, isTrue);
    expect(find.text('Verify cashier email'), findsOneWidget);
    await tester.enterText(find.byType(TextField).last, '123456');
    await tester.tap(find.text('Verify and add cashier'));
    await tester.pump();
    expect(created, repository.account.id);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await admin.close();
  });

  testWidgets('admin detail keeps account controls and provider status', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 760));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repository = _AdminRepository();
    final admin = _cubit(repository);
    await tester.pumpWidget(
      BlocProvider.value(
        value: admin,
        child: MaterialApp(
          theme: AppTheme.light,
          home: CashierDetailScreen(
            id: repository.account.id,
            onToggleTheme: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Sign-in methods'), findsOneWidget);
    expect(find.text('Mika Dela Cruz'), findsOneWidget);
    expect(find.text('Google'), findsOneWidget);
    expect(find.text('Apple'), findsNothing);
    expect(tester.takeException(), isNull);

    await tester.ensureVisible(find.text('Disable cashier'));
    await tester.tap(find.text('Disable cashier'));
    await tester.pumpAndSettle();
    expect(find.text('Disable cashier?'), findsOneWidget);
    await tester.tap(find.text('Disable').last);
    await tester.pumpAndSettle();
    expect(repository.account.status, CashierAccountStatus.disabled);
    expect(find.text('Restore cashier'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await admin.close();
  });
}

AdminCashiersCubit _cubit(_AdminRepository repository) => AdminCashiersCubit(
  list: ListCashiers(repository),
  detail: LoadCashier(repository),
  beginRegistration: BeginCashierRegistration(repository),
  resendRegistration: ResendCashierRegistration(repository),
  verifyRegistration: VerifyCashierRegistration(repository),
  changeStatus: ChangeCashierStatus(repository),
  resetLogin: ResetCashierLogin(repository),
);

final class _AdminRepository implements AdminCashierRepository {
  CashierAccount account = const CashierAccount(
    id: 'cashier-1',
    name: 'Mika Dela Cruz',
    email: 'mika@example.com',
    status: CashierAccountStatus.active,
    passwordChangeRequired: false,
    emailVerified: true,
    connectedProviders: ['PASSWORD', 'GOOGLE', 'APPLE'],
  );
  bool beganRegistration = false;

  @override
  Future<List<CashierAccount>> list({CashierAccountStatus? status}) async =>
      status == null || status == account.status ? [account] : [];

  @override
  Future<CashierAccount> detail(String id) async => account;

  @override
  Future<CashierRegistration> beginRegistration({
    required String name,
    required String email,
    required String temporaryPassword,
  }) async {
    beganRegistration = true;
    return CashierRegistration(
      id: 'registration-1',
      expiresAt: DateTime(2026, 9, 26),
    );
  }

  @override
  Future<CashierRegistration> resendRegistration(String registrationId) async =>
      CashierRegistration(id: registrationId, expiresAt: DateTime(2026, 9, 26));

  @override
  Future<CashierAccount> verifyRegistration(
    String registrationId,
    String code,
  ) async => account;

  @override
  Future<CashierAccount> setStatus(
    String id,
    CashierAccountStatus status,
  ) async {
    account = CashierAccount(
      id: account.id,
      name: account.name,
      email: account.email,
      status: status,
      passwordChangeRequired: account.passwordChangeRequired,
      emailVerified: account.emailVerified,
      connectedProviders: account.connectedProviders,
    );
    return account;
  }

  @override
  Future<CashierAccount> resetPassword(
    String id,
    String temporaryPassword,
  ) async => account;
}
