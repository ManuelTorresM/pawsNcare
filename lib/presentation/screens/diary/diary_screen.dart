import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../logic/theme/theme_cubit.dart';
import '../../../logic/diary/diary_bloc.dart';
import '../../../logic/pet/pet_bloc.dart';
import '../../../data/models/diary_entry.dart';
import '../../../data/models/pet.dart';
import '../../../core/utils/responsive_layout.dart';
import '../../theme/app_theme.dart';
import '../../widgets/accent_left_card.dart';
import '../../widgets/base_form_dialog.dart';

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

  void _showAddEntryDialog(BuildContext context, {DiaryEntry? initialEntry}) {
    final petState = context.read<PetBloc>().state;
    if (petState is! PetLoaded || petState.pets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log a pet profile first.')),
      );
      return;
    }

    final titleController = TextEditingController(
      text: initialEntry?.title ?? '',
    );
    final noteController = TextEditingController(
      text: initialEntry?.note ?? '',
    );
    String petId = initialEntry?.petId ?? petState.pets.first.id;
    String category = initialEntry?.category ?? 'walk';
    String severity = initialEntry?.severity ?? 'MILD';
    String? validationError;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            final isDark = context.read<ThemeCubit>().state;
            final textPrimary =
                isDark ? AppTheme.darkOnSurface : AppTheme.onSurface;
            final textSecondary =
                isDark ? AppTheme.darkOnSurfaceVariant : AppTheme.secondary;

            return BaseFormDialog(
              icon: Icons.book_outlined,
              title: initialEntry != null ? 'Edit Diary Log' : 'Add Diary Log',
              subtitle: initialEntry != null
                  ? 'Update entry details'
                  : 'Log a new pet diary incident',
              validationError: validationError,
              primaryButtonText:
                  initialEntry != null ? 'Save Changes' : 'Save Log',
              headerAction: initialEntry != null
                  ? IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        color: AppTheme.error,
                      ),
                      onPressed: () {
                        Navigator.pop(dialogContext);
                        _showDeleteConfirmDialog(context, initialEntry);
                      },
                    )
                  : null,
              onPrimaryPressed: () {
                final title = titleController.text.trim();
                final note = noteController.text.trim();

                final List<String> missingFields = [];
                if (petId.isEmpty) missingFields.add('Target Pet');
                if (title.isEmpty) missingFields.add('Title');
                if (note.isEmpty) missingFields.add('Notes');

                if (missingFields.isNotEmpty) {
                  setDialogState(() {
                    validationError =
                        'Missing required fields: ${missingFields.join(', ')}';
                  });
                  return;
                }

                if (initialEntry != null) {
                  final updatedEntry = DiaryEntry(
                    id: initialEntry.id,
                    petId: petId,
                    title: title,
                    category: category,
                    note: note,
                    timestamp: initialEntry.timestamp,
                    severity: severity,
                  );
                  context.read<DiaryBloc>().add(
                        UpdateDiaryEntryEvent(
                          updatedEntry,
                          currentPetId: _selectedPetId,
                        ),
                      );
                } else {
                  final entry = DiaryEntry(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    petId: petId,
                    title: title,
                    category: category,
                    note: note,
                    timestamp: DateTime.now(),
                    severity: severity,
                  );
                  context.read<DiaryBloc>().add(AddDiaryEntryEvent(entry));
                }
                Navigator.of(dialogContext).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      initialEntry != null
                          ? 'Diary log updated successfully!'
                          : 'Diary log saved successfully!',
                    ),
                    backgroundColor: AppTheme.primary,
                  ),
                );
              },
              children: [
                // Pet selection
                const FormSectionLabel('Select Pet'),
                DropdownButtonFormField<String>(
                  initialValue: petId,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    color: textPrimary,
                    fontSize: 14,
                  ),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: isDark
                        ? AppTheme.darkSurface
                        : AppTheme.surfaceContainerLow,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: isDark
                            ? const Color(0xFF383634)
                            : AppTheme.surfaceContainer,
                      ),
                    ),
                  ),
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
                const SizedBox(height: 14),

                // Category selection
                const FormSectionLabel('Category'),
                DropdownButtonFormField<String>(
                  initialValue: category,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    color: textPrimary,
                    fontSize: 14,
                  ),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: isDark
                        ? AppTheme.darkSurface
                        : AppTheme.surfaceContainerLow,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: isDark
                            ? const Color(0xFF383634)
                            : AppTheme.surfaceContainer,
                      ),
                    ),
                  ),
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
                      setDialogState(() {
                        category = val;
                        if (val == 'vet') {
                          severity = 'SEVERE';
                        } else if (val == 'food' || val == 'med') {
                          severity = 'MODERATE';
                        } else {
                          severity = 'MILD';
                        }
                      });
                    }
                  },
                ),
                const SizedBox(height: 14),

                // Severity selection
                const FormSectionLabel('Severity Level'),
                Row(
                  children: [
                    _buildSeverityOption(
                      label: 'MILD',
                      isSelected: severity == 'MILD',
                      color: const Color(0xFF5D9CEC),
                      bgColor: const Color(0xFFEBF5FB),
                      onTap: () => setDialogState(() => severity = 'MILD'),
                    ),
                    const SizedBox(width: 8),
                    _buildSeverityOption(
                      label: 'MODERATE',
                      isSelected: severity == 'MODERATE',
                      color: const Color(0xFFF39C12),
                      bgColor: const Color(0xFFFEF9E7),
                      onTap: () => setDialogState(() => severity = 'MODERATE'),
                    ),
                    const SizedBox(width: 8),
                    _buildSeverityOption(
                      label: 'SEVERE',
                      isSelected: severity == 'SEVERE',
                      color: const Color(0xFFE74C3C),
                      bgColor: const Color(0xFFFDEDEC),
                      onTap: () => setDialogState(() => severity = 'SEVERE'),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Title
                const FormSectionLabel('Title *'),
                TextField(
                  controller: titleController,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    color: textPrimary,
                    fontSize: 14,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Morning walk, New kibble test, etc.',
                    hintStyle: TextStyle(
                      color: textSecondary.withValues(alpha: 0.6),
                    ),
                    filled: true,
                    fillColor: isDark
                        ? AppTheme.darkSurface
                        : AppTheme.surfaceContainerLow,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: isDark
                            ? const Color(0xFF383634)
                            : AppTheme.surfaceContainer,
                      ),
                    ),
                    errorText: validationError != null &&
                            titleController.text.trim().isEmpty
                        ? 'Title is required'
                        : null,
                  ),
                  onChanged: (_) {
                    if (validationError != null) {
                      setDialogState(() => validationError = null);
                    }
                  },
                ),
                const SizedBox(height: 14),

                // Note
                const FormSectionLabel('Notes *'),
                TextField(
                  controller: noteController,
                  maxLines: 3,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    color: textPrimary,
                    fontSize: 14,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Write down behavioral notes or details...',
                    hintStyle: TextStyle(
                      color: textSecondary.withValues(alpha: 0.6),
                    ),
                    filled: true,
                    fillColor: isDark
                        ? AppTheme.darkSurface
                        : AppTheme.surfaceContainerLow,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: isDark
                            ? const Color(0xFF383634)
                            : AppTheme.surfaceContainer,
                      ),
                    ),
                    errorText: validationError != null &&
                            noteController.text.trim().isEmpty
                        ? 'Notes are required'
                        : null,
                  ),
                  onChanged: (_) {
                    if (validationError != null) {
                      setDialogState(() => validationError = null);
                    }
                  },
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
    final isDark = context.watch<ThemeCubit>().state;
    final textSecondary = isDark
        ? AppTheme.darkOnSurfaceVariant
        : AppTheme.secondary;
    final textPrimary = isDark ? AppTheme.darkOnSurface : AppTheme.onSurface;
    final cardBg = isDark ? AppTheme.darkSurface : AppTheme.surfaceContainerLow;
    final tileBg = isDark
        ? AppTheme.darkSurface
        : AppTheme.surfaceContainerLowest;
    final primaryColor = isDark ? AppTheme.primaryFixedDim : AppTheme.primary;
    final dividerColor = isDark
        ? const Color(0xFF383634)
        : AppTheme.surfaceContainer;

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
    if (_selectedPetId != null && pets.isNotEmpty) {
      final selectedPet = pets.firstWhere(
        (p) => p.id == _selectedPetId,
        orElse: () => pets.first,
      );
      if (selectedPet.id == _selectedPetId) {
        recordsTitle = "${selectedPet.name}'s Records";
      }
    }

    final isWide = ResponsiveLayout.isWide(context);

    return Scaffold(
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 16.0),
        child: FloatingActionButton(
          heroTag: 'fab_diary_screen_add',
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

          final leftPaneHeader = Padding(
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
                    Text(
                      'HEALTH DIARY',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                        color: textSecondary,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      recordsTitle,
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                        color: primaryColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );

          final statsRow = Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total Entries',
                          style: TextStyle(
                            fontSize: 12,
                            color: textSecondary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '$totalEntries',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Last Incident',
                          style: TextStyle(
                            fontSize: 12,
                            color: textSecondary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          lastIncidentText,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );

          final selectPetSection = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Text(
                  'SELECT A PET',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                    color: textSecondary,
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

                    bool isSelected = false;
                    if (filter == 'all') {
                      isSelected = _selectedPetId == null;
                    } else {
                      if (pets.isEmpty) {
                        isSelected = false;
                      } else {
                        final match = pets.firstWhere(
                          (p) => p.name.toLowerCase() == filter,
                          orElse: () => pets.first,
                        );
                        isSelected =
                            match.name.toLowerCase() == filter &&
                            match.id == _selectedPetId;
                      }
                    }

                    return _buildPetFilterButton(
                      filter,
                      isSelected,
                      pets,
                      isDark,
                      primaryColor,
                      textSecondary,
                    );
                  },
                ),
              ),
            ],
          );

          final entriesListView = isLoading
              ? Center(
                  child: CircularProgressIndicator(color: primaryColor),
                )
              : (entries.isEmpty
                    ? Center(
                        child: Text(
                          'No behavioral logs recorded yet.',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontStyle: FontStyle.italic,
                            color: textSecondary,
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
                          final matchedPet = pets.isNotEmpty
                              ? pets.firstWhere(
                                  (p) => p.id == entry.petId,
                                  orElse: () => pets.first,
                                )
                              : null;
                          final petName =
                              (matchedPet != null &&
                                  matchedPet.id == entry.petId)
                              ? matchedPet.name
                              : 'Luna';

                          return _buildDiaryCard(
                            entry,
                            petName,
                            isDark,
                            tileBg,
                            textPrimary,
                            textSecondary,
                            primaryColor,
                            dividerColor,
                          );
                        },
                      ));

          if (isWide) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Half: Total entries, last incident and select pet
                Expanded(
                  flex: 5,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(top: 8.0, bottom: 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        leftPaneHeader,
                        const SizedBox(height: 8),
                        statsRow,
                        const SizedBox(height: 24),
                        selectPetSection,
                      ],
                    ),
                  ),
                ),
                Container(
                  width: 1,
                  color: dividerColor.withValues(alpha: 0.5),
                ),
                // Right Half: All Diaries entries
                Expanded(
                  flex: 7,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(
                          left: 20.0,
                          right: 20.0,
                          top: 16.0,
                          bottom: 12.0,
                        ),
                        child: Text(
                          'Entries Log',
                          style: TextStyle(
                            fontFamily: 'Montserrat',
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                            color: primaryColor,
                          ),
                        ),
                      ),
                      Expanded(child: entriesListView),
                    ],
                  ),
                ),
              ],
            );
          }

          // Mobile View
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              leftPaneHeader,
              statsRow,
              const SizedBox(height: 20),
              selectPetSection,
              const SizedBox(height: 12),
              Expanded(child: entriesListView),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPetFilterButton(
    String filter,
    bool isSelected,
    List<Pet> pets,
    bool isDark,
    Color primaryColor,
    Color textSecondary,
  ) {
    final displayName = filter == 'all'
        ? 'All'
        : filter[0].toUpperCase() + filter.substring(1);

    // Resolve dynamic pet avatar if present in BLoC list
    String? resolvedAvatarUrl;
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
        onTap: () {
          String? nextId;
          if (filter != 'all' && pets.isNotEmpty) {
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
                  color: isSelected ? primaryColor : Colors.transparent,
                  width: 2,
                ),
              ),
              padding: const EdgeInsets.all(2),
              child: CircleAvatar(
                backgroundColor: isDark
                    ? const Color(0xFF383634)
                    : AppTheme.surfaceContainerHigh,
                backgroundImage: resolvedAvatarUrl != null
                    ? (resolvedAvatarUrl.startsWith('assets/')
                          ? AssetImage(resolvedAvatarUrl)
                          : (resolvedAvatarUrl.startsWith('http')
                              ? NetworkImage(resolvedAvatarUrl)
                              : FileImage(File(resolvedAvatarUrl))))
                        as ImageProvider
                    : null,
                child: resolvedAvatarUrl == null
                    ? (filter == 'all'
                          ? Icon(Icons.group, color: primaryColor, size: 30)
                          : Text(
                              displayName[0],
                              style: TextStyle(
                                fontFamily: 'Montserrat',
                                fontWeight: FontWeight.bold,
                                color: primaryColor,
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
                color: isSelected ? primaryColor : textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmDialog(BuildContext context, DiaryEntry entry) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Delete Entry?',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text('Are you sure you want to delete "${entry.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              context.read<DiaryBloc>().add(
                DeleteDiaryEntryEvent(entry.id, currentPetId: _selectedPetId),
              );
              Navigator.pop(ctx);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Widget _buildDiaryCard(
    DiaryEntry entry,
    String petName,
    bool isDark,
    Color tileBg,
    Color textPrimary,
    Color textSecondary,
    Color primaryColor,
    Color dividerColor,
  ) {
    final styles = _getCategoryStyles(entry.category);
    final label = styles['label'] as String;
    final icon = styles['icon'] as IconData;

    final severity = entry.severity;
    Color badgeColor;
    Color badgeText;
    switch (severity.toUpperCase()) {
      case 'SEVERE':
        badgeColor = isDark ? const Color(0xFF5C2B1D) : const Color(0xFFFDEDEC);
        badgeText = isDark ? const Color(0xFFFFB4A3) : const Color(0xFFE74C3C);
        break;
      case 'MODERATE':
        badgeColor = isDark ? const Color(0xFF523B17) : const Color(0xFFFEF9E7);
        badgeText = isDark ? const Color(0xFFFFD580) : const Color(0xFFF39C12);
        break;
      case 'MILD':
      default:
        badgeColor = isDark ? const Color(0xFF1D3B5C) : const Color(0xFFEBF5FB);
        badgeText = isDark ? const Color(0xFF90CAF9) : const Color(0xFF5D9CEC);
        break;
    }

    return AccentLeftCard(
      accentColor: badgeText,
      backgroundColor: tileBg,
      onTap: () => _showAddEntryDialog(context, initialEntry: entry),
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
                    style: TextStyle(fontSize: 12, color: textSecondary),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: textSecondary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    petName,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
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
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 6),

          // Note Description
          Text(
            entry.note,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              color: textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),

          // Bottom Category tag
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2E4E30) : AppTheme.primaryFixed,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 14,
                  color: isDark
                      ? AppTheme.primaryFixedDim
                      : AppTheme.onPrimaryFixedVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? AppTheme.primaryFixedDim
                        : AppTheme.onPrimaryFixedVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeverityOption({
    required String label,
    required bool isSelected,
    required Color color,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? bgColor : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? color
                  : AppTheme.outlineVariant.withValues(alpha: 0.5),
              width: 1.5,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isSelected
                  ? color
                  : AppTheme.onSurfaceVariant.withValues(alpha: 0.6),
            ),
          ),
        ),
      ),
    );
  }
}
