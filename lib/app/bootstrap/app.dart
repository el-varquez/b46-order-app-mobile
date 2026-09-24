import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../features/authentication/domain/entities/session.dart';
import '../../features/authentication/presentation/cubit/session_cubit.dart';
import '../../features/cart_checkout/presentation/cubit/cart_cubit.dart';
import '../../features/customer_orders/domain/entities/customer_order.dart';
import '../../features/customer_orders/presentation/cubit/customer_orders_cubit.dart';
import '../routing/app_router.dart';
import '../theme/app_theme.dart';
import '../theme/theme_cubit.dart';
import 'dependencies.dart';

class B46App extends StatefulWidget {
  const B46App({required this.dependencies, super.key});
  final AppDependencies dependencies;

  @override
  State<B46App> createState() => _B46AppState();
}

class _B46AppState extends State<B46App> with WidgetsBindingObserver {
  late final router = createRouter(widget.dependencies, _toggleTheme);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.dependencies.session.restore();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    router.dispose();
    widget.dependencies.close();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final role = widget.dependencies.session.state.session?.user.role;
    if (state == AppLifecycleState.resumed) {
      if (role == UserRole.customer) {
        widget.dependencies.customerOrders.refreshActive();
      }
      if (role == UserRole.cashier) {
        widget.dependencies.cashierOrders.load(quiet: true);
        widget.dependencies.cashierOrders.startPolling();
      }
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      widget.dependencies.customerOrders.stopPolling();
      widget.dependencies.cashierOrders.stopPolling();
    }
  }

  void _toggleTheme() => widget.dependencies.theme.toggle(
    MediaQuery.platformBrightnessOf(context),
  );

  @override
  Widget build(BuildContext context) => MultiBlocProvider(
    providers: [
      BlocProvider.value(value: widget.dependencies.session),
      BlocProvider.value(value: widget.dependencies.registration),
      BlocProvider.value(value: widget.dependencies.theme),
      BlocProvider.value(value: widget.dependencies.catalog),
      BlocProvider.value(value: widget.dependencies.cart),
      BlocProvider.value(value: widget.dependencies.customerOrders),
      BlocProvider.value(value: widget.dependencies.cashierOrders),
      BlocProvider.value(value: widget.dependencies.adminCashiers),
    ],
    child: MultiBlocListener(
      listeners: [
        BlocListener<SessionCubit, SessionState>(
          listener: (context, state) {
            if (state.status == SessionStatus.signedOut) {
              widget.dependencies.customerOrders.stopPolling();
              widget.dependencies.cashierOrders.stopPolling();
              widget.dependencies.adminCashiers.clear();
              context.read<CartCubit>().clear();
            }
          },
        ),
        BlocListener<CustomerOrdersCubit, CustomerOrdersState>(
          listenWhen: (previous, current) =>
              previous.active?.status != current.active?.status,
          listener: (context, state) {
            final order = state.active;
            if (order?.status == CustomerOrderStatus.rejected) {
              context.read<CartCubit>().markUnavailable(
                order!.unavailableProductIds,
              );
            }
            if (order?.status == CustomerOrderStatus.preparing ||
                order?.status == CustomerOrderStatus.onTheWay ||
                order?.status == CustomerOrderStatus.delivered) {
              context.read<CartCubit>().clear();
            }
          },
        ),
      ],
      child: BlocBuilder<ThemeCubit, ThemeMode>(
        builder: (_, mode) => MaterialApp.router(
          title: 'B46',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: mode,
          routerConfig: router,
        ),
      ),
    ),
  );
}
