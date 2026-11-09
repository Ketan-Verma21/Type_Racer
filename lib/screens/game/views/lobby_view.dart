import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:type_racer/screens/game/views/common.dart';
import 'package:type_racer/state/game_controller.dart';
import 'package:type_racer/theme/app_colors.dart';
import 'package:type_racer/theme/app_theme.dart';
import 'package:type_racer/widgets/chat_panel.dart';
import 'package:type_racer/widgets/custom_button.dart';
import 'package:type_racer/widgets/settings_panel.dart';

/// Before the race: room code, settings, who's here, chat, and Start (host).
class LobbyView extends StatefulWidget {
  final VoidCallback onLeave;
  final void Function(String code) onCopyCode;
  const LobbyView({super.key, required this.onLeave, required this.onCopyCode});

  @override
  State<LobbyView> createState() => _LobbyViewState();
}

class _LobbyViewState extends State<LobbyView> {
  bool _startPressed = false;

  void _start(GameController game) {
    setState(() => _startPressed = true);
    game.startRace();
    // safety: allow pressing again if nothing happened
    Future.delayed(const Duration(seconds: 8), () {
      if (mounted && _startPressed) setState(() => _startPressed = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameController>();
    final me = game.me!;
    final g = game.game;
    final racers = g.racers;
    final isHost = me.isHost;

    return Column(
      children: [
        GameTopBar(msg: game.timer.msg, onLeave: widget.onLeave),
        CountdownText(text: game.timer.countDown, size: 44),
        Expanded(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _RoomCode(code: g.id, onTap: () => widget.onCopyCode(g.id)),
                  const SizedBox(height: 12),
                  SettingsPanel(
                    settings: g.settings,
                    isLeader: isHost,
                    racerCount: racers.length,
                    onChange: game.updateSettings,
                  ),
                  const SizedBox(height: 12),
                  Text('PLAYERS ${racers.length}/${g.settings.maxPlayers}',
                      style: AppTheme.display(size: 12, color: AppColors.textMuted, spacing: 2)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      for (final p in racers)
                        Chip(
                          avatar: Text(p.isHost ? '👑' : '🏎️'),
                          label: Text(p.nickname + (p.id == me.id ? ' (you)' : '')),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ChatPanel(myId: me.id, onSend: game.sendChat, onReact: game.sendReaction),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: isHost
              ? (_startPressed
                  ? Text('Starting...',
                      style: AppTheme.display(size: 14, color: AppColors.textMuted))
                  : CustomButton(text: 'Start', onTap: () => _start(game)))
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.hourglass_top_rounded, size: 18, color: AppColors.textMuted),
                    const SizedBox(width: 8),
                    Text('Waiting for the host to start...',
                        style: AppTheme.body(size: 16, color: AppColors.textMuted)),
                  ],
                ),
        ),
      ],
    );
  }
}

/// Big and readable, so it can be read out loud. Tap to copy.
class _RoomCode extends StatelessWidget {
  final String code;
  final VoidCallback onTap;
  const _RoomCode({required this.code, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surfaceHigh,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.cyan.withValues(alpha: 0.35)),
        ),
        child: Column(
          children: [
            Text('ROOM CODE',
                style: AppTheme.display(size: 11, color: AppColors.textMuted, spacing: 2)),
            const SizedBox(height: 4),
            Text(code, style: AppTheme.display(size: 32, color: AppColors.cyan, spacing: 8)),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.copy_rounded, size: 16, color: AppColors.textMuted),
                const SizedBox(width: 6),
                Text('Tap to copy', style: AppTheme.body(size: 14, color: AppColors.textMuted)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
