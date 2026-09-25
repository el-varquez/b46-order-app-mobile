import 'package:b46_order_app_mobile/app/theme/app_theme.dart';
import 'package:b46_order_app_mobile/features/cashier_fulfillment/application/use_cases/cashier_use_cases.dart';
import 'package:b46_order_app_mobile/features/cashier_fulfillment/domain/entities/cashier_order.dart';
import 'package:b46_order_app_mobile/features/cashier_fulfillment/domain/repositories/cashier_repository.dart';
import 'package:b46_order_app_mobile/features/cashier_fulfillment/presentation/cubit/cashier_orders_cubit.dart';
import 'package:b46_order_app_mobile/features/cashier_fulfillment/presentation/screens/cashier_screens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('cashier orders keep prototype layout and filters on 320px', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 760));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repository = _CashierRepository();
    final orders = CashierOrdersCubit(
      LoadCashierOrders(repository),
      const Duration(days: 1),
    );
    await orders.load();
    String? opened;
    var signedOut = false;
    await tester.pumpWidget(
      BlocProvider.value(
        value: orders,
        child: MaterialApp(
          theme: AppTheme.light,
          home: CashierOrdersScreen(
            onOpen: (id) => opened = id,
            onSignOut: () => signedOut = true,
            onToggleTheme: () {},
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Store orders'), findsOneWidget);
    expect(find.text('Accepted orders only'), findsOneWidget);
    expect(find.text('NEW'), findsOneWidget);
    expect(find.text('Juan Dela Cruz'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.textContaining('Order #').first);
    expect(opened, repository.current.id);
    await tester.drag(
      find.byWidgetPredicate(
        (widget) =>
            widget is ListView && widget.scrollDirection == Axis.horizontal,
      ),
      const Offset(-180, 0),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ChoiceChip, 'Delivered'));
    await tester.pumpAndSettle();
    expect(orders.state.filter, FulfillmentStatus.delivered);
    expect(find.text('No orders here yet'), findsOneWidget);
    await tester.ensureVisible(find.text('Sign out'));
    await tester.tap(find.text('Sign out'));
    expect(signedOut, isTrue);
    expect(tester.takeException(), isNull);
    await orders.close();
  });

  testWidgets('cashier detail keeps fixed status action and order data', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 760));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repository = _CashierRepository();
    final detail = CashierOrderDetailCubit(
      load: LoadCashierOrder(repository),
      markRead: MarkCashierOrderRead(repository),
      advance: AdvanceCashierOrder(repository),
    );
    await detail.load(repository.current.id);
    await tester.pumpWidget(
      BlocProvider.value(
        value: detail,
        child: MaterialApp(
          theme: AppTheme.light,
          home: CashierOrderDetailScreen(
            orderId: repository.current.id,
            onToggleTheme: () {},
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Customer sees'), findsOneWidget);
    expect(find.text('Juan Dela Cruz'), findsOneWidget);
    expect(find.text('Out for delivery'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Out for delivery'));
    await tester.pumpAndSettle();
    expect(find.text('On the way'), findsOneWidget);
    expect(find.text('Mark delivered'), findsOneWidget);
    await tester.tap(find.text('Mark delivered'));
    await tester.pumpAndSettle();
    expect(find.text('Delivered · Read only'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await detail.close();
  });
}

final class _CashierRepository implements CashierRepository {
  CashierOrder current = CashierOrder(
    id: 'b4600000-0000-4000-8000-000000000001',
    customerName: 'Juan Dela Cruz',
    status: FulfillmentStatus.preparing,
    nextAction: FulfillmentStatus.delivering,
    unread: true,
    totalCentavos: 8200,
    deliveryAddress: 'Block 8, Bria Homes',
    deliveryNotes: 'Blue gate',
    lines: const [CashierOrderLine(id: 'coke', name: 'Coke 1.5L', quantity: 1)],
    createdAt: DateTime(2026, 9, 25),
  );

  @override
  Future<CashierOrderPage> orders({
    FulfillmentStatus? status,
    String? afterId,
  }) async => CashierOrderPage(
    orders: status == null || current.status == status ? [current] : [],
    nextAfterId: null,
  );

  @override
  Future<CashierOrder> order(String id) async => current;

  @override
  Future<CashierOrder> markRead(String id) async => current;

  @override
  Future<CashierOrder> advance(String id, FulfillmentStatus target) async {
    current = CashierOrder(
      id: current.id,
      customerName: current.customerName,
      status: target,
      nextAction: target == FulfillmentStatus.delivering
          ? FulfillmentStatus.delivered
          : null,
      unread: false,
      totalCentavos: current.totalCentavos,
      deliveryAddress: current.deliveryAddress,
      deliveryNotes: current.deliveryNotes,
      lines: current.lines,
      createdAt: current.createdAt,
    );
    return current;
  }
}
