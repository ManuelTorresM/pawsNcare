import 'package:flutter/material.dart';

class ResponsiveLayout {
  static const double mobileBreakpoint = 600.0;
  static const double tabletBreakpoint = 900.0;
  static const double maxContentWidth = 1000.0;

  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < mobileBreakpoint;

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= mobileBreakpoint && width < tabletBreakpoint;
  }

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= tabletBreakpoint;

  static bool isWide(BuildContext context) =>
      MediaQuery.of(context).size.width >= mobileBreakpoint;

  static int getGridCrossAxisCount(BuildContext context, {int mobile = 1, int tablet = 2, int desktop = 3}) {
    final width = MediaQuery.of(context).size.width;
    if (width >= tabletBreakpoint) return desktop;
    if (width >= mobileBreakpoint) return tablet;
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
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= ResponsiveLayout.tabletBreakpoint) {
          return (desktop ?? tablet ?? mobile)(context);
        }
        if (constraints.maxWidth >= ResponsiveLayout.mobileBreakpoint) {
          return (tablet ?? mobile)(context);
        }
        return mobile(context);
      },
    );
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
