import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/theme/tokens.dart';
import '../../../../shared/components/pop_icons.dart';
import '../../../../shared/components/pop_scaffold.dart';
import '../../domain/entities/customer_order.dart';
import '../cubit/customer_orders_cubit.dart';

class CustomerOrdersScreen extends StatelessWidget {
  const CustomerOrdersScreen({required this.onOpen, super.key});
  final ValueChanged<String> onOpen;

  @override
  Widget build(BuildContext context) => PopScaffold(
    appBar: AppBar(
      leading: const PopBackButton(),
      title: const Text('My orders'),
    ),
    child: BlocBuilder<CustomerOrdersCubit, CustomerOrdersState>(
      builder: (context, state) {
        if (state.status == CustomerOrdersStatus.loading &&
            state.orders.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state.orders.isEmpty && state.active == null) {
          return const EmptyState(
            title: 'No orders yet',
            message: 'Your placed orders will appear here.',
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
            padding: const EdgeInsets.all(PopSpace.md),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              return Card(
                child: ListTile(
                  onTap: () => onOpen(order.id),
                  title: Text(
                    _label(order.status),
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  subtitle: Text(
                    '${order.lines.length} item${order.lines.length == 1 ? '' : 's'} · ${_money(order.totalCentavos)}',
                  ),
                  trailing: const Icon(PopIcons.forward),
                ),
              );
            },
          ),
        );
      },
    ),
  );
}

class CustomerOrderStatusScreen extends StatelessWidget {
  const CustomerOrderStatusScreen({required this.orderId, super.key});
  final String orderId;

  @override
  Widget build(BuildContext context) => PopScaffold(
    appBar: AppBar(
      leading: const PopBackButton(),
      title: const Text('Order status'),
    ),
    child: BlocBuilder<CustomerOrdersCubit, CustomerOrdersState>(
      builder: (context, state) {
        final order = state.active?.id == orderId
            ? state.active
            : state.orders.where((value) => value.id == orderId).firstOrNull;
        if (order == null) {
          return const Center(child: CircularProgressIndicator());
        }
        return ListView(
          padding: const EdgeInsets.all(PopSpace.lg),
          children: [
            Icon(
              _icon(order.status),
              size: 72,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: PopSpace.lg),
            Text(
              _label(order.status),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium
                  ?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: PopSpace.sm),
            Text(_message(order.status), textAlign: TextAlign.center),
            const SizedBox(height: PopSpace.lg),
            ...order.lines.map(
              (line) => ListTile(
                title: Text(line.productName),
                subtitle: Text(
                  '${line.quantity} × ${_money(line.unitPriceCentavos)}',
                ),
              ),
            ),
            const Divider(),
            ListTile(
              title: const Text('Cash on delivery'),
              trailing: Text(
                _money(order.totalCentavos),
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
            if (order.status == CustomerOrderStatus.rejected)
              const Padding(
                padding: EdgeInsets.only(top: PopSpace.md),
                child: Text(
                  'The unavailable items are marked in your basket. Remove or replace them, then place a new order.',
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        );
      },
    ),
  );
}

String _label(CustomerOrderStatus status) => switch (status) {
  CustomerOrderStatus.preparing => 'Preparing your order',
  CustomerOrderStatus.onTheWay => 'On the way',
  CustomerOrderStatus.delivered => 'Delivered',
  CustomerOrderStatus.rejected => 'Some items sold out',
};

String _message(CustomerOrderStatus status) => switch (status) {
  CustomerOrderStatus.preparing => 'The store is getting your items ready.',
  CustomerOrderStatus.onTheWay => 'Your order is heading to your Bria address.',
  CustomerOrderStatus.delivered => 'Your order has arrived. Enjoy!',
  CustomerOrderStatus.rejected =>
    'Another shopper got there first. Your basket is ready to correct.',
};

IconData _icon(CustomerOrderStatus status) => switch (status) {
  CustomerOrderStatus.preparing => PopIcons.preparing,
  CustomerOrderStatus.onTheWay => PopIcons.delivering,
  CustomerOrderStatus.delivered => PopIcons.delivered,
  CustomerOrderStatus.rejected => PopIcons.rejected,
};

String _money(int centavos) => '₱${(centavos / 100).toStringAsFixed(2)}';
