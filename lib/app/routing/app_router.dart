import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../features/admin_cashier_management/presentation/screens/admin_cashier_screens.dart';
import '../../features/authentication/domain/entities/session.dart';
import '../../features/authentication/presentation/cubit/session_cubit.dart';
import '../../features/authentication/presentation/screens/login_screen.dart';
import '../../features/authentication/presentation/screens/registration_screens.dart';
import '../../features/authentication/presentation/screens/change_password_screen.dart';
import '../../features/cart_checkout/domain/entities/cart.dart';
import '../../features/cart_checkout/presentation/cubit/cart_cubit.dart';
import '../../features/cart_checkout/presentation/screens/checkout_screen.dart';
import '../../features/cashier_fulfillment/presentation/screens/cashier_screens.dart';
import '../../features/catalog/domain/entities/product.dart';
import '../../features/catalog/presentation/screens/catalog_screen.dart';
import '../../features/customer_orders/domain/entities/customer_order.dart';
import '../../features/customer_orders/presentation/cubit/customer_orders_cubit.dart';
import '../../features/customer_orders/presentation/screens/customer_orders_screen.dart';
import '../../shared/components/pop_scaffold.dart';
import '../../shared/components/customer_profile.dart';
import '../bootstrap/dependencies.dart';

GoRouter createRouter(AppDependencies dependencies, VoidCallback toggleTheme) {
  final refresh = _CubitRefresh(dependencies.session.stream);
  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: refresh,
    redirect: (context, state) {
      final session = dependencies.session.state;
      final location = state.matchedLocation;
      if (session.status == SessionStatus.restoring) {
        return location == '/splash' ? null : '/splash';
      }
      final loginArea = location.startsWith('/login');
      if (session.status != SessionStatus.authenticated) {
        return loginArea ? null : '/login';
      }
      final role = session.session!.user.role;
      if (session.session!.user.passwordChangeRequired) {
        return location == '/change-password' ? null : '/change-password';
      }
      final home = homeForRole(role);
      if (location == '/splash' ||
          loginArea ||
          location == '/change-password') {
        return home;
      }
      if (!allowedForRole(role, location)) return home;
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (_, _) => const _ExitOnBack(child: _SplashScreen()),
      ),
      GoRoute(
        path: '/login',
        builder: (context, _) => _ExitOnBack(
          child: LoginScreen(onEmail: () => context.push('/login/email')),
        ),
      ),
      GoRoute(
        path: '/login/email',
        builder: (context, _) => EmailLoginScreen(
          onRegister: (email) {
            dependencies.registration.prefillEmail(email);
            context.push('/login/register');
          },
        ),
      ),
      GoRoute(
        path: '/login/register',
        builder: (context, _) =>
            RegistrationScreen(onStarted: () => context.push('/login/verify')),
      ),
      GoRoute(
        path: '/login/verify',
        builder: (context, _) =>
            VerifyEmailScreen(onChangeEmail: () => context.pop()),
      ),
      GoRoute(
        path: '/change-password',
        builder: (_, _) => _ExitOnBack(
          child: ChangePasswordScreen(onSignOut: dependencies.session.logout),
        ),
      ),
      GoRoute(
        path: '/shop',
        builder: (_, _) => _ExitOnBack(
          child: _CustomerCatalogRoute(dependencies: dependencies),
        ),
      ),
      GoRoute(
        path: '/checkout',
        builder: (_, _) => _CheckoutRoute(dependencies: dependencies),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, _) {
          final user = dependencies.session.state.session!.user;
          return CustomerProfileScreen(
            name: user.name,
            email: user.email,
            onShop: () => context.go('/shop'),
            onOrders: () => context.go('/orders'),
            onToggleTheme: toggleTheme,
            onSignOut: dependencies.session.logout,
          );
        },
      ),
      GoRoute(
        path: '/orders',
        builder: (_, _) => _CustomerOrdersRoute(dependencies: dependencies),
        routes: [
          GoRoute(
            path: ':orderId',
            builder: (_, state) => _CustomerOrderRoute(
              dependencies: dependencies,
              orderId: state.pathParameters['orderId']!,
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/staff/orders',
        builder: (_, _) => _ExitOnBack(
          child: _CashierOrdersRoute(
            dependencies: dependencies,
            onToggleTheme: toggleTheme,
          ),
        ),
        routes: [
          GoRoute(
            path: ':orderId',
            builder: (_, state) {
              final id = state.pathParameters['orderId']!;
              return BlocProvider(
                create: (_) => dependencies.cashierOrderDetails()..load(id),
                child: CashierOrderDetailScreen(
                  orderId: id,
                  onToggleTheme: toggleTheme,
                ),
              );
            },
          ),
        ],
      ),
      GoRoute(
        path: '/admin',
        builder: (context, _) => _ExitOnBack(
          child: AdminCashiersScreen(
            onAdd: () => context.push('/admin/new'),
            onOpen: (id) => context.push('/admin/$id'),
            onSignOut: dependencies.session.logout,
          ),
        ),
        routes: [
          GoRoute(
            path: 'new',
            builder: (context, _) =>
                AddCashierScreen(onCreated: (id) => context.go('/admin/$id')),
          ),
          GoRoute(
            path: ':cashierId',
            builder: (_, state) =>
                CashierDetailScreen(id: state.pathParameters['cashierId']!),
          ),
        ],
      ),
    ],
  );
}

class _ExitOnBack extends StatefulWidget {
  const _ExitOnBack({required this.child});

  final Widget child;

  @override
  State<_ExitOnBack> createState() => _ExitOnBackState();
}

class _ExitOnBackState extends State<_ExitOnBack> {
  DateTime? lastBackAt;

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: false,
    onPopInvokedWithResult: (didPop, _) {
      if (didPop) return;

      final now = DateTime.now();
      if (lastBackAt != null &&
          now.difference(lastBackAt!) < const Duration(seconds: 2)) {
        SystemNavigator.pop();
        return;
      }

      lastBackAt = now;
      final messenger = ScaffoldMessenger.of(context);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Press back again to exit'),
          duration: Duration(seconds: 2),
        ),
      );
    },
    child: widget.child,
  );
}

String homeForRole(UserRole role) => switch (role) {
  UserRole.customer => '/shop',
  UserRole.cashier => '/staff/orders',
  UserRole.admin => '/admin',
};

bool allowedForRole(UserRole role, String location) => switch (role) {
  UserRole.customer =>
    location == '/shop' ||
        location == '/profile' ||
        location == '/checkout' ||
        location.startsWith('/orders'),
  UserRole.cashier => location.startsWith('/staff/orders'),
  UserRole.admin => location == '/admin' || location.startsWith('/admin/'),
};

final class _CubitRefresh extends ChangeNotifier {
  _CubitRefresh(Stream<Object?> stream) {
    _subscription = stream.listen((_) => notifyListeners());
  }
  late final StreamSubscription<Object?> _subscription;
  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();
  @override
  Widget build(BuildContext context) => const PopScaffold(
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          B46Mark(large: true),
          SizedBox(height: 24),
          CircularProgressIndicator(),
        ],
      ),
    ),
  );
}

class _CustomerCatalogRoute extends StatefulWidget {
  const _CustomerCatalogRoute({required this.dependencies});
  final AppDependencies dependencies;
  @override
  State<_CustomerCatalogRoute> createState() => _CustomerCatalogRouteState();
}

class _CustomerCatalogRouteState extends State<_CustomerCatalogRoute> {
  @override
  void initState() {
    super.initState();
    if (widget.dependencies.catalog.state.products.isEmpty) {
      widget.dependencies.catalog.load();
    }
  }

  @override
  Widget build(BuildContext context) => BlocBuilder<CartCubit, CartState>(
    builder: (context, cart) => CatalogScreen(
      cartCount: cart.itemCount,
      onAdd: (Product product) => context.read<CartCubit>().add(
        CartProduct(
          id: product.id,
          name: product.name,
          unitPriceCentavos: product.priceCentavos,
        ),
      ),
      onCart: () => context.push('/checkout'),
      onOrders: () => context.push('/orders'),
      onProfile: () => context.push('/profile'),
      onSignOut: widget.dependencies.session.logout,
    ),
  );
}

class _CheckoutRoute extends StatelessWidget {
  const _CheckoutRoute({required this.dependencies});
  final AppDependencies dependencies;
  @override
  Widget build(BuildContext context) =>
      BlocBuilder<CustomerOrdersCubit, CustomerOrdersState>(
        builder: (context, orderState) => CheckoutScreen(
          placing: orderState.status == CustomerOrdersStatus.placing,
          message: orderState.status == CustomerOrdersStatus.failure
              ? orderState.message
              : null,
          onPlace: (address, notes) async {
            final cart = context.read<CartCubit>().state;
            final order = await context.read<CustomerOrdersCubit>().place(
              lines: cart.lines
                  .map(
                    (line) => CheckoutLine(
                      productId: line.product.id,
                      quantity: line.quantity,
                      expectedUnitPriceCentavos: line.product.unitPriceCentavos,
                    ),
                  )
                  .toList(growable: false),
              deliveryAddress: address,
              deliveryNotes: notes,
            );
            if (order != null && context.mounted) {
              context.pushReplacement('/orders/${order.id}');
            }
          },
        ),
      );
}

class _CustomerOrdersRoute extends StatefulWidget {
  const _CustomerOrdersRoute({required this.dependencies});
  final AppDependencies dependencies;
  @override
  State<_CustomerOrdersRoute> createState() => _CustomerOrdersRouteState();
}

class _CustomerOrdersRouteState extends State<_CustomerOrdersRoute> {
  @override
  void initState() {
    super.initState();
    widget.dependencies.customerOrders.loadAll();
  }

  @override
  Widget build(BuildContext context) => CustomerOrdersScreen(
    onOpen: (id) => context.push('/orders/$id'),
    onShop: () => context.go('/shop'),
    onProfile: () => context.go('/profile'),
  );
}

class _CustomerOrderRoute extends StatefulWidget {
  const _CustomerOrderRoute({
    required this.dependencies,
    required this.orderId,
  });
  final AppDependencies dependencies;
  final String orderId;

  @override
  State<_CustomerOrderRoute> createState() => _CustomerOrderRouteState();
}

class _CustomerOrderRouteState extends State<_CustomerOrderRoute> {
  @override
  void initState() {
    super.initState();
    final state = widget.dependencies.customerOrders.state;
    final known =
        state.active?.id == widget.orderId ||
        state.orders.any((order) => order.id == widget.orderId);
    if (!known) widget.dependencies.customerOrders.loadAll();
  }

  @override
  Widget build(BuildContext context) =>
      CustomerOrderStatusScreen(orderId: widget.orderId);
}

class _CashierOrdersRoute extends StatefulWidget {
  const _CashierOrdersRoute({
    required this.dependencies,
    required this.onToggleTheme,
  });
  final AppDependencies dependencies;
  final VoidCallback onToggleTheme;
  @override
  State<_CashierOrdersRoute> createState() => _CashierOrdersRouteState();
}

class _CashierOrdersRouteState extends State<_CashierOrdersRoute> {
  @override
  void initState() {
    super.initState();
    widget.dependencies.cashierOrders.load();
    widget.dependencies.cashierOrders.startPolling();
  }

  @override
  void dispose() {
    widget.dependencies.cashierOrders.stopPolling();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => CashierOrdersScreen(
    onOpen: (id) async {
      await context.push('/staff/orders/$id');
      if (context.mounted) widget.dependencies.cashierOrders.load();
    },
    onSignOut: widget.dependencies.session.logout,
    onToggleTheme: widget.onToggleTheme,
  );
}
