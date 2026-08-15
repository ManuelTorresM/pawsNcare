import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../logic/auth/auth_bloc.dart';
import '../../../logic/pet/pet_bloc.dart';
import '../../theme/app_theme.dart';
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
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.ac_unit, color: AppTheme.tertiary),
              SizedBox(width: 8),
              Text('Winter Pet Safety Guide'),
            ],
          ),
          content: const SingleChildScrollView(
            child: Text(
              'As temperatures drop, pay close attention to your pets\' paws. '
              'Ice, salt, and snow can accumulate between toes and cause cracking, bleeding, or chemical burns from de-icers.\n\n'
              'Tips:\n'
              '1. Wipe paws with warm water after walks.\n'
              '2. Apply pet-safe paw balm before going outside.\n'
              '3. Avoid salted pathways or use dog booties if tolerated.\n'
              '4. Keep winter walks short on extremely cold days.',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
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
                  String name = 'Marco';
                  if (state is Authenticated) {
                    name = state.name;
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Good Evening, $name!',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Your furry family is doing great today.',
                        style: TextStyle(color: AppTheme.onSurfaceVariant),
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
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryFixed.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(16),
                      border: const Border(
                        left: BorderSide(color: AppTheme.primary, width: 4),
                      ),
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          right: -10,
                          bottom: -10,
                          child: Icon(
                            Icons.shield,
                            size: 80,
                            color: AppTheme.primary.withOpacity(0.08),
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.verified_user,
                                  color: AppTheme.primary,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'HEALTH STATUS',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: AppTheme.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'All pets good',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Last medical sync: 2 hours ago',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppTheme.primaryContainer,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Quick Stats Cards Row
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: widget.onNavigateToCalendar,
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceContainerLowest,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.02),
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
                                    color: AppTheme.secondaryContainer,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.calendar_month,
                                    color: AppTheme.secondary,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '2 appts',
                                        style: theme.textTheme.labelLarge
                                            ?.copyWith(fontSize: 14),
                                      ),
                                      const Text(
                                        'Fri 10 AM',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: AppTheme.onSurfaceVariant,
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
                              color: AppTheme.surfaceContainerLowest,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.02),
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
                                    color: AppTheme.tertiaryFixed,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.event_note,
                                    color: AppTheme.onTertiaryFixedVariant,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '1 task pending',
                                        style: theme.textTheme.labelLarge
                                            ?.copyWith(fontSize: 14),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const Text(
                                        'Luna vaccine log',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: AppTheme.onSurfaceVariant,
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
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Quick Link: Nutrition & Hydration Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const NutritionScreen()),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(16),
                    border: const Border(
                      left: BorderSide(
                        color: AppTheme.tertiaryContainer,
                        width: 4,
                      ),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.tertiaryFixed,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.restaurant,
                          color: AppTheme.onTertiaryFixedVariant,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Nutrition & Hydration',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Manage meals and logs',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppTheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right,
                        color: AppTheme.onSurfaceVariant,
                      ),
                    ],
                  ),
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
                decoration: InputDecoration(
                  hintText: 'Search by name...',
                  prefixIcon: const Icon(
                    Icons.search,
                    color: AppTheme.secondary,
                  ),
                  fillColor: AppTheme.surfaceContainerLowest,
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: AppTheme.surfaceContainer,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: AppTheme.surfaceContainer,
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
                    return const Center(
                      child: CircularProgressIndicator(color: AppTheme.primary),
                    );
                  } else if (state is PetLoaded) {
                    final pets = state.filteredPets;

                    return Column(
                      children: [
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: 0.85,
                              ),
                          itemCount: pets.length,
                          itemBuilder: (context, index) {
                            final pet = pets[index];
                            Color statusColor = AppTheme.primary;
                            Color statusBgColor = AppTheme.primaryFixed
                                .withOpacity(0.3);
                            if (pet.status == 'Check Diary') {
                              statusColor = AppTheme.tertiary;
                              statusBgColor = AppTheme.tertiaryFixed
                                  .withOpacity(0.4);
                            } else if (pet.status == 'Puppy') {
                              statusColor = AppTheme.secondary;
                              statusBgColor = AppTheme.secondaryContainer
                                  .withOpacity(0.6);
                            }

                            return GestureDetector(
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => PetProfileScreen(pet: pet),
                                  ),
                                );
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: AppTheme.surfaceContainerLowest,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border(
                                    left: BorderSide(
                                      color: statusColor,
                                      width: 4,
                                    ),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.02),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Expanded(
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          child:
                                              pet.avatarUrl.startsWith('http')
                                              ? Image.network(
                                                  pet.avatarUrl,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (_, _, _) =>
                                                      Container(
                                                        color: AppTheme
                                                            .surfaceContainer,
                                                        child: const Icon(
                                                          Icons.pets,
                                                          color: AppTheme
                                                              .secondary,
                                                        ),
                                                      ),
                                                )
                                              : Container(
                                                  color:
                                                      AppTheme.surfaceContainer,
                                                  child: const Icon(
                                                    Icons.pets,
                                                    color: AppTheme.secondary,
                                                  ),
                                                ),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
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
                                                  style: theme
                                                      .textTheme
                                                      .labelLarge,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                                Text(
                                                  pet.breed,
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    color: AppTheme
                                                        .onSurfaceVariant,
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
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
                                              borderRadius:
                                                  BorderRadius.circular(4),
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
                                ),
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
                              color: theme.colorScheme.outline.withOpacity(0.5),
                              width: 1.5,
                              style: BorderStyle.solid,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            backgroundColor: AppTheme.surfaceContainerLowest,
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: AppTheme.secondaryContainer,
                                child: Icon(
                                  Icons.add,
                                  color: AppTheme.secondary,
                                  size: 20,
                                ),
                              ),
                              SizedBox(width: 12),
                              Text(
                                'Add New Pet',
                                style: TextStyle(
                                  color: AppTheme.onSurfaceVariant,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
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
                  const Text(
                    'Recent Memories',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const PetAlbumScreen(),
                        ),
                      );
                    },
                    child: const Text(
                      'View Album',
                      style: TextStyle(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Horizontal scrolling memories
            SizedBox(
              height: 140,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  _buildMemoryImage(
                    'https://lh3.googleusercontent.com/aida-public/AB6AXuBl6_oeyQV-qIsHy9D2xNcPoSyI7ccxSlfqGkCntb0EHHM0IW8i2DJJ_EL50ABz-nrZGOve9I94OWfLqfeoUVb8n4f9bA9AQ5OXZGBcCJc4BXtF1nUjbT3E48dDGWmqR2iXZa6zZwoocYCfKmZuUE62NNnvl9RsY8V0NW3q3IbTRAQHgwKjPgwgnVBd18QplOa5vj6TTXbI1hoa-mXfjtWubK9aEzqQm8gp7bxm6d05ICVbPtB5r1p5',
                  ),
                  const SizedBox(width: 12),
                  _buildMemoryImage(
                    'https://lh3.googleusercontent.com/aida-public/AB6AXuDud1dBMCEUUnS8K3QpiIJN5zyzK6QNXJHb9CTg5iZjYfeN62Drez_cUi63k0F1v0zuQFz3nSdSjlVztVPWHw03FTgM7Wxd9fmApweagP0Ec3sILeqiuparq7xX2EW_3xY83Y4Y_tl727B4VJB3QEC9XIa2cRvKY7jDfuegGj-jiCx25aOloIZE3_kc7kuZX-V09dvFFpADHI5NMUfsrCYDMebDNdBzZpz5NDAvSEJRU0LfDaMg_c5L',
                  ),
                  const SizedBox(width: 12),
                  _buildMemoryImage(
                    'https://lh3.googleusercontent.com/aida-public/AB6AXuDDw84DnYLoEJSpFWlKDWSCNGtehkk_-Rkw1bRnIkjwAuOdzzqFh1LTwZdLPa9rD7iPsmAeMXIkN_iJQLb8PiLJnXIOfFRyC5DOEHkv5ZAy9wPNPkOsgHORtRlXvdTkzYA9HxAZJ0O3X9LubybYLSCDGBJxReMv5WmHcZZk4C86lIcpQgMlpKpG3z5ggne_6dKyxUprFLBP_lq8FXNJUyaoMCBf3CIfdzitQIcpyTyKdlYQxeiXkkmh',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Winter Safety Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTheme.secondary,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -10,
                      bottom: -20,
                      child: Icon(
                        Icons.ac_unit,
                        size: 100,
                        color: Colors.white.withOpacity(0.08),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Winter Pet Safety Guide',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Learn how to protect your pets\' paws from salt and ice this season with our professional tips.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                        const SizedBox(height: 18),
                        ElevatedButton(
                          onPressed: _showSafetyGuide,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: const Text('Read More'),
                        ),
                      ],
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

  Widget _buildMemoryImage(String url) {
    return Container(
      width: 140,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.network(
          url,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => Container(
            color: AppTheme.surfaceContainer,
            child: const Icon(Icons.photo, color: AppTheme.secondary),
          ),
        ),
      ),
    );
  }
}
