import 'package:flutter/widgets.dart';

/// The three window sizes the app lays itself out for (PRD FR-19).
enum ScreenSize {
  /// < 700 px: phones, narrow windows. One column.
  compact,

  /// 700–1100 px: tablets, half-screen browser windows. Two columns.
  medium,

  /// ≥ 1100 px: desktop browsers. Full-width layouts with side panels.
  expanded;

  static const double mediumFrom = 700;
  static const double expandedFrom = 1100;

  static ScreenSize forWidth(double width) {
    if (width >= expandedFrom) return ScreenSize.expanded;
    if (width >= mediumFrom) return ScreenSize.medium;
    return ScreenSize.compact;
  }

  static ScreenSize of(BuildContext context) => forWidth(MediaQuery.sizeOf(context).width);

  bool get isCompact => this == ScreenSize.compact;
  bool get isWide => this != ScreenSize.compact;
}

/// Builds a different layout per [ScreenSize], from the space it is given
/// (not the whole window), so it also works inside a panel.
class Responsive extends StatelessWidget {
  final WidgetBuilder compact;
  final WidgetBuilder? medium; // falls back to [expanded], then [compact]
  final WidgetBuilder? expanded; // falls back to [medium], then [compact]

  const Responsive({super.key, required this.compact, this.medium, this.expanded});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, box) {
      final size = ScreenSize.forWidth(box.maxWidth);
      final builder = switch (size) {
        ScreenSize.expanded => expanded ?? medium ?? compact,
        ScreenSize.medium => medium ?? expanded ?? compact,
        ScreenSize.compact => compact,
      };
      return builder(context);
    });
  }
}

/// Outer padding and the widest content should get, per size.
extension ScreenSizeSpacing on ScreenSize {
  double get gutter => switch (this) {
        ScreenSize.compact => 16,
        ScreenSize.medium => 20,
        ScreenSize.expanded => 28,
      };

  /// Content wider than this just gets hard to read.
  double get maxContentWidth => switch (this) {
        ScreenSize.compact => 600,
        ScreenSize.medium => 1000,
        ScreenSize.expanded => 1400,
      };
}
