import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../accent_left_card.dart';

class CalendarScheduleCard extends StatelessWidget {
  final String time;
  final String title;
  final String subtitle;
  final String petName;
  final IconData icon;
  final Color color;
  final bool isDark;
  final Color cardBg;
  final Color textSecondary;
  final Color textPrimary;
  final VoidCallback? onTap;

  const CalendarScheduleCard({
    super.key,
    required this.time,
    required this.title,
    required this.subtitle,
    required this.petName,
    required this.icon,
    required this.color,
    required this.isDark,
    required this.cardBg,
    required this.textSecondary,
    required this.textPrimary,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accentColor = isDark && color == AppTheme.primary
        ? AppTheme.primaryFixedDim
        : color;

    return AccentLeftCard(
      accentColor: accentColor,
      backgroundColor: cardBg,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                time,
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontWeight: FontWeight.bold,
                  color: accentColor,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'EVENT',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                  color: textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(width: 14),
          Container(
            height: 44,
            width: 1,
            color: isDark
                ? const Color(0xFF383634)
                : AppTheme.surfaceContainer,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF383634)
                        : AppTheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.pets,
                        size: 11,
                        color: isDark
                            ? AppTheme.darkOnSurface
                            : AppTheme.secondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        petName,
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? AppTheme.darkOnSurface
                              : AppTheme.secondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(icon, color: accentColor.withValues(alpha: 0.8), size: 22),
        ],
      ),
    );
  }
}
