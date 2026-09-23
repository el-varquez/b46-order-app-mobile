import 'package:flutter/material.dart';

import '../../app/theme/tokens.dart';

class PopScaffold extends StatelessWidget {
  const PopScaffold({
    required this.child,
    this.appBar,
    this.bottomNavigationBar,
    this.floatingActionButton,
    super.key,
  });

  final Widget child;
  final PreferredSizeWidget? appBar;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: appBar,
    bottomNavigationBar: bottomNavigationBar,
    floatingActionButton: floatingActionButton,
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: child,
        ),
      ),
    ),
  );
}

class B46Mark extends StatelessWidget {
  const B46Mark({this.large = false, super.key});
  final bool large;

  @override
  Widget build(BuildContext context) => Text.rich(
    TextSpan(
      children: [
        TextSpan(
          text: 'B',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        ),
        const TextSpan(
          text: '46',
          style: TextStyle(color: PopColors.brandRed),
        ),
      ],
    ),
    style: TextStyle(
      fontSize: large ? 56 : 30,
      height: 0.9,
      fontWeight: FontWeight.w900,
      fontStyle: FontStyle.italic,
      letterSpacing: -4,
    ),
  );
}

class EmptyState extends StatelessWidget {
  const EmptyState({required this.title, required this.message, super.key});
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(PopSpace.xl),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.local_grocery_store_outlined, size: 52),
        const SizedBox(height: PopSpace.md),
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: PopSpace.xs),
        Text(message, textAlign: TextAlign.center),
      ],
    ),
  );
}
