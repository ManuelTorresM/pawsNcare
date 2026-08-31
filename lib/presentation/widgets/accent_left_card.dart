import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../logic/theme/theme_cubit.dart';
import '../theme/app_theme.dart';

/// A reusable Card widget with a rounded container and a distinct 4px left-border accent stripe.
class AccentLeftCard extends StatelessWidget {
  final Color accentColor;
  final Color? backgroundColor;
  final Color? darkBackgroundColor;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final double borderRadius;
  final double borderWidth;
  final Widget child;

  const AccentLeftCard({
    super.key,
    required this.accentColor,
    required this.child,
    this.backgroundColor,
    this.darkBackgroundColor,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
    this.margin = const EdgeInsets.only(bottom: 12),
    this.borderRadius = 16.0,
    this.borderWidth = 4.0,
  });

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    try {
      final cubitState = context.watch<ThemeCubit?>()?.state;
      if (cubitState != null) {
        isDark = cubitState;
      }
    } catch (_) {}

    final Color bg = isDark
        ? (darkBackgroundColor ?? AppTheme.darkSurface)
        : (backgroundColor ?? AppTheme.surfaceContainerLow);

    Widget content = Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border(
          left: BorderSide(color: accentColor, width: borderWidth),
        ),
      ),
      padding: padding,
      child: child,
    );

    return Card(
      margin: margin,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      elevation: 0,
      color: bg,
      child: onTap != null
          ? InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(borderRadius),
              child: content,
            )
          : content,
    );
  }
}
