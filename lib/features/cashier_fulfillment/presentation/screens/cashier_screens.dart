import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/theme/tokens.dart';
import '../../../../shared/components/customer_shell.dart';
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
  Widget build(BuildContext context) => CustomerTheme(
    child: PopScaffold(
      appBar: CustomerHeader(
        title: 'Orders',
        subtitle: 'Cashier',
        action: IconButton(
          tooltip: 'Switch appearance',
          onPressed: onToggleTheme,
          icon: const Icon(PopIcons.theme),
        ),
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
              if (state.filter == null)
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
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Store orders',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Text(
                      'Accepted orders only',
                      style: TextStyle(
                        color: CustomerPalette.muted(context),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 48,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: PopSpace.md),
                  children: [
                    _filter(context, 'All', null, state.filter, cubit),
                    _filter(
                      context,
                      'Preparing',
                      FulfillmentStatus.preparing,
                      state.filter,
                      cubit,
                    ),
                    _filter(
                      context,
                      'Delivering',
                      FulfillmentStatus.delivering,
                      state.filter,
                      cubit,
                    ),
                    _filter(
                      context,
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
                _Notice(
                  text: state.message!,
                  isError: true,
                  onRetry: cubit.load,
                ),
              if (state.loading && state.orders.isEmpty)
                const Expanded(
                  child: Center(child: CircularProgressIndicator()),
                )
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
                              _SignOutButton(onPressed: onSignOut),
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
                                (state.nextAfterId == null ? 0 : 1) +
                                1,
                            itemBuilder: (context, index) {
                              if (index ==
                                  state.orders.length +
                                      (state.nextAfterId == null ? 0 : 1)) {
                                return _SignOutButton(onPressed: onSignOut);
                              }
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
    ),
  );

  Widget _filter(
    BuildContext context,
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
      showCheckmark: false,
      backgroundColor: CustomerPalette.surface(context),
      selectedColor: PopColors.launchRed,
      labelStyle: TextStyle(
        color: selected == value
            ? PopColors.white
            : CustomerPalette.ink(context),
        fontSize: 11,
        fontWeight: FontWeight.w800,
      ),
      side: BorderSide(
        color: selected == value
            ? PopColors.launchRed
            : CustomerPalette.line(context),
      ),
      shape: const StadiumBorder(),
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
  Widget build(BuildContext context) => CustomerTheme(
    child: BlocBuilder<CashierOrderDetailCubit, CashierOrderDetailState>(
      builder: (context, state) {
        final order = state.order;
        final cubit = context.read<CashierOrderDetailCubit>();
        return PopScaffold(
          appBar: CustomerHeader(
            title: 'Order details',
            subtitle: _orderLabel(orderId),
            back: true,
            action: IconButton(
              tooltip: 'Switch appearance',
              onPressed: onToggleTheme,
              icon: const Icon(PopIcons.theme),
            ),
          ),
          bottomNavigationBar: order == null
              ? null
              : SafeArea(
                  top: false,
                  child: Container(
                    padding: const EdgeInsets.all(PopSpace.md),
                    decoration: BoxDecoration(
                      color: CustomerPalette.paper(context),
                      border: Border(
                        top: BorderSide(color: CustomerPalette.line(context)),
                      ),
                    ),
                    child: SizedBox(
                      width: double.infinity,
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
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                              ),
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
                        title: 'Products',
                        trailing: '${order.lines.length} lines',
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
                                        color: CustomerPalette.soft(context),
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
                                            style: TextStyle(
                                              color: CustomerPalette.muted(
                                                context,
                                              ),
                                              fontSize: 12,
                                            ),
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
                      Divider(color: CustomerPalette.line(context)),
                      const SizedBox(height: PopSpace.xs),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Payment',
                              style: TextStyle(
                                color: CustomerPalette.muted(context),
                              ),
                            ),
                          ),
                          const Text(
                            'Cash on delivery',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                      const SizedBox(height: PopSpace.sm),
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Total',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          Text(
                            _money(order.totalCentavos),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
        );
      },
    ),
  );
}

class _SignOutButton extends StatelessWidget {
  const _SignOutButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: PopSpace.md),
    child: SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: CustomerPalette.ink(context),
          side: BorderSide(color: CustomerPalette.line(context)),
          backgroundColor: CustomerPalette.surface(context),
        ),
        child: const Text('Sign out'),
      ),
    ),
  );
}

class _CountCard extends StatelessWidget {
  const _CountCard({required this.label, required this.count});
  final String label;
  final int count;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(PopSpace.sm),
    decoration: BoxDecoration(
      color: CustomerPalette.surface(context),
      border: Border.all(color: CustomerPalette.line(context)),
      borderRadius: BorderRadius.circular(PopRadius.sm),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$count',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: PopSpace.xxs),
        Text(
          label,
          style: TextStyle(color: CustomerPalette.muted(context), fontSize: 10),
        ),
      ],
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
    color: CustomerPalette.surface(context),
    elevation: 2,
    shadowColor: CustomerPalette.ink(context).withValues(alpha: 0.16),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
      side: BorderSide(
        color: order.unread
            ? PopColors.launchRed
            : CustomerPalette.line(context),
      ),
    ),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
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
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: PopSpace.xxs),
            Text(
              '${_itemCount(order.lines)} items · ${order.deliveryAddress}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: CustomerPalette.muted(context),
                fontSize: 11,
              ),
            ),
            const SizedBox(height: PopSpace.md),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Cash on delivery',
                    style: TextStyle(
                      color: CustomerPalette.muted(context),
                      fontSize: 11,
                    ),
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
    padding: const EdgeInsets.all(17),
    decoration: const BoxDecoration(
      color: PopColors.launchRed,
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(12),
        topRight: Radius.circular(45),
        bottomLeft: Radius.circular(12),
        bottomRight: Radius.circular(12),
      ),
      boxShadow: [
        BoxShadow(color: PopColors.launchShadow, offset: Offset(7, 7)),
      ],
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
          style: const TextStyle(
            color: PopColors.white,
            fontSize: 28,
            fontWeight: FontWeight.w900,
          ),
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
  const _SectionCard({required this.title, required this.child, this.trailing});
  final String title;
  final Widget child;
  final String? trailing;

  @override
  Widget build(BuildContext context) => CustomerCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            if (trailing != null)
              Text(
                trailing!,
                style: TextStyle(
                  color: CustomerPalette.muted(context),
                  fontSize: 11,
                ),
              ),
          ],
        ),
        const SizedBox(height: PopSpace.sm),
        child,
      ],
    ),
  );
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});
  final FulfillmentStatus status;

  @override
  Widget build(BuildContext context) {
    final delivered = status == FulfillmentStatus.delivered;
    final color = delivered ? PopColors.success : CustomerPalette.ink(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: PopSpace.xs,
        vertical: PopSpace.xxs,
      ),
      decoration: BoxDecoration(
        color: delivered
            ? PopColors.success.withValues(alpha: 0.14)
            : CustomerPalette.soft(context),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        _status(status),
        style: TextStyle(
          color: color,
          fontSize: 10,
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
      color: PopColors.launchRed,
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
