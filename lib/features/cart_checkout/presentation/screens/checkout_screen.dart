import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/theme/tokens.dart';
import '../../../../shared/components/pop_icons.dart';
import '../../../../shared/components/pop_scaffold.dart';
import '../cubit/cart_cubit.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({
    required this.placing,
    required this.message,
    required this.onPlace,
    super.key,
  });

  final bool placing;
  final String? message;
  final Future<void> Function(String address, String notes) onPlace;

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final address = TextEditingController(text: 'Block 12, Bria Homes');
  final notes = TextEditingController();

  @override
  void dispose() {
    address.dispose();
    notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PopScaffold(
    appBar: AppBar(
      leading: const PopBackButton(),
      title: const Text('Review basket'),
    ),
    child: BlocBuilder<CartCubit, CartState>(
      builder: (context, cart) => ListView(
        padding: const EdgeInsets.all(PopSpace.md),
        children: [
          if (cart.lines.isEmpty)
            const EmptyState(
              title: 'Your basket is empty',
              message: 'Add something from the shelf first.',
            )
          else ...[
            ...cart.lines.map(
              (line) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(PopSpace.sm),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              line.product.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: 'Remove',
                            onPressed: () => context.read<CartCubit>().remove(
                              line.product.id,
                            ),
                            icon: const Icon(PopIcons.remove),
                          ),
                        ],
                      ),
                      if (cart.unavailableIds.contains(line.product.id))
                        const Text('No longer available — remove or replace'),
                      Row(
                        children: [
                          IconButton(
                            tooltip: 'Decrease quantity',
                            onPressed: () => context
                                .read<CartCubit>()
                                .decrement(line.product.id),
                            icon: const Icon(PopIcons.decrease),
                          ),
                          Text('${line.quantity}'),
                          IconButton(
                            tooltip: 'Increase quantity',
                            onPressed: () =>
                                context.read<CartCubit>().add(line.product),
                            icon: const Icon(PopIcons.increase),
                          ),
                          const Spacer(),
                          Text(
                            _money(line.lineTotalCentavos),
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: PopSpace.md),
            TextField(
              controller: address,
              decoration: const InputDecoration(labelText: 'Delivery address'),
              maxLength: 500,
            ),
            const SizedBox(height: PopSpace.sm),
            TextField(
              controller: notes,
              decoration: const InputDecoration(
                labelText: 'Delivery notes (optional)',
              ),
              maxLength: 500,
            ),
            const SizedBox(height: PopSpace.md),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Cash on delivery',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                Expanded(
                  child: Text(
                    _money(cart.totalCentavos),
                    textAlign: TextAlign.end,
                    style: Theme.of(context).textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            ),
            if (widget.message != null) ...[
              const SizedBox(height: PopSpace.md),
              Text(widget.message!, textAlign: TextAlign.center),
            ],
            const SizedBox(height: PopSpace.lg),
            FilledButton(
              key: const Key('place-order'),
              onPressed:
                  widget.placing ||
                      cart.unavailableIds.isNotEmpty ||
                      address.text.trim().isEmpty
                  ? null
                  : () =>
                        widget.onPlace(address.text.trim(), notes.text.trim()),
              child: Text(widget.placing ? 'Placing order…' : 'Place order'),
            ),
          ],
        ],
      ),
    ),
  );
}

String _money(int centavos) => '₱${(centavos / 100).toStringAsFixed(2)}';
