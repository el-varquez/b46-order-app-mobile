import 'package:flutter/material.dart';

import '../../app/theme/tokens.dart';
import 'customer_shell.dart';

class CustomerProfileScreen extends StatelessWidget {
  const CustomerProfileScreen({
    required this.name,
    required this.email,
    required this.onShop,
    required this.onOrders,
    required this.onToggleTheme,
    required this.onSignOut,
    super.key,
  });

  final String name;
  final String email;
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
            const CustomerCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Delivery area',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  SizedBox(height: 6),
                  Text('Bria Homes'),
                ],
              ),
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
