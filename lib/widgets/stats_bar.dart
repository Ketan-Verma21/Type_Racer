import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../utils/game_modes.dart';

/// Live stats strip for the local player: WPM, accuracy, progress, mode.
class StatsBar extends StatelessWidget {
  final int wpm;
  final double accuracy;
  final int done;
  final int total;
  final GameMode mode;

  const StatsBar({
    Key? key,
    required this.wpm,
    required this.accuracy,
    required this.done,
    required this.total,
    required this.mode,
  }) : super(key: key);

  Widget _tile(String label, String value, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surface.withOpacity(0.85),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.35)),
        ),
        child: Column(
          children: [
            Text(value, style: AppTheme.display(size: 18, color: color)),
            const SizedBox(height: 2),
            Text(label,
                style: AppTheme.body(
                    size: 11, color: AppColors.textMuted, weight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accColor = accuracy >= 0.95
        ? AppColors.green
        : (accuracy >= 0.85 ? AppColors.yellow : AppColors.red);
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 600),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            _tile('WPM', '$wpm', AppColors.cyan),
            _tile('ACCURACY', '${(accuracy * 100).round()}%', accColor),
            _tile('WORDS', '$done/$total', AppColors.magenta),
            _tile(mode.name.toUpperCase(), mode.emoji, AppColors.yellow),
          ],
        ),
      ),
    );
  }
}
