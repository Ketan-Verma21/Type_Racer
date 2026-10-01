import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../utils/game_modes.dart';

/// Lobby settings. The host gets chips to change them; everyone else sees a
/// read-only summary.
class SettingsPanel extends StatelessWidget {
  final Map<String, dynamic> settings;
  final bool isLeader;
  final int racerCount;
  final void Function(Map<String, dynamic> newSettings) onChange;

  const SettingsPanel({
    Key? key,
    required this.settings,
    required this.isLeader,
    required this.racerCount,
    required this.onChange,
  }) : super(key: key);

  void _set(String key, dynamic value) {
    onChange({...settings, key: value});
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) {
    return ChoiceChip(
      label: Text(label,
          style: AppTheme.body(
            size: 15,
            weight: FontWeight.w700,
            color: selected ? AppColors.bg : AppColors.textPrimary,
          )),
      selected: selected,
      showCheckmark: false,
      selectedColor: AppColors.cyan,
      backgroundColor: AppColors.surfaceHigh,
      side: BorderSide(color: AppColors.cyan.withOpacity(0.3)),
      onSelected: (_) => onTap(),
    );
  }

  Widget _group(String label, Widget child) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: AppTheme.display(
                  size: 11, color: AppColors.textMuted, spacing: 2)),
          const SizedBox(height: 6),
          child,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mode = GameModes.byId(settings['mode']?.toString());
    final time = (settings['timeLimit'] as num).toInt();
    final length = settings['length'].toString();
    final maxPlayers = (settings['maxPlayers'] as num).toInt();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.85),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.magenta.withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.tune_rounded, color: AppColors.magenta, size: 20),
              const SizedBox(width: 8),
              Text('RACE SETTINGS', style: AppTheme.display(size: 14, spacing: 2)),
              const Spacer(),
              if (!isLeader)
                Text('host only',
                    style: AppTheme.body(size: 13, color: AppColors.textMuted)),
            ],
          ),
          if (isLeader) ...[
            _group(
              'MODE',
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (final m in GameModes.all)
                    _chip('${m.emoji} ${m.name}', m.id == mode.id,
                        () => _set('mode', m.id)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(mode.desc,
                  style: AppTheme.body(size: 14, color: AppColors.textMuted)),
            ),
            _group(
              'TIME LIMIT',
              Wrap(
                spacing: 8,
                children: [
                  for (final t in GameModes.times)
                    _chip('${t}s', t == time, () => _set('timeLimit', t)),
                ],
              ),
            ),
            _group(
              'QUOTE LENGTH',
              Wrap(
                spacing: 8,
                children: [
                  for (final e in GameModes.lengths.entries)
                    _chip(e.value, e.key == length, () => _set('length', e.key)),
                ],
              ),
            ),
            _group(
              'MAX PLAYERS',
              Row(
                children: [
                  IconButton(
                    onPressed: maxPlayers > racerCount && maxPlayers > 1
                        ? () => _set('maxPlayers', maxPlayers - 1)
                        : null,
                    icon: const Icon(Icons.remove_circle_outline_rounded),
                    color: AppColors.cyan,
                  ),
                  Text('$maxPlayers',
                      style: AppTheme.display(size: 18, color: AppColors.cyan)),
                  IconButton(
                    onPressed: maxPlayers < 8
                        ? () => _set('maxPlayers', maxPlayers + 1)
                        : null,
                    icon: const Icon(Icons.add_circle_outline_rounded),
                    color: AppColors.cyan,
                  ),
                ],
              ),
            ),
          ] else ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                Chip(label: Text('${mode.emoji} ${mode.name}')),
                Chip(label: Text('${time}s')),
                Chip(label: Text(GameModes.lengths[length] ?? length)),
                Chip(label: Text('Max $maxPlayers')),
              ],
            ),
            const SizedBox(height: 6),
            Text(mode.desc,
                style: AppTheme.body(size: 14, color: AppColors.textMuted)),
          ],
        ],
      ),
    );
  }
}
