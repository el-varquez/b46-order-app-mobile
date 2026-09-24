import 'package:b46_order_app_mobile/app/theme/app_theme.dart';
import 'package:b46_order_app_mobile/app/theme/tokens.dart';
import 'package:b46_order_app_mobile/features/cart_checkout/application/use_cases/update_cart.dart';
import 'package:b46_order_app_mobile/features/cart_checkout/data/repositories/memory_cart_repository.dart';
import 'package:b46_order_app_mobile/features/cart_checkout/domain/entities/cart.dart';
import 'package:b46_order_app_mobile/features/cart_checkout/presentation/cubit/cart_cubit.dart';
import 'package:b46_order_app_mobile/features/cart_checkout/presentation/screens/checkout_screen.dart';
import 'package:b46_order_app_mobile/features/catalog/application/use_cases/load_products.dart';
import 'package:b46_order_app_mobile/features/catalog/domain/entities/product.dart';
import 'package:b46_order_app_mobile/features/catalog/domain/repositories/catalog_repository.dart';
import 'package:b46_order_app_mobile/features/catalog/presentation/cubit/catalog_cubit.dart';
import 'package:b46_order_app_mobile/features/catalog/presentation/screens/catalog_screen.dart';
import 'package:b46_order_app_mobile/features/customer_orders/application/use_cases/customer_order_use_cases.dart';
import 'package:b46_order_app_mobile/features/customer_orders/domain/entities/customer_order.dart';
import 'package:b46_order_app_mobile/features/customer_orders/domain/repositories/customer_order_repository.dart';
import 'package:b46_order_app_mobile/features/customer_orders/presentation/cubit/customer_orders_cubit.dart';
import 'package:b46_order_app_mobile/features/customer_orders/presentation/screens/customer_orders_screen.dart';
import 'package:b46_order_app_mobile/shared/components/customer_profile.dart';
import 'package:b46_order_app_mobile/shared/components/pop_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('catalog grid and checkout fit a 320px phone', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 760));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final catalog = CatalogCubit(LoadProducts(_CatalogRepository()));
    final cart = CartCubit(UpdateCart(MemoryCartRepository()));
    var cartOpened = false;
    await catalog.load();
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider.value(value: catalog),
          BlocProvider.value(value: cart),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: CatalogScreen(
            cartCount: 0,
            deliveryArea: 'Block 8, Lot 2, Bria Homes',
            onAdd: (_) {},
            onCart: () => cartOpened = true,
            onOrders: () {},
            onSignOut: () {},
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Block 8, Lot 2, Bria Homes'), findsOneWidget);
    expect(find.byKey(const Key('basket-count-badge')), findsNothing);
    expect(find.text('Coke 1.5L'), findsOneWidget);
    await tester.tap(find.byTooltip('Your basket'));
    expect(cartOpened, isTrue);
    await tester.enterText(find.byKey(const Key('product-search')), 'soap');
    await tester.pump();
    expect(find.text('Coke 1.5L'), findsNothing);
    expect(find.text('Bath soap'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('product-search')), '');
    await tester.pump();
    await tester.tap(find.text('Drinks'));
    await tester.pump();
    expect(find.text('Coke 1.5L'), findsOneWidget);
    expect(find.text('Bath soap'), findsNothing);
    expect(tester.takeException(), isNull);

    cart.add(
      const CartProduct(id: 'coke', name: 'Coke 1.5L', unitPriceCentavos: 8200),
    );
    await tester.pumpWidget(
      BlocProvider.value(
        value: cart,
        child: MaterialApp(
          theme: AppTheme.light,
          home: CheckoutScreen(
            initialAddress: 'Block 8, Lot 2, Bria Homes',
            placing: false,
            message: null,
            onPlace: (_, _) async {},
          ),
        ),
      ),
    );
    await tester.pump();
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('delivery-address')))
          .controller!
          .text,
      'Block 8, Lot 2, Bria Homes',
    );
    await tester.scrollUntilVisible(
      find.byKey(const Key('place-order')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.textContaining('Place order'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await catalog.close();
    await cart.close();
  });

  testWidgets('adding a product flies to the header basket', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final catalog = CatalogCubit(LoadProducts(_CatalogRepository()));
    final cart = CartCubit(UpdateCart(MemoryCartRepository()));
    await catalog.load();
    var opened = 0;
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider.value(value: catalog),
          BlocProvider.value(value: cart),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: BlocBuilder<CartCubit, CartState>(
            builder: (context, state) => CatalogScreen(
              cartCount: state.itemCount,
              onAdd: (product) => cart.add(
                CartProduct(
                  id: product.id,
                  name: product.name,
                  unitPriceCentavos: product.priceCentavos,
                ),
              ),
              onCart: () => opened++,
              onOrders: () {},
              onSignOut: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.ensureVisible(find.text('Add').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add').first);
    await tester.pump();
    expect(cart.state.itemCount, 1);
    expect(find.byKey(const Key('view-cart')), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const Key('basket-count-badge')),
        matching: find.text('1'),
      ),
      findsOneWidget,
    );
    await tester.tapAt(
      tester.getCenter(find.byKey(const Key('basket-count-badge'))),
    );
    expect(opened, 1);
    expect(find.byKey(const Key('add-to-basket-flight')), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(const Key('add-to-basket-flight')), findsOneWidget);
    await tester.ensureVisible(find.text('Add').first);
    await tester.pump();
    await tester.tap(find.text('Add').first);
    await tester.pump();
    expect(cart.state.itemCount, 2);
    expect(
      find.descendant(
        of: find.byKey(const Key('basket-count-badge')),
        matching: find.text('2'),
      ),
      findsOneWidget,
    );
    expect(find.byKey(const Key('add-to-basket-flight')), findsNWidgets(2));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('add-to-basket-flight')), findsNothing);
    expect(tester.takeException(), isNull);
    await catalog.close();
    await cart.close();
  });

  testWidgets('basket item removes only after a left swipe', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 760));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final cart = CartCubit(UpdateCart(MemoryCartRepository()));
    cart.add(
      const CartProduct(id: 'coke', name: 'Coke 1.5L', unitPriceCentavos: 8200),
    );
    await tester.pumpWidget(
      BlocProvider.value(
        value: cart,
        child: MaterialApp(
          theme: AppTheme.light,
          home: CheckoutScreen(
            placing: false,
            message: null,
            onPlace: (_, _) async {},
          ),
        ),
      ),
    );
    await tester.pump();
    const row = ValueKey('basket-line-coke');
    expect(find.text('Your basket (1)'), findsOneWidget);
    expect(find.byTooltip('Remove'), findsNothing);
    await tester.tap(find.byIcon(PopIcons.plus));
    await tester.pump();
    expect(cart.state.itemCount, 2);
    expect(find.text('Your basket (2)'), findsOneWidget);
    await tester.tap(find.byIcon(PopIcons.minus));
    await tester.pump();
    expect(cart.state.itemCount, 1);
    expect(find.text('Your basket (1)'), findsOneWidget);
    await tester.drag(find.byKey(row), const Offset(260, 0));
    await tester.pumpAndSettle();
    expect(cart.state.lines, hasLength(1));

    await tester.drag(find.byKey(row), const Offset(-280, 0));
    await tester.pumpAndSettle();
    expect(cart.state.lines, isEmpty);
    expect(find.text('Your basket is empty'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await cart.close();
  });

  testWidgets('orders and order status fit a 320px phone', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 760));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repository = _OrdersRepository();
    final orders = CustomerOrdersCubit(
      place: PlaceCustomerOrder(repository),
      loadOrder: LoadCustomerOrder(repository),
      loadOrders: LoadCustomerOrders(repository),
      ids: _Ids(),
      pollInterval: const Duration(days: 1),
    );
    await orders.loadAll();
    String? openedId;
    await tester.pumpWidget(
      BlocProvider.value(
        value: orders,
        child: MaterialApp(
          theme: AppTheme.light,
          home: CustomerOrdersScreen(
            onOpen: (id) => openedId = id,
            onShop: () {},
            onProfile: () {},
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.text('View status'));
    expect(openedId, 'order-1');
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(
      BlocProvider.value(
        value: orders,
        child: MaterialApp(
          theme: AppTheme.light,
          home: const CustomerOrderStatusScreen(orderId: 'order-1'),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Preparing your order'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await orders.close();
  });

  testWidgets('profile edits delivery area', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 760));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    var savedArea = 'Bria Homes';
    Widget profile() => MaterialApp(
      theme: AppTheme.light,
      home: CustomerProfileScreen(
        name: 'Juan',
        email: 'juan@example.com',
        deliveryArea: savedArea,
        deliveryAreaLoading: false,
        onSaveDeliveryArea: (value) async {
          savedArea = value;
          return true;
        },
        onShop: () {},
        onOrders: () {},
        onToggleTheme: () {},
        onSignOut: () {},
      ),
    );
    await tester.pumpWidget(profile());
    await tester.tap(find.text('Edit delivery area'));
    await tester.pump();
    await tester.enterText(
      find.byKey(const Key('delivery-area-input')),
      'Block 8, Lot 2, Bria Homes',
    );
    await tester.tap(find.text('Save'));
    await tester.pump();
    expect(savedArea, 'Block 8, Lot 2, Bria Homes');
    await tester.pumpWidget(profile());
    expect(find.text('Block 8, Lot 2, Bria Homes'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('delivered order steps are green', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 760));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repository = _OrdersRepository(CustomerOrderStatus.delivered);
    final orders = CustomerOrdersCubit(
      place: PlaceCustomerOrder(repository),
      loadOrder: LoadCustomerOrder(repository),
      loadOrders: LoadCustomerOrders(repository),
      ids: _Ids(),
      pollInterval: const Duration(days: 1),
    );
    await orders.loadAll();
    await tester.pumpWidget(
      BlocProvider.value(
        value: orders,
        child: MaterialApp(
          theme: AppTheme.light,
          home: const CustomerOrderStatusScreen(orderId: 'order-1'),
        ),
      ),
    );
    await tester.pump();
    expect(
      tester.widget<Icon>(find.byKey(const Key('order-status-icon'))).color,
      PopColors.success,
    );
    for (var index = 0; index < 3; index++) {
      final circle = tester.widget<Container>(
        find.byKey(Key('order-step-$index')),
      );
      expect((circle.decoration! as BoxDecoration).color, PopColors.success);
    }
    expect(tester.takeException(), isNull);
    await orders.close();
  });
}

final class _CatalogRepository implements CatalogRepository {
  @override
  Future<ProductPage> products({
    int limit = 20,
    String afterId = '',
    int snapshotRevision = 0,
  }) async => const ProductPage(
    products: [
      Product(
        id: 'coke',
        name: 'Coke 1.5L',
        description: 'Chilled bottle',
        priceCentavos: 8200,
        categoryId: 'drinks',
        categoryName: 'Drinks',
        available: true,
      ),
      Product(
        id: 'soap',
        name: 'Bath soap',
        description: 'Everyday essential',
        priceCentavos: 3500,
        categoryId: 'home',
        categoryName: 'Home',
        available: true,
      ),
    ],
    snapshotRevision: 1,
    afterId: '',
    hasMore: false,
  );
}

final class _OrdersRepository implements CustomerOrderRepository {
  _OrdersRepository([
    CustomerOrderStatus status = CustomerOrderStatus.preparing,
  ]) : orderValue = CustomerOrder(
         id: 'order-1',
         checkoutId: 'checkout-1',
         status: status,
         totalCentavos: 8200,
         deliveryAddress: 'Block 12, Bria Homes',
         lines: const [
           CustomerOrderLine(
             productId: 'coke',
             productName: 'Coke 1.5L',
             quantity: 1,
             unitPriceCentavos: 8200,
           ),
         ],
         unavailableProductIds: const [],
         createdAt: DateTime.utc(2026),
       );
  final CustomerOrder orderValue;

  @override
  Future<CustomerOrder> order(String orderId) async => orderValue;

  @override
  Future<List<CustomerOrder>> orders() async => [orderValue];

  @override
  Future<CustomerOrder> place({
    required String checkoutId,
    required List<CheckoutLine> lines,
    required String deliveryAddress,
    required String deliveryNotes,
  }) async => orderValue;
}

final class _Ids implements CheckoutIdGenerator {
  @override
  String next() => 'checkout-1';
}
