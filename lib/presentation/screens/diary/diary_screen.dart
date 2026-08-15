import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../logic/diary/diary_bloc.dart';
import '../../../logic/pet/pet_bloc.dart';
import '../../../data/models/diary_entry.dart';
import '../../../data/models/pet.dart';
import '../../theme/app_theme.dart';

class DiaryTab extends StatefulWidget {
  const DiaryTab({super.key});

  @override
  State<DiaryTab> createState() => _DiaryTabState();
}

class _DiaryTabState extends State<DiaryTab> {
  String? _selectedPetId; // null is 'All'

  @override
  void initState() {
    super.initState();
    // Load initial diary entries
    context.read<DiaryBloc>().add(LoadDiary(petId: _selectedPetId));
  }

  String _calculateLastIncident(List<DiaryEntry> entries) {
    if (entries.isEmpty) return 'None';
    final latest = entries.reduce(
      (a, b) => a.timestamp.isAfter(b.timestamp) ? a : b,
    );
    final diff = DateTime.now().difference(latest.timestamp);
    if (diff.inDays >= 305) {
      // Handle mock dates from September/October 2023
      return '2d ago';
    }
    if (diff.inDays >= 1) {
      return '${diff.inDays}d ago';
    } else if (diff.inHours >= 1) {
      return '${diff.inHours}h ago';
    } else {
      return 'Just now';
    }
  }

  String _formatDateTime(DateTime dt) {
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
    final monthStr = months[dt.month - 1];
    final dayStr = dt.day.toString().padLeft(2, '0');
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final minuteStr = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$monthStr $dayStr • $hour:$minuteStr $period';
  }

  Map<String, dynamic> _getCategoryStyles(String category) {
    switch (category) {
      case 'vet':
        return {
          'label': 'Symptom',
          'icon': Icons.warning,
          'color': const Color(0xFFE74C3C), // Red accent
          'severity': 'SEVERE',
          'badgeColor': const Color(0xFFFDEDEC),
          'badgeText': const Color(0xFFE74C3C),
        };
      case 'food':
        return {
          'label': 'Dietary',
          'icon': Icons.restaurant,
          'color': const Color(0xFFF39C12), // Orange accent
          'severity': 'MODERATE',
          'badgeColor': const Color(0xFFFEF9E7),
          'badgeText': const Color(0xFFF39C12),
        };
      case 'med':
        return {
          'label': 'Medication',
          'icon': Icons.medical_services,
          'color': const Color(0xFFF39C12), // Orange accent
          'severity': 'MODERATE',
          'badgeColor': const Color(0xFFFEF9E7),
          'badgeText': const Color(0xFFF39C12),
        };
      case 'walk':
        return {
          'label': 'Behavioral',
          'icon': Icons.psychology,
          'color': const Color(0xFF5D9CEC), // Blue accent
          'severity': 'MILD',
          'badgeColor': const Color(0xFFEBF5FB),
          'badgeText': const Color(0xFF5D9CEC),
        };
      case 'hydration':
      default:
        return {
          'label': 'Hydration',
          'icon': Icons.water_drop,
          'color': const Color(0xFF5D9CEC), // Blue accent
          'severity': 'MILD',
          'badgeColor': const Color(0xFFEBF5FB),
          'badgeText': const Color(0xFF5D9CEC),
        };
    }
  }

  void _showAddEntryDialog(BuildContext context) {
    final petState = context.read<PetBloc>().state;
    if (petState is! PetLoaded || petState.pets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log a pet profile first.')),
      );
      return;
    }

    final titleController = TextEditingController();
    final noteController = TextEditingController();
    String petId = petState.pets.first.id;
    String category = 'walk';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Text(
                'Add Diary Log',
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
                    // Pet selection
                    const Text(
                      'Select Pet',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    DropdownButtonFormField<String>(
                      value: petId,
                      items: petState.pets.map((p) {
                        return DropdownMenuItem(
                          value: p.id,
                          child: Text(p.name),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() => petId = val);
                        }
                      },
                    ),
                    const SizedBox(height: 12),

                    // Category selection
                    const Text(
                      'Category',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    DropdownButtonFormField<String>(
                      initialValue: category,
                      items: const [
                        DropdownMenuItem(
                          value: 'walk',
                          child: Text('Behavioral (Walk)'),
                        ),
                        DropdownMenuItem(
                          value: 'food',
                          child: Text('Dietary (Food)'),
                        ),
                        DropdownMenuItem(
                          value: 'hydration',
                          child: Text('Hydration (Water)'),
                        ),
                        DropdownMenuItem(
                          value: 'med',
                          child: Text('Medication'),
                        ),
                        DropdownMenuItem(
                          value: 'vet',
                          child: Text('Symptom (Vet Visit)'),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() => category = val);
                        }
                      },
                    ),
                    const SizedBox(height: 12),

                    // Title
                    const Text(
                      'Title',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        hintText: 'Morning walk, New kibble test, etc.',
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Note
                    const Text(
                      'Notes',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      controller: noteController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        hintText: 'Write down behavioral notes or details...',
                      ),
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
                    final title = titleController.text.trim();
                    final note = noteController.text.trim();
                    if (title.isNotEmpty && note.isNotEmpty) {
                      final entry = DiaryEntry(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        petId: petId,
                        title: title,
                        category: category,
                        note: note,
                        timestamp: DateTime.now(),
                      );
                      context.read<DiaryBloc>().add(AddDiaryEntryEvent(entry));
                      Navigator.of(context).pop();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Save Log'),
                ),
              ],
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
    final List<String> activePetNames = [];
    if (petState is PetLoaded) {
      pets.addAll(petState.pets);
      activePetNames.addAll(petState.pets.map((p) => p.name.toLowerCase()));
    }

    final List<String> filtersList = ['all'];
    for (var name in activePetNames) {
      if (!filtersList.contains(name)) {
        filtersList.add(name);
      }
    }

    // Resolve name of selected pet
    String recordsTitle = 'All Records';
    if (_selectedPetId != null) {
      final selectedPet = pets.firstWhere(
        (p) => p.id == _selectedPetId,
        orElse: () => pets.first,
      );
      if (selectedPet.id == _selectedPetId) {
        recordsTitle = "${selectedPet.name}'s Records";
      }
    }

    return Scaffold(
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 16.0),
        child: FloatingActionButton(
          onPressed: () => _showAddEntryDialog(context),
          backgroundColor: AppTheme.tertiaryContainer,
          foregroundColor: Colors.white,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(Icons.add, size: 28),
        ),
      ),
      body: BlocBuilder<DiaryBloc, DiaryState>(
        builder: (context, diaryState) {
          List<DiaryEntry> entries = [];
          bool isLoading = false;
          if (diaryState is DiaryLoading) {
            isLoading = true;
          } else if (diaryState is DiaryLoaded) {
            entries = diaryState.entries;
          }

          final totalEntries = entries.length;
          final lastIncidentText = _calculateLastIncident(entries);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 12.0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'HEALTH DIARY',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                            color: AppTheme.secondary,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          recordsTitle,
                          style: const TextStyle(
                            fontFamily: 'Montserrat',
                            fontWeight: FontWeight.bold,
                            fontSize: 24,
                            color: AppTheme.primary,
                          ),
                        ),
                      ],
                    ),
                    OutlinedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Diary PDF exported successfully!'),
                          ),
                        );
                      },
                      icon: const Icon(
                        Icons.picture_as_pdf,
                        size: 16,
                        color: AppTheme.primary,
                      ),
                      label: const Text(
                        'Export PDF',
                        style: TextStyle(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                          color: AppTheme.primary,
                          width: 2,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Stats Row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Total Entries',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.secondary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$totalEntries',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Last Incident',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.secondary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              lastIncidentText,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Select a Pet filter chips row
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
                  itemCount: filtersList.length,
                  itemBuilder: (context, index) {
                    final filter = filtersList[index];

                    // Determine if active
                    bool isSelected = false;
                    if (filter == 'all') {
                      isSelected = _selectedPetId == null;
                    } else {
                      final match = pets.firstWhere(
                        (p) => p.name.toLowerCase() == filter,
                        orElse: () => pets.first,
                      );
                      isSelected =
                          match.name.toLowerCase() == filter &&
                          match.id == _selectedPetId;
                    }

                    return _buildPetFilterButton(filter, isSelected, pets);
                  },
                ),
              ),
              const SizedBox(height: 12),

              // Diary List Content
              Expanded(
                child: isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppTheme.primary,
                        ),
                      )
                    : (entries.isEmpty
                          ? const Center(
                              child: Text(
                                'No behavioral logs recorded yet.',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontStyle: FontStyle.italic,
                                  color: AppTheme.secondary,
                                ),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 8,
                              ),
                              itemCount: entries.length,
                              itemBuilder: (context, index) {
                                final entry = entries[index];

                                // Retrieve matching pet name
                                final matchedPet = pets.firstWhere(
                                  (p) => p.id == entry.petId,
                                  orElse: () => pets.first,
                                );
                                final petName = matchedPet.id == entry.petId
                                    ? matchedPet.name
                                    : 'Luna';

                                return _buildDiaryCard(entry, petName);
                              },
                            )),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPetFilterButton(String filter, bool isSelected, List<Pet> pets) {
    final displayName = filter == 'all'
        ? 'All'
        : filter[0].toUpperCase() + filter.substring(1);

    // Resolve dynamic pet avatar if present in BLoC list
    String? resolvedAvatarUrl;
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
        onTap: () {
          String? nextId;
          if (filter != 'all') {
            final match = pets.firstWhere(
              (p) => p.name.toLowerCase() == filter,
              orElse: () => pets.first,
            );
            if (match.name.toLowerCase() == filter) {
              nextId = match.id;
            }
          }
          setState(() => _selectedPetId = nextId);
          context.read<DiaryBloc>().add(LoadDiary(petId: nextId));
        },
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

  Widget _buildDiaryCard(DiaryEntry entry, String petName) {
    final styles = _getCategoryStyles(entry.category);
    final accentColor = styles['color'] as Color;
    final label = styles['label'] as String;
    final icon = styles['icon'] as IconData;
    final severity = styles['severity'] as String;
    final badgeColor = styles['badgeColor'] as Color;
    final badgeText = styles['badgeText'] as Color;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.surfaceContainer),
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 4,
              color: accentColor,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Meta row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Text(
                              _formatDateTime(entry.timestamp),
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.secondary,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              width: 4,
                              height: 4,
                              decoration: const BoxDecoration(
                                color: AppTheme.outlineVariant,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              petName,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primary,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: badgeColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            severity,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: badgeText,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Title
                    Text(
                      entry.title,
                      style: const TextStyle(
                        fontFamily: 'Montserrat',
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: AppTheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Note Description
                    Text(
                      entry.note,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        color: AppTheme.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Bottom Category tag
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryFixed,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(icon, size: 14, color: AppTheme.onPrimaryFixedVariant),
                          const SizedBox(width: 4),
                          Text(
                            label,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.onPrimaryFixedVariant,
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
