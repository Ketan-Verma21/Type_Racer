import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:type_racer/domain/game_modes.dart';
import 'package:type_racer/state/leaderboard_controller.dart';
import 'package:type_racer/theme/app_colors.dart';
import 'package:type_racer/theme/app_theme.dart';
import 'package:type_racer/ui/layout/panel.dart';

/// Top racers per mode (FR-15): best WPM, highest first. Loads when shown
/// and when the mode changes.
class LeaderboardPanel extends StatefulWidget {
  /// Fill the height it gets (inside a bounded column) instead of sizing to fit.
  final bool fill;
  const LeaderboardPanel({super.key, this.fill = false});

  @override
  State<LeaderboardPanel> createState() => _LeaderboardPanelState();
}

class _LeaderboardPanelState extends State<LeaderboardPanel> {
  String _mode = GameModes.classic.id;
  late final LeaderboardController _boards = context.read<LeaderboardController>();

  @override
  void initState() {
    super.initState();
    // after the first frame: loading notifies listeners, not allowed mid-build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _boards.load(_mode);
    });
  }

  void _select(String mode) {
    setState(() => _mode = mode);
    _boards.load(mode);
  }

  @override
  Widget build(BuildContext context) {
    final boards = context.watch<LeaderboardController>();
    final board = boards.board(_mode);
    final loading = boards.isLoading(_mode) && board == null;

    final Widget list;
    if (loading) {
      list = const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator(color: AppColors.yellow)),
      );
    } else if (board == null || board.entries.isEmpty) {
      list = Padding(
        padding: const EdgeInsets.all(24),
        child: Text('No races yet — be the first! 🏁',
            textAlign: TextAlign.center, style: AppTheme.body(color: AppColors.textMuted)),
      );
    } else {
      final rows = [
        for (var i = 0; i < board.entries.length; i++)
          _Row(rank: i + 1, nickname: board.entries[i].nickname, wpm: board.entries[i].wpm),
      ];
      list = widget.fill ? ListView(children: rows) : Column(children: rows);
    }

    return Panel(
      title: 'TOP RACERS',
      icon: Icons.emoji_events_rounded,
      accent: AppColors.yellow,
      fill: widget.fill,
      child: Column(
        mainAxisSize: widget.fill ? MainAxisSize.max : MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              for (final m in GameModes.all)
                ChoiceChip(
                  label: Text('${m.emoji} ${m.name}'),
                  selected: m.id == _mode,
                  showCheckmark: false,
                  selectedColor: AppColors.yellow,
                  labelStyle: AppTheme.body(
                    size: 14,
                    weight: FontWeight.w700,
                    color: m.id == _mode ? AppColors.bg : AppColors.textPrimary,
                  ),
                  onSelected: (_) => _select(m.id),
                ),
            ],
          ),
          const SizedBox(height: 10),
          if (widget.fill) Expanded(child: list) else list,
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final int rank;
  final String nickname;
  final int wpm;
  const _Row({required this.rank, required this.nickname, required this.wpm});

  @override
  Widget build(BuildContext context) {
    const medals = ['🥇', '🥈', '🥉'];
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            child: rank <= 3
                ? Text(medals[rank - 1], style: const TextStyle(fontSize: 20))
                : Text('#$rank', style: AppTheme.display(size: 13, color: AppColors.textMuted)),
          ),
          Expanded(
            child: Text(nickname,
                overflow: TextOverflow.ellipsis,
                style: AppTheme.body(size: 17, weight: FontWeight.w700)),
          ),
          Text('$wpm', style: AppTheme.display(size: 17, color: AppColors.cyan)),
          const SizedBox(width: 4),
          Text('WPM', style: AppTheme.body(size: 12, color: AppColors.textMuted)),
        ],
      ),
    );
  }
}
