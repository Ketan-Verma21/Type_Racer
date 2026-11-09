import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:type_racer/data/models/player.dart';
import 'package:type_racer/screens/game/views/common.dart';
import 'package:type_racer/state/game_controller.dart';
import 'package:type_racer/theme/app_colors.dart';
import 'package:type_racer/theme/app_theme.dart';
import 'package:type_racer/ui/layout/breakpoints.dart';
import 'package:type_racer/ui/layout/panel.dart';
import 'package:type_racer/widgets/chat_panel.dart';
import 'package:type_racer/widgets/custom_button.dart';
import 'package:type_racer/widgets/settings_panel.dart';

/// Before the race: room code, settings, who's here, chat, and Start (host).
///   phone:   one scrolling column
///   tablet:  [code + settings + players | chat]
///   desktop: [code + settings | players | chat], chat always in view
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
    final size = ScreenSize.of(context);
    final g = game.game;
    final me = game.me!;

    final code = _RoomCode(code: g.id, onTap: () => widget.onCopyCode(g.id));
    final settings = SettingsPanel(
      settings: g.settings,
      isLeader: me.isHost,
      racerCount: g.racers.length,
      onChange: game.updateSettings,
    );
    final players = _Players(racers: g.racers, myId: me.id, max: g.settings.maxPlayers);
    ChatPanel chat({bool expand = false}) =>
        ChatPanel(myId: me.id, onSend: game.sendChat, onReact: game.sendReaction, expand: expand);
    final start = _StartBar(
      isHost: me.isHost,
      pressed: _startPressed,
      onStart: () => _start(game),
    );

    const gap = SizedBox(height: 12, width: 16);

    return Column(
      children: [
        GameTopBar(msg: game.timer.msg, onLeave: widget.onLeave),
        CountdownText(text: game.timer.countDown, size: size.isCompact ? 44 : 56),
        Expanded(
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: size.maxContentWidth),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: size.gutter),
                child: Responsive(
                  compact: (_) => ListView(
                    children: [code, gap, settings, gap, players, gap, chat(), gap],
                  ),
                  medium: (_) => Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: ListView(children: [code, gap, settings, gap, players, gap]),
                      ),
                      gap,
                      Expanded(child: Padding(padding: const EdgeInsets.only(bottom: 12), child: chat(expand: true))),
                    ],
                  ),
                  expanded: (_) => Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(flex: 4, child: ListView(children: [code, gap, settings, gap])),
                      gap,
                      Expanded(flex: 3, child: ListView(children: [players, gap])),
                      gap,
                      Expanded(
                        flex: 4,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: chat(expand: true),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        Padding(padding: const EdgeInsets.fromLTRB(16, 8, 16, 16), child: start),
      ],
    );
  }
}

/// Start (host) or "waiting for the host".
class _StartBar extends StatelessWidget {
  final bool isHost;
  final bool pressed;
  final VoidCallback onStart;
  const _StartBar({required this.isHost, required this.pressed, required this.onStart});

  @override
  Widget build(BuildContext context) {
    if (isHost) {
      return pressed
          ? Text('Starting...', style: AppTheme.display(size: 14, color: AppColors.textMuted))
          : CustomButton(text: 'Start', onTap: onStart);
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.hourglass_top_rounded, size: 18, color: AppColors.textMuted),
        const SizedBox(width: 8),
        Flexible(
          child: Text('Waiting for the host to start...',
              style: AppTheme.body(size: 16, color: AppColors.textMuted)),
        ),
      ],
    );
  }
}

class _Players extends StatelessWidget {
  final List<Player> racers;
  final String myId;
  final int max;
  const _Players({required this.racers, required this.myId, required this.max});

  @override
  Widget build(BuildContext context) {
    return Panel(
      title: 'PLAYERS ${racers.length}/$max',
      icon: Icons.groups_rounded,
      accent: AppColors.yellow,
      child: Wrap(
        spacing: 8,
        runSpacing: 6,
        children: [
          for (final p in racers)
            Chip(
              avatar: Text(p.isHost ? '👑' : '🏎️'),
              label: Text(p.nickname + (p.id == myId ? ' (you)' : '')),
            ),
        ],
      ),
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
