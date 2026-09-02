import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/pet.dart';
import '../../../data/models/medication.dart';
import '../../../logic/theme/theme_cubit.dart';
import '../../../logic/auth/auth_bloc.dart';
import '../../../logic/pet/pet_bloc.dart';
import '../../../core/utils/responsive_layout.dart';
import '../../theme/app_theme.dart';
import '../../widgets/accent_left_card.dart';
import '../../widgets/memory_image_card.dart';
import '../../widgets/dashboard/home_invitation_banner.dart';
import '../pet/pet_profile_screen.dart';
import '../pet/add_pet_wizard.dart';
import '../nutrition/nutrition_screen.dart';
import '../pet/pet_album_screen.dart';

class HomeTab extends StatefulWidget {
  final VoidCallback onNavigateToDiary;
  final VoidCallback onNavigateToCalendar;

  const HomeTab({
    super.key,
    required this.onNavigateToDiary,
    required this.onNavigateToCalendar,
  });

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showSafetyGuide() {
    final parentContext = context;
    final isDark = parentContext.read<ThemeCubit>().state;
    final dialogBg = isDark ? AppTheme.darkBackground : AppTheme.background;
    final cardBg = isDark
        ? AppTheme.darkSurface
        : AppTheme.surfaceContainerLowest;
    final borderCol = isDark
        ? const Color(0xFF383634)
        : AppTheme.surfaceContainer;
    final textPrimary = isDark ? AppTheme.darkOnSurface : AppTheme.onSurface;
    final textSecondary = isDark
        ? AppTheme.darkOnSurfaceVariant
        : AppTheme.secondary;

    showDialog(
      context: parentContext,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setModalState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              backgroundColor: dialogBg,
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 24,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top Bar in Dialog
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14,
                        ),
                        color: isDark ? AppTheme.darkSurface : AppTheme.surface,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.ac_unit,
                                  color: AppTheme.primary,
                                  size: 22,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Winter Safety',
                                  style: TextStyle(
                                    fontFamily: 'Montserrat',
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: textPrimary,
                                  ),
                                ),
                              ],
                            ),
                            IconButton(
                              onPressed: () =>
                                  Navigator.of(dialogContext).pop(),
                              icon: Icon(
                                Icons.close,
                                color: textSecondary,
                                size: 20,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),

                      Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Hero Banner
                            Container(
                              width: double.infinity,
                              height: 180,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                gradient: LinearGradient(
                                  colors: isDark
                                      ? const [
                                          Color(0xFF1E293B),
                                          Color(0xFF0F172A),
                                        ]
                                      : const [
                                          AppTheme.primary,
                                          Color(0xFF2E4E30),
                                        ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                              child: Stack(
                                children: [
                                  Positioned(
                                    right: -20,
                                    bottom: -20,
                                    child: Icon(
                                      Icons.pets,
                                      size: 140,
                                      color: Colors.white.withValues(
                                        alpha: 0.1,
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(20.0),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppTheme.primaryFixed,
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                          ),
                                          child: const Text(
                                            'Seasonal Guide',
                                            style: TextStyle(
                                              fontFamily: 'Inter',
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: AppTheme
                                                  .onPrimaryFixedVariant,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        const Text(
                                          'Cold Weather Care',
                                          style: TextStyle(
                                            fontFamily: 'Montserrat',
                                            fontSize: 22,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Keep your furry family members safe, warm, and happy during winter.',
                                          style: TextStyle(
                                            fontFamily: 'Inter',
                                            fontSize: 12,
                                            color: Colors.white.withValues(
                                              alpha: 0.9,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),

                            // 4 Winter Safety Cards (Vertical Stack)
                            _buildSafetyTipCard(
                              icon: Icons.pets,
                              iconColor: AppTheme.primary,
                              iconBg: AppTheme.primaryFixed,
                              title: 'Paws Protection',
                              desc:
                                  'Sidewalk salt and chemical de-icers can cause severe irritation to paw pads and are toxic if ingested during grooming. Always wipe your pet\'s paws with a warm, damp cloth immediately after returning from a walk.',
                              cardBg: cardBg,
                              borderCol: borderCol,
                              textPrimary: textPrimary,
                              textSecondary: textSecondary,
                            ),
                            const SizedBox(height: 12),

                            _buildSafetyTipCard(
                              icon: Icons.device_thermostat,
                              iconColor: AppTheme.tertiary,
                              iconBg: AppTheme.tertiaryFixed,
                              title: 'Temperature Check',
                              desc:
                                  'A general rule: if it\'s too cold for you, it\'s too cold for them. Short-haired breeds, puppies, and senior dogs are especially vulnerable. Limit outdoor time when temperatures drop below freezing.',
                              cardBg: cardBg,
                              borderCol: borderCol,
                              textPrimary: textPrimary,
                              textSecondary: textSecondary,
                            ),
                            const SizedBox(height: 12),

                            _buildSafetyTipCard(
                              icon: Icons.warning_amber_rounded,
                              iconColor: AppTheme.error,
                              iconBg: AppTheme.errorContainer,
                              title: 'Antifreeze Alert',
                              desc:
                                  'Ethylene glycol, common in antifreeze, is highly toxic to pets but has a sweet taste that attracts them. Even a small amount can be fatal. Clean up any spills in your garage or driveway immediately and consider using pet-safe propylene glycol alternatives. If you suspect ingestion, contact emergency veterinary care instantly.',
                              cardBg: cardBg,
                              borderCol: borderCol,
                              textPrimary: textPrimary,
                              textSecondary: textSecondary,
                            ),
                            const SizedBox(height: 12),

                            _buildSafetyTipCard(
                              icon: Icons.checkroom,
                              iconColor: AppTheme.secondary,
                              iconBg: AppTheme.secondaryContainer,
                              title: 'Winter Gear',
                              desc:
                                  'Protective clothing isn\'t just a fashion statement—it\'s essential medical prevention for many breeds. Insulated coats protect the core, while booties prevent ice buildup between toes and shield against harsh chemicals.',
                              cardBg: cardBg,
                              borderCol: borderCol,
                              textPrimary: textPrimary,
                              textSecondary: textSecondary,
                            ),
                            const SizedBox(height: 20),

                            // Simple Advertisement: Call your local vet
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: isDark
                                      ? [
                                          const Color(0xFF2E221E),
                                          const Color(0xFF231916),
                                        ]
                                      : [
                                          const Color(0xFFFFF3EE),
                                          const Color(0xFFFFEAE2),
                                        ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: AppTheme.tertiary.withValues(
                                    alpha: isDark ? 0.35 : 0.3,
                                  ),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.tertiary.withValues(
                                      alpha: isDark ? 0.15 : 0.08,
                                    ),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: AppTheme.tertiary,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppTheme.tertiary.withValues(
                                            alpha: 0.3,
                                          ),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.phone_in_talk_rounded,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              'Call Your Local Vet',
                                              style: TextStyle(
                                                fontFamily: 'Montserrat',
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                                color: textPrimary,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 6,
                                                    vertical: 2,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: AppTheme.tertiary,
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: const Text(
                                                'AD',
                                                style: TextStyle(
                                                  fontFamily: 'Inter',
                                                  fontSize: 8,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                  letterSpacing: 0.5,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          'In case of emergency, contact your nearest veterinarian clinic immediately.',
                                          style: TextStyle(
                                            fontFamily: 'Inter',
                                            fontSize: 11,
                                            color: textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSafetyTipCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String desc,
    required Color cardBg,
    required Color borderCol,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderCol),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 20),
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
                    fontSize: 15,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  desc,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    height: 1.4,
                    color: textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeCubit>().state;
    final textSecondary = isDark
        ? AppTheme.darkOnSurfaceVariant
        : AppTheme.secondary;
    final textPrimary = isDark ? AppTheme.darkOnSurface : AppTheme.onSurface;
    final cardBg = isDark
        ? AppTheme.darkSurface
        : AppTheme.surfaceContainerLowest;
    final headerColor = isDark ? AppTheme.primaryFixedDim : AppTheme.primary;
    final theme = Theme.of(context);

    return RefreshIndicator(
      onRefresh: () async {
        context.read<PetBloc>().add(LoadPets());
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 100), // padding for bottom nav
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Greeting Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: BlocBuilder<AuthBloc, AuthState>(
                builder: (context, state) {
                  String name = 'Pet Parent';
                  if (state is Authenticated && state.name.isNotEmpty) {
                    name = state.name;
                  } else {
                    final currentUser = FirebaseAuth.instance.currentUser;
                    if (currentUser?.displayName?.isNotEmpty == true) {
                      name = currentUser!.displayName!;
                    } else if (currentUser?.email?.isNotEmpty == true) {
                      name = currentUser!.email!.split('@').first;
                    }
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Good Evening, $name!',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Your furry family is doing great today.',
                        style: TextStyle(color: textSecondary),
                      ),
                    ],
                  );
                },
              ),
            ),

            // Health Status & Stats Layout
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  // Health Card
                  BlocBuilder<PetBloc, PetState>(
                    builder: (context, petState) {
                      String healthTitle = 'All pets healthy';
                      String healthSubtitle = 'Medical sync up to date';

                      if (petState is PetLoaded) {
                        if (petState.pets.isEmpty) {
                          healthTitle = 'No pets registered';
                          healthSubtitle =
                              'Add your first pet to sync health profile';
                        } else {
                          final hasAttention = petState.pets.any(
                            (p) => p.status == 'Check Diary',
                          );
                          if (hasAttention) {
                            healthTitle = 'Attention needed';
                            healthSubtitle = 'Check diary entries for updates';
                          }
                        }
                      }

                      return AccentLeftCard(
                        accentColor: headerColor,
                        backgroundColor: isDark
                            ? const Color(0xFF2E4E30).withValues(alpha: 0.5)
                            : AppTheme.primaryFixed.withValues(alpha: 0.3),
                        margin: EdgeInsets.zero,
                        padding: const EdgeInsets.all(20),
                        child: Stack(
                          children: [
                            Positioned(
                              right: -10,
                              bottom: -10,
                              child: Icon(
                                Icons.shield,
                                size: 80,
                                color: headerColor.withValues(alpha: 0.08),
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.verified_user,
                                      color: headerColor,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'HEALTH STATUS',
                                      style: theme.textTheme.labelSmall
                                          ?.copyWith(
                                            color: headerColor,
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  healthTitle,
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: headerColor,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  healthSubtitle,
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
                    },
                  ),
                  const SizedBox(height: 16),

                  // Quick Stats Cards Row (Dynamic & Functional)
                  BlocBuilder<PetBloc, PetState>(
                    builder: (context, petState) {
                      int monthEventsAheadCount = 0;
                      String nextEventSubtitle = 'No schedule';
                      int expiredTasksCount = 0;
                      String expiredTaskSubtitle = 'All up to date';

                      if (petState is PetLoaded && petState.pets.isNotEmpty) {
                        final now = DateTime.now();
                        final List<Medication> upcomingMonthEvents = [];
                        final List<Medication> expiredTasks = [];

                        for (var p in petState.pets) {
                          for (var m in p.medications) {
                            if (!m.isCompleted) {
                              if (m.nextDoseDate.isBefore(now)) {
                                // Expired task without completion
                                expiredTasks.add(m);
                              } else {
                                // Upcoming event in the month ahead
                                final endOfMonth = DateTime(
                                  now.year,
                                  now.month + 1,
                                  0,
                                  23,
                                  59,
                                  59,
                                );
                                if (m.nextDoseDate.isBefore(endOfMonth) ||
                                    m.nextDoseDate.difference(now).inDays <=
                                        30) {
                                  upcomingMonthEvents.add(m);
                                }
                              }
                            }
                          }
                        }

                        // 1. Month Events Ahead
                        upcomingMonthEvents.sort(
                          (a, b) => a.nextDoseDate.compareTo(b.nextDoseDate),
                        );
                        monthEventsAheadCount = upcomingMonthEvents.length;

                        if (upcomingMonthEvents.isNotEmpty) {
                          final nextDate =
                              upcomingMonthEvents.first.nextDoseDate;
                          const months = [
                            'Jan',
                            'Feb',
                            'Mar',
                            'Apr',
                            'May',
                            'Jun',
                            'Jul',
                            'Aug',
                            'Sep',
                            'Oct',
                            'Nov',
                            'Dec',
                          ];
                          if (nextDate.year == now.year &&
                              nextDate.month == now.month &&
                              nextDate.day == now.day) {
                            nextEventSubtitle = 'Next: Today';
                          } else {
                            nextEventSubtitle =
                                'Next: ${months[nextDate.month - 1]} ${nextDate.day}';
                          }
                        }

                        // 2. Expired Tasks (without completion)
                        expiredTasks.sort(
                          (a, b) => a.nextDoseDate.compareTo(b.nextDoseDate),
                        );
                        expiredTasksCount = expiredTasks.length;

                        if (expiredTasks.isNotEmpty) {
                          expiredTaskSubtitle =
                              'Overdue: ${expiredTasks.first.name}';
                        } else {
                          expiredTaskSubtitle = 'All up to date';
                        }
                      }

                      return Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: widget.onNavigateToCalendar,
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: cardBg,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: isDark ? 0.2 : 0.02,
                                      ),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? const Color(0xFF383634)
                                            : AppTheme.secondaryContainer,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        Icons.calendar_month,
                                        color: textSecondary,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            monthEventsAheadCount > 0
                                                ? '$monthEventsAheadCount event${monthEventsAheadCount == 1 ? '' : 's'}'
                                                : '0 events',
                                            style: theme.textTheme.labelLarge
                                                ?.copyWith(
                                                  fontSize: 14,
                                                  color: textPrimary,
                                                ),
                                          ),
                                          Text(
                                            nextEventSubtitle,
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: textSecondary,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GestureDetector(
                              onTap: widget.onNavigateToDiary,
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: cardBg,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: isDark ? 0.2 : 0.02,
                                      ),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: expiredTasksCount > 0
                                            ? (isDark
                                                  ? const Color(0xFF5C2B29)
                                                  : const Color(0xFFFFDAD6))
                                            : (isDark
                                                  ? const Color(0xFF2E4E30)
                                                  : AppTheme.tertiaryFixed),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        expiredTasksCount > 0
                                            ? Icons.warning_amber_rounded
                                            : Icons.event_note,
                                        color: expiredTasksCount > 0
                                            ? (isDark
                                                  ? const Color(0xFFFFB4A3)
                                                  : const Color(0xFF410E0B))
                                            : (isDark
                                                  ? AppTheme.primaryFixedDim
                                                  : AppTheme
                                                        .onTertiaryFixedVariant),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            expiredTasksCount > 0
                                                ? '$expiredTasksCount expired'
                                                : '0 pending',
                                            style: theme.textTheme.labelLarge
                                                ?.copyWith(
                                                  fontSize: 14,
                                                  color: expiredTasksCount > 0
                                                      ? (isDark
                                                            ? const Color(
                                                                0xFFFFB4A3,
                                                              )
                                                            : const Color(
                                                                0xFFB3261E,
                                                              ))
                                                      : textPrimary,
                                                ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          Text(
                                            expiredTaskSubtitle,
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: textSecondary,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Quick Link: Nutrition & Hydration Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: AccentLeftCard(
                accentColor: isDark
                    ? AppTheme.foodConceptDark
                    : AppTheme.foodConcept,
                backgroundColor: cardBg,
                margin: EdgeInsets.zero,
                padding: const EdgeInsets.all(16),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const NutritionScreen()),
                  );
                },
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color:
                            (isDark
                                    ? AppTheme.foodConceptDark
                                    : AppTheme.foodConcept)
                                .withValues(alpha: isDark ? 0.25 : 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.restaurant,
                        color: isDark
                            ? AppTheme.foodConceptDark
                            : AppTheme.foodConcept,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Nutrition & Hydration',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Manage meals and logs',
                            style: TextStyle(
                              fontSize: 13,
                              color: textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right, color: textSecondary),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Your Pets Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Your Pets',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                  color: textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Search Bar Input
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextFormField(
                controller: _searchController,
                onChanged: (value) {
                  context.read<PetBloc>().add(SearchPets(value));
                },
                style: TextStyle(color: textPrimary),
                decoration: InputDecoration(
                  hintText: 'Search by name...',
                  hintStyle: TextStyle(color: textSecondary),
                  prefixIcon: Icon(Icons.search, color: textSecondary),
                  fillColor: cardBg,
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: isDark
                          ? const Color(0xFF383634)
                          : AppTheme.surfaceContainer,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: isDark
                          ? const Color(0xFF383634)
                          : AppTheme.surfaceContainer,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Pets Grid
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: BlocBuilder<PetBloc, PetState>(
                builder: (context, state) {
                  if (state is PetLoading) {
                    return Center(
                      child: CircularProgressIndicator(color: headerColor),
                    );
                  } else if (state is PetLoaded) {
                    final currentUser = FirebaseAuth.instance.currentUser;
                    final currentUid = currentUser?.uid ?? '';
                    final currentEmail = currentUser?.email ?? '';

                    final pets = state.filteredPets.where((pet) {
                      final isPendingInviteForUser = pet.members.any(
                        (m) =>
                            m.status == 'Pending' &&
                            ((currentUid.isNotEmpty && m.id == currentUid) ||
                                (currentEmail.isNotEmpty &&
                                    m.email.toLowerCase() ==
                                        currentEmail.toLowerCase())),
                      );

                      // Hide only if this pet is a pending invitation for current user
                      if (isPendingInviteForUser) return false;

                      // Otherwise show all owned pets and accepted shared pets
                      return true;
                    }).toList();

                    return Column(
                      children: [
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount:
                                ResponsiveLayout.getGridCrossAxisCount(
                              context,
                              mobile: 2,
                              tablet: 3,
                              desktop: 4,
                            ),
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.85,
                          ),
                          itemCount: pets.length,
                          itemBuilder: (context, index) {
                            final pet = pets[index];
                            Color statusColor = headerColor;
                            Color statusBgColor = isDark
                                ? const Color(0xFF2E4E30)
                                : AppTheme.primaryFixed.withValues(alpha: 0.3);
                            if (pet.status == 'Check Diary') {
                              statusColor = isDark
                                  ? const Color(0xFFFFB4A3)
                                  : AppTheme.tertiary;
                              statusBgColor = isDark
                                  ? const Color(0xFF5C2B1D)
                                  : AppTheme.tertiaryFixed.withValues(
                                      alpha: 0.4,
                                    );
                            } else if (pet.status == 'Puppy') {
                              statusColor = textSecondary;
                              statusBgColor = isDark
                                  ? const Color(0xFF383634)
                                  : AppTheme.secondaryContainer.withValues(
                                      alpha: 0.6,
                                    );
                            }
                            return AccentLeftCard(
                              accentColor: statusColor,
                              backgroundColor: cardBg,
                              margin: EdgeInsets.zero,
                              padding: const EdgeInsets.all(12.0),
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => PetProfileScreen(pet: pet),
                                  ),
                                );
                              },
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: pet.avatarUrl.startsWith('assets/')
                                          ? Image.asset(
                                              pet.avatarUrl,
                                              fit: BoxFit.cover,
                                            )
                                          : (pet.avatarUrl.startsWith('http') ||
                                                  pet.avatarUrl.startsWith('https')
                                              ? Image.network(
                                                  pet.avatarUrl,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (_, _, _) =>
                                                      Container(
                                                    color: isDark
                                                        ? const Color(
                                                            0xFF383634,
                                                          )
                                                        : AppTheme.primaryFixed
                                                            .withValues(
                                                              alpha: 0.3,
                                                            ),
                                                    child: const Icon(
                                                      Icons.pets,
                                                      size: 32,
                                                      color: AppTheme.primary,
                                                    ),
                                                  ),
                                                )
                                              : (pet.avatarUrl.isNotEmpty &&
                                                      File(
                                                        pet.avatarUrl,
                                                      ).existsSync()
                                                  ? Image.file(
                                                      File(pet.avatarUrl),
                                                      fit: BoxFit.cover,
                                                      errorBuilder: (_, _, _) =>
                                                          Container(
                                                        color: isDark
                                                            ? const Color(
                                                                0xFF383634,
                                                              )
                                                            : AppTheme
                                                                .primaryFixed
                                                                .withValues(
                                                                  alpha: 0.3,
                                                                ),
                                                        child: const Icon(
                                                          Icons.pets,
                                                          size: 32,
                                                          color: AppTheme
                                                              .primary,
                                                        ),
                                                      ),
                                                    )
                                                  : Container(
                                                      color: isDark
                                                          ? const Color(
                                                              0xFF383634,
                                                            )
                                                          : AppTheme.primaryFixed
                                                              .withValues(
                                                                alpha: 0.3,
                                                              ),
                                                      child: const Icon(
                                                        Icons.pets,
                                                        size: 32,
                                                        color: AppTheme.primary,
                                                      ),
                                                    ))),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              pet.name,
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                                color: textPrimary,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            Text(
                                              pet.breed,
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: textSecondary,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: statusBgColor,
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: Text(
                                          pet.status,
                                          style: TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                            color: statusColor,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 16),

                        // Add Pet Dashed Button
                        OutlinedButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const AddPetWizard(),
                              ),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: isDark
                                  ? const Color(0xFF383634)
                                  : theme.colorScheme.outline.withValues(
                                      alpha: 0.5,
                                    ),
                              width: 1.5,
                              style: BorderStyle.solid,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            backgroundColor: cardBg,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: isDark
                                    ? const Color(0xFF383634)
                                    : AppTheme.secondaryContainer,
                                child: Icon(
                                  Icons.add,
                                  color: textSecondary,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Add New Pet',
                                style: TextStyle(
                                  color: textSecondary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Invitation Received Banner
                        HomeInvitationBanner(
                          allPets: state.pets,
                          isDark: isDark,
                          textSecondary: textSecondary,
                        ),
                      ],
                    );
                  } else if (state is PetError) {
                    return Center(child: Text('Error: ${state.message}'));
                  }
                  return const Center(child: Text('No pets logged.'));
                },
              ),
            ),
            const SizedBox(height: 32),

            // Recent Memories Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recent Memories',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: textPrimary,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const PetAlbumScreen(),
                        ),
                      );
                    },
                    child: Text(
                      'View Album',
                      style: TextStyle(
                        color: headerColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Horizontal scrolling memories (Max 5 most recent memories)
            BlocBuilder<PetBloc, PetState>(
              builder: (context, state) {
                final List<MapEntry<String, Pet>> memoryEntries = [];
                if (state is PetLoaded) {
                  for (final pet in state.pets) {
                    for (final photo in pet.photos) {
                      memoryEntries.add(MapEntry(photo, pet));
                    }
                  }
                }

                // Newest memories appear first (on the left)
                final limitedMemories = memoryEntries.take(5).toList();

                if (limitedMemories.isEmpty) {
                  return Container(
                    height: 100,
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      'No memories added yet.',
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        color: textSecondary,
                      ),
                    ),
                  );
                }

                return SizedBox(
                  height: 140,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: limitedMemories.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final memory = limitedMemories[index];
                      final photoUrl = memory.key;
                      final ownerPet = memory.value;

                      return MemoryImageCard(
                        url: photoUrl,
                        width: 140,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => PetProfileScreen(pet: ownerPet),
                            ),
                          );
                        },
                      );
                    },
                  ),
                );
              },
            ),
            const SizedBox(height: 24),

            // Winter Safety Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: LinearGradient(
                    colors: isDark
                        ? const [Color(0xFF1E293B), Color(0xFF0F172A)]
                        : const [Color(0xFF0284C7), Color(0xFF0369A1)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (isDark ? Colors.black : const Color(0xFF0284C7))
                          .withValues(alpha: 0.2),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // Background Glow Decorative Circles
                    Positioned(
                      right: -30,
                      top: -30,
                      child: Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 10,
                      bottom: -25,
                      child: Icon(
                        Icons.ac_unit,
                        size: 130,
                        color: Colors.white.withValues(alpha: 0.12),
                      ),
                    ),

                    // Card Content
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Top Category Badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.3),
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.ac_unit,
                                  size: 12,
                                  color: Colors.white,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'SEASONAL ADVISORY',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),

                          const Text(
                            'Winter Pet Safety Guide',
                            style: TextStyle(
                              fontFamily: 'Montserrat',
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Learn how to protect your pet\'s sensitive paws from salt, ice, and cold weather with our quick guide.',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 13,
                              color: Colors.white.withValues(alpha: 0.85),
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 20),

                          ElevatedButton.icon(
                            onPressed: _showSafetyGuide,
                            icon: const Icon(
                              Icons.arrow_forward_rounded,
                              size: 16,
                            ),
                            label: const Text('Read Safety Tips'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: isDark
                                  ? const Color(0xFF0F172A)
                                  : const Color(0xFF0284C7),
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              textStyle: const TextStyle(
                                fontFamily: 'Montserrat',
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
