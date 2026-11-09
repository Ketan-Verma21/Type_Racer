import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:type_racer/theme/app_colors.dart';
import 'package:type_racer/theme/app_theme.dart';
import 'package:type_racer/state/game_controller.dart';

/// The sentence card with live, per-letter feedback.
/// `typed` is the text currently in the input box (shared with GameTextField).
class SentenceGame extends StatelessWidget {
  final ValueNotifier<String> typed;
  final double maxWidth;
  final double fontSize;
  const SentenceGame({Key? key, required this.typed, this.maxWidth = 600, this.fontSize = 24})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameController>();
    final words = game.game.words;
    final me = game.me;
    if (me == null) return const SizedBox.shrink();
    final i = me.wordIndex;
    if (i >= words.length) return const SizedBox.shrink();

    final current = words[i];
    final done = words.sublist(0, i).join(' ');
    final remaining = words.sublist(i + 1).join(' ');
    final base = AppTheme.mono(size: fontSize, height: 1.6);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(18),
      constraints: BoxConstraints(maxWidth: maxWidth),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cyan.withValues(alpha: 0.3)),
      ),
      child: ValueListenableBuilder<String>(
        valueListenable: typed,
        builder: (context, t, _) {
          final spans = <InlineSpan>[
            // finished words -> green
            TextSpan(
              text: done.isEmpty ? '' : '$done ',
              style: base.copyWith(color: AppColors.green),
            ),
          ];

          // current word, letter by letter
          for (int k = 0; k < current.length; k++) {
            if (k < t.length) {
              final ok = t[k] == current[k];
              spans.add(TextSpan(
                text: current[k],
                style: base.copyWith(
                  color: ok ? AppColors.green : AppColors.red,
                  backgroundColor:
                      ok ? null : AppColors.red.withValues(alpha: 0.25),
                  fontWeight: FontWeight.w800,
                ),
              ));
            } else if (k == t.length) {
              // the letter you need to type next (the "cursor")
              spans.add(TextSpan(
                text: current[k],
                style: base.copyWith(
                  color: AppColors.bg,
                  backgroundColor: AppColors.cyan,
                  fontWeight: FontWeight.w800,
                ),
              ));
            } else {
              spans.add(TextSpan(
                text: current[k],
                style: base.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ));
            }
          }

          // typed more letters than the word has
          if (t.length > current.length) {
            spans.add(TextSpan(
              text: t.substring(current.length),
              style: base.copyWith(
                color: AppColors.red,
                backgroundColor: AppColors.red.withValues(alpha: 0.25),
                decoration: TextDecoration.lineThrough,
              ),
            ));
          }

          spans.add(TextSpan(
            text: remaining.isEmpty ? '' : ' $remaining',
            style: base.copyWith(color: AppColors.textMuted),
          ));

          return Text.rich(TextSpan(style: base, children: spans));
        },
      ),
    );
  }
}
