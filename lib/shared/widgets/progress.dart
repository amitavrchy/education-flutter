import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../core/l10n/tr.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

/// Circular progress with a centred label.
class ProgressRing extends StatelessWidget {
  const ProgressRing({
    super.key,
    required this.value,
    this.size = 56,
    this.stroke = 6,
    this.color,
    this.center,
  });

  /// 0..1
  final double value;
  final double size;
  final double stroke;
  final Color? color;
  final Widget? center;

  @override
  Widget build(BuildContext context) {
    final v = value.clamp(0.0, 1.0);
    return Semantics(
      value: context.pct(v * 100),
      child: SizedBox.square(
        dimension: size,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: v),
          duration: context.reduceMotion ? Duration.zero : AppDurations.slow,
          curve: Curves.easeOutCubic,
          builder: (context, animated, _) => CustomPaint(
            painter: _RingPainter(
              value: animated,
              stroke: stroke,
              color: color ?? context.colors.primary,
              track: context.colors.surfaceContainerHighest,
            ),
            child: Center(
              child: center ??
                  Text(
                    context.pct(v * 100),
                    style: (size >= 64 ? context.text.titleMedium : context.text.labelMedium)
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.value, required this.stroke, required this.color, required this.track});

  final double value;
  final double stroke;
  final Color color;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final inset = rect.deflate(stroke / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(inset, 0, math.pi * 2, false, paint..color = track);
    if (value > 0) {
      canvas.drawArc(inset, -math.pi / 2, math.pi * 2 * value, false, paint..color = color);
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.value != value || old.color != color || old.track != track;
}

/// Label + percentage + linear bar (mastery, chapter completion).
class LabeledProgress extends StatelessWidget {
  const LabeledProgress({
    super.key,
    required this.label,
    required this.value,
    this.color,
    this.trailing,
    this.dense = false,
  });

  final String label;
  final double value;
  final Color? color;
  final String? trailing;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      value: context.pct(value * 100),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: dense ? AppSpacing.xs : AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(label, style: context.text.bodyMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
                Text(
                  trailing ?? context.pct(value * 100),
                  style: context.text.labelMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            LinearProgressIndicator(
              value: value.clamp(0.0, 1.0),
              minHeight: dense ? 6 : 8,
              color: color,
            ),
          ],
        ),
      ),
    );
  }
}

/// Colour for a 0..1 mastery/accuracy value.
Color masteryColor(BuildContext context, double value) {
  final p = context.palette;
  if (value >= 0.75) return p.success;
  if (value >= 0.5) return p.info;
  if (value >= 0.35) return p.warning;
  return p.danger;
}
