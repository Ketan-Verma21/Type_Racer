import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:type_racer/providers/game_state_provider.dart';
import 'package:type_racer/theme/app_colors.dart';
import 'package:type_racer/theme/app_theme.dart';
import 'package:type_racer/utils/player_utils.dart';

/// Ranked results. While the race is still running it shows live standings
/// ("waiting for others"); once it is over it crowns the winner.
class Scoreboard extends StatelessWidget {
  final String myId;
  const Scoreboard({Key? key, required this.myId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final game = Provider.of<GameStateProvider>(context);
    final words = game.gameState['words'] as List;
    final isOver = game.gameState['isOver'] == true;
    final ranked = rankPlayers(game.gameState['players'] as List, words.length);
    const medals = ['🥇', '🥈', '🥉'];

    final winner = ranked.isNotEmpty ? ranked.first : null;
    final iWon = isOver && winner != null && winner['_id'].toString() == myId;
    final title = !isOver
        ? 'WAITING FOR OTHERS...'
        : (iWon ? 'YOU WON! 🎉' : '${winner?['nickname']} WINS!');

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 600),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface.withOpacity(0.85),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.yellow.withOpacity(0.5)),
          boxShadow: [
            BoxShadow(color: AppColors.yellow.withOpacity(0.15), blurRadius: 24),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(isOver ? '🏆' : '⏳', style: const TextStyle(fontSize: 44))
                .animate(key: ValueKey(isOver))
                .scale(duration: 600.ms, curve: Curves.elasticOut),
            const SizedBox(height: 4),
            Text(title,
                textAlign: TextAlign.center,
                style: AppTheme.display(
                    size: 20, color: AppColors.yellow, spacing: 2)),
            const SizedBox(height: 12),
            for (int i = 0; i < ranked.length; i++)
              _row(i, ranked[i], medals, words.length, isOver),
          ],
        ),
      ),
    );
  }

  Widget _row(int i, dynamic p, List<String> medals, int wordCount, bool isOver) {
    final eliminated = p['isEliminated'] == true;
    final wpm = wpmOf(p);
    final mine = p['_id'].toString() == myId;
    final showMedal = i < 3 && !eliminated && wpm >= 0;
    final isWinner = i == 0 && isOver && !eliminated;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isWinner
            ? AppColors.yellow.withOpacity(0.12)
            : AppColors.surfaceHigh,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: mine
              ? AppColors.cyan
              : (isWinner
                  ? AppColors.yellow.withOpacity(0.6)
                  : Colors.transparent),
          width: mine ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Text(
              showMedal ? medals[i] : '#${i + 1}',
              style: showMedal
                  ? const TextStyle(fontSize: 26)
                  : AppTheme.display(size: 14, color: AppColors.textMuted),
            ),
          ),
          Expanded(
            child: Text(
              p['nickname'].toString() + (mine ? ' (you)' : ''),
              overflow: TextOverflow.ellipsis,
              style: AppTheme.body(size: 20, weight: FontWeight.w700),
            ),
          ),
          if (eliminated)
            Text('OUT', style: AppTheme.display(size: 16, color: AppColors.red))
          else ...[
            Text(wpm < 0 ? '...' : '${wpm.round()}',
                style: AppTheme.display(size: 20, color: AppColors.cyan)),
            const SizedBox(width: 4),
            Text('WPM',
                style: AppTheme.body(size: 13, color: AppColors.textMuted)),
          ],
        ],
      ),
    )
        .animate()
        .fadeIn(delay: (200 + i * 120).ms, duration: 400.ms)
        .slideX(begin: 0.2, curve: Curves.easeOut);
  }
}
