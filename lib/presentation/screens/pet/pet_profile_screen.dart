import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../widgets/photo_source_bottom_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../logic/theme/theme_cubit.dart';
import '../../../logic/pet/pet_bloc.dart';
import '../../../logic/diary/diary_bloc.dart';
import '../../../data/models/pet.dart';
import '../../../data/models/weight_log.dart';
import '../../../data/models/medication.dart';
import '../../../data/models/diary_entry.dart';
import '../../../core/utils/responsive_layout.dart';
import '../../theme/app_theme.dart';
import '../../widgets/accent_left_card.dart';
import '../../widgets/pet/pet_recent_memories_widget.dart';
import '../../widgets/base_form_dialog.dart';
import '../../../core/services/local_media_service.dart';
import '../../../data/services/google_drive_service.dart';
import 'pet_details_screen.dart';
import 'meds_vaccines_screen.dart';
import 'pet_album_screen.dart';

class PetProfileScreen extends StatefulWidget {
  final Pet pet;
  const PetProfileScreen({super.key, required this.pet});

  @override
  State<PetProfileScreen> createState() => _PetProfileScreenState();
}

class _PetProfileScreenState extends State<PetProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Pet _pet;
  String _selectedWeightUnit = 'kg';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _pet = widget.pet;
    _loadWeightUnitPreference();
  }

  Future<void> _loadWeightUnitPreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedUnit = prefs.getString('preferred_weight_unit') ?? 'kg';
      if (mounted) {
        setState(() {
          _selectedWeightUnit = savedUnit;
        });
      }
    } catch (_) {}
  }

  Future<void> _setWeightUnit(String unit) async {
    setState(() {
      _selectedWeightUnit = unit;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('preferred_weight_unit', unit);
    } catch (_) {}
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showAddWeightDialog() {
    final weightController = TextEditingController();
    final noteController = TextEditingController();
    String dialogUnit = _selectedWeightUnit;
    String? validationError;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            final isDark = context.read<ThemeCubit>().state;
            final textPrimary = isDark
                ? AppTheme.darkOnSurface
                : AppTheme.onSurface;
            final textSecondary = isDark
                ? AppTheme.darkOnSurfaceVariant
                : AppTheme.secondary;

            return BaseFormDialog(
              icon: Icons.scale_outlined,
              title: 'Log New Weight',
              subtitle: 'Track ${_pet.name}\'s physical growth & health',
              validationError: validationError,
              primaryButtonText: 'Save Log',
              primaryButtonIcon: Icons.check,
              onPrimaryPressed: () {
                final weightValue = double.tryParse(
                  weightController.text.trim(),
                );
                if (weightValue == null || weightValue <= 0) {
                  setDialogState(() {
                    validationError =
                        'Please enter a valid weight number above 0';
                  });
                  return;
                }

                final maxVal = dialogUnit == 'kg' ? 150.0 : 330.0;
                if (weightValue > maxVal) {
                  setDialogState(() {
                    validationError =
                        'Weight exceeds standard range (Max $maxVal $dialogUnit)';
                  });
                  return;
                }

                final newLog = WeightLog(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  weight: weightValue,
                  unit: dialogUnit,
                  date: DateTime.now(),
                  note: noteController.text.trim().isEmpty
                      ? 'At Home'
                      : noteController.text.trim(),
                );

                final updatedHistory = List<WeightLog>.from(_pet.weightHistory)
                  ..insert(0, newLog);

                final weightInKg = dialogUnit == 'lbs'
                    ? weightValue / 2.20462
                    : weightValue;

                final updatedPet = _pet.copyWith(
                  weight: weightInKg,
                  weightHistory: updatedHistory,
                );

                context.read<PetBloc>().add(UpdatePet(updatedPet));
                setState(() {
                  _pet = updatedPet;
                });
                _setWeightUnit(dialogUnit);
                Navigator.of(dialogContext).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Logged ${weightValue.toStringAsFixed(1)} $dialogUnit for ${_pet.name}!',
                    ),
                    backgroundColor: AppTheme.primary,
                  ),
                );
              },
              children: [
                const FormSectionLabel('WEIGHT MEASUREMENT'),
                // Unit selector toggle pill
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppTheme.darkSurface
                        : AppTheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF383634)
                          : AppTheme.surfaceContainer,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setDialogState(() {
                            dialogUnit = 'kg';
                            validationError = null;
                          }),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: dialogUnit == 'kg'
                                  ? AppTheme.primary
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: dialogUnit == 'kg'
                                  ? [
                                      BoxShadow(
                                        color: AppTheme.primary.withValues(
                                          alpha: 0.3,
                                        ),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : [],
                            ),
                            child: Center(
                              child: Text(
                                'Kilograms (kg)',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: dialogUnit == 'kg'
                                      ? Colors.white
                                      : textSecondary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setDialogState(() {
                            dialogUnit = 'lbs';
                            validationError = null;
                          }),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: dialogUnit == 'lbs'
                                  ? AppTheme.primary
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: dialogUnit == 'lbs'
                                  ? [
                                      BoxShadow(
                                        color: AppTheme.primary.withValues(
                                          alpha: 0.3,
                                        ),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : [],
                            ),
                            child: Center(
                              child: Text(
                                'Pounds (lbs)',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: dialogUnit == 'lbs'
                                      ? Colors.white
                                      : textSecondary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // Weight input field
                TextField(
                  controller: weightController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: '0.0',
                    hintStyle: TextStyle(
                      color: textSecondary.withValues(alpha: 0.5),
                      fontWeight: FontWeight.normal,
                    ),
                    prefixIcon: const Icon(
                      Icons.monitor_weight_outlined,
                      color: AppTheme.primary,
                    ),
                    suffixText: dialogUnit,
                    suffixStyle: const TextStyle(
                      fontFamily: 'Montserrat',
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: AppTheme.primary,
                    ),
                    filled: true,
                    fillColor: isDark
                        ? AppTheme.darkSurface
                        : AppTheme.surfaceContainerLow,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: isDark
                            ? const Color(0xFF383634)
                            : AppTheme.surfaceContainer,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: isDark
                            ? const Color(0xFF383634)
                            : AppTheme.surfaceContainer,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: AppTheme.primary,
                        width: 1.5,
                      ),
                    ),
                  ),
                  onChanged: (_) {
                    if (validationError != null) {
                      setDialogState(() => validationError = null);
                    }
                  },
                ),
                const SizedBox(height: 14),

                const FormSectionLabel('NOTES & DETAILS'),
                TextField(
                  controller: noteController,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    color: textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: 'e.g. Morning baseline, vet visit, post-walk',
                    hintStyle: TextStyle(
                      color: textSecondary.withValues(alpha: 0.6),
                      fontSize: 13,
                    ),
                    prefixIcon: const Icon(
                      Icons.sticky_note_2_outlined,
                      color: AppTheme.secondary,
                    ),
                    filled: true,
                    fillColor: isDark
                        ? AppTheme.darkSurface
                        : AppTheme.surfaceContainerLow,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: isDark
                            ? const Color(0xFF383634)
                            : AppTheme.surfaceContainer,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: isDark
                            ? const Color(0xFF383634)
                            : AppTheme.surfaceContainer,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: AppTheme.secondary,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _deleteWeightLog(WeightLog logToDelete) {
    final isDark = context.read<ThemeCubit>().state;
    final textPrimary = isDark ? AppTheme.darkOnSurface : AppTheme.onSurface;
    final textSecondary = isDark
        ? AppTheme.darkOnSurfaceVariant
        : AppTheme.secondary;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: isDark
              ? AppTheme.darkSurface
              : AppTheme.surfaceContainerLowest,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Delete Weight Log?',
            style: TextStyle(fontWeight: FontWeight.bold, color: textPrimary),
          ),
          content: Text(
            'Are you sure you want to delete this weight log recorded on ${logToDelete.date.day}/${logToDelete.date.month}/${logToDelete.date.year}?',
            style: TextStyle(color: textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text('Cancel', style: TextStyle(color: textSecondary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.error,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                final updatedHistory = List<WeightLog>.from(_pet.weightHistory)
                  ..removeWhere((item) => item.id == logToDelete.id);

                double newPetWeight = _pet.weight;
                if (updatedHistory.isNotEmpty) {
                  final latest = updatedHistory.first;
                  newPetWeight = latest.unit.toLowerCase() == 'lbs'
                      ? latest.weight / 2.20462
                      : latest.weight;
                }

                final updatedPet = _pet.copyWith(
                  weightHistory: updatedHistory,
                  weight: newPetWeight,
                );

                context.read<PetBloc>().add(UpdatePet(updatedPet));
                setState(() {
                  _pet = updatedPet;
                });
                Navigator.of(dialogContext).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Weight log deleted!'),
                    backgroundColor: AppTheme.error,
                  ),
                );
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHeroPictureCard({
    required bool isDark,
    required Color textSecondary,
    double? height,
  }) {
    Widget buildRawImage(BoxFit fit) {
      return LocalMediaService.buildSmartImage(
        path: _pet.avatarUrl,
        fit: fit,
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Stack(
        children: [
          Container(
            height: height,
            width: double.infinity,
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF2A2826)
                  : AppTheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Subtle background image fill
                  Opacity(opacity: 0.35, child: buildRawImage(BoxFit.cover)),
                  // Foreground complete pet image without cropping
                  Center(child: buildRawImage(BoxFit.contain)),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.85),
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _pet.name,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_pet.breed} • ${_pet.ageString}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
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
    final headerColor = isDark ? AppTheme.primaryFixedDim : AppTheme.primary;

    final petState = context.watch<PetBloc>().state;
    if (petState is PetLoaded) {
      final updatedPet = petState.pets.firstWhere(
        (p) => p.id == _pet.id,
        orElse: () => _pet,
      );
      if (updatedPet.id == _pet.id) {
        _pet = updatedPet;
      }
    }

    final isWide = ResponsiveLayout.isWide(context);

    final petHeroHeader = Column(
      children: [
        // Profile Hero Section
        _buildHeroPictureCard(
          isDark: isDark,
          textSecondary: textSecondary,
          height: 280,
        ),
        const SizedBox(height: 20),

        // Quick Stats Row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Row(
            children: [
              _buildStatCard(
                label: 'Age',
                value: _pet.ageString,
                icon: Icons.cake,
                iconColor: const Color(0xFF9E5A44),
              ),
              const SizedBox(width: 8),
              _buildStatCard(
                label: 'Weight',
                value: _selectedWeightUnit == 'lbs'
                    ? '${(_pet.weight * 2.20462).toStringAsFixed(1)} lbs'
                    : '${_pet.weight.toStringAsFixed(1)} kg',
                icon: Icons.scale_outlined,
                iconColor: const Color(0xFF1F6156),
              ),
              const SizedBox(width: 8),
              _buildStatCard(
                label: 'Vaccine',
                value: _getNextVaccineDate(),
                icon: Icons.vaccines,
                iconColor: const Color(0xFFE67E22),
              ),
              const SizedBox(width: 8),
              _buildStatCard(
                label: 'Details',
                value: 'Info',
                icon: Icons.assignment_outlined,
                iconColor: Colors.white,
                isHighlighted: true,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => PetDetailsScreen(pet: _pet),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Recent Photos Gallery
        PetRecentMemoriesWidget(
          photos: _pet.photos,
          textPrimary: textPrimary,
          headerColor: headerColor,
          onViewAlbum: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) =>
                    PetAlbumScreen(initialPetFilter: _pet.name),
              ),
            );
          },
          onAddPhoto: () => _showAddPhotoModal(context),
          onPhotoTap: (index) => _openPhotoViewer(context, index),
        ),
        const SizedBox(height: 16),
      ],
    );

    final tabsHeaderAndBody = Column(
      children: [
        // Tabs navigation
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF383634) : AppTheme.surfaceContainer,
            borderRadius: BorderRadius.circular(999),
          ),
          child: TabBar(
            controller: _tabController,
            indicatorSize: TabBarIndicatorSize.tab,
            indicatorPadding: EdgeInsets.zero,
            indicator: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              color: isDark ? AppTheme.darkSurface : Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.08),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            labelColor: headerColor,
            unselectedLabelColor: textPrimary,
            labelStyle: const TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
            unselectedLabelStyle: const TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
            dividerColor: Colors.transparent,
            overlayColor: WidgetStateProperty.all(Colors.transparent),
            tabs: const [
              Tab(text: 'Diary'),
              Tab(text: 'Weight'),
              Tab(text: 'Meds'),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Tab View Body
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [_buildDiaryTab(), _buildWeightTab(), _buildMedsTab()],
          ),
        ),
      ],
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${_pet.name}\'s Profile',
          style: TextStyle(fontWeight: FontWeight.bold, color: textPrimary),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: headerColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppTheme.error),
            onPressed: () {
              showDialog(
                context: context,
                builder: (dialogContext) => AlertDialog(
                  title: const Text('Delete Pet Profile?'),
                  content: Text(
                    'Are you sure you want to delete ${_pet.name}? This will clear all health and diary histories.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        context.read<PetBloc>().add(DeletePet(_pet.id));
                        Navigator.pop(dialogContext);
                        Navigator.of(context).pop(); // Go back to HomeTab
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.error,
                      ),
                      child: const Text(
                        'Delete',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          context.read<PetBloc>().add(LoadPets());
        },
        child: isWide
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Left Half: Hero image expanding to fill vertical space, stats & gallery
                  Expanded(
                    flex: 5,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 24.0),
                      child: Column(
                        children: [
                          Expanded(
                            child: _buildHeroPictureCard(
                              isDark: isDark,
                              textSecondary: textSecondary,
                              height: double.infinity,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Quick Stats Row
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20.0,
                            ),
                            child: Row(
                              children: [
                                _buildStatCard(
                                  label: 'Age',
                                  value: _pet.ageString,
                                  icon: Icons.cake,
                                  iconColor: const Color(0xFF9E5A44),
                                ),
                                const SizedBox(width: 8),
                                _buildStatCard(
                                  label: 'Weight',
                                  value: _selectedWeightUnit == 'lbs'
                                      ? '${(_pet.weight * 2.20462).toStringAsFixed(1)} lbs'
                                      : '${_pet.weight.toStringAsFixed(1)} kg',
                                  icon: Icons.scale_outlined,
                                  iconColor: const Color(0xFF1F6156),
                                ),
                                const SizedBox(width: 8),
                                _buildStatCard(
                                  label: 'Vaccine',
                                  value: _getNextVaccineDate(),
                                  icon: Icons.vaccines,
                                  iconColor: const Color(0xFFE67E22),
                                ),
                                const SizedBox(width: 8),
                                _buildStatCard(
                                  label: 'Details',
                                  value: 'Info',
                                  icon: Icons.assignment_outlined,
                                  iconColor: Colors.white,
                                  isHighlighted: true,
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            PetDetailsScreen(pet: _pet),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Recent Photos Gallery
                          PetRecentMemoriesWidget(
                            photos: _pet.photos,
                            textPrimary: textPrimary,
                            headerColor: headerColor,
                            onViewAlbum: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => PetAlbumScreen(
                                    initialPetFilter: _pet.name,
                                  ),
                                ),
                              );
                            },
                            onAddPhoto: () => _showAddPhotoModal(context),
                            onPhotoTap: (index) =>
                                _openPhotoViewer(context, index),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    width: 1,
                    color:
                        (isDark
                                ? const Color(0xFF383634)
                                : AppTheme.surfaceContainer)
                            .withValues(alpha: 0.5),
                  ),
                  // Right Half: Diary, Weight, Meds Tabs
                  Expanded(
                    flex: 6,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: tabsHeaderAndBody,
                    ),
                  ),
                ],
              )
            : NestedScrollView(
                headerSliverBuilder:
                    (BuildContext context, bool innerBoxIsScrolled) {
                      return <Widget>[SliverToBoxAdapter(child: petHeroHeader)];
                    },
                body: tabsHeaderAndBody,
              ),
      ),
    );
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    required IconData icon,
    required Color iconColor,
    bool isHighlighted = false,
    VoidCallback? onTap,
  }) {
    final isDark = context.read<ThemeCubit>().state;
    final textSecondary = isDark
        ? AppTheme.darkOnSurfaceVariant
        : AppTheme.secondary;
    final textPrimary = isDark ? AppTheme.darkOnSurface : AppTheme.onSurface;
    final cardBg = isDark ? AppTheme.darkSurface : Colors.white;
    final headerColor = isDark ? AppTheme.primaryFixedDim : AppTheme.primary;

    final cardBody = Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: isHighlighted ? headerColor : cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isHighlighted
              ? headerColor
              : (isDark
                    ? const Color(0xFF383634)
                    : AppTheme.surfaceContainerLow),
          width: 1,
        ),
        boxShadow: isHighlighted
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: isHighlighted
                ? Colors.white
                : (isDark && iconColor == const Color(0xFF1F6156)
                      ? AppTheme.primaryFixedDim
                      : iconColor),
            size: 24,
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isHighlighted
                  ? Colors.white.withValues(alpha: 0.8)
                  : textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: isHighlighted ? Colors.white : textPrimary,
            ),
          ),
        ],
      ),
    );

    return Expanded(
      child: onTap != null
          ? GestureDetector(onTap: onTap, child: cardBody)
          : cardBody,
    );
  }

  Future<void> _pickPhoto(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: source);
      if (!mounted) return;
      if (pickedFile != null) {
        String finalPath = pickedFile.path;
        final file = File(pickedFile.path);
        if (file.existsSync()) {
          final savedFile = await LocalMediaService.saveToPawsNCareDirectory(
            file,
          );
          finalPath = savedFile.path;

          if (await GoogleDriveService.isDriveLinked()) {
            final driveUrl = await GoogleDriveService.uploadPetImageToDrive(
              savedFile,
              _pet,
              isProfilePicture: false,
            );
            if (driveUrl != null) {
              finalPath = driveUrl;
            }
          }
        }

        final updatedPhotos = List<String>.from(_pet.photos)
          ..insert(0, finalPath);
        final updatedPet = _pet.copyWith(photos: updatedPhotos);

        if (!mounted) return;
        context.read<PetBloc>().add(UpdatePet(updatedPet));
        setState(() {
          _pet = updatedPet;
        });

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Photo added to ${_pet.name}\'s gallery!'),
            backgroundColor: AppTheme.primary,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error selecting photo: $e')));
    }
  }

  void _openPhotoViewer(BuildContext context, int index) {
    if (index < 0 || index >= _pet.photos.length) return;
    final photoUrl = _pet.photos[index];
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.95),
      builder: (dialogContext) {
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
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: InteractiveViewer(
                      child: LocalMediaService.buildSmartImage(
                        path: photoUrl,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () {
                          Navigator.of(dialogContext).pop();
                          _confirmDeletePhoto(index);
                        },
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Color(0xFFFFB4A3),
                          size: 18,
                        ),
                        label: const Text(
                          'Delete Photo',
                          style: TextStyle(color: Color(0xFFFFB4A3)),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: const Color(
                              0xFFFFB4A3,
                            ).withValues(alpha: 0.5),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Close'),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _confirmDeletePhoto(int index) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Delete Photo?',
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontWeight: FontWeight.bold,
              color: AppTheme.primary,
            ),
          ),
          content: const Text(
            'Are you sure you want to remove this photo from your pet profile?',
            style: TextStyle(fontFamily: 'Inter'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                final updatedPhotos = List<String>.from(_pet.photos)
                  ..removeAt(index);
                final updatedPet = _pet.copyWith(photos: updatedPhotos);

                context.read<PetBloc>().add(UpdatePet(updatedPet));
                setState(() {
                  _pet = updatedPet;
                });

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Photo deleted successfully.')),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.error,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showAddPhotoModal(BuildContext context) async {
    final source = await PhotoSourceBottomSheet.show(
      context,
      title: 'Select Media Source',
    );
    if (source != null) {
      _pickPhoto(source);
    }
  }

  String _getNextVaccineDate() {
    if (_pet.medications.isEmpty) return 'Oct 12';
    final meds = List<Medication>.from(_pet.medications)
      ..sort((a, b) => a.nextDoseDate.compareTo(b.nextDoseDate));
    final next = meds.first.nextDoseDate;
    final months = [
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
    return '${months[next.month - 1]} ${next.day}';
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return Icons.restaurant;
      case 'walk':
        return Icons.directions_walk;
      case 'med':
        return Icons.medication;
      case 'vet':
        return Icons.medical_services;
      case 'hydration':
        return Icons.water_drop;
      default:
        return Icons.notes;
    }
  }

  Color _getCategoryColor(String category, bool isDark) {
    switch (category.toLowerCase()) {
      case 'food':
        return const Color(0xFFE67E22);
      case 'walk':
        return isDark ? AppTheme.primaryFixedDim : AppTheme.primary;
      case 'med':
        return AppTheme.tertiary;
      case 'vet':
        return const Color(0xFF9B59B6);
      case 'hydration':
        return const Color(0xFF2980B9);
      default:
        return isDark ? AppTheme.primaryFixedDim : AppTheme.primary;
    }
  }

  Widget _buildMinimalDiaryTile(
    DiaryEntry entry,
    bool isDark,
    Color cardBg,
    Color textPrimary,
    Color textSecondary,
    Color headerColor,
  ) {
    final catColor = _getCategoryColor(entry.category, isDark);
    final catIcon = _getCategoryIcon(entry.category);
    final now = DateTime.now();
    final dt = entry.timestamp;
    final isToday =
        dt.year == now.year && dt.month == now.month && dt.day == now.day;
    final timeStr = _formatTime(dt);
    final dateStr = isToday
        ? 'Today, $timeStr'
        : '${dt.day}/${dt.month} • $timeStr';

    Color accentColor;
    switch (entry.severity.toUpperCase()) {
      case 'SEVERE':
        accentColor = isDark
            ? const Color(0xFFFFB4A3)
            : const Color(0xFFE74C3C);
        break;
      case 'MODERATE':
        accentColor = isDark
            ? const Color(0xFFFFD580)
            : const Color(0xFFF39C12);
        break;
      case 'MILD':
      default:
        accentColor = isDark
            ? const Color(0xFF90CAF9)
            : const Color(0xFF5D9CEC);
        break;
    }

    return AccentLeftCard(
      accentColor: accentColor,
      backgroundColor: cardBg,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      borderRadius: 14.0,
      child: Row(
        children: [
          // Category Avatar Box
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: catColor.withValues(alpha: isDark ? 0.2 : 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(catIcon, color: catColor, size: 20),
          ),
          const SizedBox(width: 12),
          // Title & Note info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        entry.title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      dateStr,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: textSecondary,
                      ),
                    ),
                  ],
                ),
                if (entry.note.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    entry.note,
                    style: TextStyle(fontSize: 12, color: textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiaryTab() {
    final isDark = context.watch<ThemeCubit>().state;
    final textSecondary = isDark
        ? AppTheme.darkOnSurfaceVariant
        : AppTheme.secondary;
    final textPrimary = isDark ? AppTheme.darkOnSurface : AppTheme.onSurface;
    final cardBg = isDark
        ? AppTheme.darkSurface
        : AppTheme.surfaceContainerLowest;
    final headerColor = isDark ? AppTheme.primaryFixedDim : AppTheme.primary;

    return BlocBuilder<DiaryBloc, DiaryState>(
      builder: (context, state) {
        if (state is DiaryLoaded) {
          final petEntries =
              state.entries.where((e) => e.petId == _pet.id).toList()
                ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

          if (petEntries.isEmpty) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _buildEmptyMinimalCard(
                'No activity logs recorded for ${_pet.name}.',
                isDark,
                cardBg,
                textSecondary,
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                ...petEntries.map(
                  (entry) => _buildMinimalDiaryTile(
                    entry,
                    isDark,
                    cardBg,
                    textPrimary,
                    textSecondary,
                    headerColor,
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        }
        return Center(child: CircularProgressIndicator(color: headerColor));
      },
    );
  }

  String _getMonthName(int month) {
    const monthNames = [
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
    return monthNames[month - 1];
  }

  Widget _buildWeightTab() {
    final isDark = context.watch<ThemeCubit>().state;
    final textSecondary = isDark
        ? AppTheme.darkOnSurfaceVariant
        : AppTheme.secondary;
    final textPrimary = isDark ? AppTheme.darkOnSurface : AppTheme.onSurface;
    final cardBg = isDark
        ? AppTheme.darkSurface
        : AppTheme.surfaceContainerLowest;
    final headerColor = isDark ? AppTheme.primaryFixedDim : AppTheme.primary;

    final history = _pet.weightHistory;

    // Use system date (DateTime.now()) as reference to calculate the last 6 months (oldest to newest)
    final now = DateTime.now();
    final last6Months = List.generate(6, (i) {
      return DateTime(now.year, now.month - (5 - i), 1);
    });

    // Chronologically sort history
    final sortedHistory = List<WeightLog>.from(history)
      ..sort((a, b) => a.date.compareTo(b.date));

    // 1) Compute raw monthly averages in baseline KG using system reference months
    final List<double?> rawMonthlyAveragesKg = last6Months.map((m) {
      final logsInMonth = sortedHistory
          .where((log) => log.date.year == m.year && log.date.month == m.month)
          .toList();

      if (logsInMonth.isNotEmpty) {
        final sum = logsInMonth.fold<double>(0.0, (val, log) {
          final wInKg = log.unit.toLowerCase() == 'lbs'
              ? log.weight / 2.20462
              : log.weight;
          return val + wInKg;
        });
        return sum / logsInMonth.length;
      }

      // Check if there is any log logged prior to the end of month m
      final endOfMonth = DateTime(m.year, m.month + 1, 0, 23, 59, 59);
      final priorLogs = sortedHistory
          .where((log) => log.date.isBefore(endOfMonth))
          .toList();

      if (priorLogs.isNotEmpty) {
        final lastPriorLog = priorLogs.last;
        return lastPriorLog.unit.toLowerCase() == 'lbs'
            ? lastPriorLog.weight / 2.20462
            : lastPriorLog.weight;
      }

      return null;
    }).toList();

    // 2) Convert monthly averages to active _selectedWeightUnit
    final List<double?> averages = rawMonthlyAveragesKg.map((wKg) {
      if (wKg == null) return null;
      return _selectedWeightUnit == 'lbs' ? wKg * 2.20462 : wKg;
    }).toList();

    // Scale calculation
    double finalMinW = 0.0;
    double finalMaxW = 10.0;
    double? foundMin;
    double? foundMax;
    for (final avg in averages) {
      if (avg != null) {
        if (foundMin == null || avg < foundMin) foundMin = avg;
        if (foundMax == null || avg > foundMax) foundMax = avg;
      }
    }

    if (foundMin != null && foundMax != null) {
      if (foundMin == foundMax) {
        finalMinW = foundMin - 1.0;
        finalMaxW = foundMax + 1.0;
      } else {
        final diff = foundMax - foundMin;
        finalMinW = foundMin - diff * 0.15;
        finalMaxW = foundMax + diff * 0.15;
        if (finalMinW < 0) finalMinW = 0.0;
      }
    }

    // Trend badge calculation
    String trendText = 'No data';
    bool showTrend = false;
    double trendDiff = 0.0;

    int latestDataIdx = -1;
    int prevDataIdx = -1;
    for (int i = 5; i >= 0; i--) {
      if (averages[i] != null) {
        if (latestDataIdx == -1) {
          latestDataIdx = i;
        } else if (prevDataIdx == -1) {
          prevDataIdx = i;
          break;
        }
      }
    }

    if (latestDataIdx != -1 && prevDataIdx != -1) {
      final w1 = averages[latestDataIdx]!;
      final w2 = averages[prevDataIdx]!;
      trendDiff = w1 - w2;
      final prefix = trendDiff >= 0 ? '+' : '';
      trendText =
          '$prefix${trendDiff.toStringAsFixed(1)}$_selectedWeightUnit this month';
      showTrend = true;
    } else if (latestDataIdx != -1) {
      trendText = '0.0$_selectedWeightUnit this month';
      showTrend = true;
    }

    final double chartMinW = finalMinW;
    final double chartMaxW = finalMaxW;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Weight trend card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isDark
                    ? const Color(0xFF383634)
                    : AppTheme.surfaceContainerLow,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.01),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: history.isEmpty
                ? SizedBox(
                    height: 220,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.monitor_weight_outlined,
                            size: 44,
                            color: textSecondary.withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No weight logs recorded yet.',
                            style: TextStyle(
                              color: textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Tap "+ Add Log" below to record weight.',
                            style: TextStyle(
                              fontSize: 12,
                              color: textSecondary.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Weight\nTrend',
                                style: TextStyle(
                                  fontFamily: 'Montserrat',
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  height: 1.1,
                                  color: textPrimary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Last 6 months monitoring',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: textSecondary,
                                ),
                              ),
                            ],
                          ),
                          if (showTrend)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: trendDiff >= 0
                                    ? (isDark
                                          ? const Color(0xFF2E4E30)
                                          : const Color(0xFFE2F5E9))
                                    : (isDark
                                          ? const Color(0xFF5C2B1D)
                                          : const Color(0xFFFDE8E8)),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                trendText,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: trendDiff >= 0
                                      ? (isDark
                                            ? AppTheme.primaryFixedDim
                                            : const Color(0xFF386B52))
                                      : (isDark
                                            ? const Color(0xFFFFB4A3)
                                            : const Color(0xFF9B1C1C)),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Graph area
                      SizedBox(
                        height: 160,
                        child: Stack(
                          children: [
                            // Horizontal grid lines
                            Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: List.generate(
                                4,
                                (index) => Container(
                                  height: 1,
                                  color: isDark
                                      ? const Color(0xFF383634)
                                      : AppTheme.surfaceContainerLow,
                                ),
                              ),
                            ),
                            // Bars and labels
                            Positioned.fill(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4.0,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: List.generate(6, (idx) {
                                    final m = last6Months[idx];
                                    final avg = averages[idx];
                                    final monthLabel = _getMonthName(m.month);
                                    final isLatestMonth = idx == 5;
                                    Widget barWidget;
                                    Widget weightTextWidget;

                                    if (avg != null) {
                                      final factor = (chartMinW == chartMaxW)
                                          ? 0.5
                                          : (avg - chartMinW) /
                                                (chartMaxW - chartMinW);
                                      final clampedFactor = factor.clamp(
                                        0.0,
                                        1.0,
                                      );
                                      const double plotHeight = 70.0;
                                      final double barHeight =
                                          plotHeight *
                                          (0.15 + 0.7 * clampedFactor);

                                      weightTextWidget = Text(
                                        avg.toStringAsFixed(1),
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: isLatestMonth
                                              ? FontWeight.bold
                                              : FontWeight.w500,
                                          color: isLatestMonth
                                              ? headerColor
                                              : textSecondary,
                                        ),
                                      );

                                      barWidget = SizedBox(
                                        height: 76,
                                        child: Stack(
                                          alignment: Alignment.bottomCenter,
                                          clipBehavior: Clip.none,
                                          children: [
                                            // Vertical line bar
                                            Container(
                                              width: isLatestMonth ? 5 : 3,
                                              height: barHeight,
                                              decoration: BoxDecoration(
                                                color: isLatestMonth
                                                    ? headerColor
                                                    : headerColor.withValues(
                                                        alpha: 0.4,
                                                      ),
                                                borderRadius:
                                                    BorderRadius.circular(3),
                                              ),
                                            ),
                                            // Circular dot marker
                                            Positioned(
                                              bottom: barHeight - 4,
                                              child: Container(
                                                width: isLatestMonth ? 10 : 8,
                                                height: isLatestMonth ? 10 : 8,
                                                decoration: BoxDecoration(
                                                  color: isLatestMonth
                                                      ? headerColor
                                                      : headerColor.withValues(
                                                          alpha: 0.8,
                                                        ),
                                                  shape: BoxShape.circle,
                                                  border: isLatestMonth
                                                      ? Border.all(
                                                          color: headerColor
                                                              .withValues(
                                                                alpha: 0.2,
                                                              ),
                                                          width: 3,
                                                          strokeAlign: BorderSide
                                                              .strokeAlignOutside,
                                                        )
                                                      : null,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    } else {
                                      weightTextWidget = Text(
                                        'N/A',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                          color: textSecondary,
                                        ),
                                      );
                                      barWidget = const SizedBox(height: 76);
                                    }

                                    return Expanded(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          weightTextWidget,
                                          const SizedBox(height: 6),
                                          barWidget,
                                          const SizedBox(height: 8),
                                          Text(
                                            monthLabel,
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: isLatestMonth
                                                  ? FontWeight.bold
                                                  : FontWeight.w500,
                                              color: isLatestMonth
                                                  ? textPrimary
                                                  : textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
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

          // Action row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Weight History Logs',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: textPrimary,
                ),
              ),
              Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppTheme.darkSurface
                          : AppTheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF383634)
                            : AppTheme.surfaceContainer,
                      ),
                    ),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => _setWeightUnit('kg'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: _selectedWeightUnit == 'kg'
                                  ? AppTheme.primary
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              'kg',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: _selectedWeightUnit == 'kg'
                                    ? Colors.white
                                    : textSecondary,
                              ),
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => _setWeightUnit('lbs'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: _selectedWeightUnit == 'lbs'
                                  ? AppTheme.primary
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              'lbs',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: _selectedWeightUnit == 'lbs'
                                    ? Colors.white
                                    : textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _showAddWeightDialog,
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text(
                      'Add Log',
                      style: TextStyle(fontSize: 12),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: headerColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Weight Logs List
          if (history.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20.0),
              child: Center(
                child: Text(
                  'No weight history logs recorded.',
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: textSecondary,
                  ),
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: history.length,
              itemBuilder: (context, index) {
                final log = history[index];
                double displayWeightVal;
                if (_selectedWeightUnit == 'lbs') {
                  displayWeightVal = log.unit == 'lbs'
                      ? log.weight
                      : log.weight * 2.20462;
                } else {
                  displayWeightVal = log.unit == 'lbs'
                      ? log.weight / 2.20462
                      : log.weight;
                }

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF383634)
                          : AppTheme.surfaceContainerLow,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${log.date.day}/${log.date.month}/${log.date.year}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: textPrimary,
                              ),
                            ),
                            if (log.note.isNotEmpty)
                              Text(
                                log.note,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: textSecondary,
                                ),
                              ),
                          ],
                        ),
                      ),
                      Text(
                        '${displayWeightVal.toStringAsFixed(1)} $_selectedWeightUnit',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: headerColor,
                        ),
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          size: 20,
                          color: AppTheme.error,
                        ),
                        tooltip: 'Delete Log',
                        onPressed: () => _deleteWeightLog(log),
                      ),
                    ],
                  ),
                );
              },
            ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  String _getMonthAbbr(int month) {
    const months = [
      'JAN',
      'FEB',
      'MAR',
      'APR',
      'MAY',
      'JUN',
      'JUL',
      'AUG',
      'SEP',
      'OCT',
      'NOV',
      'DEC',
    ];
    return months[(month - 1).clamp(0, 11)];
  }

  Widget _buildEmptyMinimalCard(
    String message,
    bool isDark,
    Color cardBg,
    Color textSecondary,
  ) {
    return AccentLeftCard(
      accentColor: AppTheme.secondary,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      child: Text(
        message,
        style: TextStyle(
          fontStyle: FontStyle.italic,
          fontSize: 12,
          color: textSecondary,
        ),
      ),
    );
  }

  Widget _buildMinimalMedTile(
    Medication med,
    bool isDark,
    Color cardBg,
    Color textPrimary,
    Color textSecondary,
    Color headerColor,
  ) {
    final date = med.nextDoseDate;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueDate = DateTime(date.year, date.month, date.day);
    final isToday = today.isAtSameMomentAs(dueDate);
    final isOverdue = dueDate.isBefore(today);
    final daysOverdue = today.difference(dueDate).inDays;

    final String statusText;
    final Color statusColor;
    final Color statusBg;
    final IconData statusIcon;

    if (isToday) {
      statusText = 'Due Today';
      statusColor = isDark
          ? AppTheme.statusScheduledDark
          : AppTheme.statusScheduled;
      statusBg = isDark
          ? AppTheme.statusScheduledDarkBg
          : AppTheme.statusScheduledBg;
      statusIcon = Icons.today;
    } else if (isOverdue) {
      statusText = 'Overdue${daysOverdue > 0 ? ' ${daysOverdue}d' : ''}';
      statusColor = isDark
          ? AppTheme.statusOverdueDark
          : AppTheme.statusOverdue;
      statusBg = isDark
          ? AppTheme.statusOverdueDarkBg
          : AppTheme.statusOverdueBg;
      statusIcon = Icons.error_outline;
    } else {
      statusText = 'Scheduled';
      statusColor = isDark
          ? AppTheme.statusScheduledDark
          : AppTheme.statusScheduled;
      statusBg = isDark
          ? AppTheme.statusScheduledDarkBg
          : AppTheme.statusScheduledBg;
      statusIcon = Icons.event;
    }

    return AccentLeftCard(
      accentColor: statusColor,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => MedsVaccinesScreen(pet: _pet)),
        );
      },
      child: Row(
        children: [
          // Date Badge Box
          Container(
            width: 48,
            height: 50,
            decoration: BoxDecoration(
              color: statusBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _getMonthAbbr(date.month),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
                Text(
                  '${date.day}',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: statusColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Title & Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        med.name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: statusBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusIcon, size: 11, color: statusColor),
                          const SizedBox(width: 4),
                          Text(
                            statusText,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: statusColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${med.dose.isNotEmpty ? med.dose : '1 Dose'} • ${med.frequency.isNotEmpty ? med.frequency : 'Daily'}',
                  style: TextStyle(fontSize: 12, color: textSecondary),
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Doses today: ${med.dosesToday}/${med.maxDosesToday}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: med.dosesToday >= med.maxDosesToday
                            ? textSecondary
                            : headerColor,
                      ),
                    ),
                    Text(
                      (med.dosesToday > 0 &&
                              med.administeredDate != null &&
                              med.administeredDate!.year == now.year &&
                              med.administeredDate!.month == now.month &&
                              med.administeredDate!.day == now.day)
                          ? 'Last: ${_formatTime(med.administeredDate!)}'
                          : 'Last: None today',
                      style: TextStyle(
                        fontSize: 11,
                        color: textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMinimalVaccineTile(
    Medication v,
    bool isDark,
    Color cardBg,
    Color textPrimary,
    Color textSecondary,
    Color headerColor,
  ) {
    final date = v.nextDoseDate;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueDate = DateTime(date.year, date.month, date.day);
    final isToday = today.isAtSameMomentAs(dueDate);
    final isOverdue = dueDate.isBefore(today);
    final daysOverdue = today.difference(dueDate).inDays;

    final String statusText;
    final Color statusColor;
    final Color statusBg;
    final IconData statusIcon;

    if (isToday) {
      statusText = 'Due Today';
      statusColor = isDark
          ? AppTheme.statusScheduledDark
          : AppTheme.statusScheduled;
      statusBg = isDark
          ? AppTheme.statusScheduledDarkBg
          : AppTheme.statusScheduledBg;
      statusIcon = Icons.today;
    } else if (isOverdue) {
      statusText = 'Overdue${daysOverdue > 0 ? ' ${daysOverdue}d' : ''}';
      statusColor = isDark
          ? AppTheme.statusOverdueDark
          : AppTheme.statusOverdue;
      statusBg = isDark
          ? AppTheme.statusOverdueDarkBg
          : AppTheme.statusOverdueBg;
      statusIcon = Icons.error_outline;
    } else {
      statusText = 'Scheduled';
      statusColor = isDark
          ? AppTheme.statusScheduledDark
          : AppTheme.statusScheduled;
      statusBg = isDark
          ? AppTheme.statusScheduledDarkBg
          : AppTheme.statusScheduledBg;
      statusIcon = Icons.event;
    }

    return AccentLeftCard(
      accentColor: statusColor,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => MedsVaccinesScreen(pet: _pet)),
        );
      },
      child: Row(
        children: [
          // Date Badge Box
          Container(
            width: 48,
            height: 50,
            decoration: BoxDecoration(
              color: statusBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _getMonthAbbr(date.month),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
                Text(
                  '${date.day}',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: statusColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Title & Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        v.name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: statusBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusIcon, size: 11, color: statusColor),
                          const SizedBox(width: 4),
                          Text(
                            statusText,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: statusColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  v.dose.isNotEmpty ? v.dose : 'Vaccine Booster',
                  style: TextStyle(fontSize: 12, color: textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedsTab() {
    final isDark = context.watch<ThemeCubit>().state;
    final textSecondary = isDark
        ? AppTheme.darkOnSurfaceVariant
        : AppTheme.secondary;
    final textPrimary = isDark ? AppTheme.darkOnSurface : AppTheme.onSurface;
    final cardBg = isDark
        ? AppTheme.darkSurface
        : AppTheme.surfaceContainerLowest;
    final headerColor = isDark ? AppTheme.primaryFixedDim : AppTheme.primary;

    // Upcoming Medications: type != 'vaccine', type != 'event' and not completed
    final upcomingMeds =
        _pet.medications
            .where(
              (m) => m.type != 'vaccine' && m.type != 'event' && !m.isCompleted,
            )
            .toList()
          ..sort((a, b) => a.nextDoseDate.compareTo(b.nextDoseDate));

    // Upcoming Vaccines: type == 'vaccine' and unsaved to history and not completed
    final upcomingVaccines =
        _pet.medications
            .where(
              (m) =>
                  m.type == 'vaccine' && !m.isSavedToHistory && !m.isCompleted,
            )
            .toList()
          ..sort((a, b) => a.nextDoseDate.compareTo(b.nextDoseDate));

    // Administered Vaccines ready to be saved to Vaccination History: type == 'vaccine' && isCompleted && !isSavedToHistory
    final readyToSaveVaccines = _pet.medications
        .where(
          (m) => m.type == 'vaccine' && m.isCompleted && !m.isSavedToHistory,
        )
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),

          // 1. Upcoming Medications Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.medication_outlined, color: headerColor, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Upcoming Medications',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      fontFamily: 'Montserrat',
                      color: textPrimary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF2E4E30)
                      : AppTheme.primaryContainer.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${upcomingMeds.length}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: headerColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (upcomingMeds.isEmpty)
            _buildEmptyMinimalCard(
              'No upcoming medications scheduled.',
              isDark,
              cardBg,
              textSecondary,
            )
          else
            ...upcomingMeds.map(
              (med) => _buildMinimalMedTile(
                med,
                isDark,
                cardBg,
                textPrimary,
                textSecondary,
                headerColor,
              ),
            ),

          const SizedBox(height: 24),

          // 2. Upcoming Vaccines Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.vaccines_outlined,
                    color: AppTheme.tertiary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Upcoming Vaccines',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      fontFamily: 'Montserrat',
                      color: textPrimary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.tertiaryContainer.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${upcomingVaccines.length}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.tertiary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (upcomingVaccines.isEmpty)
            _buildEmptyMinimalCard(
              'No upcoming vaccines scheduled.',
              isDark,
              cardBg,
              textSecondary,
            )
          else
            ...upcomingVaccines.map(
              (v) => _buildMinimalVaccineTile(
                v,
                isDark,
                cardBg,
                textPrimary,
                textSecondary,
                headerColor,
              ),
            ),

          const SizedBox(height: 24),

          // Action Button to Manage All Meds
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => MedsVaccinesScreen(pet: _pet),
                  ),
                );
              },
              icon: Icon(Icons.tune, size: 18, color: headerColor),
              label: Text(
                'Manage All Meds & Vaccines',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: headerColor,
                ),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: BorderSide(color: headerColor, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Vaccines Ready to be Saved Banner (Under Manage All Meds & Vaccines Button)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isDark
                  ? AppTheme.primaryContainer.withValues(alpha: 0.2)
                  : AppTheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark
                    ? AppTheme.primaryFixedDim.withValues(alpha: 0.3)
                    : AppTheme.primary.withValues(alpha: 0.25),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.verified_rounded, color: headerColor, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    readyToSaveVaccines.isNotEmpty
                        ? '${readyToSaveVaccines.length} ${readyToSaveVaccines.length == 1 ? 'administered vaccine is' : 'administered vaccines are'} ready to be saved to health history!'
                        : 'All administered vaccines are saved to health history.',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
