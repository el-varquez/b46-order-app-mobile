import 'package:flutter/material.dart';

import '../../app/theme/tokens.dart';
import 'pop_icons.dart';

class PopBackButton extends StatelessWidget {
  const PopBackButton({super.key});

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: MaterialLocalizations.of(context).backButtonTooltip,
    icon: const Icon(PopIcons.back),
    onPressed: () => Navigator.of(context).maybePop(),
  );
}

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
  const B46Mark({this.large = false, this.onRedBackground = false, super.key});
  final bool large;
  final bool onRedBackground;

  @override
  Widget build(BuildContext context) => Text.rich(
    TextSpan(
      children: [
        TextSpan(
          text: 'B',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        ),
        TextSpan(
          text: '46',
          style: TextStyle(
            color: onRedBackground ? PopColors.white : PopColors.brandRed,
          ),
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
        const Icon(PopIcons.emptyShelf, size: 52),
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
