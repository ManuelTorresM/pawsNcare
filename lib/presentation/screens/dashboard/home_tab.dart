import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/pet.dart';
import '../../../data/models/medication.dart';
import '../../../logic/theme/theme_cubit.dart';
import '../../../logic/auth/auth_bloc.dart';
import '../../../logic/pet/pet_bloc.dart';
import '../../../core/utils/responsive_layout.dart';
import '../../../core/services/local_media_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/accent_left_card.dart';
import '../../widgets/health_status_card.dart';
import '../../widgets/memory_image_card.dart';
import '../../widgets/dashboard/home_invitation_banner.dart';
import '../../widgets/guides/winter_pet_safety_guide_widget.dart';
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
    final isWide = ResponsiveLayout.isWide(context);

    // 1. Greeting Section
    final greetingSection = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          String name = 'Pet Parent';
          if (state is Authenticated && state.name.isNotEmpty) {
            name = state.name;
          } else {
            try {
              final currentUser = FirebaseAuth.instance.currentUser;
              if (currentUser?.displayName?.isNotEmpty == true) {
                name = currentUser!.displayName!;
              } else if (currentUser?.email?.isNotEmpty == true) {
                name = currentUser!.email!.split('@').first;
              }
            } catch (_) {}
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
    );

    // 2. Health Status & Quick Stats Layout
    final healthAndStatsSection = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          // Health Card
          const HealthStatusCard(),
          const SizedBox(height: 16),

          // Quick Stats Cards Row
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
                        expiredTasks.add(m);
                      } else {
                        final endOfMonth = DateTime(
                          now.year,
                          now.month + 1,
                          0,
                          23,
                          59,
                          59,
                        );
                        if (m.nextDoseDate.isBefore(endOfMonth) ||
                            m.nextDoseDate.difference(now).inDays <= 30) {
                          upcomingMonthEvents.add(m);
                        }
                      }
                    }
                  }
                }

                upcomingMonthEvents.sort(
                  (a, b) => a.nextDoseDate.compareTo(b.nextDoseDate),
                );
                monthEventsAheadCount = upcomingMonthEvents.length;

                if (upcomingMonthEvents.isNotEmpty) {
                  final nextDate = upcomingMonthEvents.first.nextDoseDate;
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

                expiredTasks.sort(
                  (a, b) => a.nextDoseDate.compareTo(b.nextDoseDate),
                );
                expiredTasksCount = expiredTasks.length;

                if (expiredTasks.isNotEmpty) {
                  expiredTaskSubtitle = 'Overdue: ${expiredTasks.first.name}';
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
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    monthEventsAheadCount > 0
                                        ? '$monthEventsAheadCount event${monthEventsAheadCount == 1 ? '' : 's'}'
                                        : '0 events',
                                    style: theme.textTheme.labelLarge?.copyWith(
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
                                          : AppTheme.onTertiaryFixedVariant),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    expiredTasksCount > 0
                                        ? '$expiredTasksCount expired'
                                        : '0 pending',
                                    style: theme.textTheme.labelLarge?.copyWith(
                                      fontSize: 14,
                                      color: expiredTasksCount > 0
                                          ? (isDark
                                                ? const Color(0xFFFFB4A3)
                                                : const Color(0xFFB3261E))
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
    );

    // 3. Nutrition Quick Link Card
    final nutritionSection = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: AccentLeftCard(
        accentColor: isDark ? AppTheme.foodConceptDark : AppTheme.foodConcept,
        backgroundColor: cardBg,
        margin: EdgeInsets.zero,
        padding: const EdgeInsets.all(16),
        onTap: () {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const NutritionScreen()));
        },
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color:
                    (isDark ? AppTheme.foodConceptDark : AppTheme.foodConcept)
                        .withValues(alpha: isDark ? 0.25 : 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.restaurant,
                color: isDark ? AppTheme.foodConceptDark : AppTheme.foodConcept,
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
                    style: TextStyle(fontSize: 13, color: textSecondary),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: textSecondary),
          ],
        ),
      ),
    );

    // 4. Your Pets Section
    final yourPetsSection = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
                String currentUid = '';
                String currentEmail = '';
                try {
                  final currentUser = FirebaseAuth.instance.currentUser;
                  currentUid = currentUser?.uid ?? '';
                  currentEmail = currentUser?.email ?? '';
                } catch (_) {}

                final pets = state.filteredPets.where((pet) {
                  final isPendingInviteForUser = pet.members.any(
                    (m) =>
                        m.status == 'Pending' &&
                        ((currentUid.isNotEmpty && m.id == currentUid) ||
                            (currentEmail.isNotEmpty &&
                                m.email.toLowerCase() ==
                                    currentEmail.toLowerCase())),
                  );
                  if (isPendingInviteForUser) return false;
                  return true;
                }).toList();

                return Column(
                  children: [
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: isWide
                            ? 2
                            : ResponsiveLayout.getGridCrossAxisCount(
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
                        Color statusColor;
                        Color statusBgColor;
                        if (pet.status == 'EMERGENCY') {
                          statusColor = isDark
                              ? const Color(0xFFFFB4A3)
                              : AppTheme.error;
                          statusBgColor = isDark
                              ? const Color(0xFF5C2B1D)
                              : const Color(0xFFFDEDEC);
                        } else if (pet.status == 'CONCERNING') {
                          statusColor = isDark
                              ? AppTheme.statusConcerningDark
                              : AppTheme.statusConcerning;
                          statusBgColor = isDark
                              ? AppTheme.statusConcerningDarkBg
                              : AppTheme.statusConcerningBg;
                        } else {
                          // HEALTHY
                          statusColor = isDark
                              ? AppTheme.primaryFixedDim
                              : AppTheme.primary;
                          statusBgColor = isDark
                              ? const Color(0xFF2E4E30)
                              : AppTheme.primaryFixed.withValues(alpha: 0.3);
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
                                  child: LocalMediaService.buildSmartImage(
                                    path: pet.avatarUrl,
                                    fit: BoxFit.cover,
                                    fallbackWidget: Container(
                                      color: isDark
                                          ? const Color(0xFF383634)
                                          : AppTheme.primaryFixed.withValues(
                                              alpha: 0.3,
                                            ),
                                      child: const Icon(
                                        Icons.pets,
                                        size: 32,
                                        color: AppTheme.primary,
                                      ),
                                    ),
                                  ),
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
                                      borderRadius: BorderRadius.circular(4),
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
      ],
    );

    // 5. Recent Memories Section
    final recentMemoriesSection = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
                    MaterialPageRoute(builder: (_) => const PetAlbumScreen()),
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
                separatorBuilder: (context, index) => const SizedBox(width: 12),
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
      ],
    );

    // 6. Winter Safety Advisory Card Section
    const winterSafetySection = WinterPetSafetyGuideWidget();

    return RefreshIndicator(
      onRefresh: () async {
        context.read<PetBloc>().add(LoadPets());
      },
      child: isWide
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    physics: const NeverScrollableScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        greetingSection,
                        healthAndStatsSection,
                        const SizedBox(height: 24),
                        nutritionSection,
                        const SizedBox(height: 24),
                        winterSafetySection,
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.only(bottom: 100),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        yourPetsSection,
                        const SizedBox(height: 32),
                        recentMemoriesSection,
                      ],
                    ),
                  ),
                ),
              ],
            )
          : SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  greetingSection,
                  healthAndStatsSection,
                  const SizedBox(height: 24),
                  nutritionSection,
                  const SizedBox(height: 32),
                  yourPetsSection,
                  const SizedBox(height: 32),
                  recentMemoriesSection,
                  const SizedBox(height: 24),
                  winterSafetySection,
                ],
              ),
            ),
    );
  }
}
