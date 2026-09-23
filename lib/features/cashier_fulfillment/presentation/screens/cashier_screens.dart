import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/theme/tokens.dart';
import '../../../../shared/components/pop_scaffold.dart';
import '../../domain/entities/cashier_order.dart';
import '../cubit/cashier_orders_cubit.dart';

class CashierOrdersScreen extends StatelessWidget {
  const CashierOrdersScreen({
    required this.onOpen,
    required this.onSignOut,
    super.key,
  });
  final ValueChanged<String> onOpen;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) => PopScaffold(
    appBar: AppBar(
      title: const Text('Orders'),
      actions: [
        IconButton(onPressed: onSignOut, icon: const Icon(Icons.logout)),
      ],
    ),
    child: BlocBuilder<CashierOrdersCubit, CashierOrdersState>(
      builder: (context, state) {
        if (state.loading && state.orders.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state.orders.isEmpty) {
          return const EmptyState(
            title: 'No active orders',
            message: 'New accepted orders will appear here.',
          );
        }
        return RefreshIndicator(
          onRefresh: context.read<CashierOrdersCubit>().load,
          child: ListView.builder(
            padding: const EdgeInsets.all(PopSpace.md),
            itemCount: state.orders.length,
            itemBuilder: (context, index) {
              final order = state.orders[index];
              return Card(
                child: ListTile(
                  onTap: () => onOpen(order.id),
                  leading: order.unread
                      ? const Badge(
                          label: Text('New'),
                          child: Icon(Icons.receipt_long),
                        )
                      : const Icon(Icons.receipt_long),
                  title: Text(
                    order.customerName,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  subtitle: Text(
                    '${_status(order.status)} · ${order.lines.length} items',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                ),
              );
            },
          ),
        );
      },
    ),
  );
}

class CashierOrderDetailScreen extends StatelessWidget {
  const CashierOrderDetailScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<CashierOrderDetailCubit, CashierOrderDetailState>(
        builder: (context, state) {
          final order = state.order;
          return PopScaffold(
            appBar: AppBar(title: const Text('Order details')),
            bottomNavigationBar: order?.nextAction == null
                ? null
                : SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.all(PopSpace.md),
                      child: FilledButton(
                        onPressed: state.advancing
                            ? null
                            : context.read<CashierOrderDetailCubit>().advance,
                        child: Text(
                          state.advancing
                              ? 'Updating…'
                              : _action(order!.nextAction!),
                        ),
                      ),
                    ),
                  ),
            child: order == null
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    padding: const EdgeInsets.all(PopSpace.lg),
                    children: [
                      Text(
                        _status(order.status),
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: PopSpace.md),
                      Text(
                        order.customerName,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Text(order.deliveryAddress),
                      if (order.deliveryNotes.isNotEmpty)
                        Text('Note: ${order.deliveryNotes}'),
                      const SizedBox(height: PopSpace.lg),
                      ...order.lines.map(
                        (line) => ListTile(
                          title: Text(line.name),
                          trailing: Text('× ${line.quantity}'),
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
                      if (state.message != null)
                        Text(state.message!, textAlign: TextAlign.center),
                    ],
                  ),
          );
        },
      );
}

String _status(FulfillmentStatus status) => switch (status) {
  FulfillmentStatus.preparing => 'Preparing',
  FulfillmentStatus.delivering => 'Delivering',
  FulfillmentStatus.delivered => 'Delivered',
};
String _action(FulfillmentStatus status) => switch (status) {
  FulfillmentStatus.delivering => 'Out for delivery',
  FulfillmentStatus.delivered => 'Mark delivered',
  FulfillmentStatus.preparing => 'Preparing',
};
String _money(int centavos) => '₱${(centavos / 100).toStringAsFixed(2)}';
