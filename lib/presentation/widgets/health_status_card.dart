import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/pet.dart';
import '../../logic/pet/pet_bloc.dart';
import '../../logic/theme/theme_cubit.dart';
import '../theme/app_theme.dart';
import 'accent_left_card.dart';

/// Modular Health Status Card widget displaying pet health attention levels
/// with dynamic color themes (Green for Healthy, Orange for Concerning, Red for Emergency)
/// and a counter badge of not HEALTHY pets inside the shield icon on the right.
class HealthStatusCard extends StatelessWidget {
  final List<Pet>? pets;
  final EdgeInsetsGeometry margin;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  const HealthStatusCard({
    super.key,
    this.pets,
    this.margin = EdgeInsets.zero,
    this.padding = const EdgeInsets.all(20),
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeCubit>().state;

    if (pets != null) {
      return _buildCard(context, pets!, isDark);
    }

    return BlocBuilder<PetBloc, PetState>(
      builder: (context, state) {
        final currentPets = state is PetLoaded ? state.pets : <Pet>[];
        return _buildCard(context, currentPets, isDark);
      },
    );
  }

  Widget _buildCard(BuildContext context, List<Pet> petList, bool isDark) {
    final theme = Theme.of(context);
    final textSecondary =
        isDark ? AppTheme.darkOnSurfaceVariant : AppTheme.secondary;

    final emergencyCount =
        petList.where((p) => p.status == 'EMERGENCY').length;
    final concerningCount =
        petList.where((p) => p.status == 'CONCERNING').length;
    final notHealthyCount = emergencyCount + concerningCount;

    Color accentColor;
    Color backgroundColor;
    String title;
    String subtitle;
    IconData headerIcon;

    if (emergencyCount > 0) {
      // Red base colors for EMERGENCY state
      accentColor =
          isDark ? AppTheme.statusOverdueDark : AppTheme.statusOverdue;
      backgroundColor =
          isDark ? AppTheme.statusOverdueDarkBg : AppTheme.statusOverdueBg;
      title = emergencyCount == 1
          ? 'Emergency attention needed'
          : '$emergencyCount pets in emergency state';
      subtitle = 'Immediate medical care or vet check required';
      headerIcon = Icons.warning_rounded;
    } else if (concerningCount > 0) {
      // Orange base colors for CONCERNING state
      accentColor =
          isDark ? AppTheme.statusConcerningDark : AppTheme.statusConcerning;
      backgroundColor =
          isDark ? AppTheme.statusConcerningDarkBg : AppTheme.statusConcerningBg;
      title = concerningCount == 1
          ? 'Attention needed'
          : '$concerningCount pets need attention';
      subtitle = 'Check pet health profiles and diary';
      headerIcon = Icons.warning_amber_rounded;
    } else {
      // Green base colors for HEALTHY / NORMAL state
      accentColor = isDark ? AppTheme.statusAdministeredDark : AppTheme.primary;
      backgroundColor = isDark
          ? const Color(0xFF2E4E30).withValues(alpha: 0.5)
          : AppTheme.primaryFixed.withValues(alpha: 0.3);
      if (petList.isEmpty) {
        title = 'No pets registered';
        subtitle = 'Add your first pet to sync health profile';
      } else {
        title = 'All pets healthy';
        subtitle = 'Medical sync up to date';
      }
      headerIcon = Icons.verified_user;
    }

    return AccentLeftCard(
      accentColor: accentColor,
      backgroundColor: backgroundColor,
      margin: margin,
      padding: padding,
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Shield icon with counter inside in top-right area
          Positioned(
            right: -10,
            bottom: -10,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  Icons.shield,
                  size: 80,
                  color: accentColor.withValues(alpha: 0.12),
                ),
                if (notHealthyCount > 0)
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: accentColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: accentColor.withValues(alpha: 0.4),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$notHealthyCount',
                      style: TextStyle(
                        color: (accentColor == AppTheme.statusOverdueDark ||
                                accentColor == AppTheme.statusConcerningDark)
                            ? Colors.black87
                            : Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    headerIcon,
                    color: accentColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'HEALTH STATUS',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: accentColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: accentColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 13,
                  color: textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
