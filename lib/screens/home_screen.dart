import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:type_racer/theme/app_colors.dart';
import 'package:type_racer/theme/app_theme.dart';
import 'package:type_racer/widgets/custom_button.dart';
import 'package:type_racer/widgets/game_background.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      body: GameBackground(
        child: SafeArea(
          child: Center(
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
                  // gradient title
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
                  SizedBox(height: size.height * 0.08),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 20,
                    runSpacing: 20,
                    children: [
                      CustomButton(
                        text: 'Create',
                        ishome: true,
                        onTap: () =>
                            Navigator.pushNamed(context, '/create-room'),
                      ),
                      CustomButton(
                        text: 'Join',
                        ishome: true,
                        secondary: true,
                        onTap: () =>
                            Navigator.pushNamed(context, '/join-room'),
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
    );
  }
}
