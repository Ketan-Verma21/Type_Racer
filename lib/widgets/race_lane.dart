import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// One player's lane: name, live WPM, %, glowing trail and a car that
/// slides smoothly along the track as `progress` (0..1) increases.
class RaceLane extends StatelessWidget {
  final String name;
  final double progress;
  final Color color;
  final int wpm; // live (or final) WPM, 0 = not known yet
  final bool isMe;
  final bool isLeader;
  final bool isEliminated;

  const RaceLane({
    Key? key,
    required this.name,
    required this.progress,
    required this.color,
    this.wpm = 0,
    this.isMe = false,
    this.isLeader = false,
    this.isEliminated = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final p = progress.isNaN ? 0.0 : progress.clamp(0.0, 1.0).toDouble();
    final finished = p >= 1;

    return Opacity(
      opacity: isEliminated ? 0.55 : 1,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
        decoration: BoxDecoration(
          color: AppColors.surface.withOpacity(0.85),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isMe ? AppColors.cyan : color.withOpacity(0.4),
            width: isMe ? 2 : 1,
          ),
          boxShadow: [BoxShadow(color: color.withOpacity(0.12), blurRadius: 14)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                isLeader
                    ? const Text('👑', style: TextStyle(fontSize: 16))
                    : Icon(Icons.person_rounded, size: 18, color: color),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    name,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.display(size: 14, spacing: 1),
                  ),
                ),
                if (isMe) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: AppColors.cyan,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text('YOU',
                        style: AppTheme.display(
                            size: 9, color: AppColors.bg, spacing: 1)),
                  ),
                ],
                const Spacer(),
                if (finished && !isEliminated)
                  const Padding(
                    padding: EdgeInsets.only(right: 6),
                    child: Icon(Icons.emoji_events_rounded,
                        color: AppColors.yellow, size: 20),
                  ),
                if (isEliminated)
                  Text('OUT',
                      style: AppTheme.display(size: 13, color: AppColors.red))
                else ...[
                  if (wpm > 0)
                    Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: Text('$wpm WPM',
                          style: AppTheme.display(
                              size: 12, color: AppColors.textMuted)),
                    ),
                  Text('${(p * 100).round()}%',
                      style: AppTheme.display(size: 14, color: color)),
                ],
              ],
            ),
            const SizedBox(height: 6),
            SizedBox(
              height: 46,
              child: LayoutBuilder(builder: (context, box) {
                const carW = 44.0;
                final travel = box.maxWidth - carW;
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      left: 0,
                      right: 0,
                      top: 22,
                      child: Container(
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceHigh,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeOutCubic,
                      left: 0,
                      top: 22,
                      width: travel * p + carW / 2,
                      child: Container(
                        height: 4,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: [
                            BoxShadow(
                                color: color.withOpacity(0.7), blurRadius: 10)
                          ],
                        ),
                      ),
                    ),
                    const Positioned(
                      right: 0,
                      top: 0,
                      child: Text('🏁', style: TextStyle(fontSize: 22)),
                    ),
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeOutCubic,
                      left: travel * p,
                      top: 4,
                      child: SizedBox(
                        width: carW,
                        child: isEliminated
                            ? const Text('💥', style: TextStyle(fontSize: 30))
                            : Transform.flip(
                                flipX: true, // emoji faces left; flip to face finish
                                child: const Text('🏎️',
                                    style: TextStyle(fontSize: 30)),
                              ),
                      ),
                    ),
                  ],
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
