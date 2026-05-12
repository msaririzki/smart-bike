import 'package:flutter/material.dart';

/// A single digit that "rolls" vertically when the value changes,
/// similar to an odometer or airport departure board.
class RollingDigit extends StatelessWidget {
  const RollingDigit({
    super.key,
    required this.digit,
    this.textStyle,
    this.duration = const Duration(milliseconds: 400),
  });

  final String digit;
  final TextStyle? textStyle;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final style = textStyle ??
        Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w700,
              fontFeatures: const [FontFeature.tabularFigures()],
            );

    return AnimatedSwitcher(
      duration: duration,
      transitionBuilder: (child, animation) {
        // Determine direction: new child slides up from below,
        // old child slides up and out
        final isEntering = child.key == ValueKey(digit);
        final offset = isEntering
            ? Tween<Offset>(
                begin: const Offset(0, 0.6),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              ))
            : Tween<Offset>(
                begin: Offset.zero,
                end: const Offset(0, -0.6),
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeInCubic,
              ));

        return ClipRect(
          child: SlideTransition(
            position: offset,
            child: FadeTransition(
              opacity: animation,
              child: child,
            ),
          ),
        );
      },
      child: Text(
        digit,
        key: ValueKey(digit),
        style: style,
      ),
    );
  }
}

/// Displays a numeric value with rolling digit animation.
/// Each character (digit, dot, unit) is animated independently.
class RollingNumber extends StatelessWidget {
  const RollingNumber({
    super.key,
    required this.value,
    this.suffix = '',
    this.textStyle,
    this.suffixStyle,
    this.duration = const Duration(milliseconds: 400),
  });

  final String value;
  final String suffix;
  final TextStyle? textStyle;
  final TextStyle? suffixStyle;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ...value.split('').map((char) {
          return RollingDigit(
            digit: char,
            textStyle: textStyle,
            duration: duration,
          );
        }),
        if (suffix.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 2),
            child: Text(
              suffix,
              style: suffixStyle ??
                  Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: const Color(0xff667085),
                        fontWeight: FontWeight.w500,
                      ),
            ),
          ),
      ],
    );
  }
}
