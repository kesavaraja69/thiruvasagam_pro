import 'package:flutter/material.dart';

/// A widget that wraps its child with an eye protection overlay.
/// When enabled, it applies:
/// 1. A warm amber/sepia tint to reduce blue light
/// 2. A brightness dimming overlay
class EyeProtectionOverlay extends StatelessWidget {
  final Widget child;
  final bool enabled;
  final double warmth; // 0.0 = no warmth, 1.0 = maximum warm tint
  final double dimness; // 0.0 = no dimming, 1.0 = maximum dimming

  const EyeProtectionOverlay({
    super.key,
    required this.child,
    this.enabled = false,
    this.warmth = 0.3,
    this.dimness = 0.15,
  });

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;

    return Stack(
      children: [
        child,
        // Warm amber tint overlay
        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Color.fromRGBO(255, 183, 77, warmth * 0.35),
              ),
            ),
          ),
        ),
        // Brightness dimming overlay
        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Color.fromRGBO(0, 0, 0, dimness),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
