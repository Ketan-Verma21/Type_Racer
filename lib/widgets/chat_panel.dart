import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

const List<String> kReactionEmojis = ['😂', '🔥', '👏', '😮', '💀', '❤️'];

/// Row of emoji buttons. Tapping one floats it across everyone's screen.
class ReactionBar extends StatelessWidget {
  final void Function(String emoji) onReact;
  const ReactionBar({Key? key, required this.onReact}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      children: [
        for (final e in kReactionEmojis)
          InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => onReact(e),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.surfaceHigh,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.cyan.withOpacity(0.25)),
              ),
              child: Text(e, style: const TextStyle(fontSize: 22)),
            ),
          ),
      ],
    );
  }
}

/// Lobby chat: message list, input box and reaction buttons.
class ChatPanel extends StatefulWidget {
  final String myId;
  final void Function(String text) onSend;
  final void Function(String emoji) onReact;

  const ChatPanel({
    Key? key,
    required this.myId,
    required this.onSend,
    required this.onReact,
  }) : super(key: key);

  @override
  State<ChatPanel> createState() => _ChatPanelState();
}

class _ChatPanelState extends State<ChatPanel> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scroll = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    widget.onSend(text);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.85),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cyan.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.chat_bubble_outline_rounded,
                  color: AppColors.cyan, size: 20),
              const SizedBox(width: 8),
              Text('LOBBY CHAT', style: AppTheme.display(size: 14, spacing: 2)),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 130,
            child: Consumer<ChatProvider>(
              builder: (context, chat, _) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scroll.hasClients) {
                    _scroll.jumpTo(_scroll.position.maxScrollExtent);
                  }
                });
                if (chat.messages.isEmpty) {
                  return Center(
                    child: Text('Say hi 👋',
                        style: AppTheme.body(color: AppColors.textMuted)),
                  );
                }
                return ListView.builder(
                  controller: _scroll,
                  itemCount: chat.messages.length,
                  itemBuilder: (_, i) {
                    final m = chat.messages[i];
                    final mine = m.playerId == widget.myId;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text.rich(TextSpan(children: [
                        TextSpan(
                          text: '${m.nickname}: ',
                          style: AppTheme.body(
                              size: 15,
                              weight: FontWeight.w800,
                              color: mine ? AppColors.cyan : AppColors.magenta),
                        ),
                        TextSpan(text: m.text, style: AppTheme.body(size: 15)),
                      ])),
                    );
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  maxLength: 140,
                  onSubmitted: (_) => _send(),
                  style: AppTheme.body(size: 16),
                  decoration: const InputDecoration(
                    hintText: 'Type a message...',
                    counterText: '',
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _send,
                icon: const Icon(Icons.send_rounded),
                color: AppColors.cyan,
              ),
            ],
          ),
          const SizedBox(height: 10),
          ReactionBar(onReact: widget.onReact),
        ],
      ),
    );
  }
}

/// Emojis that float up the screen when anyone reacts. Put it in a Stack.
class ReactionOverlay extends StatelessWidget {
  const ReactionOverlay({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Consumer<ChatProvider>(
        builder: (context, chat, _) => Stack(
          children: [
            for (final r in chat.reactions)
              Align(
                key: ValueKey(r.id),
                alignment: Alignment(r.x, 0.85),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(r.emoji, style: const TextStyle(fontSize: 44)),
                    Text(r.nickname,
                        style: AppTheme.body(
                            size: 12,
                            weight: FontWeight.w800,
                            color: AppColors.textPrimary)),
                  ],
                )
                    .animate()
                    .moveY(
                        begin: 0,
                        end: -280,
                        duration: 2300.ms,
                        curve: Curves.easeOut)
                    .fadeIn(duration: 200.ms)
                    .fadeOut(delay: 1800.ms, duration: 500.ms),
              ),
          ],
        ),
      ),
    );
  }
}
