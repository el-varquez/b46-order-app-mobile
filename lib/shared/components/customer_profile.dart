import 'package:flutter/material.dart';

import '../../app/theme/tokens.dart';
import 'customer_shell.dart';

class CustomerProfileScreen extends StatelessWidget {
  const CustomerProfileScreen({
    required this.name,
    required this.email,
    required this.deliveryArea,
    required this.deliveryAreaLoading,
    required this.onSaveDeliveryArea,
    required this.onShop,
    required this.onOrders,
    required this.onToggleTheme,
    required this.onSignOut,
    super.key,
  });

  final String name;
  final String email;
  final String deliveryArea;
  final bool deliveryAreaLoading;
  final Future<bool> Function(String) onSaveDeliveryArea;
  final VoidCallback onShop;
  final VoidCallback onOrders;
  final VoidCallback onToggleTheme;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) => CustomerTheme(
    child: Builder(
      builder: (context) => Scaffold(
        appBar: const CustomerHeader(title: 'Profile'),
        bottomNavigationBar: CustomerBottomNav(
          selected: 'Profile',
          onShop: onShop,
          onOrders: onOrders,
          onProfile: () {},
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          children: [
            Container(
              constraints: const BoxConstraints(minHeight: 220),
              padding: const EdgeInsets.all(26),
              decoration: const BoxDecoration(
                color: PopColors.launchRed,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(70),
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
                boxShadow: [
                  BoxShadow(
                    color: PopColors.launchShadow,
                    offset: Offset(10, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'B46',
                    style: TextStyle(
                      color: PopColors.white,
                      fontSize: 64,
                      fontWeight: FontWeight.w900,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Hi, $name.',
                    style: const TextStyle(
                      color: PopColors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    email,
                    style: const TextStyle(
                      color: PopColors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 25),
            _DeliveryAreaCard(
              area: deliveryArea,
              loading: deliveryAreaLoading,
              onSave: onSaveDeliveryArea,
            ),
            const SizedBox(height: 10),
            CustomerCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Appearance',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    CustomerPalette.dark(context) ? 'Dark mode' : 'Light mode',
                    style: TextStyle(color: CustomerPalette.muted(context)),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: onToggleTheme,
                    child: const Text('Switch appearance'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: onSignOut,
              style: OutlinedButton.styleFrom(
                foregroundColor: PopColors.authDanger,
                side: const BorderSide(color: PopColors.authDanger),
              ),
              child: const Text('Sign out'),
            ),
          ],
        ),
      ),
    ),
  );
}

class _DeliveryAreaCard extends StatefulWidget {
  const _DeliveryAreaCard({
    required this.area,
    required this.loading,
    required this.onSave,
  });

  final String area;
  final bool loading;
  final Future<bool> Function(String) onSave;

  @override
  State<_DeliveryAreaCard> createState() => _DeliveryAreaCardState();
}

class _DeliveryAreaCardState extends State<_DeliveryAreaCard> {
  late final controller = TextEditingController(text: widget.area);
  bool editing = false;
  bool saving = false;

  @override
  void didUpdateWidget(covariant _DeliveryAreaCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!editing && widget.area != oldWidget.area) {
      controller.text = widget.area;
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final area = controller.text.trim();
    if (area.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter your delivery area.')),
      );
      return;
    }
    setState(() => saving = true);
    final saved = await widget.onSave(area);
    if (!mounted) return;
    setState(() {
      saving = false;
      if (saved) editing = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          saved ? 'Delivery area saved.' : 'Could not save your delivery area.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => CustomerCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Delivery area',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        if (editing) ...[
          TextField(
            key: const Key('delivery-area-input'),
            controller: controller,
            maxLength: 500,
            maxLines: 2,
            decoration: const InputDecoration(
              hintText: 'Block and lot, Bria Homes',
            ),
          ),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: saving
                      ? null
                      : () => setState(() {
                          controller.text = widget.area;
                          editing = false;
                        }),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: saving ? null : _save,
                  child: Text(saving ? 'Saving…' : 'Save'),
                ),
              ),
            ],
          ),
        ] else ...[
          Text(widget.loading ? 'Loading…' : widget.area),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: widget.loading
                ? null
                : () => setState(() => editing = true),
            child: const Text('Edit delivery area'),
          ),
        ],
      ],
    ),
  );
}
