import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import '../../../logic/pet/pet_bloc.dart';
import '../../../data/models/pet.dart';
import '../../../data/models/weight_log.dart';
import '../../../data/models/medication.dart';
import '../../theme/app_theme.dart';
import 'create_pet_step1.dart';
import 'medical_history_step2.dart';
import 'lifestyle_routine_step3.dart';
import 'create_pet_finish_screen.dart';

class AddPetWizard extends StatefulWidget {
  const AddPetWizard({super.key});

  @override
  State<AddPetWizard> createState() => _AddPetWizardState();
}

class _AddPetWizardState extends State<AddPetWizard> {
  int _currentStep = 0; // 0: Basic Info, 1: Health, 2: Routine

  // Step 1 State
  final _nameController = TextEditingController();
  final _breedController = TextEditingController();
  String? _selectedSpecies;
  String? _selectedGender;
  String? _selectedNeutered;
  DateTime? _birthDate;
  String _selectedAvatar = 'assets/avatars/dog.png';

  // Step 2 State
  final List<Map<String, dynamic>> _vaccinations = [
    {'name': 'Rabies', 'subtitle': 'Last administration date', 'date': null},
    {'name': 'Distemper', 'subtitle': 'DHPP combination vaccine', 'date': null},
    {
      'name': 'Parvovirus',
      'subtitle': 'Highly contagious protection',
      'date': null,
    },
  ];
  final List<String> _selectedConditions = ['none'];
  final List<String> _selectedAllergies = [];

  // Step 3 State
  String _selectedActivityLevel = 'Moderate';
  bool _isDietEnabled = true;
  String _selectedFoodType = 'Mixed';
  final _feedingNotesController = TextEditingController();
  final _weightController = TextEditingController(text: '0.0');
  String _selectedWeightUnit = 'kg';
  final List<String> _selectedBehaviorTags = [];

  final _scrollController = ScrollController();

  void _scrollToTop() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _nameController.dispose();
    _breedController.dispose();
    _feedingNotesController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  void _showDiscardModal() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              const Icon(
                Icons.warning_amber_rounded,
                color: AppTheme.tertiary,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                'Discard progress?',
                style: Theme.of(
                  dialogContext,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'If you leave now, the information you\'ve entered for your pet will be lost.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.secondary),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                child: const Text('Keep Editing'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop(); // Dismiss modal
                  Navigator.of(context).pop(); // Go back from wizard
                },
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.tertiary,
                  minimumSize: const Size.fromHeight(48),
                ),
                child: const Text('Discard'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showPhotoModal() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Add Pet Photo',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: const Icon(
                    Icons.photo_library,
                    color: AppTheme.primary,
                  ),
                  title: const Text('Choose from Gallery'),
                  onTap: () async {
                    final navigator = Navigator.of(context);
                    final scaffoldMessenger = ScaffoldMessenger.of(context);
                    navigator.pop();
                    try {
                      final picker = ImagePicker();
                      final file = await picker.pickImage(
                        source: ImageSource.gallery,
                      );
                      if (file != null) {
                        setState(() {
                          _selectedAvatar = file.path;
                        });
                      }
                    } catch (e) {
                      scaffoldMessenger.showSnackBar(
                        SnackBar(content: Text('Error selecting image: $e')),
                      );
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.photo_camera,
                    color: AppTheme.primary,
                  ),
                  title: const Text('Open Camera'),
                  onTap: () async {
                    final navigator = Navigator.of(context);
                    final scaffoldMessenger = ScaffoldMessenger.of(context);
                    navigator.pop();
                    try {
                      final picker = ImagePicker();
                      final file = await picker.pickImage(
                        source: ImageSource.camera,
                      );
                      if (file != null) {
                        setState(() {
                          _selectedAvatar = file.path;
                        });
                      }
                    } catch (e) {
                      scaffoldMessenger.showSnackBar(
                        SnackBar(content: Text('Error capturing photo: $e')),
                      );
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.account_circle,
                    color: AppTheme.primary,
                  ),
                  title: const Text('Choose Avatar'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _showAvatarSelector();
                  },
                ),
                const Divider(),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
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

  void _showAvatarSelector() {
    showDialog(
      context: context,
      builder: (context) {
        final avatars = [
          'assets/avatars/dog.png',
          'assets/avatars/cat.png',
          'assets/avatars/lil_dog.png',
        ];
        return AlertDialog(
          title: const Text('Choose Avatar'),
          content: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: avatars.map((url) {
              final ImageProvider imageProvider = url.startsWith('assets/')
                  ? AssetImage(url)
                  : (url.startsWith('http')
                          ? NetworkImage(url)
                          : FileImage(File(url)))
                      as ImageProvider;

              return GestureDetector(
                onTap: () {
                  setState(() => _selectedAvatar = url);
                  Navigator.of(context).pop();
                },
                child: CircleAvatar(
                  radius: 32,
                  backgroundImage: imageProvider,
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Future<void> _submitWizard() async {
    final petId = DateTime.now().millisecondsSinceEpoch.toString();

    // Parse and validate weight
    final weightText = _weightController.text.trim();
    final weightVal = double.tryParse(weightText);
    final maxAllowedWeight = _selectedWeightUnit == 'kg' ? 150.0 : 330.0;
    if (weightVal == null || weightVal < 0.0 || weightVal > maxAllowedWeight) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please enter a valid weight between 0.0 and ${maxAllowedWeight.toStringAsFixed(1)} $_selectedWeightUnit.',
          ),
        ),
      );
      return;
    }

    final weightInKg = _selectedWeightUnit == 'lbs'
        ? weightVal / 2.20462
        : weightVal;

    // Calculate age string
    final birth =
        _birthDate ?? DateTime.now().subtract(const Duration(days: 365));
    final difference = DateTime.now().difference(birth).inDays;
    final years = (difference / 365).floor();
    final months = ((difference % 365) / 30).floor();
    String ageStr = '';
    if (years > 0) {
      ageStr = '${years}y ';
    }
    ageStr += '${months}m';

    // Compile medications from vaccinations list
    final List<Medication> meds = [];
    for (var vac in _vaccinations) {
      final date = vac['date'] as DateTime?;
      if (date != null) {
        meds.add(
          Medication(
            id: '${vac['name'].toString().toLowerCase()}_$petId',
            name: vac['name'],
            nextDoseDate: date.add(const Duration(days: 365)),
            administeredDate: date,
            isCompleted: true,
            type: 'vaccine',
          ),
        );
      }
    }

    final currentUser = FirebaseAuth.instance.currentUser;
    final currentOwnerId =
        currentUser?.uid ?? currentUser?.email ?? 'current_owner';

    final newPet = Pet(
      id: petId,
      ownerId: currentOwnerId,
      name: _nameController.text.isNotEmpty
          ? _nameController.text
          : 'New Companion',
      breed: _breedController.text.isNotEmpty
          ? _breedController.text
          : 'Mixed Breed',
      ageString: ageStr,
      birthDate: birth,
      avatarUrl: _selectedAvatar,
      status: years == 0 ? 'Puppy' : 'Healthy',
      weight: weightInKg,
      weightHistory: weightVal == 0.0
          ? const []
          : [
              WeightLog(
                id: 'w_$petId',
                weight: weightVal,
                unit: _selectedWeightUnit,
                date: DateTime.now(),
                note: 'Initial Weight',
              ),
            ],
      medications: meds,
      photos: const [],
      species: _selectedSpecies ?? 'Dog',
      gender: _selectedGender ?? 'Female',
      neutered: _selectedNeutered ?? 'Yes',
      allergies: _selectedAllergies,
      activityLevel: _selectedActivityLevel,
      dietEnabled: _isDietEnabled,
      foodType: _selectedFoodType,
      feedingNotes: _feedingNotesController.text.trim(),
      behaviorTags: _selectedBehaviorTags,
    );

    if (!mounted) return;
    context.read<PetBloc>().add(AddPet(newPet));
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => CreatePetFinishScreen(pet: newPet),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Paws & Care',
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.bold,
            color: AppTheme.primary,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.primary),
          onPressed: _showDiscardModal,
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Custom progress indicators matching Stitch Layout
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Step ${_currentStep + 1} of 3',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primary,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        _currentStep == 0
                            ? 'Basic Info'
                            : _currentStep == 1
                            ? 'Health History'
                            : 'Lifestyle & Diet',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          color: AppTheme.secondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (_currentStep + 1) / 3,
                      backgroundColor: AppTheme.surfaceContainer,
                      color: AppTheme.primary,
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(),

            // Wizard Step Contents
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppTheme.surfaceContainer.withValues(
                            alpha: 0.3,
                          ),
                        ),
                      ),
                      padding: const EdgeInsets.all(20),
                      child: _buildStepContent(),
                    ),
                    const SizedBox(height: 24),
                    // Stepper Navigation Actions
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (_currentStep > 0)
                          OutlinedButton(
                            onPressed: () {
                              setState(() => _currentStep--);
                              _scrollToTop();
                            },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Back'),
                          )
                        else
                          const SizedBox.shrink(),

                        ElevatedButton(
                          onPressed: () {
                            if (_currentStep < 2) {
                              if (_currentStep == 0) {
                                if (_nameController.text.trim().isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        "Please enter the pet's name.",
                                      ),
                                    ),
                                  );
                                  return;
                                }
                                if (_selectedSpecies == null ||
                                    _selectedSpecies!.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        "Please select the pet's species.",
                                      ),
                                    ),
                                  );
                                  return;
                                }
                                if (_selectedGender == null ||
                                    _selectedGender!.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        "Please select the pet's gender.",
                                      ),
                                    ),
                                  );
                                  return;
                                }
                                if (_selectedNeutered == null ||
                                    _selectedNeutered!.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        "Please select whether the pet is neutered or spayed.",
                                      ),
                                    ),
                                  );
                                  return;
                                }
                                if (_birthDate == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        "Please select the pet's date of birth.",
                                      ),
                                    ),
                                  );
                                  return;
                                }
                              }
                              setState(() => _currentStep++);
                              _scrollToTop();
                            } else {
                              _submitWizard();
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Row(
                            children: [
                              Text(
                                _currentStep == 2
                                    ? 'Complete Profile'
                                    : 'Continue',
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.arrow_forward, size: 16),
                            ],
                          ),
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

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return CreatePetStep1(
          nameController: _nameController,
          breedController: _breedController,
          selectedSpecies: _selectedSpecies,
          onSpeciesChanged: (species) =>
              setState(() => _selectedSpecies = species),
          selectedGender: _selectedGender,
          onGenderChanged: (gender) => setState(() => _selectedGender = gender),
          selectedNeutered: _selectedNeutered,
          onNeuteredChanged: (neutered) =>
              setState(() => _selectedNeutered = neutered),
          birthDate: _birthDate,
          onBirthDateChanged: (date) => setState(() => _birthDate = date),
          selectedAvatar: _selectedAvatar,
          onPhotoSelectorPressed: _showPhotoModal,
        );
      case 1:
        return MedicalHistoryStep2(
          vaccinations: _vaccinations,
          onVaccineDateChanged: (index, date) {
            setState(() {
              _vaccinations[index]['date'] = date;
            });
          },
          onVaccineRemoved: (index) {
            setState(() {
              _vaccinations.removeAt(index);
            });
          },
          onAddCustomVaccine: (name) {
            setState(() {
              _vaccinations.add({
                'name': name,
                'subtitle': 'Custom vaccine record',
                'date': null,
              });
            });
          },
          selectedConditions: _selectedConditions,
          onConditionToggled: (condition) {
            setState(() {
              if (condition == 'none') {
                _selectedConditions.clear();
                _selectedConditions.add('none');
              } else {
                _selectedConditions.remove('none');
                if (_selectedConditions.contains(condition)) {
                  _selectedConditions.remove(condition);
                } else {
                  _selectedConditions.add(condition);
                }
                if (_selectedConditions.isEmpty) {
                  _selectedConditions.add('none');
                }
              }
            });
          },
          onAddCustomCondition: (condition) {
            setState(() {
              _selectedConditions.remove('none');
              final lower = condition.toLowerCase();
              if (!_selectedConditions.contains(lower)) {
                _selectedConditions.add(lower);
              }
            });
          },
          selectedAllergies: _selectedAllergies,
          onAllergyAdded: (allergy) {
            setState(() {
              if (!_selectedAllergies.contains(allergy)) {
                _selectedAllergies.add(allergy);
              }
            });
          },
          onAllergyRemoved: (allergy) {
            setState(() {
              _selectedAllergies.remove(allergy);
            });
          },
        );
      case 2:
        return LifestyleRoutineStep3(
          selectedActivityLevel: _selectedActivityLevel,
          onActivityLevelChanged: (level) =>
              setState(() => _selectedActivityLevel = level),
          isDietEnabled: _isDietEnabled,
          onDietEnabledChanged: (val) => setState(() => _isDietEnabled = val),
          selectedFoodType: _selectedFoodType,
          onFoodTypeChanged: (type) => setState(() => _selectedFoodType = type),
          feedingNotesController: _feedingNotesController,
          selectedBehaviorTags: _selectedBehaviorTags,
          onBehaviorTagToggled: (tag) {
            setState(() {
              if (_selectedBehaviorTags.contains(tag)) {
                _selectedBehaviorTags.remove(tag);
              } else {
                _selectedBehaviorTags.add(tag);
              }
            });
          },
          weightController: _weightController,
          selectedWeightUnit: _selectedWeightUnit,
          onWeightUnitChanged: (unit) =>
              setState(() => _selectedWeightUnit = unit),
        );
      default:
        return const SizedBox.shrink();
    }
  }
}
