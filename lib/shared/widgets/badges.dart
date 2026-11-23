import 'package:material_ui/material_ui.dart';

import '../../core/l10n/common_strings.dart';
import '../../core/l10n/tr.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

enum Tone { neutral, primary, success, warning, info, danger }

extension ToneColors on Tone {
  (Color fg, Color bg) colorsOf(BuildContext context) {
    final p = context.palette;
    final c = context.colors;
    return switch (this) {
      Tone.neutral => (c.onSurfaceVariant, c.surfaceContainerHighest),
      Tone.primary => (c.onPrimaryContainer, c.primaryContainer),
      Tone.success => (p.success, p.successContainer),
      Tone.warning => (p.warning, p.warningContainer),
      Tone.info => (p.info, p.infoContainer),
      Tone.danger => (p.danger, p.dangerContainer),
    };
  }
}

/// Small rounded label: status, difficulty, verification, tags.
class Pill extends StatelessWidget {
  const Pill(this.label, {super.key, this.tone = Tone.neutral, this.icon, this.color});

  final String label;
  final Tone tone;
  final IconData? icon;

  /// Custom colour (e.g. subject colour) overriding [tone].
  final Color? color;

  @override
  Widget build(BuildContext context) {
    var (fg, bg) = tone.colorsOf(context);
    if (color != null) {
      fg = color!;
      bg = color!.withValues(alpha: 0.12);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xxs + 1),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(AppRadius.pill)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 13, color: fg), const SizedBox(width: 3)],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.text.labelSmall?.copyWith(color: fg, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

/// Marks sample numbers and simulated features so mock content is never mistaken for real.
class DemoBadge extends StatelessWidget {
  const DemoBadge({super.key, this.label});

  final Tr? label;

  @override
  Widget build(BuildContext context) => Semantics(
    label: context.tr(label ?? S.demoData),
    child: Pill(context.tr(label ?? S.demoData), tone: Tone.warning, icon: Icons.science_outlined),
  );
}

class SimulatedBadge extends StatelessWidget {
  const SimulatedBadge({super.key});

  @override
  Widget build(BuildContext context) => const DemoBadge(label: S.simulated);
}

/// Kept for the original dashboard widgets.
class DemoDataBadge extends StatelessWidget {
  const DemoDataBadge({super.key});

  @override
  Widget build(BuildContext context) => const DemoBadge();
}

/// Inline banner for warnings, notices and AI transparency labels.
class InfoBanner extends StatelessWidget {
  const InfoBanner({
    super.key,
    required this.message,
    this.title,
    this.tone = Tone.info,
    this.icon,
    this.action,
  });

  final String message;
  final String? title;
  final Tone tone;
  final IconData? icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final (fg, bg) = tone.colorsOf(context);
    final defaultIcon = switch (tone) {
      Tone.success => Icons.check_circle_outline,
      Tone.warning => Icons.warning_amber_rounded,
      Tone.danger => Icons.error_outline,
      _ => Icons.info_outline,
    };
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(color: bg.withValues(alpha: 0.7), borderRadius: AppRadius.field),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon ?? defaultIcon, color: fg, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title != null)
                  Text(title!, style: context.text.titleSmall?.copyWith(color: fg)),
                Text(message, style: context.text.bodySmall?.copyWith(color: context.colors.onSurface)),
                if (action != null) Align(alignment: AlignmentDirectional.centerEnd, child: action),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
