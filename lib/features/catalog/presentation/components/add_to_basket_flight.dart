import 'package:flutter/material.dart';

import '../../../../app/theme/tokens.dart';
import '../../../../shared/components/pop_icons.dart';

/// A visual confirmation only; adding the product happens before this runs.
class AddToBasketFlight extends StatefulWidget {
  const AddToBasketFlight({
    required this.start,
    required this.end,
    required this.itemIcon,
    required this.imageUrl,
    required this.onFinished,
    super.key,
  });

  final Offset start;
  final Offset end;
  final IconData itemIcon;
  final Uri? imageUrl;
  final VoidCallback onFinished;

  @override
  State<AddToBasketFlight> createState() => _AddToBasketFlightState();
}

class _AddToBasketFlightState extends State<AddToBasketFlight>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller =
      AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 900),
      )..addStatusListener((status) {
        if (status == AnimationStatus.completed) widget.onFinished();
      });

  @override
  void initState() {
    super.initState();
    controller.forward();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final time = controller.value;
        final appear = Curves.easeOutBack.transform(
          (time / 0.18).clamp(0.0, 1.0),
        );
        final drop = Curves.easeInCubic.transform(
          ((time - 0.14) / 0.40).clamp(0.0, 1.0),
        );
        final travel = Curves.easeInOutCubic.transform(
          ((time - 0.55) / 0.45).clamp(0.0, 1.0),
        );
        final center = Offset.lerp(widget.start, widget.end, travel)!;
        final scale = appear * (1 - 0.75 * travel);
        final fade = ((1 - travel) / 0.18).clamp(0.0, 1.0);

        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: center.dx - 36,
              top: center.dy - 36,
              child: Opacity(
                opacity: fade,
                child: Transform.scale(
                  scale: scale,
                  child: SizedBox(
                    width: 72,
                    height: 72,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: PopColors.launchRed,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: const [
                              BoxShadow(
                                color: PopColors.launchShadow,
                                blurRadius: 12,
                                offset: Offset(4, 6),
                              ),
                            ],
                          ),
                          child: const Icon(
                            PopIcons.basket,
                            color: PopColors.white,
                            size: 32,
                          ),
                        ),
                        if (time >= 0.14 && time < 0.55)
                          Positioned(
                            left: 17,
                            top: -43 + 52 * drop,
                            child: Opacity(
                              opacity: ((1 - drop) / 0.25).clamp(0.0, 1.0),
                              child: Transform.scale(
                                scale: 1 - 0.55 * drop,
                                child: Container(
                                  width: 38,
                                  height: 38,
                                  clipBehavior: Clip.antiAlias,
                                  decoration: BoxDecoration(
                                    color: PopColors.white,
                                    borderRadius: BorderRadius.circular(11),
                                    border: Border.all(
                                      color: PopColors.launchRed,
                                      width: 2,
                                    ),
                                  ),
                                  child: widget.imageUrl == null
                                      ? Icon(
                                          widget.itemIcon,
                                          color: PopColors.launchRed,
                                          size: 23,
                                        )
                                      : Image.network(
                                          widget.imageUrl.toString(),
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, _, _) => Icon(
                                            widget.itemIcon,
                                            color: PopColors.launchRed,
                                            size: 23,
                                          ),
                                        ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    ),
  );
}
