import 'package:flutter/material.dart';

import '../../../../app/theme/tokens.dart';
import '../../../../shared/components/pop_icons.dart';

/// Prototype styling stays local to authentication forms.
class AuthFormScaffold extends StatelessWidget {
  const AuthFormScaffold({required this.title, required this.child, super.key});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context);
    final dark = base.brightness == Brightness.dark;
    final background = dark ? PopColors.launchBackground : PopColors.cream;
    final surface = dark ? PopColors.launchSurface : PopColors.white;
    final ink = dark ? PopColors.authDarkInk : PopColors.authInk;
    final muted = dark ? PopColors.launchMuted : PopColors.launchLightMuted;
    final line = dark ? PopColors.launchOutline : PopColors.launchLightOutline;
    final soft = dark ? PopColors.authDarkSoft : PopColors.authSoft;
    final danger = dark ? PopColors.authDarkDanger : PopColors.authDanger;
    OutlineInputBorder border(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: color, width: width),
        );
    return Theme(
      data: base.copyWith(
        colorScheme: base.colorScheme.copyWith(
          primary: PopColors.launchRed,
          onPrimary: PopColors.white,
          surface: surface,
          onSurface: ink,
          onSurfaceVariant: muted,
          outline: line,
          error: danger,
        ),
        scaffoldBackgroundColor: background,
        textTheme: base.textTheme
            .apply(bodyColor: ink, displayColor: ink)
            .copyWith(
              bodyLarge: base.textTheme.bodyLarge?.copyWith(
                color: ink,
                fontSize: 16,
              ),
              headlineSmall: base.textTheme.headlineSmall?.copyWith(
                color: ink,
                fontSize: 32,
                height: 1.15,
                fontWeight: FontWeight.w700,
              ),
            ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: surface,
          contentPadding: const EdgeInsets.all(12),
          constraints: const BoxConstraints(minHeight: 50),
          border: border(line),
          enabledBorder: border(line),
          disabledBorder: border(line),
          focusedBorder: border(PopColors.launchRed, 2),
          errorBorder: border(danger),
          focusedErrorBorder: border(danger, 2),
          hintStyle: TextStyle(color: muted, fontSize: 16),
          helperStyle: TextStyle(color: muted, fontSize: 11),
          errorStyle: TextStyle(color: danger, fontSize: 11),
          errorMaxLines: 3,
          suffixIconColor: muted,
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: PopColors.launchRed,
            foregroundColor: PopColors.white,
            minimumSize: const Size.fromHeight(50),
            padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            textStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: PopColors.launchRed,
            minimumSize: const Size(44, 44),
            textStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: PopColors.launchRed,
        ),
      ),
      child: Builder(
        builder: (context) => Scaffold(
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            tooltip: MaterialLocalizations.of(context)
                                .backButtonTooltip,
                            onPressed: () => Navigator.of(context).maybePop(),
                            style: IconButton.styleFrom(
                              backgroundColor: soft.withValues(alpha: 0.42),
                              foregroundColor: ink,
                              fixedSize: const Size(46, 46),
                            ),
                            icon: const Icon(PopIcons.back, size: 22),
                          ),
                          const SizedBox(width: 11),
                          Expanded(
                            child: Text(
                              title,
                              style: TextStyle(
                                color: ink,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(child: child),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AuthFieldLabel extends StatelessWidget {
  const AuthFieldLabel(this.label, {super.key});
  final String label;
  @override
  Widget build(BuildContext context) => Text(
    label,
    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
  );
}

class AuthMessage extends StatelessWidget {
  const AuthMessage(this.message, {super.key});
  final String message;
  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: Text(
      message,
      textAlign: TextAlign.center,
      style: TextStyle(
        color: Theme.of(context).colorScheme.error,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

class AuthWordmark extends StatelessWidget {
  const AuthWordmark({this.onRedBackground = false, super.key});
  final bool onRedBackground;
  @override
  Widget build(BuildContext context) => Semantics(
    label: 'B46',
    image: true,
    excludeSemantics: true,
    child: SizedBox(
      height: 106,
      child: Align(
        alignment: Alignment.centerLeft,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 82,
                height: 106,
                child: CustomPaint(
                  painter: _AuthInitialPainter(
                    onRedBackground
                        ? PopColors.cream
                        : Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
              Text(
                '46',
                textScaler: TextScaler.noScaling,
                style: TextStyle(
                  color: onRedBackground
                      ? PopColors.white
                      : PopColors.launchRed,
                  fontSize: 106,
                  height: 1,
                  letterSpacing: -8,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

// A vector initial keeps the poster's serif mark consistent on Android and iOS.
class _AuthInitialPainter extends CustomPainter {
  const _AuthInitialPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(0, 22);
    canvas.scale(size.width / 82, (size.height - 30) / 76);
    final mark = Path()
      ..fillType = PathFillType.evenOdd
      ..moveTo(2, 0)
      ..lineTo(40, 0)
      ..cubicTo(62, 0, 74, 6, 74, 19)
      ..cubicTo(74, 30, 65, 35, 52, 37)
      ..cubicTo(70, 39, 80, 45, 80, 56)
      ..cubicTo(80, 71, 65, 76, 42, 76)
      ..lineTo(2, 76)
      ..lineTo(2, 72)
      ..cubicTo(13, 71, 15, 70, 15, 64)
      ..lineTo(15, 12)
      ..cubicTo(15, 6, 13, 5, 2, 4)
      ..close()
      ..moveTo(35, 5)
      ..lineTo(35, 35)
      ..lineTo(40, 35)
      ..cubicTo(50, 35, 54, 29, 54, 20)
      ..cubicTo(54, 10, 50, 5, 40, 5)
      ..close()
      ..moveTo(35, 40)
      ..lineTo(35, 64)
      ..cubicTo(35, 70, 37, 71, 43, 71)
      ..cubicTo(54, 71, 58, 65, 58, 56)
      ..cubicTo(58, 45, 52, 40, 42, 40)
      ..close();
    canvas.drawPath(mark, Paint()..color = color);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_AuthInitialPainter oldDelegate) =>
      color != oldDelegate.color;
}
