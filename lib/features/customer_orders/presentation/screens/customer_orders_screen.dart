import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/theme/tokens.dart';
import '../../../../shared/components/customer_shell.dart';
import '../../../../shared/components/pop_icons.dart';
import '../../domain/entities/customer_order.dart';
import '../cubit/customer_orders_cubit.dart';

class CustomerOrdersScreen extends StatelessWidget {
  const CustomerOrdersScreen({
    required this.onOpen,
    this.onShop,
    this.onProfile,
    super.key,
  });
  final ValueChanged<String> onOpen;
  final VoidCallback? onShop;
  final VoidCallback? onProfile;

  @override
  Widget build(BuildContext context) => CustomerTheme(
    child: Builder(
      builder: (context) => Scaffold(
        appBar: const CustomerHeader(title: 'My orders', back: true),
        bottomNavigationBar: onShop == null || onProfile == null
            ? null
            : CustomerBottomNav(
                selected: 'Orders',
                onShop: onShop!,
                onOrders: () {},
                onProfile: onProfile!,
              ),
        body: BlocBuilder<CustomerOrdersCubit, CustomerOrdersState>(
          builder: (context, state) {
            if (state.status == CustomerOrdersStatus.loading &&
                state.orders.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state.orders.isEmpty && state.active == null) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(30),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        PopIcons.orders,
                        size: 48,
                        color: CustomerPalette.muted(context),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'No orders yet',
                        style: TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        'Your active and recent orders will appear here.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: CustomerPalette.muted(context)),
                      ),
                      if (onShop != null) ...[
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: onShop,
                          child: const Text('Shop now'),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }
            final orders =
                state.active == null ||
                    state.orders.any((order) => order.id == state.active!.id)
                ? state.orders
                : [state.active!, ...state.orders];
            return RefreshIndicator(
              onRefresh: context.read<CustomerOrdersCubit>().loadAll,
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                itemCount: orders.length,
                itemBuilder: (context, index) {
                  final order = orders[index];
                  final rejected = order.status == CustomerOrderStatus.rejected;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: CustomerCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  order.id,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 9,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: rejected
                                      ? PopColors.authDanger.withValues(
                                          alpha: 0.15,
                                        )
                                      : PopColors.success.withValues(
                                          alpha: 0.14,
                                        ),
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                child: Text(
                                  _shortLabel(order.status),
                                  style: TextStyle(
                                    color: rejected
                                        ? PopColors.authDanger
                                        : PopColors.success,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 7),
                          Text(
                            '${order.lines.length} product line${order.lines.length == 1 ? '' : 's'} · Cash on delivery',
                            style: TextStyle(
                              color: CustomerPalette.muted(context),
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _money(order.totalCentavos),
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 10),
                          OutlinedButton(
                            onPressed: () => onOpen(order.id),
                            child: const Text('View status'),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    ),
  );
}

class CustomerOrderStatusScreen extends StatelessWidget {
  const CustomerOrderStatusScreen({required this.orderId, super.key});
  final String orderId;

  @override
  Widget build(BuildContext context) => CustomerTheme(
    child: Builder(
      builder: (context) => Scaffold(
        appBar: CustomerHeader(title: 'Order status', back: true),
        body: BlocBuilder<CustomerOrdersCubit, CustomerOrdersState>(
          builder: (context, state) {
            final order = state.active?.id == orderId
                ? state.active
                : state.orders
                      .where((value) => value.id == orderId)
                      .firstOrNull;
            if (order == null) {
              return const Center(child: CircularProgressIndicator());
            }
            final rejected = order.status == CustomerOrderStatus.rejected;
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 30, 16, 32),
              children: [
                Center(
                  child: Container(
                    width: 94,
                    height: 94,
                    decoration: BoxDecoration(
                      color: CustomerPalette.soft(context),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _icon(order.status),
                      key: const Key('order-status-icon'),
                      size: 43,
                      color: rejected
                          ? PopColors.authDanger
                          : PopColors.success,
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                Text(
                  _label(order.status),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 31,
                    height: 1.1,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _message(order.status),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: CustomerPalette.muted(context),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 22),
                CustomerCard(
                  child: Row(
                    children: [
                      const Icon(PopIcons.delivered, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              order.id,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              'Cash on delivery · ${_money(order.totalCentavos)}',
                              style: TextStyle(
                                color: CustomerPalette.muted(context),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (!rejected) ...[
                  const SizedBox(height: 23),
                  _timeline(context, order.status),
                ],
                const SizedBox(height: 10),
                CustomerCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Products',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ...order.lines.map(
                        (line) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 7),
                          child: Row(
                            children: [
                              Expanded(child: Text(line.productName)),
                              Text(
                                '×${line.quantity} · ${_money(line.unitPriceCentavos * line.quantity)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (rejected) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'The unavailable items are marked in your basket. Remove or replace them, then place a new order.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            );
          },
        ),
      ),
    ),
  );

  Widget _timeline(BuildContext context, CustomerOrderStatus status) {
    final current = switch (status) {
      CustomerOrderStatus.preparing => 0,
      CustomerOrderStatus.onTheWay => 1,
      CustomerOrderStatus.delivered => 2,
      CustomerOrderStatus.rejected => 0,
    };
    const steps = [
      ('Preparing', 'B46 is gathering your items'),
      ('Delivering', 'Your rider is on the way'),
      ('Delivered', 'Your order has arrived'),
    ];
    return Column(
      children: [
        for (var index = 0; index < steps.length; index++)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    key: Key('order-step-$index'),
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: index <= current
                          ? PopColors.success
                          : CustomerPalette.soft(context),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: index <= current
                          ? const Icon(
                              PopIcons.check,
                              size: 13,
                              color: PopColors.white,
                            )
                          : Text(
                              '${index + 1}',
                              style: TextStyle(
                                color: CustomerPalette.ink(context),
                                fontSize: 11,
                              ),
                            ),
                    ),
                  ),
                  if (index < steps.length - 1)
                    Container(
                      width: 2,
                      height: 38,
                      color: index < current
                          ? PopColors.success
                          : CustomerPalette.line(context),
                    ),
                ],
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      steps[index].$1,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    Text(
                      steps[index].$2,
                      style: TextStyle(
                        color: CustomerPalette.muted(context),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
      ],
    );
  }
}

String _shortLabel(CustomerOrderStatus status) => switch (status) {
  CustomerOrderStatus.preparing => 'Preparing',
  CustomerOrderStatus.onTheWay => 'On the way',
  CustomerOrderStatus.delivered => 'Delivered',
  CustomerOrderStatus.rejected => 'Not placed',
};

String _label(CustomerOrderStatus status) => switch (status) {
  CustomerOrderStatus.preparing => 'Preparing your order',
  CustomerOrderStatus.onTheWay => 'Your order is on the way',
  CustomerOrderStatus.delivered => 'Order delivered',
  CustomerOrderStatus.rejected => 'An item sold out',
};

String _message(CustomerOrderStatus status) => switch (status) {
  CustomerOrderStatus.preparing =>
    'Your order was placed. B46 is getting everything ready.',
  CustomerOrderStatus.onTheWay =>
    'Your rider is delivering your order inside Bria.',
  CustomerOrderStatus.delivered =>
    'Your order has arrived. Thanks for shopping with B46.',
  CustomerOrderStatus.rejected =>
    'Your order was not placed. Review the marked items in your basket.',
};

IconData _icon(CustomerOrderStatus status) => switch (status) {
  CustomerOrderStatus.preparing => PopIcons.preparing,
  CustomerOrderStatus.onTheWay => PopIcons.delivering,
  CustomerOrderStatus.delivered => PopIcons.delivered,
  CustomerOrderStatus.rejected => PopIcons.rejected,
};

String _money(int centavos) => '₱${(centavos / 100).toStringAsFixed(2)}';
