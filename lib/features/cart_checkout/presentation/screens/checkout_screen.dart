import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/theme/tokens.dart';
import '../../../../shared/components/customer_shell.dart';
import '../../../../shared/components/pop_icons.dart';
import '../cubit/cart_cubit.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({
    required this.placing,
    required this.message,
    required this.onPlace,
    this.initialAddress = 'Block 12, Bria Homes',
    super.key,
  });

  final bool placing;
  final String? message;
  final Future<void> Function(String address, String notes) onPlace;
  final String initialAddress;

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  late final address = TextEditingController(text: widget.initialAddress);
  final notes = TextEditingController();

  @override
  void initState() {
    super.initState();
    address.addListener(_updateAddress);
  }

  void _updateAddress() => setState(() {});

  @override
  void dispose() {
    address.removeListener(_updateAddress);
    address.dispose();
    notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => CustomerTheme(
    child: Builder(
      builder: (context) => Scaffold(
        appBar: const CustomerHeader(title: 'Checkout', back: true),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          children: [
            const Text(
              'Delivery details',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 16),
            const Text(
              'Bria delivery address',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            TextField(
              key: const Key('delivery-address'),
              controller: address,
              decoration: const InputDecoration(
                hintText: 'Your address inside Bria',
              ),
              maxLength: 500,
            ),
            const SizedBox(height: 12),
            const Text(
              'Delivery note',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: notes,
              decoration: const InputDecoration(
                hintText: 'Landmark or instructions',
              ),
              maxLength: 500,
            ),
            const SizedBox(height: 16),
            const Text(
              'Payment',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 14),
            CustomerCard(
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: CustomerPalette.soft(context),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: const Icon(PopIcons.cash, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Cash on delivery',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                        Text(
                          'Pay when your order arrives',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: CustomerPalette.muted(context),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (widget.message != null) ...[
              const SizedBox(height: 16),
              Text(
                widget.message!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: PopColors.authDanger),
              ),
            ],
          ],
        ),
        bottomNavigationBar: BlocBuilder<CartCubit, CartState>(
          builder: (context, cart) => SafeArea(
            top: false,
            child: Container(
              key: const Key('checkout-footer'),
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
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Amount due',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      Text(
                        _money(cart.totalCentavos),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      key: const Key('place-order'),
                      onPressed:
                          widget.placing ||
                              cart.lines.isEmpty ||
                              cart.unavailableIds.isNotEmpty ||
                              address.text.trim().isEmpty
                          ? null
                          : () => widget.onPlace(
                              address.text.trim(),
                              notes.text.trim(),
                            ),
                      child: Text(
                        widget.placing
                            ? 'Placing order…'
                            : 'Place order · ${_money(cart.totalCentavos)}',
                      ),
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
}

String _money(int centavos) => '₱${(centavos / 100).toStringAsFixed(2)}';
