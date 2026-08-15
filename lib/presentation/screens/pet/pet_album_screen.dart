import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../logic/pet/pet_bloc.dart';
import '../../../data/models/pet.dart';
import '../../theme/app_theme.dart';

class MemoryItem {
  final String id;
  final String imageUrl;
  final String caption;
  final String petId; // lowercase name (luna, oliver, bella, all, etc.)
  final String month; // e.g. "October 2023"
  final bool isVideo;
  bool isFavorite;

  MemoryItem({
    required this.id,
    required this.imageUrl,
    required this.caption,
    required this.petId,
    required this.month,
    this.isVideo = false,
    this.isFavorite = false,
  });
}

class PetAlbumScreen extends StatefulWidget {
  const PetAlbumScreen({super.key});

  @override
  State<PetAlbumScreen> createState() => _PetAlbumScreenState();
}

class _PetAlbumScreenState extends State<PetAlbumScreen> {
  String _selectedFilter = 'all'; // 'all', 'luna', 'oliver', 'bella', etc.
  String _selectedTab = 'all'; // 'all', 'video', 'favorite'

  // Standard template memories
  final List<MemoryItem> _memories = [];

  // Helper lists of static avatars to align with layout
  final Map<String, String> _fallbackAvatars = {};

  String _formatMonthYear(DateTime date) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  void _showUploadModal(List<Pet> pets) {
    final captionController = TextEditingController();
    final urlController = TextEditingController(
      text: 'https://lh3.googleusercontent.com/aida/AP1WRLtrgME_RmIjbhaKotM3yFpCT7DU6U1PWGClNijvL1udZ-MwwSE4sRJXIkOpdXG_cQrlHdzVHWgOScO25q_9O5XS5IYrq9YpSPzMMCfFUgQin2wChhfacReYAlFZmlABvz70D9BrOoYsd_UfBK1v2te37yMvk_LKQM0nfhOK_Smz_StRBkZ7xC7Mw-AfJwUe6IrQBGllmI1NtCd5O0NUnlXVtaS0dVA9d1RpHUon7HaYl-S_cZT-vjk0XIE',
    );

    // Dynamic dropdown values
    final List<String> petOptions = pets.isNotEmpty 
        ? pets.map((p) => p.name.toLowerCase()).toList() 
        : ['luna', 'oliver', 'bella'];
    String uploadPetTarget = petOptions[0];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text(
                'Upload Photo',
                style: TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.bold, color: AppTheme.primary),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Mock Dropzone
                    Container(
                      height: 100,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.outlineVariant),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.cloud_upload_outlined, color: AppTheme.primary, size: 30),
                          SizedBox(height: 4),
                          Text('Photo Selected', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          Text('Browse files to change', style: TextStyle(fontSize: 10, color: AppTheme.onSurfaceVariant)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // URL Field for mock upload source
                    const Text('Photo URL (Mock Source)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                    const SizedBox(height: 4),
                    TextField(
                      controller: urlController,
                      decoration: const InputDecoration(hintText: 'Image network address'),
                    ),
                    const SizedBox(height: 12),

                    // Target Pet Selection
                    const Text('Assign to Pet', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                    const SizedBox(height: 4),
                    DropdownButtonFormField<String>(
                      value: uploadPetTarget,
                      items: petOptions.map((name) {
                        return DropdownMenuItem(
                          value: name,
                          child: Text(name[0].toUpperCase() + name.substring(1)),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setModalState(() => uploadPetTarget = val);
                        }
                      },
                    ),
                    const SizedBox(height: 12),

                    // Caption Input
                    const Text('Caption (Optional)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                    const SizedBox(height: 4),
                    TextField(
                      controller: captionController,
                      decoration: const InputDecoration(hintText: 'Write a memory...'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final targetUrl = urlController.text.trim();
                    if (targetUrl.isNotEmpty) {
                      final timestamp = DateTime.now();
                      final formattedMonth = _formatMonthYear(timestamp);

                      setState(() {
                        _memories.insert(
                          0,
                          MemoryItem(
                            id: timestamp.millisecondsSinceEpoch.toString(),
                            petId: uploadPetTarget,
                            imageUrl: targetUrl,
                            caption: captionController.text.trim().isNotEmpty
                                ? captionController.text.trim()
                                : 'Uploaded Memory',
                            month: formattedMonth,
                          ),
                        );
                      });

                      // Sync photo upload back into user's saved BLoC profile
                      if (pets.isNotEmpty) {
                        final matchedPet = pets.firstWhere(
                          (p) => p.name.toLowerCase() == uploadPetTarget,
                          orElse: () => pets.first,
                        );
                        if (matchedPet.name.toLowerCase() == uploadPetTarget) {
                          final updatedPhotos = List<String>.from(matchedPet.photos)..add(targetUrl);
                          final updatedPet = matchedPet.copyWith(photos: updatedPhotos);
                          context.read<PetBloc>().add(UpdatePet(updatedPet));
                        }
                      }

                      Navigator.of(context).pop();
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.white),
                  child: const Text('Post Photo'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _openLightbox(MemoryItem memory) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.95),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setLightboxState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Large Image Container
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: InteractiveViewer(
                          child: Image.network(
                            memory.imageUrl,
                            fit: BoxFit.contain,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                height: 300,
                                color: AppTheme.surfaceContainerLow,
                                child: const Center(child: CircularProgressIndicator(color: AppTheme.primary)),
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Caption
                      Text(
                        memory.caption,
                        style: const TextStyle(
                          fontFamily: 'Montserrat',
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),

                      // Action Buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () {
                              Navigator.of(context).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Memory shared successfully!')),
                              );
                            },
                            icon: const Icon(Icons.share, color: Colors.white, size: 18),
                            label: const Text('Share', style: TextStyle(color: Colors.white)),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.white30),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                          const SizedBox(width: 16),
                          ElevatedButton.icon(
                            onPressed: () {
                              setLightboxState(() {
                                memory.isFavorite = !memory.isFavorite;
                              });
                              setState(() {});
                            },
                            icon: Icon(
                              memory.isFavorite ? Icons.favorite : Icons.favorite_border,
                              color: Colors.white,
                              size: 18,
                            ),
                            label: Text(memory.isFavorite ? 'Favorited' : 'Favorite'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: memory.isFavorite ? AppTheme.primary : Colors.white24,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Close button
                  Positioned(
                    top: 0,
                    right: 0,
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white, size: 28),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final petState = context.watch<PetBloc>().state;
    final List<Pet> pets = [];
    final List<String> registeredPets = [];

    if (petState is PetLoaded) {
      pets.addAll(petState.pets);
      registeredPets.addAll(petState.pets.map((p) => p.name.toLowerCase()));
    }

    // Filter list relies purely on BLoC registered pets
    final List<String> activeFilters = ['all'];
    for (var name in registeredPets) {
      if (!activeFilters.contains(name)) {
        activeFilters.add(name);
      }
    }

    // Dynamic memories compiled by merging default templates with user's saved profile photos
    final List<MemoryItem> activeMemoriesList = List.from(_memories);
    for (var pet in pets) {
      final petNameLower = pet.name.toLowerCase();
      for (int i = 0; i < pet.photos.length; i++) {
        final photoUrl = pet.photos[i];
        if (!activeMemoriesList.any((m) => m.imageUrl == photoUrl)) {
          // Group custom photos under the month of pet's birthdate, or current month fallback
          final String creationMonth = _formatMonthYear(pet.birthDate);
          activeMemoriesList.add(
            MemoryItem(
              id: '${pet.id}_profile_photo_$i',
              petId: petNameLower,
              imageUrl: photoUrl,
              caption: 'Memory of ${pet.name}',
              month: creationMonth,
            ),
          );
        }
      }
    }

    // Apply Filter Selection
    final filteredMemories = activeMemoriesList.where((m) {
      final matchesPet = _selectedFilter == 'all' || m.petId == _selectedFilter;
      if (!matchesPet) return false;

      if (_selectedTab == 'video') return m.isVideo;
      if (_selectedTab == 'favorite') return m.isFavorite;
      return true;
    }).toList();

    // Group Memories by Month of Creation
    final Map<String, List<MemoryItem>> groupedMemories = {};
    for (var m in filteredMemories) {
      groupedMemories.putIfAbsent(m.month, () => []).add(m);
    }

    final totalCount = filteredMemories.length;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Family Album',
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: AppTheme.primary,
              ),
            ),
            Text(
              '$totalCount Memories',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                color: AppTheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.primary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: AppTheme.primary),
            onPressed: () {},
          ),
          // Owner profile avatar circle
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
              radius: 18,
              backgroundImage: const NetworkImage(
                'https://lh3.googleusercontent.com/aida-public/AB6AXuDbMAgO8k3oNW5CEWqcyeq3x0u2uuM8RUNW8MnbvVUX61icw1UR6uDJyAnSOLaTEl9Xi1JJZkBb2DVmP94k3kNpFeWZzV7-uxHllmGnvUZIXor2nZtYD_QrpiXS5Ik6HrE7ezcPzLk-kNfA3n_CSeQE6SmmCQ_1VgqPy6_zBxXej1DqS1uV5jva2W74C-eaWikcclVFmWdwLRRrTma7DnhWNqrKgUJoqkJaecfnj1XIF6hLdWJ8gGMKXnFUpzPiO13Yd05HKDSSfUw',
              ),
              backgroundColor: AppTheme.surfaceContainerHigh,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Select a Pet Section
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24.0),
                    child: Text(
                      'SELECT A PET',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                        color: AppTheme.secondary,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 105,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: activeFilters.length,
                      itemBuilder: (context, index) {
                        final filter = activeFilters[index];
                        final isSelected = _selectedFilter == filter;
                        return _buildPetFilterButton(filter, isSelected, pets);
                      },
                    ),
                  ),
                ],
              ),
            ),

            // Gallery Header (Title, Sub-tabs & Upload Button)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Gallery',
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                          color: AppTheme.onSurface,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _showUploadModal(pets),
                        icon: const Icon(Icons.add_a_photo, size: 16),
                        label: const Text('Upload New', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Sub-tabs row
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildSubTab('all', 'All Photos'),
                        const SizedBox(width: 8),
                        _buildSubTab('video', 'Videos'),
                        const SizedBox(width: 8),
                        _buildSubTab('favorite', 'Favorites'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Photo Groups Scrollable Grid
            Expanded(
              child: filteredMemories.isEmpty
                  ? const Center(
                      child: Text(
                        'No memories found for this filter.',
                        style: TextStyle(fontFamily: 'Inter', fontStyle: FontStyle.italic, color: AppTheme.secondary),
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      children: groupedMemories.keys.map((month) {
                        final list = groupedMemories[month]!;
                        return _buildMonthSection(month, list);
                      }).toList(),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPetFilterButton(String filter, bool isSelected, List<Pet> pets) {
    final displayName = filter == 'all' ? 'All' : filter[0].toUpperCase() + filter.substring(1);
    
    // Resolve dynamic pet avatar if present in BLoC list
    String? resolvedAvatarUrl = _fallbackAvatars[filter];
    if (filter != 'all') {
      final match = pets.firstWhere(
        (p) => p.name.toLowerCase() == filter,
        orElse: () => pets.first,
      );
      if (match.name.toLowerCase() == filter && match.avatarUrl.isNotEmpty) {
        resolvedAvatarUrl = match.avatarUrl;
      }
    }

    return Padding(
      padding: const EdgeInsets.only(right: 14.0),
      child: GestureDetector(
        onTap: () => setState(() => _selectedFilter = filter),
        child: Column(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppTheme.primary : Colors.transparent,
                  width: 2,
                ),
              ),
              padding: const EdgeInsets.all(2),
              child: CircleAvatar(
                backgroundColor: AppTheme.surfaceContainerHigh,
                backgroundImage: resolvedAvatarUrl != null ? NetworkImage(resolvedAvatarUrl) : null,
                child: resolvedAvatarUrl == null
                    ? (filter == 'all'
                        ? const Icon(Icons.group, color: AppTheme.primary, size: 30)
                        : Text(
                            displayName[0],
                            style: const TextStyle(
                              fontFamily: 'Montserrat',
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primary,
                              fontSize: 24,
                            ),
                          ))
                    : null,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              displayName,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? AppTheme.primary : AppTheme.secondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubTab(String key, String label) {
    final isSelected = _selectedTab == key;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = key),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryContainer : AppTheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isSelected ? AppTheme.onPrimaryContainer : AppTheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Widget _buildMonthSection(String month, List<MemoryItem> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            Text(
              month,
              style: const TextStyle(
                fontFamily: 'Montserrat',
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: Container(height: 1, color: AppTheme.outlineVariant)),
            const SizedBox(width: 12),
            TextButton(
              onPressed: () {},
              child: const Text('Select', style: TextStyle(fontFamily: 'Inter', color: AppTheme.primary)),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Photo Grid Layout
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 1.0,
          ),
          itemBuilder: (context, index) {
            final item = items[index];
            return GestureDetector(
              onTap: () => _openLightbox(item),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  image: DecorationImage(
                    image: NetworkImage(item.imageUrl),
                    fit: BoxFit.cover,
                  ),
                ),
                child: item.isVideo
                    ? const Center(
                        child: Icon(Icons.play_circle_fill, color: Colors.white, size: 36),
                      )
                    : null,
              ),
            );
          },
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
