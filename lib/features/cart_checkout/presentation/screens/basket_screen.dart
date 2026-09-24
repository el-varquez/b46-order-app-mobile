import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/theme/tokens.dart';
import '../../../../shared/components/customer_shell.dart';
import '../../../../shared/components/pop_icons.dart';
import '../cubit/cart_cubit.dart';

class BasketScreen extends StatelessWidget {
  const BasketScreen({required this.onCheckout, super.key});

  final VoidCallback onCheckout;

  @override
  Widget build(BuildContext context) => CustomerTheme(
    child: Builder(
      builder: (context) => Scaffold(
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(68),
          child: BlocBuilder<CartCubit, CartState>(
            builder: (context, cart) => CustomerHeader(
              title: 'Your basket (${cart.itemCount})',
              back: true,
            ),
          ),
        ),
        body: BlocBuilder<CartCubit, CartState>(
          builder: (context, cart) => ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            children: [
              if (cart.lines.isEmpty) ...[
                const SizedBox(height: 100),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        PopIcons.basket,
                        size: 48,
                        color: CustomerPalette.muted(context),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Your basket is empty',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Add a few neighborhood essentials to continue.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: CustomerPalette.muted(context)),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                if (cart.unavailableIds.isNotEmpty) ...[
                  CustomerCard(
                    child: Row(
                      children: [
                        const Icon(
                          PopIcons.rejected,
                          color: PopColors.authDanger,
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'An item sold out. Remove it before checkout.',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                ...cart.lines.map(
                  (line) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Dismissible(
                      key: ValueKey('basket-line-${line.product.id}'),
                      direction: DismissDirection.endToStart,
                      onDismissed: (_) =>
                          context.read<CartCubit>().remove(line.product.id),
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        decoration: BoxDecoration(
                          color: PopColors.authDanger,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Text(
                          'Remove',
                          style: TextStyle(
                            color: PopColors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      child: CustomerCard(
                        child: Row(
                          children: [
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                color: CustomerPalette.soft(context),
                                borderRadius: BorderRadius.circular(9),
                              ),
                              child: const Icon(PopIcons.groceries, size: 32),
                            ),
                            const SizedBox(width: 11),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    line.product.name,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${_money(line.product.unitPriceCentavos)} each',
                                    style: TextStyle(
                                      color: CustomerPalette.muted(context),
                                      fontSize: 11,
                                    ),
                                  ),
                                  if (cart.unavailableIds.contains(
                                    line.product.id,
                                  ))
                                    const Text(
                                      'Sold out',
                                      style: TextStyle(
                                        color: PopColors.authDanger,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _quantityButton(
                                  context,
                                  PopIcons.minus,
                                  'Decrease quantity',
                                  () => context.read<CartCubit>().decrement(
                                    line.product.id,
                                  ),
                                ),
                                SizedBox(
                                  width: 28,
                                  child: Text(
                                    '${line.quantity}',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                _quantityButton(
                                  context,
                                  PopIcons.plus,
                                  'Increase quantity',
                                  cart.unavailableIds.contains(line.product.id)
                                      ? null
                                      : () => context.read<CartCubit>().add(
                                          line.product,
                                        ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        bottomNavigationBar: BlocBuilder<CartCubit, CartState>(
          builder: (context, cart) => cart.lines.isEmpty
              ? const SizedBox.shrink()
              : SafeArea(
                  top: false,
                  child: Container(
                    key: const Key('basket-footer'),
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    decoration: BoxDecoration(
                      color: CustomerPalette.paper(context),
                      border: Border(
                        top: BorderSide(color: CustomerPalette.line(context)),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _summaryRow(
                          context,
                          'Items',
                          _money(cart.totalCentavos),
                        ),
                        const SizedBox(height: 8),
                        _summaryRow(
                          context,
                          'Delivery inside Bria',
                          'Included',
                        ),
                        Divider(
                          height: 28,
                          color: CustomerPalette.line(context),
                        ),
                        _summaryRow(
                          context,
                          'Total',
                          _money(cart.totalCentavos),
                          total: true,
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            key: const Key('continue-to-checkout'),
                            onPressed: cart.unavailableIds.isEmpty
                                ? onCheckout
                                : null,
                            child: const Text('Continue to checkout'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    ),
  );

  Widget _quantityButton(
    BuildContext context,
    IconData icon,
    String tooltip,
    VoidCallback? action,
  ) => SizedBox(
    width: 36,
    height: 36,
    child: FilledButton(
      onPressed: action,
      style: FilledButton.styleFrom(
        padding: EdgeInsets.zero,
        backgroundColor: CustomerPalette.soft(context),
        foregroundColor: CustomerPalette.ink(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
      ),
      child: Icon(icon, size: 18, semanticLabel: tooltip),
    ),
  );

  Widget _summaryRow(
    BuildContext context,
    String label,
    String value, {
    bool total = false,
  }) => Row(
    children: [
      Expanded(
        child: Text(
          label,
          style: TextStyle(
            color: total
                ? CustomerPalette.ink(context)
                : CustomerPalette.muted(context),
            fontSize: total ? 18 : 14,
            fontWeight: total ? FontWeight.w900 : FontWeight.normal,
          ),
        ),
      ),
      Text(
        value,
        style: TextStyle(
          fontSize: total ? 18 : 14,
          fontWeight: FontWeight.w900,
        ),
      ),
    ],
  );
}

String _money(int centavos) => '₱${(centavos / 100).toStringAsFixed(2)}';
