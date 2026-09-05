import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../widgets/photo_source_bottom_sheet.dart';
import '../../widgets/base_form_dialog.dart';
import '../../../data/models/pet.dart';
import '../../../data/models/pet_role.dart';
import '../../../logic/pet/pet_bloc.dart';
import '../../../logic/theme/theme_cubit.dart';
import '../../../core/utils/responsive_layout.dart';
import '../../../core/services/local_media_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/role_badge.dart';
import 'medical_history_screen.dart';
import 'share_ownership_screen.dart';
import 'invitation_received_screen.dart';

class PetDetailsScreen extends StatefulWidget {
  final Pet pet;

  const PetDetailsScreen({super.key, required this.pet});

  @override
  State<PetDetailsScreen> createState() => _PetDetailsScreenState();
}

class _PetDetailsScreenState extends State<PetDetailsScreen> {
  late Pet _pet;

  @override
  void initState() {
    super.initState();
    _pet = widget.pet;
  }

  PetRole get _currentUserRole {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || _pet.ownerId.isEmpty || _pet.ownerId == user.uid) {
        return PetRole.owner;
      }

      for (final m in _pet.members) {
        if (m.status == 'Accepted' &&
            (m.id == user.uid ||
                (user.email != null &&
                    m.email.isNotEmpty &&
                    m.email.toLowerCase() == user.email!.toLowerCase()))) {
          return m.role;
        }
      }
    } catch (_) {}
    return PetRole.owner;
  }

  void _updatePet(Pet updated) {
    setState(() {
      _pet = updated;
    });
    context.read<PetBloc>().add(UpdatePet(updated));
  }

  Widget _buildPetImageWidget(
    String url, {
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    double iconSize = 24,
  }) {
    return LocalMediaService.buildSmartImage(
      path: url,
      width: width,
      height: height,
      fit: fit,
      fallbackWidget: Container(
        width: width,
        height: height,
        color: AppTheme.surfaceContainer,
        child: Icon(Icons.pets, size: iconSize, color: AppTheme.secondary),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 1. Comprehensive Pet Profile Edit Dialog (Matches create_pet_step1)
  // ---------------------------------------------------------------------------
  void _showEditPetProfileDialog() {
    final nameCtrl = TextEditingController(text: _pet.name);
    final breedCtrl = TextEditingController(text: _pet.breed);
    String selectedAvatarUrl = _pet.avatarUrl;
    String selectedGender = _pet.gender;
    String selectedNeutered = _pet.neutered;
    DateTime selectedBirthDate = _pet.birthDate;
    String selectedStatus = ['HEALTHY', 'CONCERNING', 'EMERGENCY'].contains(_pet.status)
        ? _pet.status
        : 'HEALTHY';

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            Widget buildOptionChip(
              String value,
              IconData? icon,
              String currentValue,
              ValueChanged<String> onChanged,
            ) {
              final isSelected =
                  currentValue.toLowerCase() == value.toLowerCase();
              return OutlinedButton(
                onPressed: () => onChanged(value),
                style: OutlinedButton.styleFrom(
                  backgroundColor: isSelected
                      ? AppTheme.primary
                      : AppTheme.surfaceContainerLow,
                  foregroundColor: isSelected
                      ? Colors.white
                      : AppTheme.secondary,
                  side: BorderSide(
                    color: isSelected
                        ? AppTheme.primary
                        : AppTheme.surfaceContainer,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (icon != null) ...[
                      Icon(
                        icon,
                        color: isSelected ? Colors.white : AppTheme.secondary,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      value,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              );
            }

            return BaseFormDialog(
              icon: Icons.pets,
              title: 'Edit Companion Profile',
              subtitle: 'Update basic details & photo',
              primaryButtonText: 'Save',
              primaryButtonIcon: Icons.check,
              onPrimaryPressed: () {
                final newName = nameCtrl.text.trim();
                if (newName.isNotEmpty) {
                  final updated = _pet.copyWith(
                    name: newName,
                    avatarUrl: selectedAvatarUrl,
                    breed: breedCtrl.text.trim(),
                    gender: selectedGender,
                    neutered: selectedNeutered,
                    birthDate: selectedBirthDate,
                    status: selectedStatus,
                  );
                  _updatePet(updated);
                  Navigator.pop(dialogContext);
                }
              },
              children: [
                // Interactive Pet Profile Photo Button
                Center(
                  child: GestureDetector(
                    onTap: () async {
                      final source = await PhotoSourceBottomSheet.show(
                        dialogContext,
                        title: 'Change Pet Photo',
                      );
                      if (source == null) return;
                      if (!mounted) return;
                      final messenger = ScaffoldMessenger.of(context);
                      try {
                        final picker = ImagePicker();
                        final file = await picker.pickImage(source: source);
                        if (file != null) {
                          setDialogState(() {
                            selectedAvatarUrl = file.path;
                          });
                        }
                      } catch (e) {
                        messenger.showSnackBar(
                          SnackBar(content: Text('Error selecting image: $e')),
                        );
                      }
                    },
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        Container(
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppTheme.primaryFixed,
                              width: 3,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(48),
                            child: _buildPetImageWidget(
                              selectedAvatarUrl,
                              width: 96,
                              height: 96,
                              iconSize: 32,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppTheme.primary,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(
                            Icons.edit,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Pet Name
                const Text(
                  'Pet Name',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    hintText: 'e.g. Luna',
                    filled: true,
                    fillColor: AppTheme.surfaceContainerLow,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Breed
                const Text(
                  'Breed',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: breedCtrl,
                  decoration: InputDecoration(
                    hintText: 'Search or enter breed...',
                    filled: true,
                    fillColor: AppTheme.surfaceContainerLow,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Gender
                const Text(
                  'Gender',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: buildOptionChip(
                        'Male',
                        Icons.male,
                        selectedGender,
                        (v) => setDialogState(() => selectedGender = v),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: buildOptionChip(
                        'Female',
                        Icons.female,
                        selectedGender,
                        (v) => setDialogState(() => selectedGender = v),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Neutered / Spayed
                const Text(
                  'Neutered / Spayed',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: buildOptionChip(
                        'Yes',
                        null,
                        selectedNeutered,
                        (v) => setDialogState(() => selectedNeutered = v),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: buildOptionChip(
                        'No',
                        null,
                        selectedNeutered,
                        (v) => setDialogState(() => selectedNeutered = v),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Health Status
                const Text(
                  'Health Status',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: buildOptionChip(
                        'HEALTHY',
                        Icons.check_circle_outline,
                        selectedStatus,
                        (v) => setDialogState(() => selectedStatus = v),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: buildOptionChip(
                        'CONCERNING',
                        Icons.warning_amber_rounded,
                        selectedStatus,
                        (v) => setDialogState(() => selectedStatus = v),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: buildOptionChip(
                        'EMERGENCY',
                        Icons.error_outline,
                        selectedStatus,
                        (v) => setDialogState(() => selectedStatus = v),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Date of Birth
                const Text(
                  'Date of Birth',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: dialogContext,
                      initialDate: selectedBirthDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      setDialogState(() => selectedBirthDate = date);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${selectedBirthDate.day}/${selectedBirthDate.month}/${selectedBirthDate.year}',
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Icon(
                          Icons.calendar_today,
                          color: AppTheme.primary,
                          size: 18,
                        ),
                      ],
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

  // ---------------------------------------------------------------------------
  // 3. Edit Health Profile Dialog (Matches medical_history_step2)
  // ---------------------------------------------------------------------------
  void _showEditHealthProfileDialog() {
    List<String> selectedConditions = List<String>.from(_pet.medicalConditions);
    if (selectedConditions.isEmpty) {
      selectedConditions = ['none'];
    }
    List<String> selectedAllergies = List<String>.from(_pet.allergies);

    // Custom Condition State
    bool isCustomConditionVisible = false;
    final customConditionCtrl = TextEditingController();

    // Allergies Autocomplete State
    final allergySearchCtrl = TextEditingController();
    const List<String> allergyLibrary = [
      'Beef',
      'Pollen',
      'Grain-Free',
      'Chicken',
      'Dairy',
      'Flea Saliva',
      'Penicillin',
      'Soy',
      'Wheat',
      'Dust Mites',
    ];
    List<String> filteredAllergies = [];
    bool isAllergyDropdownVisible = false;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            void toggleCondition(String condition) {
              setDialogState(() {
                final lower = condition.toLowerCase();
                if (lower == 'none') {
                  selectedConditions = ['none'];
                } else {
                  selectedConditions.remove('none');
                  if (selectedConditions.contains(lower)) {
                    selectedConditions.remove(lower);
                  } else {
                    selectedConditions.add(lower);
                  }
                  if (selectedConditions.isEmpty) {
                    selectedConditions = ['none'];
                  }
                }
              });
            }

            Widget buildConditionButton(String label) {
              final lower = label.toLowerCase();
              final isSelected = selectedConditions.contains(lower);
              return OutlinedButton(
                onPressed: () => toggleCondition(label),
                style: OutlinedButton.styleFrom(
                  backgroundColor: isSelected
                      ? AppTheme.primary
                      : AppTheme.surfaceContainerLow,
                  foregroundColor: isSelected
                      ? Colors.white
                      : AppTheme.secondary,
                  side: BorderSide(
                    color: isSelected
                        ? AppTheme.primary
                        : AppTheme.surfaceContainer,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: Text(
                  label,
                  style: const TextStyle(
                    fontFamily: 'Montserrat',
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              );
            }

            Widget buildAddCustomButton() {
              return OutlinedButton.icon(
                onPressed: () =>
                    setDialogState(() => isCustomConditionVisible = true),
                icon: const Icon(Icons.add, size: 14),
                label: const Text(
                  'Add Custom',
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primary,
                  side: const BorderSide(color: AppTheme.primary),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              );
            }

            return BaseFormDialog(
              icon: Icons.healing_outlined,
              title: 'Edit Health Profile',
              subtitle: 'Update medical conditions & allergies',
              primaryButtonText: 'Save',
              primaryButtonIcon: Icons.check,
              onPrimaryPressed: () {
                final updated = _pet.copyWith(
                  medicalConditions: selectedConditions,
                  allergies: selectedAllergies,
                );
                _updatePet(updated);
                Navigator.pop(dialogContext);
              },
              children: [
                // Section 1: Medical Conditions
                const Row(
                  children: [
                    Icon(
                      Icons.healing_outlined,
                      color: AppTheme.primary,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Medical Conditions',
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // 2-Column Grid Layout
                Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: buildConditionButton('Diabetes')),
                        const SizedBox(width: 8),
                        Expanded(child: buildConditionButton('Arthritis')),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(child: buildConditionButton('Heart Murmur')),
                        const SizedBox(width: 8),
                        Expanded(child: buildConditionButton('Epilepsy')),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(child: buildConditionButton('None')),
                        const SizedBox(width: 8),
                        Expanded(child: buildAddCustomButton()),
                      ],
                    ),
                  ],
                ),

                // Custom Added Conditions Tags
                if (selectedConditions.any(
                  (c) =>
                      c != 'diabetes' &&
                      c != 'arthritis' &&
                      c != 'heart murmur' &&
                      c != 'epilepsy' &&
                      c != 'none',
                )) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: selectedConditions
                        .where(
                          (c) =>
                              c != 'diabetes' &&
                              c != 'arthritis' &&
                              c != 'heart murmur' &&
                              c != 'epilepsy' &&
                              c != 'none',
                        )
                        .map((condition) {
                          return Chip(
                            label: Text(condition),
                            deleteIcon: const Icon(Icons.close, size: 14),
                            onDeleted: () => toggleCondition(condition),
                            backgroundColor: AppTheme.primary.withValues(
                              alpha: 0.1,
                            ),
                            labelStyle: const TextStyle(
                              fontFamily: 'Montserrat',
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primary,
                              fontSize: 11,
                            ),
                          );
                        })
                        .toList(),
                  ),
                ],

                if (isCustomConditionVisible) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: customConditionCtrl,
                          autofocus: true,
                          decoration: const InputDecoration(
                            hintText: 'Enter condition...',
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      ElevatedButton(
                        onPressed: () {
                          final text = customConditionCtrl.text.trim();
                          if (text.isNotEmpty) {
                            toggleCondition(text);
                            customConditionCtrl.clear();
                            setDialogState(
                              () => isCustomConditionVisible = false,
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                        child: const Text('Add'),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () => setDialogState(
                          () => isCustomConditionVisible = false,
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 20),

                // Section 2: Allergies
                const Row(
                  children: [
                    Icon(Icons.eco_outlined, color: AppTheme.primary, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Allergies',
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                TextField(
                  controller: allergySearchCtrl,
                  decoration: const InputDecoration(
                    hintText: 'Search or type custom allergy...',
                    isDense: true,
                    prefixIcon: Icon(Icons.search, size: 18),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                  onSubmitted: (value) {
                    final query = value.trim();
                    if (query.isNotEmpty) {
                      setDialogState(() {
                        if (!selectedAllergies.contains(query)) {
                          selectedAllergies.add(query);
                        }
                        allergySearchCtrl.clear();
                        isAllergyDropdownVisible = false;
                        filteredAllergies = [];
                      });
                    }
                  },
                  onChanged: (query) {
                    if (query.isEmpty) {
                      setDialogState(() {
                        filteredAllergies = [];
                        isAllergyDropdownVisible = false;
                      });
                      return;
                    }
                    final filtered = allergyLibrary
                        .where(
                          (a) =>
                              a.toLowerCase().contains(query.toLowerCase()) &&
                              !selectedAllergies.contains(a),
                        )
                        .toList();
                    setDialogState(() {
                      filteredAllergies = filtered;
                      isAllergyDropdownVisible = true;
                    });
                  },
                ),

                if (isAllergyDropdownVisible &&
                    filteredAllergies.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Container(
                    constraints: const BoxConstraints(maxHeight: 150),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.surfaceContainer),
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        children: filteredAllergies.map((allergy) {
                          return ListTile(
                            dense: true,
                            title: Text(
                              allergy,
                              style: const TextStyle(fontSize: 13),
                            ),
                            onTap: () {
                              setDialogState(() {
                                if (!selectedAllergies.contains(allergy)) {
                                  selectedAllergies.add(allergy);
                                }
                                allergySearchCtrl.clear();
                                isAllergyDropdownVisible = false;
                                filteredAllergies = [];
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],

                if (selectedAllergies.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: selectedAllergies.map((allergy) {
                      return Chip(
                        label: Text(allergy),
                        deleteIcon: const Icon(Icons.close, size: 14),
                        onDeleted: () {
                          setDialogState(() {
                            selectedAllergies.remove(allergy);
                          });
                        },
                        backgroundColor: AppTheme.errorContainer,
                        labelStyle: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.error,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            );
          },
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // 4. Edit Lifestyle & Routine Dialog (Matches lifestyle_routine_step3)
  // ---------------------------------------------------------------------------
  void _showEditLifestyleDialog() {
    String selectedActivity = _pet.activityLevel.isNotEmpty
        ? _pet.activityLevel
        : 'Moderate';
    bool isDietEnabled = _pet.dietEnabled;
    String selectedFoodType = _pet.foodType.isNotEmpty
        ? _pet.foodType
        : 'Dry Kibble';
    final notesCtrl = TextEditingController(text: _pet.feedingNotes);
    List<String> selectedBehaviorTags = List<String>.from(_pet.behaviorTags);

    const foodTypeItems = [
      'Mixed',
      'Home-cooked',
      'Dry Kibble',
      'Wet Food',
      'Raw Diet',
      'Other',
    ];

    const presetBehaviorTags = [
      'Social',
      'Anxious',
      'Quiet',
      'Playful',
      'Vocal',
      'Independent',
    ];

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            Widget buildActivityCard(
              String value,
              IconData icon,
              String label,
            ) {
              final isSelected =
                  selectedActivity.toLowerCase() == value.toLowerCase();
              return GestureDetector(
                onTap: () => setDialogState(() => selectedActivity = value),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.primaryFixedDim.withValues(alpha: 0.2)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.primary
                          : AppTheme.surfaceContainer,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, color: AppTheme.primary, size: 26),
                      const SizedBox(height: 6),
                      Text(
                        label,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return BaseFormDialog(
              icon: Icons.directions_run,
              title: 'Edit Lifestyle & Routine',
              subtitle: 'Update activity level, diet & behavior tags',
              primaryButtonText: 'Save',
              primaryButtonIcon: Icons.check,
              onPrimaryPressed: () {
                final updated = _pet.copyWith(
                  activityLevel: selectedActivity,
                  dietEnabled: isDietEnabled,
                  foodType: selectedFoodType,
                  feedingNotes: notesCtrl.text.trim(),
                  behaviorTags: selectedBehaviorTags,
                );
                _updatePet(updated);
                Navigator.pop(dialogContext);
              },
              children: [
                // Section 1: Activity Level
                const Text(
                  'Activity Level',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: AppTheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 10),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1.3,
                  children: [
                    buildActivityCard('Low', Icons.bed_outlined, 'Low'),
                    buildActivityCard(
                      'Moderate',
                      Icons.directions_walk,
                      'Moderate',
                    ),
                    buildActivityCard(
                      'High',
                      Icons.run_circle_outlined,
                      'High',
                    ),
                    buildActivityCard('Very High', Icons.bolt, 'Very High'),
                  ],
                ),
                const SizedBox(height: 20),

                // Section 2: Diet & Nutrition Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.surfaceContainer),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Diet & Nutrition',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          Switch(
                            value: isDietEnabled,
                            activeThumbColor: AppTheme.primary,
                            onChanged: (val) {
                              setDialogState(() => isDietEnabled = val);
                            },
                          ),
                        ],
                      ),
                      if (isDietEnabled) ...[
                        const SizedBox(height: 14),
                        const Text(
                          'Main food type',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            color: AppTheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          initialValue: foodTypeItems.contains(selectedFoodType)
                              ? selectedFoodType
                              : 'Dry Kibble',
                          decoration: const InputDecoration(
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                          ),
                          items: foodTypeItems
                              .map(
                                (type) => DropdownMenuItem(
                                  value: type,
                                  child: Text(type),
                                ),
                              )
                              .toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setDialogState(() => selectedFoodType = val);
                            }
                          },
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'Feeding Schedule/Notes',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            color: AppTheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: notesCtrl,
                          maxLines: 3,
                          minLines: 2,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                          ),
                          decoration: InputDecoration(
                            hintText:
                                'e.g. 1/2 cup twice a day, morning and evening.',
                            hintStyle: TextStyle(
                              color: AppTheme.secondary.withValues(alpha: 0.5),
                              fontSize: 12,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
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
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: AppTheme.primary,
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Section 3: Behavior Tags
                const Text(
                  'Behavior Tags (Optional)',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: AppTheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: presetBehaviorTags.map((tag) {
                    final isSelected = selectedBehaviorTags.contains(tag);
                    return FilterChip(
                      label: Text(tag),
                      selected: isSelected,
                      onSelected: (val) {
                        setDialogState(() {
                          if (isSelected) {
                            selectedBehaviorTags.remove(tag);
                          } else {
                            selectedBehaviorTags.add(tag);
                          }
                        });
                      },
                      selectedColor: AppTheme.secondaryContainer,
                      checkmarkColor: AppTheme.secondary,
                      labelStyle: TextStyle(
                        fontFamily: 'Inter',
                        color: isSelected
                            ? AppTheme.onSurface
                            : AppTheme.secondary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    );
                  }).toList(),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildPendingInviteBanner() {
    String userEmail = '';
    String userId = '';
    try {
      final user = FirebaseAuth.instance.currentUser;
      userEmail = user?.email ?? '';
      userId = user?.uid ?? '';
    } catch (_) {}

    final pendingMatches = _pet.members.where(
      (m) =>
          m.status == 'Pending' &&
          (m.id == userId ||
              (userEmail.isNotEmpty &&
                  m.email.toLowerCase() == userEmail.toLowerCase())),
    );

    if (pendingMatches.isEmpty) return const SizedBox.shrink();
    final invitation = pendingMatches.first;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.tertiaryFixed.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.tertiary),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: AppTheme.tertiary,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.mail_outline,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pending Care Invitation!',
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: AppTheme.tertiary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'You were invited as ${invitation.role.displayName}.',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    color: AppTheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final result = await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => InvitationReceivedScreen(
                    pet: _pet,
                    invitation: invitation,
                  ),
                ),
              );
              if (result != null) {
                setState(() {});
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.tertiary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('View', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final petState = context.watch<PetBloc>().state;
    if (petState is PetLoaded) {
      final updatedPet = petState.pets.firstWhere(
        (p) => p.id == widget.pet.id || p.id == _pet.id,
        orElse: () => _pet,
      );
      _pet = updatedPet;
    }

    // Dynamic birthdate string
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
    final birthStr =
        "${months[_pet.birthDate.month - 1]} ${_pet.birthDate.day}, ${_pet.birthDate.year}";

    // Age value calculation
    final now = DateTime.now();
    int ageYears = now.year - _pet.birthDate.year;
    if (now.month < _pet.birthDate.month ||
        (now.month == _pet.birthDate.month && now.day < _pet.birthDate.day)) {
      ageYears--;
    }
    if (ageYears < 0) ageYears = 0;

    final isDark = context.watch<ThemeCubit>().state;
    final bgColor = isDark ? AppTheme.darkBackground : AppTheme.background;
    final cardBg = isDark ? AppTheme.darkSurface : Colors.white;
    final textPrimary = isDark ? AppTheme.darkOnSurface : AppTheme.onSurface;
    final textSecondary = isDark
        ? AppTheme.darkOnSurfaceVariant
        : AppTheme.onSurfaceVariant;
    final headerColor = isDark ? AppTheme.primaryFixedDim : AppTheme.primary;
    final borderColor = isDark
        ? AppTheme.darkBorder
        : AppTheme.surfaceContainerLow;

    final ageCardBg = isDark
        ? const Color(0xFF5C2B1D)
        : AppTheme.tertiaryFixed.withValues(alpha: 0.4);
    final ageCardText = isDark ? const Color(0xFFFFB4A3) : AppTheme.tertiary;
    final ageCardBorder = isDark
        ? const Color(0xFF7E2B18)
        : AppTheme.tertiaryFixed.withValues(alpha: 0.3);

    final isWide = ResponsiveLayout.isWide(context);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: headerColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            Text(
              "${_pet.name}'s Details",
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontWeight: FontWeight.bold,
                color: headerColor,
                fontSize: 18,
              ),
            ),
            const SizedBox(width: 8),
            RoleBadge(role: _currentUserRole, isCompact: true),
          ],
        ),
        actions: [
          if (_currentUserRole.canManageMembers)
            IconButton(
              icon: Icon(Icons.share_outlined, color: headerColor),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => ShareOwnershipScreen(pet: _pet),
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left Pane: Pending invite, Hero & Age card, Basic Information
                  Expanded(
                    flex: 5,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildPendingInviteBanner(),
                          // Hero Image Area (Asymmetric Layout)
                          SizedBox(
                            height: 180,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Asymmetrical Rotated Image Container
                                Expanded(
                                  flex: 5,
                                  child: Transform.rotate(
                                    angle: -0.02,
                                    child: Container(
                                      height: 180,
                                      decoration: BoxDecoration(
                                        color: AppTheme.surfaceContainer,
                                        borderRadius: BorderRadius.circular(24),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(
                                              alpha: isDark ? 0.25 : 0.08,
                                            ),
                                            blurRadius: 10,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                        border: Border.all(
                                          color: isDark
                                              ? AppTheme.darkBorder
                                              : Colors.white,
                                          width: 4,
                                        ),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(20),
                                        child: _buildPetImageWidget(
                                          _pet.avatarUrl,
                                          iconSize: 48,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // Side info card (Age)
                                Expanded(
                                  flex: 3,
                                  child: Column(
                                    children: [
                                      // Age Card
                                      Expanded(
                                        child: Container(
                                          width: double.infinity,
                                          decoration: BoxDecoration(
                                            color: ageCardBg,
                                            borderRadius: BorderRadius.circular(
                                              24,
                                            ),
                                            border: Border.all(
                                              color: ageCardBorder,
                                            ),
                                          ),
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                'Age',
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: ageCardText,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                '$ageYears',
                                                style: TextStyle(
                                                  fontSize: 28,
                                                  fontFamily: 'Montserrat',
                                                  fontWeight: FontWeight.bold,
                                                  color: ageCardText,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                ageYears == 1
                                                    ? 'Year'
                                                    : 'Years',
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: ageCardText,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 28),

                          // Section 1: Basic Info
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Basic Information',
                                style: TextStyle(
                                  fontFamily: 'Montserrat',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: headerColor,
                                ),
                              ),
                              if (_currentUserRole.canEditProfile)
                                TextButton.icon(
                                  onPressed: _showEditPetProfileDialog,
                                  icon: Icon(
                                    Icons.edit_outlined,
                                    size: 18,
                                    color: headerColor,
                                  ),
                                  label: Text(
                                    'Edit',
                                    style: TextStyle(
                                      color: headerColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Bento Grid of Basic info
                          GridView.count(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisCount: 2,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 1.5,
                            children: [
                              _buildBentoItem(
                                title: 'Birthday',
                                value: birthStr,
                                icon: Icons.cake,
                                cardBg: cardBg,
                                textPrimary: textPrimary,
                                textSecondary: textSecondary,
                                headerColor: headerColor,
                                borderColor: borderColor,
                              ),
                              _buildBentoItem(
                                title: 'Breed',
                                value: _pet.breed.isNotEmpty
                                    ? _pet.breed
                                    : 'Unknown',
                                icon: Icons.pets,
                                cardBg: cardBg,
                                textPrimary: textPrimary,
                                textSecondary: textSecondary,
                                headerColor: headerColor,
                                borderColor: borderColor,
                              ),
                              _buildBentoItem(
                                title: 'Gender',
                                value: _pet.gender,
                                icon: _pet.gender.toLowerCase() == 'female'
                                    ? Icons.female
                                    : Icons.male,
                                cardBg: cardBg,
                                textPrimary: textPrimary,
                                textSecondary: textSecondary,
                                headerColor: headerColor,
                                borderColor: borderColor,
                              ),
                              _buildBentoItem(
                                title: 'Neutered',
                                value: _pet.neutered,
                                icon: Icons.verified,
                                cardBg: cardBg,
                                textPrimary: textPrimary,
                                textSecondary: textSecondary,
                                headerColor: headerColor,
                                borderColor: borderColor,
                              ),
                            ],
                          ),
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
                  // Right Pane: Health Profile and Lifestyle & Routine
                  Expanded(
                    flex: 6,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Section 2: Health Profile
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Health Profile',
                                style: TextStyle(
                                  fontFamily: 'Montserrat',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: headerColor,
                                ),
                              ),
                              if (_currentUserRole.canLogMedical)
                                TextButton.icon(
                                  onPressed: _showEditHealthProfileDialog,
                                  icon: Icon(
                                    Icons.edit_outlined,
                                    size: 18,
                                    color: headerColor,
                                  ),
                                  label: Text(
                                    'Edit',
                                    style: TextStyle(
                                      color: headerColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: cardBg,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: borderColor),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(
                                    alpha: isDark ? 0.2 : 0.01,
                                  ),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Medical Conditions',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                _pet.medicalConditions.isEmpty ||
                                        (_pet.medicalConditions.length == 1 &&
                                            _pet.medicalConditions.first
                                                    .toLowerCase() ==
                                                'none')
                                    ? Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isDark
                                              ? AppTheme.darkBorder
                                              : AppTheme.surfaceContainer,
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                        child: Text(
                                          'None',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: textPrimary,
                                          ),
                                        ),
                                      )
                                    : Wrap(
                                        spacing: 6,
                                        runSpacing: 6,
                                        children: _pet.medicalConditions
                                            .where(
                                              (c) => c.toLowerCase() != 'none',
                                            )
                                            .map(
                                              (c) => Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 6,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: AppTheme.primary
                                                      .withValues(
                                                        alpha: isDark
                                                            ? 0.25
                                                            : 0.1,
                                                      ),
                                                  borderRadius:
                                                      BorderRadius.circular(20),
                                                ),
                                                child: Text(
                                                  c[0].toUpperCase() +
                                                      c.substring(1),
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                    color: headerColor,
                                                  ),
                                                ),
                                              ),
                                            )
                                            .toList(),
                                      ),
                                const SizedBox(height: 16),
                                Text(
                                  'Allergies',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                _pet.allergies.isEmpty
                                    ? Text(
                                        'None',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: textPrimary,
                                        ),
                                      )
                                    : Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: _pet.allergies
                                            .map(
                                              (a) =>
                                                  _buildAllergyChip(a, isDark),
                                            )
                                            .toList(),
                                      ),
                                const SizedBox(height: 16),
                                // Vaccination button
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            MedicalHistoryScreen(pet: _pet),
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isDark
                                        ? AppTheme.primaryContainer
                                        : AppTheme.primaryFixed,
                                    foregroundColor: isDark
                                        ? AppTheme.onPrimaryContainer
                                        : AppTheme.onPrimaryFixedVariant,
                                    elevation: 0,
                                    minimumSize: const Size.fromHeight(50),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(Icons.vaccines),
                                          SizedBox(width: 8),
                                          Text(
                                            'Vaccination History',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Icon(Icons.chevron_right),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 28),

                          // Section 3: Lifestyle & Routine
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Lifestyle & Routine',
                                style: TextStyle(
                                  fontFamily: 'Montserrat',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: headerColor,
                                ),
                              ),
                              if (_currentUserRole.canEditProfile)
                                TextButton.icon(
                                  onPressed: _showEditLifestyleDialog,
                                  icon: Icon(
                                    Icons.edit_outlined,
                                    size: 18,
                                    color: headerColor,
                                  ),
                                  label: Text(
                                    'Edit',
                                    style: TextStyle(
                                      color: headerColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: cardBg,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: borderColor),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(
                                    alpha: isDark ? 0.2 : 0.01,
                                  ),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                _buildRoutineItem(
                                  title: 'Activity Level',
                                  value: _pet.activityLevel.isNotEmpty
                                      ? _pet.activityLevel
                                      : 'Moderate',
                                  icon: Icons.directions_run,
                                  textSecondary: textSecondary,
                                  headerColor: headerColor,
                                ),
                                Divider(
                                  height: 24,
                                  color: isDark
                                      ? AppTheme.darkBorder
                                      : AppTheme.surfaceContainer,
                                ),
                                _buildRoutineItem(
                                  title: 'Diet',
                                  value: _pet.dietEnabled
                                      ? "${_pet.foodType.isNotEmpty ? _pet.foodType : 'Mixed'}${_pet.feedingNotes.isNotEmpty ? ' - ${_pet.feedingNotes}' : ''}"
                                      : 'Not Specified',
                                  icon: Icons.restaurant,
                                  textSecondary: textSecondary,
                                  headerColor: headerColor,
                                ),
                                Divider(
                                  height: 24,
                                  color: isDark
                                      ? AppTheme.darkBorder
                                      : AppTheme.surfaceContainer,
                                ),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Behavior Tags',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: textSecondary,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          _pet.behaviorTags.isEmpty
                                              ? Text(
                                                  'None',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                    color: textPrimary,
                                                  ),
                                                )
                                              : Wrap(
                                                  spacing: 8,
                                                  runSpacing: 8,
                                                  children: _pet.behaviorTags
                                                      .map(
                                                        (t) =>
                                                            _buildBehaviorChip(
                                                              t,
                                                              isDark,
                                                            ),
                                                      )
                                                      .toList(),
                                                ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              )
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPendingInviteBanner(),
                    // Hero Image Area (Asymmetric Layout)
                    SizedBox(
                      height: 180,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Asymmetrical Rotated Image Container
                          Expanded(
                            flex: 5,
                            child: Transform.rotate(
                              angle: -0.02,
                              child: Container(
                                height: 180,
                                decoration: BoxDecoration(
                                  color: AppTheme.surfaceContainer,
                                  borderRadius: BorderRadius.circular(24),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: isDark ? 0.25 : 0.08,
                                      ),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                  border: Border.all(
                                    color: isDark
                                        ? AppTheme.darkBorder
                                        : Colors.white,
                                    width: 4,
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  child: _buildPetImageWidget(
                                    _pet.avatarUrl,
                                    iconSize: 48,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Side info card (Age)
                          Expanded(
                            flex: 3,
                            child: Column(
                              children: [
                                // Age Card
                                Expanded(
                                  child: Container(
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      color: ageCardBg,
                                      borderRadius: BorderRadius.circular(24),
                                      border: Border.all(color: ageCardBorder),
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          'Age',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: ageCardText,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '$ageYears',
                                          style: TextStyle(
                                            fontSize: 28,
                                            fontFamily: 'Montserrat',
                                            fontWeight: FontWeight.bold,
                                            color: ageCardText,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          ageYears == 1 ? 'Year' : 'Years',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: ageCardText,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Section 1: Basic Info
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Basic Information',
                          style: TextStyle(
                            fontFamily: 'Montserrat',
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: headerColor,
                          ),
                        ),
                        if (_currentUserRole.canEditProfile)
                          TextButton.icon(
                            onPressed: _showEditPetProfileDialog,
                            icon: Icon(
                              Icons.edit_outlined,
                              size: 18,
                              color: headerColor,
                            ),
                            label: Text(
                              'Edit',
                              style: TextStyle(
                                color: headerColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Bento Grid of Basic info
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.5,
                      children: [
                        _buildBentoItem(
                          title: 'Birthday',
                          value: birthStr,
                          icon: Icons.cake,
                          cardBg: cardBg,
                          textPrimary: textPrimary,
                          textSecondary: textSecondary,
                          headerColor: headerColor,
                          borderColor: borderColor,
                        ),
                        _buildBentoItem(
                          title: 'Breed',
                          value: _pet.breed.isNotEmpty ? _pet.breed : 'Unknown',
                          icon: Icons.pets,
                          cardBg: cardBg,
                          textPrimary: textPrimary,
                          textSecondary: textSecondary,
                          headerColor: headerColor,
                          borderColor: borderColor,
                        ),
                        _buildBentoItem(
                          title: 'Gender',
                          value: _pet.gender,
                          icon: _pet.gender.toLowerCase() == 'female'
                              ? Icons.female
                              : Icons.male,
                          cardBg: cardBg,
                          textPrimary: textPrimary,
                          textSecondary: textSecondary,
                          headerColor: headerColor,
                          borderColor: borderColor,
                        ),
                        _buildBentoItem(
                          title: 'Neutered',
                          value: _pet.neutered,
                          icon: Icons.verified,
                          cardBg: cardBg,
                          textPrimary: textPrimary,
                          textSecondary: textSecondary,
                          headerColor: headerColor,
                          borderColor: borderColor,
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),

                    // Section 2: Health Profile
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Health Profile',
                          style: TextStyle(
                            fontFamily: 'Montserrat',
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: headerColor,
                          ),
                        ),
                        if (_currentUserRole.canLogMedical)
                          TextButton.icon(
                            onPressed: _showEditHealthProfileDialog,
                            icon: Icon(
                              Icons.edit_outlined,
                              size: 18,
                              color: headerColor,
                            ),
                            label: Text(
                              'Edit',
                              style: TextStyle(
                                color: headerColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: borderColor),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(
                              alpha: isDark ? 0.2 : 0.01,
                            ),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Medical Conditions',
                            style: TextStyle(
                              fontSize: 12,
                              color: textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 6),
                          _pet.medicalConditions.isEmpty ||
                                  (_pet.medicalConditions.length == 1 &&
                                      _pet.medicalConditions.first
                                              .toLowerCase() ==
                                          'none')
                              ? Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? AppTheme.darkBorder
                                        : AppTheme.surfaceContainer,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    'None',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: textPrimary,
                                    ),
                                  ),
                                )
                              : Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: _pet.medicalConditions
                                      .where((c) => c.toLowerCase() != 'none')
                                      .map(
                                        (c) => Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppTheme.primary.withValues(
                                              alpha: isDark ? 0.25 : 0.1,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                          ),
                                          child: Text(
                                            c[0].toUpperCase() + c.substring(1),
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: headerColor,
                                            ),
                                          ),
                                        ),
                                      )
                                      .toList(),
                                ),
                          const SizedBox(height: 16),
                          Text(
                            'Allergies',
                            style: TextStyle(
                              fontSize: 12,
                              color: textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 6),
                          _pet.allergies.isEmpty
                              ? Text(
                                  'None',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: textPrimary,
                                  ),
                                )
                              : Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: _pet.allergies
                                      .map((a) => _buildAllergyChip(a, isDark))
                                      .toList(),
                                ),
                          const SizedBox(height: 16),
                          // Vaccination button
                          ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) =>
                                      MedicalHistoryScreen(pet: _pet),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isDark
                                  ? AppTheme.primaryContainer
                                  : AppTheme.primaryFixed,
                              foregroundColor: isDark
                                  ? AppTheme.onPrimaryContainer
                                  : AppTheme.onPrimaryFixedVariant,
                              elevation: 0,
                              minimumSize: const Size.fromHeight(50),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.vaccines),
                                    SizedBox(width: 8),
                                    Text(
                                      'Vaccination History',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                Icon(Icons.chevron_right),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Section 3: Lifestyle & Routine
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Lifestyle & Routine',
                          style: TextStyle(
                            fontFamily: 'Montserrat',
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: headerColor,
                          ),
                        ),
                        if (_currentUserRole.canEditProfile)
                          TextButton.icon(
                            onPressed: _showEditLifestyleDialog,
                            icon: Icon(
                              Icons.edit_outlined,
                              size: 18,
                              color: headerColor,
                            ),
                            label: Text(
                              'Edit',
                              style: TextStyle(
                                color: headerColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: borderColor),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(
                              alpha: isDark ? 0.2 : 0.01,
                            ),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          _buildRoutineItem(
                            title: 'Activity Level',
                            value: _pet.activityLevel.isNotEmpty
                                ? _pet.activityLevel
                                : 'Moderate',
                            icon: Icons.directions_run,
                            textSecondary: textSecondary,
                            headerColor: headerColor,
                          ),
                          Divider(
                            height: 24,
                            color: isDark
                                ? AppTheme.darkBorder
                                : AppTheme.surfaceContainer,
                          ),
                          _buildRoutineItem(
                            title: 'Diet',
                            value: _pet.dietEnabled
                                ? "${_pet.foodType.isNotEmpty ? _pet.foodType : 'Mixed'}${_pet.feedingNotes.isNotEmpty ? ' - ${_pet.feedingNotes}' : ''}"
                                : 'Not Specified',
                            icon: Icons.restaurant,
                            textSecondary: textSecondary,
                            headerColor: headerColor,
                          ),
                          Divider(
                            height: 24,
                            color: isDark
                                ? AppTheme.darkBorder
                                : AppTheme.surfaceContainer,
                          ),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Behavior Tags',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: textSecondary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    _pet.behaviorTags.isEmpty
                                        ? Text(
                                            'None',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: textPrimary,
                                            ),
                                          )
                                        : Wrap(
                                            spacing: 8,
                                            runSpacing: 8,
                                            children: _pet.behaviorTags
                                                .map(
                                                  (t) => _buildBehaviorChip(
                                                    t,
                                                    isDark,
                                                  ),
                                                )
                                                .toList(),
                                          ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildBentoItem({
    required String title,
    required String value,
    required IconData icon,
    required Color cardBg,
    required Color textPrimary,
    required Color textSecondary,
    required Color headerColor,
    required Color borderColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.01),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: headerColor),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllergyChip(String text, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF5C2B1D) : AppTheme.errorContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.warning_amber_rounded,
            size: 14,
            color: isDark ? const Color(0xFFFFB4A3) : AppTheme.error,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isDark ? const Color(0xFFFFB4A3) : AppTheme.error,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBehaviorChip(String text, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isDark
            ? AppTheme.darkBorder
            : AppTheme.primaryFixedDim.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: isDark
              ? AppTheme.darkOnSurface
              : AppTheme.onPrimaryFixedVariant,
        ),
      ),
    );
  }

  Widget _buildRoutineItem({
    required String title,
    required String value,
    required IconData icon,
    required Color textSecondary,
    required Color headerColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: headerColor,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Icon(icon, color: headerColor),
      ],
    );
  }
}
