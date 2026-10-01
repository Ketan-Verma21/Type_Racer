import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:type_racer/providers/game_state_provider.dart';
import 'package:type_racer/theme/app_colors.dart';
import 'package:type_racer/theme/app_theme.dart';

/// Final results: players ranked by WPM with medals and staggered entrance.
class Scoreboard extends StatelessWidget {
  const Scoreboard({Key? key}) : super(key: key);

  num _wpm(dynamic p) => num.tryParse(p['WPM'].toString()) ?? 0;

  @override
  Widget build(BuildContext context) {
    final game = Provider.of<GameStateProvider>(context);
    final players = List.from(game.gameState['players']);
    players.sort((a, b) => _wpm(b).compareTo(_wpm(a)));
    const medals = ['🥇', '🥈', '🥉'];

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
            BoxShadow(
                color: AppColors.yellow.withOpacity(0.15), blurRadius: 24),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🏆', style: TextStyle(fontSize: 44))
                .animate()
                .scale(duration: 600.ms, curve: Curves.elasticOut),
            Text('RACE FINISHED',
                style: AppTheme.display(
                    size: 20, color: AppColors.yellow, spacing: 3)),
            const SizedBox(height: 12),
            for (int i = 0; i < players.length; i++)
              Container(
                margin: const EdgeInsets.symmetric(vertical: 4),
                padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: i == 0
                      ? AppColors.yellow.withOpacity(0.12)
                      : AppColors.surfaceHigh,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: i == 0
                        ? AppColors.yellow.withOpacity(0.6)
                        : Colors.transparent,
                  ),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 40,
                      child: Text(
                        (i < 3 && _wpm(players[i]) >= 0)
                            ? medals[i]
                            : '#${i + 1}',
                        style: (i < 3 && _wpm(players[i]) >= 0)
                            ? const TextStyle(fontSize: 26)
                            : AppTheme.display(
                            size: 14, color: AppColors.textMuted),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        players[i]['nickname'].toString(),
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.body(
                            size: 20, weight: FontWeight.w700),
                      ),
                    ),
                    Text(_wpm(players[i]) < 0 ? '...' : '${_wpm(players[i])}',
                        style: AppTheme.display(
                            size: 20, color: AppColors.cyan)),
                    const SizedBox(width: 4),
                    Text('WPM',
                        style: AppTheme.body(
                            size: 13, color: AppColors.textMuted)),
                  ],
                ),
              )
                  .animate()
                  .fadeIn(delay: (250 + i * 150).ms, duration: 400.ms)
                  .slideX(begin: 0.2, curve: Curves.easeOut),
          ],
        ),
      ),
    );
  }
}
