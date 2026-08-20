import 'package:flutter/material.dart';

/// Where the layout changes shape.
///
/// Two numbers, kept in one place: a breakpoint repeated per screen stops
/// being a breakpoint the first time someone edits one copy of it.
enum LayoutSize {
  /// Phone, and any browser window narrowed to phone width: one column,
  /// destinations along the bottom where a thumb reaches them.
  compact,

  /// Tablet, or a desktop window sharing the screen: the destinations move
  /// to a side rail, so they stop being four icons stretched across a wall.
  medium,

  /// A full desktop window: the rail is wide enough to read as a menu.
  expanded;

  static const mediumMin = 600.0;
  static const expandedMin = 1100.0;

  static LayoutSize of(BuildContext context) =>
      fromWidth(MediaQuery.sizeOf(context).width);

  static LayoutSize fromWidth(double width) => width < mediumMin
      ? LayoutSize.compact
      : width < expandedMin
          ? LayoutSize.medium
          : LayoutSize.expanded;

  bool get isCompact => this == LayoutSize.compact;
}

/// Caps a screen's content and centres what is left over.
///
/// Line length is the reason. A phone layout poured into a 1440px window
/// gives 24px of text and 1300px of nothing between a label and its value,
/// which is how the app read on the web before this existed.
class ContentWidth extends StatelessWidget {
  /// Wide enough for a three-column stat row, narrow enough that a label and
  /// its value stay in the same glance.
  static const readable = 760.0;

  /// For screens whose content is a map: a map does get better with room.
  static const wide = 1080.0;

  final double maxWidth;
  final Widget child;

  const ContentWidth({
    super.key,
    this.maxWidth = readable,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}

/// Keeps a floating action button beside the content it acts on.
///
/// The default end-float pins the button to the window's corner, which on a
/// wide screen leaves it hovering over empty background a few hundred pixels
/// from the form it belongs to. This shifts it in by the same gutter
/// [ContentWidth] leaves, so the button tracks the column at any width.
///
/// It measures that gutter against the whole scaffold, so it belongs on
/// screens whose content is centred in it - a pushed screen, not one behind
/// the side rail.
class ContentAlignedFabLocation extends StandardFabLocation
    with FabEndOffsetX, FabFloatOffsetY {
  final double maxContentWidth;

  const ContentAlignedFabLocation(
      {this.maxContentWidth = ContentWidth.readable});

  @override
  double getOffsetX(
      ScaffoldPrelayoutGeometry scaffoldGeometry, double adjustment) {
    final endX = super.getOffsetX(scaffoldGeometry, adjustment);
    final gutter = (scaffoldGeometry.scaffoldSize.width - maxContentWidth) / 2;
    return gutter > 0 ? endX - gutter : endX;
  }
}
