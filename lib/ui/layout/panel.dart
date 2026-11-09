import 'package:flutter/material.dart';
import 'package:type_racer/theme/app_colors.dart';
import 'package:type_racer/theme/app_theme.dart';

/// A titled card used for the columns of the wide layouts.
/// [fill]: the child takes all the height the panel gets (only inside a
/// bounded-height parent, e.g. an Expanded column); otherwise it sizes to fit.
class Panel extends StatelessWidget {
  final String? title;
  final IconData? icon;
  final Color accent;
  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool fill;

  const Panel({
    super.key,
    this.title,
    this.icon,
    this.accent = AppColors.cyan,
    this.padding = const EdgeInsets.all(16),
    this.fill = false,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withValues(alpha: 0.3)),
      ),
      child: Column(
        mainAxisSize: fill ? MainAxisSize.max : MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null) ...[
            Row(children: [
              if (icon != null) ...[
                Icon(icon, color: accent, size: 20),
                const SizedBox(width: 8),
              ],
              Text(title!, style: AppTheme.display(size: 14, spacing: 2)),
            ]),
            const SizedBox(height: 10),
          ],
          if (fill) Expanded(child: child) else child,
        ],
      ),
    );
  }
}
