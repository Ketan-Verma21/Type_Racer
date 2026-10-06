import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// Glowing gradient button with a press animation.
/// `onTap: null` shows it greyed out and ignores taps.
class CustomButton extends StatefulWidget {
  final String text;
  final VoidCallback? onTap;
  final bool ishome;
  final bool secondary;

  const CustomButton({
    Key? key,
    required this.text,
    this.onTap,
    this.ishome = false,
    this.secondary = false,
  }) : super(key: key);

  @override
  State<CustomButton> createState() => _CustomButtonState();
}

class _CustomButtonState extends State<CustomButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    final gradient =
    widget.secondary ? AppColors.secondaryGradient : AppColors.primaryGradient;
    final glow = widget.secondary ? AppColors.magenta : AppColors.cyan;

    return Opacity(
      opacity: enabled ? 1 : 0.4,
      child: GestureDetector(
        onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: enabled
            ? (_) {
          setState(() => _pressed = false);
          widget.onTap?.call();
        }
            : null,
        child: AnimatedScale(
          scale: _pressed ? 0.94 : 1,
          duration: const Duration(milliseconds: 100),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            constraints: BoxConstraints(minWidth: widget.ishome ? 150 : 240),
            padding: EdgeInsets.symmetric(
              horizontal: 28,
              vertical: widget.ishome ? 18 : 15,
            ),
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: glow.withOpacity(!enabled ? 0 : (_pressed ? 0.25 : 0.55)),
                  blurRadius: _pressed ? 8 : 22,
                  spreadRadius: _pressed ? 0 : 1,
                ),
              ],
            ),
            child: Text(
              widget.text.toUpperCase(),
              textAlign: TextAlign.center,
              style: AppTheme.display(
                size: widget.ishome ? 18 : 16,
                color: AppColors.bg,
                spacing: 2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
