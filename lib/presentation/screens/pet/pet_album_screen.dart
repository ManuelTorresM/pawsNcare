import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
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
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  void _startMediaUploadFlow(List<Pet> pets) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Select Media Source',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: const Icon(Icons.photo_library, color: AppTheme.primary),
                  title: const Text('Choose from Gallery'),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _pickMedia(pets, ImageSource.gallery);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_camera, color: AppTheme.primary),
                  title: const Text('Open Camera'),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _pickMedia(pets, ImageSource.camera);
                  },
                ),
                const Divider(),
                TextButton(
                  onPressed: () => Navigator.of(sheetContext).pop(),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.secondary,
                  ),
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickMedia(List<Pet> pets, ImageSource source) async {
    try {
      final picker = ImagePicker();
      final file = await picker.pickImage(source: source);
      if (!mounted) return;

      if (file != null) {
        _showPostDetailsDialog(pets, file.path);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking media: $e')),
      );
    }
  }

  void _showPostDetailsDialog(List<Pet> pets, String filePath) {
    final captionController = TextEditingController();
    final List<String> petOptions = pets.isNotEmpty
        ? pets.map((p) => p.name.toLowerCase()).toList()
        : ['luna', 'oliver', 'bella'];
    String uploadPetTarget = petOptions[0];

    showDialog(
      context: context,
      builder: (dialogContext) {
        final postNavigator = Navigator.of(dialogContext);
        final petBloc = context.read<PetBloc>();
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Text(
                'Post Photo Memory',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primary,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Preview picked media
                    Container(
                      height: 120,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.outlineVariant),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.file(
                          File(filePath),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => const Center(
                            child: Icon(Icons.broken_image, color: AppTheme.secondary, size: 40),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Target Pet Selection
                    const Text(
                      'Assign to Pet',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    DropdownButtonFormField<String>(
                      initialValue: uploadPetTarget,
                      items: petOptions.map((name) {
                        return DropdownMenuItem(
                          value: name,
                          child: Text(
                            name[0].toUpperCase() + name.substring(1),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setModalState(() => uploadPetTarget = val);
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // Caption Input
                    const Text(
                      'Caption (Optional)',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      controller: captionController,
                      decoration: const InputDecoration(
                        hintText: 'Write a memory...',
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => postNavigator.pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final timestamp = DateTime.now();
                    final formattedMonth = _formatMonthYear(timestamp);

                    setState(() {
                      _memories.insert(
                        0,
                        MemoryItem(
                          id: timestamp.millisecondsSinceEpoch.toString(),
                          petId: uploadPetTarget,
                          imageUrl: filePath,
                          caption: captionController.text.trim().isNotEmpty
                              ? captionController.text.trim()
                              : 'Uploaded Memory',
                          month: formattedMonth,
                          isVideo: false,
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
                        final updatedPhotos = List<String>.from(
                          matchedPet.photos,
                        )..add(filePath);
                        final updatedPet = matchedPet.copyWith(
                          photos: updatedPhotos,
                        );
                        petBloc.add(UpdatePet(updatedPet));
                      }
                    }

                    postNavigator.pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Post Memory'),
                ),
              ],
            );
          },
        );
      },
    ).then((_) {
      captionController.dispose();
    });
  }

  void _openLightbox(MemoryItem memory) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.95),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setLightboxState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 24,
              ),
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
                          child: memory.imageUrl.startsWith('http') || memory.imageUrl.startsWith('https')
                              ? Image.network(
                                  memory.imageUrl,
                                  fit: BoxFit.contain,
                                  loadingBuilder: (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Container(
                                      height: 300,
                                      color: AppTheme.surfaceContainerLow,
                                      child: const Center(
                                        child: CircularProgressIndicator(
                                          color: AppTheme.primary,
                                        ),
                                      ),
                                    );
                                  },
                                  errorBuilder: (context, error, stackTrace) =>
                                      Container(
                                        height: 300,
                                        color: AppTheme.surfaceContainerLow,
                                        child: const Center(
                                          child: Icon(
                                            Icons.broken_image,
                                            size: 48,
                                            color: AppTheme.secondary,
                                          ),
                                        ),
                                      ),
                                )
                              : Image.file(
                                  File(memory.imageUrl),
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Container(
                                        height: 300,
                                        color: AppTheme.surfaceContainerLow,
                                        child: const Center(
                                          child: Icon(
                                            Icons.broken_image,
                                            size: 48,
                                            color: AppTheme.secondary,
                                          ),
                                        ),
                                      ),
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
                                const SnackBar(
                                  content: Text('Memory shared successfully!'),
                                ),
                              );
                            },
                            icon: const Icon(
                              Icons.share,
                              color: Colors.white,
                              size: 18,
                            ),
                            label: const Text(
                              'Share',
                              style: TextStyle(color: Colors.white),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.white30),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
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
                              memory.isFavorite
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: Colors.white,
                              size: 18,
                            ),
                            label: Text(
                              memory.isFavorite ? 'Favorited' : 'Favorite',
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: memory.isFavorite
                                  ? AppTheme.primary
                                  : Colors.white24,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
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
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 28,
                      ),
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
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 8.0,
              ),
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
                        onPressed: () => _startMediaUploadFlow(pets),
                        icon: const Icon(Icons.add_a_photo, size: 16),
                        label: const Text(
                          'Upload New',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
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
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontStyle: FontStyle.italic,
                          color: AppTheme.secondary,
                        ),
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
    final displayName = filter == 'all'
        ? 'All'
        : filter[0].toUpperCase() + filter.substring(1);

    // Resolve dynamic pet avatar if present in BLoC list
    String? resolvedAvatarUrl = _fallbackAvatars[filter];
    if (filter != 'all' && pets.isNotEmpty) {
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
                backgroundImage: resolvedAvatarUrl != null
                    ? NetworkImage(resolvedAvatarUrl)
                    : null,
                child: resolvedAvatarUrl == null
                    ? (filter == 'all'
                          ? const Icon(
                              Icons.group,
                              color: AppTheme.primary,
                              size: 30,
                            )
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
          color: isSelected
              ? AppTheme.primaryContainer
              : AppTheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isSelected
                ? AppTheme.onPrimaryContainer
                : AppTheme.onSurfaceVariant,
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
            Expanded(
              child: Container(height: 1, color: AppTheme.outlineVariant),
            ),
            const SizedBox(width: 12),
            TextButton(
              onPressed: () {},
              child: const Text(
                'Select',
                style: TextStyle(fontFamily: 'Inter', color: AppTheme.primary),
              ),
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
                    image: (item.imageUrl.startsWith('http') || item.imageUrl.startsWith('https')
                        ? NetworkImage(item.imageUrl)
                        : FileImage(File(item.imageUrl))) as ImageProvider,
                    fit: BoxFit.cover,
                  ),
                ),
                child: item.isVideo
                    ? const Center(
                        child: Icon(
                          Icons.play_circle_fill,
                          color: Colors.white,
                          size: 36,
                        ),
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
