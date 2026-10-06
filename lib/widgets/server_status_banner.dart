import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:provider/provider.dart';
import '../providers/server_status_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// Shows what the server is doing: waking up, online, or unreachable.
class ServerStatusBanner extends StatelessWidget {
  const ServerStatusBanner({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<ServerStatusProvider>(
      builder: (context, s, _) {
        Widget child;
        switch (s.state) {
          case ServerState.checking:
            child = const SizedBox(height: 56);
            break;
          case ServerState.waking:
            child = _card(
              color: AppColors.yellow,
              leading: const SpinKitWave(color: AppColors.yellow, size: 22),
              title: 'Waking up the server...',
              subtitle:
              'Free hosting sleeps when idle. This takes about a minute '
                  '(${s.secondsWaiting}s)',
            );
            break;
          case ServerState.ready:
            child = SizedBox(
              height: 56,
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.circle, size: 10, color: AppColors.green),
                    const SizedBox(width: 8),
                    Text('Server online',
                        style: AppTheme.body(
                            size: 15, color: AppColors.textMuted)),
                  ],
                ),
              ),
            );
            break;
          case ServerState.failed:
            child = _card(
              color: AppColors.red,
              leading: const Icon(Icons.cloud_off_rounded,
                  color: AppColors.red, size: 26),
              title: "Couldn't reach the server",
              subtitle: 'Check your internet connection and try again.',
              action: TextButton(
                onPressed: s.wake,
                child: const Text('Retry'),
              ),
            );
            break;
        }
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: KeyedSubtree(key: ValueKey(s.state), child: child),
        );
      },
    );
  }

  Widget _card({
    required Color color,
    required Widget leading,
    required String title,
    required String subtitle,
    Widget? action,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          leading,
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTheme.display(size: 13, spacing: 1)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style:
                    AppTheme.body(size: 14, color: AppColors.textMuted)),
              ],
            ),
          ),
          if (action != null) action,
        ],
      ),
    );
  }
}
