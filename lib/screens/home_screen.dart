import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:type_racer/providers/server_status_provider.dart';
import 'package:type_racer/theme/app_colors.dart';
import 'package:type_racer/theme/app_theme.dart';
import 'package:type_racer/widgets/custom_button.dart';
import 'package:type_racer/widgets/game_background.dart';
import 'package:type_racer/widgets/server_status_banner.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // coming back to the app after a while: the server may have gone to sleep
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<ServerStatusProvider>().refreshIfStale();
    }
  }

  Future<void> _go(String route) async {
    final navigator = Navigator.of(context);
    final status = context.read<ServerStatusProvider>();
    // re-pings first if the server might be asleep
    if (await status.ensureReady() && mounted) {
      navigator.pushNamed(route);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final ready = context.watch<ServerStatusProvider>().isReady;

    return Scaffold(
      body: GameBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // bobbing car
                    const Text('🏎️', style: TextStyle(fontSize: 72))
                        .animate(onPlay: (c) => c.repeat(reverse: true))
                        .moveY(
                      begin: -8,
                      end: 8,
                      duration: 900.ms,
                      curve: Curves.easeInOut,
                    ),
                    const SizedBox(height: 12),
                    ShaderMask(
                      shaderCallback: (r) =>
                          AppColors.titleGradient.createShader(r),
                      child: Text(
                        'TYPE RACER',
                        style: AppTheme.display(
                            size: 40, color: Colors.white, spacing: 4),
                      ),
                    )
                        .animate()
                        .fadeIn(duration: 600.ms)
                        .slideY(begin: -0.3, curve: Curves.easeOutBack),
                    const SizedBox(height: 10),
                    Text(
                      'Create or join a room to race!',
                      style: AppTheme.body(
                          size: 20, color: AppColors.textMuted),
                    ).animate().fadeIn(delay: 300.ms, duration: 600.ms),
                    SizedBox(height: size.height * 0.05),
                    const ServerStatusBanner(),
                    SizedBox(height: size.height * 0.03),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 20,
                      runSpacing: 20,
                      children: [
                        CustomButton(
                          text: 'Create',
                          ishome: true,
                          onTap: ready ? () => _go('/create-room') : null,
                        ),
                        CustomButton(
                          text: 'Join',
                          ishome: true,
                          secondary: true,
                          onTap: ready ? () => _go('/join-room') : null,
                        ),
                      ],
                    )
                        .animate()
                        .fadeIn(delay: 500.ms, duration: 500.ms)
                        .slideY(begin: 0.3, curve: Curves.easeOut),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
