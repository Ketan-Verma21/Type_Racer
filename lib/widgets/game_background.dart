import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Animated night-city backdrop: soft neon glows + a scrolling "road" grid.
/// Wrap every screen body with this.
class GameBackground extends StatefulWidget {
  final Widget child;
  const GameBackground({Key? key, required this.child}) : super(key: key);

  @override
  State<GameBackground> createState() => _GameBackgroundState();
}

class _GameBackgroundState extends State<GameBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0B0F1E), Color(0xFF111A3A)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        AnimatedBuilder(
          animation: _c,
          builder: (_, __) => CustomPaint(painter: _GridPainter(_c.value)),
        ),
        _glow(top: -120, left: -100, color: AppColors.cyan),
        _glow(bottom: -140, right: -120, color: AppColors.magenta),
        widget.child,
      ],
    );
  }

  Widget _glow({
    double? top,
    double? bottom,
    double? left,
    double? right,
    required Color color,
  }) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: IgnorePointer(
        child: Container(
          width: 340,
          height: 340,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [color.withOpacity(0.22), color.withOpacity(0)],
            ),
          ),
        ),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  final double t;
  _GridPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.cyan.withOpacity(0.06)
      ..strokeWidth = 1;
    const gap = 48.0;
    final offset = t * gap;
    for (double y = -gap + offset; y < size.height; y += gap) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    for (double x = 0; x < size.width; x += gap) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter old) => old.t != t;
}
