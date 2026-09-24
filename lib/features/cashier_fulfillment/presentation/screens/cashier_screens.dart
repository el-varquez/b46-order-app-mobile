import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/theme/tokens.dart';
import '../../../../shared/components/pop_icons.dart';
import '../../../../shared/components/pop_scaffold.dart';
import '../../domain/entities/cashier_order.dart';
import '../cubit/cashier_orders_cubit.dart';

class CashierOrdersScreen extends StatelessWidget {
  const CashierOrdersScreen({
    required this.onOpen,
    required this.onSignOut,
    required this.onToggleTheme,
    super.key,
  });

  final ValueChanged<String> onOpen;
  final VoidCallback onSignOut;
  final VoidCallback onToggleTheme;

  @override
  Widget build(BuildContext context) => PopScaffold(
    appBar: AppBar(
      leadingWidth: 76,
      leading: const Center(child: B46Mark()),
      title: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Cashier', style: TextStyle(fontSize: 12)),
          Text('Orders', style: TextStyle(fontWeight: FontWeight.w900)),
        ],
      ),
      actions: [
        IconButton(
          tooltip: 'Switch appearance',
          onPressed: onToggleTheme,
          icon: const Icon(PopIcons.theme),
        ),
        IconButton(
          tooltip: 'Sign out',
          onPressed: onSignOut,
          icon: const Icon(PopIcons.signOut),
        ),
      ],
    ),
    child: BlocBuilder<CashierOrdersCubit, CashierOrdersState>(
      builder: (context, state) {
        final cubit = context.read<CashierOrdersCubit>();
        final preparing = state.orders
            .where((order) => order.status == FulfillmentStatus.preparing)
            .length;
        final delivering = state.orders
            .where((order) => order.status == FulfillmentStatus.delivering)
            .length;
        final delivered = state.orders
            .where((order) => order.status == FulfillmentStatus.delivered)
            .length;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (state.filter == null && state.orders.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  PopSpace.md,
                  PopSpace.sm,
                  PopSpace.md,
                  0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Recent ${state.orders.length} orders',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                    const SizedBox(height: PopSpace.xs),
                    Row(
                      children: [
                        Expanded(
                          child: _CountCard(
                            label: 'Preparing',
                            count: preparing,
                          ),
                        ),
                        const SizedBox(width: PopSpace.xs),
                        Expanded(
                          child: _CountCard(
                            label: 'Delivering',
                            count: delivering,
                          ),
                        ),
                        const SizedBox(width: PopSpace.xs),
                        Expanded(
                          child: _CountCard(
                            label: 'Delivered',
                            count: delivered,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                PopSpace.md,
                PopSpace.md,
                PopSpace.md,
                PopSpace.xs,
              ),
              child: Text(
                'Store orders',
                style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w900),
              ),
            ),
            SizedBox(
              height: 48,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: PopSpace.md),
                children: [
                  _filter('All', null, state.filter, cubit),
                  _filter(
                    'Preparing',
                    FulfillmentStatus.preparing,
                    state.filter,
                    cubit,
                  ),
                  _filter(
                    'Delivering',
                    FulfillmentStatus.delivering,
                    state.filter,
                    cubit,
                  ),
                  _filter(
                    'Delivered',
                    FulfillmentStatus.delivered,
                    state.filter,
                    cubit,
                  ),
                ],
              ),
            ),
            if (state.newOrderCount > 0)
              _Notice(
                text: state.newOrderCount == 1
                    ? 'A new order is ready to prepare.'
                    : '${state.newOrderCount} new orders are ready to prepare.',
                isError: false,
              ),
            if (state.message != null)
              _Notice(text: state.message!, isError: true, onRetry: cubit.load),
            if (state.loading && state.orders.isEmpty)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else
              Expanded(
                child: RefreshIndicator(
                  onRefresh: cubit.load,
                  child: state.orders.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            EmptyState(
                              title: state.message == null
                                  ? 'No orders here yet'
                                  : 'Orders could not load',
                              message: state.message == null
                                  ? 'Accepted orders will appear here. Pull down to check again.'
                                  : 'Check your connection, then pull down or tap Retry.',
                            ),
                          ],
                        )
                      : ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(
                            PopSpace.md,
                            PopSpace.xs,
                            PopSpace.md,
                            PopSpace.lg,
                          ),
                          itemCount:
                              state.orders.length +
                              (state.nextAfterId == null ? 0 : 1),
                          itemBuilder: (context, index) {
                            if (index == state.orders.length) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: PopSpace.md,
                                ),
                                child: OutlinedButton(
                                  onPressed: state.loadingMore
                                      ? null
                                      : cubit.loadMore,
                                  child: Text(
                                    state.loadingMore
                                        ? 'Loading…'
                                        : 'Load more orders',
                                  ),
                                ),
                              );
                            }
                            return _OrderCard(
                              order: state.orders[index],
                              onTap: () => onOpen(state.orders[index].id),
                            );
                          },
                        ),
                ),
              ),
          ],
        );
      },
    ),
  );

  Widget _filter(
    String label,
    FulfillmentStatus? value,
    FulfillmentStatus? selected,
    CashierOrdersCubit cubit,
  ) => Padding(
    padding: const EdgeInsets.only(right: PopSpace.xs),
    child: ChoiceChip(
      label: Text(label),
      selected: selected == value,
      onSelected: (_) => cubit.selectFilter(value),
    ),
  );
}

class CashierOrderDetailScreen extends StatelessWidget {
  const CashierOrderDetailScreen({
    required this.orderId,
    required this.onToggleTheme,
    super.key,
  });

  final String orderId;
  final VoidCallback onToggleTheme;

  @override
  Widget build(
    BuildContext context,
  ) => BlocBuilder<CashierOrderDetailCubit, CashierOrderDetailState>(
    builder: (context, state) {
      final order = state.order;
      final cubit = context.read<CashierOrderDetailCubit>();
      return PopScaffold(
        appBar: AppBar(
          leading: const PopBackButton(),
          title: const Text('Order details'),
          actions: [
            IconButton(
              tooltip: 'Switch appearance',
              onPressed: onToggleTheme,
              icon: const Icon(PopIcons.theme),
            ),
          ],
        ),
        bottomNavigationBar: order == null
            ? null
            : SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.all(PopSpace.md),
                  child: order.nextAction == null
                      ? OutlinedButton(
                          onPressed: null,
                          child: const Text('Delivered · Read only'),
                        )
                      : FilledButton(
                          onPressed: state.advancing || state.loading
                              ? null
                              : cubit.advance,
                          child: Text(
                            state.advancing
                                ? 'Updating…'
                                : _action(order.nextAction!),
                          ),
                        ),
                ),
              ),
        child: order == null
            ? state.loading
                  ? const Center(child: CircularProgressIndicator())
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const EmptyState(
                          title: 'Order could not load',
                          message: 'Check your connection and try again.',
                        ),
                        OutlinedButton(
                          onPressed: () => cubit.load(orderId),
                          child: const Text('Retry'),
                        ),
                      ],
                    )
            : RefreshIndicator(
                onRefresh: () => cubit.load(orderId),
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(
                    PopSpace.md,
                    PopSpace.sm,
                    PopSpace.md,
                    PopSpace.lg,
                  ),
                  children: [
                    _CustomerStatusHero(order: order),
                    const SizedBox(height: PopSpace.lg),
                    if (state.message != null) ...[
                      _Notice(
                        text: state.message!,
                        isError: !state.message!.startsWith(
                          'This order changed.',
                        ),
                        onRetry: () => cubit.load(orderId),
                      ),
                      const SizedBox(height: PopSpace.sm),
                    ],
                    _SectionCard(
                      title: 'Customer & delivery',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            order.customerName,
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: PopSpace.xs),
                          Text(order.deliveryAddress),
                          if (order.deliveryNotes.isNotEmpty) ...[
                            const SizedBox(height: PopSpace.sm),
                            Text('Note: ${order.deliveryNotes}'),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: PopSpace.sm),
                    _SectionCard(
                      title: 'Products · ${order.lines.length} lines',
                      child: Column(
                        children: [
                          for (final line in order.lines)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: PopSpace.sm,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary
                                          .withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(
                                        PopRadius.sm,
                                      ),
                                    ),
                                    child: const Icon(PopIcons.preparing),
                                  ),
                                  const SizedBox(width: PopSpace.sm),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          line.name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        Text(
                                          order.status ==
                                                  FulfillmentStatus.preparing
                                              ? 'Prepare and verify'
                                              : 'Order item',
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    '×${line.quantity}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: PopSpace.sm),
                    _SectionCard(
                      title: 'Payment',
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Cash on delivery'),
                          Text(
                            _money(order.totalCentavos),
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      );
    },
  );
}

class _CountCard extends StatelessWidget {
  const _CountCard({required this.label, required this.count});
  final String label;
  final int count;

  @override
  Widget build(BuildContext context) => Card(
    margin: EdgeInsets.zero,
    child: Padding(
      padding: const EdgeInsets.all(PopSpace.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$count',
            style: Theme.of(context).textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w900),
          ),
          Text(label, style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
    ),
  );
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order, required this.onTap});
  final CashierOrder order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: PopSpace.sm),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(PopRadius.md),
      side: BorderSide(
        color: order.unread
            ? PopColors.brandRed
            : Theme.of(context).colorScheme.outline.withValues(alpha: 0.35),
        width: order.unread ? 2 : 1,
      ),
    ),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(PopRadius.md),
      child: Padding(
        padding: const EdgeInsets.all(PopSpace.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    _orderLabel(order.id),
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
                if (order.unread) ...[
                  const _NewPill(),
                  const SizedBox(width: PopSpace.xs),
                ],
                _StatusPill(status: order.status),
              ],
            ),
            const SizedBox(height: PopSpace.sm),
            Text(
              order.customerName,
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: PopSpace.xxs),
            Text(
              '${_itemCount(order.lines)} items · ${order.deliveryAddress}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: PopSpace.md),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Cash on delivery',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                Text(
                  _money(order.totalCentavos),
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(width: PopSpace.xs),
                const Icon(PopIcons.forward, size: 18),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class _CustomerStatusHero extends StatelessWidget {
  const _CustomerStatusHero({required this.order});
  final CashierOrder order;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(PopSpace.lg),
    decoration: const BoxDecoration(
      color: PopColors.brandRed,
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(PopRadius.sm),
        topRight: Radius.circular(44),
        bottomLeft: Radius.circular(PopRadius.sm),
        bottomRight: Radius.circular(PopRadius.sm),
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Customer sees', style: TextStyle(color: PopColors.white)),
        const SizedBox(height: PopSpace.xs),
        Text(
          switch (order.status) {
            FulfillmentStatus.preparing => 'Preparing',
            FulfillmentStatus.delivering => 'On the way',
            FulfillmentStatus.delivered => 'Delivered',
          },
          style: Theme.of(context).textTheme.headlineMedium
              ?.copyWith(color: PopColors.white, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: PopSpace.xs),
        Text(
          '${_orderLabel(order.id)} · ${_placedAt(context, order.createdAt)}',
          style: const TextStyle(color: PopColors.white),
        ),
      ],
    ),
  );
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Card(
    margin: EdgeInsets.zero,
    child: Padding(
      padding: const EdgeInsets.all(PopSpace.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: PopSpace.sm),
          child,
        ],
      ),
    ),
  );
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});
  final FulfillmentStatus status;

  @override
  Widget build(BuildContext context) {
    final color = status == FulfillmentStatus.delivered
        ? PopColors.success
        : status == FulfillmentStatus.delivering
        ? PopColors.warning
        : PopColors.brandRed;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: PopSpace.xs,
        vertical: PopSpace.xxs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        _status(status),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _NewPill extends StatelessWidget {
  const _NewPill();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(
      horizontal: PopSpace.xs,
      vertical: PopSpace.xxs,
    ),
    decoration: BoxDecoration(
      color: PopColors.brandRed,
      borderRadius: BorderRadius.circular(99),
    ),
    child: const Text(
      'NEW',
      style: TextStyle(
        color: PopColors.white,
        fontSize: 11,
        fontWeight: FontWeight.w900,
      ),
    ),
  );
}

class _Notice extends StatelessWidget {
  const _Notice({required this.text, required this.isError, this.onRetry});
  final String text;
  final bool isError;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(
      PopSpace.md,
      PopSpace.xs,
      PopSpace.md,
      PopSpace.xs,
    ),
    child: DecoratedBox(
      decoration: BoxDecoration(
        color:
            (isError ? Theme.of(context).colorScheme.error : PopColors.success)
                .withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(PopRadius.sm),
      ),
      child: Padding(
        padding: const EdgeInsets.all(PopSpace.sm),
        child: Row(
          children: [
            Expanded(child: Text(text)),
            if (onRetry != null)
              TextButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    ),
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

String _orderLabel(String id) => 'Order #${id.split('-').first.toUpperCase()}';
String _money(int centavos) => '₱${(centavos / 100).toStringAsFixed(2)}';
int _itemCount(List<CashierOrderLine> lines) =>
    lines.fold(0, (total, line) => total + line.quantity);

String _placedAt(BuildContext context, DateTime createdAt) {
  final local = createdAt.toLocal();
  final format = MaterialLocalizations.of(context);
  return '${format.formatMediumDate(local)} · ${format.formatTimeOfDay(TimeOfDay.fromDateTime(local))}';
}
