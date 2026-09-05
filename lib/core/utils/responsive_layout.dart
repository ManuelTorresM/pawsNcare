import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ResponsiveLayout {
  static const double mobileBreakpoint = 600.0;
  static const double tabletBreakpoint = 900.0;
  static const double maxContentWidth = 1000.0;

  /// Checks if the hardware device is a tablet based on physical shortest side.
  static bool isTabletDevice(BuildContext context) =>
      MediaQuery.of(context).size.shortestSide >= 600;

  /// Checks if device is currently in landscape (horizontal) mode.
  static bool isLandscape(BuildContext context) =>
      MediaQuery.of(context).orientation == Orientation.landscape;

  /// Returns true ONLY if device is a tablet AND rotated horizontally (landscape).
  /// - Phone (Portrait/Landscape): false (Normal version)
  /// - Tablet (Portrait): false (Normal version)
  /// - Tablet (Landscape): true (Tablet version)
  static bool isTabletLayout(BuildContext context) {
    return isTabletDevice(context) && isLandscape(context);
  }

  static bool isWide(BuildContext context) => isTabletLayout(context);

  static bool isMobile(BuildContext context) => !isTabletLayout(context);

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= tabletBreakpoint;

  /// Restricts phone orientation strictly to vertical (portrait),
  /// while allowing tablets to rotate freely.
  static void enforceOrientation(BuildContext context) {
    if (!isTabletDevice(context)) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    } else {
      SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    }
  }

  static int getGridCrossAxisCount(
    BuildContext context, {
    int mobile = 1,
    int tablet = 2,
    int desktop = 3,
  }) {
    if (isTabletLayout(context)) return tablet;
    return mobile;
  }
}

class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(BuildContext context) mobile;
  final Widget Function(BuildContext context)? tablet;
  final Widget Function(BuildContext context)? desktop;

  const ResponsiveBuilder({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    ResponsiveLayout.enforceOrientation(context);

    if (ResponsiveLayout.isTabletLayout(context) && tablet != null) {
      return (tablet ?? mobile)(context);
    }
    return mobile(context);
  }
}

class ResponsiveMaxContainer extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry padding;

  const ResponsiveMaxContainer({
    super.key,
    required this.child,
    this.maxWidth = ResponsiveLayout.maxContentWidth,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}
