import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:type_racer/providers/game_state_provider.dart';
import 'package:type_racer/theme/app_colors.dart';
import 'package:type_racer/utils/player_utils.dart';

/// The sentence card with live, per-letter feedback.
/// `typed` is the text currently in the input box (shared with GameTextField).
class SentenceGame extends StatelessWidget {
  final ValueNotifier<String> typed;
  const SentenceGame({Key? key, required this.typed}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final game = Provider.of<GameStateProvider>(context);
    final List words = game.gameState['words'];
    final me = findMe(game.gameState['players']);
    if (me == null) return const SizedBox.shrink();
    final int i = me['currentWordIndex'];
    if (i >= words.length) return const SizedBox.shrink();

    final current = words[i].toString();
    final done = words.sublist(0, i).join(' ');
    final remaining = words.sublist(i + 1).join(' ');
    final base = GoogleFonts.jetBrainsMono(fontSize: 24, height: 1.6);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(18),
      constraints: const BoxConstraints(maxWidth: 600),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.85),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cyan.withOpacity(0.3)),
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
                  ok ? null : AppColors.red.withOpacity(0.25),
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
                backgroundColor: AppColors.red.withOpacity(0.25),
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
