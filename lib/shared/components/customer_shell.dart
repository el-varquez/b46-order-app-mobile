import 'package:flutter/material.dart';

import '../../app/theme/tokens.dart';
import 'pop_icons.dart';
import 'pop_scaffold.dart';

abstract final class CustomerPalette {
  static bool dark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;
  static Color paper(BuildContext context) =>
      dark(context) ? PopColors.prototypeDarkPaper : PopColors.prototypePaper;
  static Color surface(BuildContext context) =>
      dark(context) ? PopColors.prototypeDarkSurface : PopColors.white;
  static Color ink(BuildContext context) =>
      dark(context) ? PopColors.authDarkInk : PopColors.prototypeInk;
  static Color muted(BuildContext context) =>
      dark(context) ? PopColors.prototypeDarkMuted : PopColors.prototypeMuted;
  static Color line(BuildContext context) =>
      dark(context) ? PopColors.prototypeDarkLine : PopColors.prototypeLine;
  static Color soft(BuildContext context) =>
      dark(context) ? PopColors.prototypeDarkSoft : PopColors.prototypeSoft;
}

class CustomerTheme extends StatelessWidget {
  const CustomerTheme({required this.child, super.key});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context);
    final paper = CustomerPalette.paper(context);
    final surface = CustomerPalette.surface(context);
    final ink = CustomerPalette.ink(context);
    final muted = CustomerPalette.muted(context);
    final line = CustomerPalette.line(context);
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: line),
    );
    return Theme(
      data: base.copyWith(
        scaffoldBackgroundColor: paper,
        colorScheme: base.colorScheme.copyWith(
          primary: PopColors.launchRed,
          onPrimary: PopColors.white,
          surface: surface,
          onSurface: ink,
          onSurfaceVariant: muted,
          outline: line,
        ),
        textTheme: base.textTheme.apply(bodyColor: ink, displayColor: ink),
        appBarTheme: AppBarTheme(
          backgroundColor: paper,
          foregroundColor: ink,
          elevation: 0,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: surface,
          border: border,
          enabledBorder: border,
          focusedBorder: border.copyWith(
            borderSide: const BorderSide(color: PopColors.launchRed, width: 2),
          ),
          hintStyle: TextStyle(color: muted),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 13,
            vertical: 13,
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: PopColors.launchRed,
            foregroundColor: PopColors.white,
            minimumSize: const Size.fromHeight(50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            textStyle: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
        cardTheme: CardThemeData(
          color: surface,
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: line),
          ),
        ),
      ),
      child: child,
    );
  }
}

class CustomerHeader extends StatelessWidget implements PreferredSizeWidget {
  const CustomerHeader({
    this.title,
    this.subtitle,
    this.back = false,
    this.action,
    super.key,
  });
  final String? title;
  final String? subtitle;
  final bool back;
  final Widget? action;

  @override
  Size get preferredSize => const Size.fromHeight(68);

  @override
  Widget build(BuildContext context) => AppBar(
    toolbarHeight: 68,
    automaticallyImplyLeading: false,
    titleSpacing: 16,
    actions: action == null ? null : [action!, const SizedBox(width: 12)],
    title: Row(
      children: [
        if (back) ...[
          IconButton(
            tooltip: 'Back',
            onPressed: () => Navigator.of(context).maybePop(),
            style: IconButton.styleFrom(
              backgroundColor: CustomerPalette.soft(context)
                  .withValues(alpha: 0.42),
              fixedSize: const Size(46, 46),
            ),
            icon: const Icon(PopIcons.back),
          ),
          const SizedBox(width: 11),
        ] else ...[
          const B46Mark(),
          const SizedBox(width: 11),
        ],
        Expanded(
          child: subtitle == null
              ? Text(
                  title ?? '',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      subtitle!,
                      style: TextStyle(
                        fontSize: 11,
                        color: CustomerPalette.muted(context),
                      ),
                    ),
                    Text(
                      title ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
        ),
      ],
    ),
  );
}

class CustomerBottomNav extends StatelessWidget {
  const CustomerBottomNav({
    required this.selected,
    required this.onShop,
    required this.onOrders,
    required this.onProfile,
    super.key,
  });
  final String selected;
  final VoidCallback onShop;
  final VoidCallback onOrders;
  final VoidCallback onProfile;

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      decoration: BoxDecoration(
        color: CustomerPalette.paper(context),
        border: Border(top: BorderSide(color: CustomerPalette.line(context))),
      ),
      child: Row(
        children: [
          _item(context, 'Shop', PopIcons.home, onShop),
          _item(context, 'Orders', PopIcons.orders, onOrders),
          _item(context, 'Profile', PopIcons.profile, onProfile),
        ],
      ),
    ),
  );

  Widget _item(
    BuildContext context,
    String label,
    IconData icon,
    VoidCallback action,
  ) {
    final active = selected == label;
    return Expanded(
      child: TextButton(
        onPressed: active ? null : action,
        style: TextButton.styleFrom(
          foregroundColor: active
              ? PopColors.launchRed
              : CustomerPalette.muted(context),
          disabledForegroundColor: PopColors.launchRed,
          backgroundColor: active ? CustomerPalette.soft(context) : null,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 21),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }
}

class CustomerCard extends StatelessWidget {
  const CustomerCard({
    required this.child,
    this.padding = const EdgeInsets.all(14),
    super.key,
  });
  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: CustomerPalette.surface(context),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: CustomerPalette.line(context)),
    ),
    child: child,
  );
}
