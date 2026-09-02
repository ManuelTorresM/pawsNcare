import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../logic/pet/pet_bloc.dart';
import '../../../logic/notifications/global_notification_service.dart';
import '../../../data/models/app_notification.dart';
import '../../theme/app_theme.dart';
import '../../../core/utils/responsive_layout.dart';
import '../../widgets/nutrition/nutrition_reminder_card.dart';
import '../../widgets/base_form_dialog.dart';

class ReminderItem {
  final String id;
  final String title;
  final String subtitle;
  final List<String> targetPets;
  final String type; // 'feeding' or 'hydration'
  final String notes;
  final TimeOfDay time;

  ReminderItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.targetPets,
    required this.type,
    this.notes = '',
    this.time = const TimeOfDay(hour: 8, minute: 0),
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'targetPets': targetPets,
      'type': type,
      'notes': notes,
      'hour': time.hour,
      'minute': time.minute,
    };
  }

  factory ReminderItem.fromMap(Map<String, dynamic> map) {
    return ReminderItem(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      subtitle: map['subtitle'] ?? '',
      targetPets: List<String>.from(map['targetPets'] ?? ['All Pets']),
      type: map['type'] ?? 'feeding',
      notes: map['notes'] ?? '',
      time: TimeOfDay(hour: map['hour'] ?? 8, minute: map['minute'] ?? 0),
    );
  }
}

class NutritionScreen extends StatefulWidget {
  const NutritionScreen({super.key});

  @override
  State<NutritionScreen> createState() => _NutritionScreenState();
}

class _NutritionScreenState extends State<NutritionScreen> {
  // Master Toggles
  bool _masterFeedingEnabled = true;
  bool _masterHydrationEnabled = true;

  // Reminders List
  List<ReminderItem> _reminders = [
    ReminderItem(
      id: 'f1',
      title: 'Breakfast',
      subtitle: '07:30 AM • 1.5 cups',
      targetPets: ['All Pets'],
      type: 'feeding',
      notes: 'Add note',
      time: const TimeOfDay(hour: 7, minute: 30),
    ),
    ReminderItem(
      id: 'f2',
      title: 'Lunch',
      subtitle: '12:30 PM • 1.0 cup',
      targetPets: ['All Pets'],
      type: 'feeding',
      notes: 'Add note',
      time: const TimeOfDay(hour: 12, minute: 30),
    ),
    ReminderItem(
      id: 'f3',
      title: 'Dinner',
      subtitle: '06:00 PM • 1.5 cups',
      targetPets: ['All Pets'],
      type: 'feeding',
      notes: 'Add note',
      time: const TimeOfDay(hour: 18, minute: 0),
    ),
    ReminderItem(
      id: 'h1',
      title: 'Every 4 Hours',
      subtitle: 'Daily Reminder',
      targetPets: ['All Pets'],
      type: 'hydration',
      notes: 'Add note',
      time: const TimeOfDay(hour: 8, minute: 0),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadSavedReminders();
  }

  Future<void> _loadSavedReminders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString('saved_nutrition_reminders');
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final List<dynamic> list = jsonDecode(jsonStr);
        if (list.isNotEmpty) {
          setState(() {
            _reminders = list
                .map((item) => ReminderItem.fromMap(item))
                .toList();
          });
        }
      }
    } catch (e) {
      debugPrint('[NutritionScreen] Error loading reminders: $e');
    }
  }

  Future<void> _persistReminders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = _reminders.map((r) => r.toMap()).toList();
      await prefs.setString('saved_nutrition_reminders', jsonEncode(list));
    } catch (e) {
      debugPrint('[NutritionScreen] Error saving reminders: $e');
    }
  }

  void _showDeleteConfirmation(ReminderItem item) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              const Icon(
                Icons.warning_amber_rounded,
                color: AppTheme.tertiary,
                size: 48,
              ),
              const SizedBox(height: 16),
              const Text(
                'Remove Reminder?',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Are you sure you want to remove this reminder? This action cannot be undone.',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  color: AppTheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _reminders.removeWhere((r) => r.id == item.id);
                        });
                        _persistReminders();
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Reminder removed successfully.'),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.tertiary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Remove'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _navigateToAddMeal() {
    _showAddMealDialog();
  }

  void _navigateToAddHydration() {
    _showAddHydrationDialog();
  }

  void _showAddMealDialog() {
    final petState = context.read<PetBloc>().state;
    final List<String> registeredPets = [];
    if (petState is PetLoaded) {
      registeredPets.addAll(petState.pets.map((p) => p.name));
    }

    final nameController = TextEditingController();
    final amountController = TextEditingController();
    final notesController = TextEditingController();
    TimeOfDay selectedTime = const TimeOfDay(hour: 8, minute: 0);
    String selectedUnit = 'Cups';
    final List<String> selectedPets = ['All Pets'];
    String? validationError;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return BaseFormDialog(
              icon: Icons.restaurant_outlined,
              title: 'Add Meal Reminder',
              subtitle: 'Set up feeding portions & schedule for your pets',
              validationError: validationError,
              primaryButtonText: 'Save Meal',
              primaryButtonIcon: Icons.check,
              onPrimaryPressed: () {
                final title = nameController.text.trim().isNotEmpty
                    ? nameController.text.trim()
                    : 'Meal';
                final amountText = amountController.text.trim().isNotEmpty
                    ? amountController.text.trim()
                    : '1.0';
                final formattedTime = selectedTime.format(context);
                final subtitle =
                    '$formattedTime • $amountText ${selectedUnit.toLowerCase()}';

                final newItem = ReminderItem(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  title: title,
                  subtitle: subtitle,
                  targetPets: List.from(selectedPets),
                  type: 'feeding',
                  notes: notesController.text.trim(),
                  time: selectedTime,
                );

                setState(() {
                  _reminders.add(newItem);
                });
                _persistReminders();

                Navigator.of(dialogContext).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Meal reminder "$title" added!'),
                    backgroundColor: AppTheme.primary,
                  ),
                );
              },
              children: [
                const FormSectionLabel('SELECT PETS'),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _buildModalPetChip(
                      'All Pets',
                      Colors.transparent,
                      selectedPets,
                      registeredPets,
                      setModalState,
                    ),
                    ...registeredPets.map((name) {
                      Color bulletColor = AppTheme.secondary;
                      if (name.toLowerCase() == 'luna') {
                        bulletColor = AppTheme.tertiary;
                      } else if (name.toLowerCase() == 'oliver') {
                        bulletColor = AppTheme.primaryFixedDim;
                      }
                      return _buildModalPetChip(
                        name,
                        bulletColor,
                        selectedPets,
                        registeredPets,
                        setModalState,
                      );
                    }),
                  ],
                ),
                const SizedBox(height: 16),
                const FormSectionLabel('MEAL NAME'),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    hintText: 'e.g. Breakfast',
                    prefixIcon: Icon(Icons.restaurant_menu),
                  ),
                ),
                const SizedBox(height: 16),
                const FormSectionLabel('REMINDER TIME'),
                InkWell(
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: selectedTime,
                    );
                    if (picked != null) {
                      setModalState(() => selectedTime = picked);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.surfaceContainer),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          selectedTime.format(context),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Icon(Icons.access_time, color: AppTheme.primary),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const FormSectionLabel('FOOD AMOUNT'),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: amountController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'e.g. 1.5',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    DropdownButtonFormField<String>(
                      initialValue: selectedUnit,
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      items: ['Cups', 'Grams', 'Ounces', 'Scoops']
                          .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setModalState(() => selectedUnit = val);
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const FormSectionLabel('ADDITIONAL NOTES'),
                TextField(
                  controller: notesController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    hintText: 'Mix with warm water or special diet instructions...',
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showAddHydrationDialog() {
    final petState = context.read<PetBloc>().state;
    final List<String> registeredPets = [];
    if (petState is PetLoaded) {
      registeredPets.addAll(petState.pets.map((p) => p.name));
    }

    String selectedFrequency = '2h';
    final customHoursController = TextEditingController();
    final notesController = TextEditingController();
    final amountController = TextEditingController(text: '250');
    String selectedUnit = 'ml';
    final List<String> selectedPets = ['All Pets'];
    String? validationError;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return BaseFormDialog(
              icon: Icons.water_drop_outlined,
              title: 'Add Hydration Reminder',
              subtitle: 'Automated water intake reminders for your pets',
              validationError: validationError,
              primaryButtonText: 'Save Hydration',
              primaryButtonIcon: Icons.check,
              onPrimaryPressed: () {
                String title = '';
                if (selectedFrequency == '2h') {
                  title = 'Every 2 Hours';
                } else if (selectedFrequency == '4h') {
                  title = 'Every 4 Hours';
                } else if (selectedFrequency == '6h') {
                  title = 'Every 6 Hours';
                } else {
                  final hrs = customHoursController.text.trim().isNotEmpty
                      ? customHoursController.text.trim()
                      : '3';
                  title = 'Every $hrs Hours';
                }

                final amountText = amountController.text.trim().isNotEmpty
                    ? amountController.text.trim()
                    : '250';
                final subtitle =
                    'Daily Reminder • $amountText ${selectedUnit.toLowerCase()}';

                final newItem = ReminderItem(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  title: title,
                  subtitle: subtitle,
                  targetPets: List.from(selectedPets),
                  type: 'hydration',
                  notes: notesController.text.trim(),
                );

                setState(() {
                  _reminders.add(newItem);
                });
                _persistReminders();

                Navigator.of(dialogContext).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Hydration reminder "$title" added!'),
                    backgroundColor: AppTheme.primary,
                  ),
                );
              },
              children: [
                const FormSectionLabel('SELECT PETS'),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _buildModalPetChip(
                      'All Pets',
                      Colors.transparent,
                      selectedPets,
                      registeredPets,
                      setModalState,
                    ),
                    ...registeredPets.map((name) {
                      Color bulletColor = AppTheme.secondary;
                      if (name.toLowerCase() == 'luna') {
                        bulletColor = AppTheme.tertiary;
                      } else if (name.toLowerCase() == 'oliver') {
                        bulletColor = AppTheme.primaryFixedDim;
                      }
                      return _buildModalPetChip(
                        name,
                        bulletColor,
                        selectedPets,
                        registeredPets,
                        setModalState,
                      );
                    }),
                  ],
                ),
                const SizedBox(height: 16),
                const FormSectionLabel('FREQUENCY'),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('Every 2h'),
                      selected: selectedFrequency == '2h',
                      selectedColor: AppTheme.primary,
                      labelStyle: TextStyle(
                        color: selectedFrequency == '2h'
                            ? Colors.white
                            : AppTheme.onSurface,
                        fontSize: 12,
                      ),
                      onSelected: (val) =>
                          setModalState(() => selectedFrequency = '2h'),
                    ),
                    ChoiceChip(
                      label: const Text('Every 4h'),
                      selected: selectedFrequency == '4h',
                      selectedColor: AppTheme.primary,
                      labelStyle: TextStyle(
                        color: selectedFrequency == '4h'
                            ? Colors.white
                            : AppTheme.onSurface,
                        fontSize: 12,
                      ),
                      onSelected: (val) =>
                          setModalState(() => selectedFrequency = '4h'),
                    ),
                    ChoiceChip(
                      label: const Text('Every 6h'),
                      selected: selectedFrequency == '6h',
                      selectedColor: AppTheme.primary,
                      labelStyle: TextStyle(
                        color: selectedFrequency == '6h'
                            ? Colors.white
                            : AppTheme.onSurface,
                        fontSize: 12,
                      ),
                      onSelected: (val) =>
                          setModalState(() => selectedFrequency = '6h'),
                    ),
                    ChoiceChip(
                      label: const Text('Custom'),
                      selected: selectedFrequency == 'custom',
                      selectedColor: AppTheme.primary,
                      labelStyle: TextStyle(
                        color: selectedFrequency == 'custom'
                            ? Colors.white
                            : AppTheme.onSurface,
                        fontSize: 12,
                      ),
                      onSelected: (val) =>
                          setModalState(() => selectedFrequency = 'custom'),
                    ),
                  ],
                ),
                if (selectedFrequency == 'custom') ...[
                  const SizedBox(height: 10),
                  const FormSectionLabel('CUSTOM HOURS INTERVAL'),
                  TextField(
                    controller: customHoursController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      hintText: 'e.g. 3 (hours)',
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                const FormSectionLabel('WATER VOLUME'),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: amountController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'e.g. 250',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    DropdownButtonFormField<String>(
                      initialValue: selectedUnit,
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      items: ['ml', 'Liters', 'Cups']
                          .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setModalState(() => selectedUnit = val);
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const FormSectionLabel('ADDITIONAL NOTES'),
                TextField(
                  controller: notesController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    hintText: 'Refill water bowl with fresh filtered water...',
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showEditReminderDialog(ReminderItem item) {
    final petState = context.read<PetBloc>().state;
    final List<String> registeredPets = [];
    if (petState is PetLoaded) {
      registeredPets.addAll(petState.pets.map((p) => p.name));
    }

    final isHydration = item.type == 'hydration';
    final nameController = TextEditingController(text: item.title);

    String selectedFrequency = '2h';
    String customHoursVal = '3';
    if (isHydration) {
      final tLower = item.title.toLowerCase();
      if (tLower.contains('2h') || tLower.contains('2 hour')) {
        selectedFrequency = '2h';
      } else if (tLower.contains('4h') || tLower.contains('4 hour')) {
        selectedFrequency = '4h';
      } else if (tLower.contains('6h') || tLower.contains('6 hour')) {
        selectedFrequency = '6h';
      } else {
        selectedFrequency = 'custom';
        final numMatch = RegExp(r'\d+').firstMatch(item.title);
        if (numMatch != null) {
          customHoursVal = numMatch.group(0)!;
        }
      }
    }
    final customHoursController = TextEditingController(text: customHoursVal);

    String initialAmount = isHydration ? '250' : '1.0';
    String initialUnit = isHydration ? 'ml' : 'Cups';
    if (item.subtitle.contains('•')) {
      final parts = item.subtitle.split('•');
      if (parts.length > 1) {
        final amountPart = parts[1].trim();
        final tokens = amountPart.split(' ');
        if (tokens.isNotEmpty) initialAmount = tokens[0];
        if (tokens.length > 1) {
          final unitRaw = tokens[1].toLowerCase();
          if (unitRaw.contains('cup')) {
            initialUnit = 'Cups';
          } else if (unitRaw.contains('gram')) {
            initialUnit = 'Grams';
          } else if (unitRaw.contains('ounce')) {
            initialUnit = 'Ounces';
          } else if (unitRaw.contains('scoop')) {
            initialUnit = 'Scoops';
          } else if (unitRaw.contains('ml')) {
            initialUnit = 'ml';
          } else if (unitRaw.contains('liter') || unitRaw.contains('l')) {
            initialUnit = 'Liters';
          }
        }
      }
    }

    final amountController = TextEditingController(text: initialAmount);
    final notesController = TextEditingController(text: item.notes);
    TimeOfDay selectedTime = item.time;
    String selectedUnit = initialUnit;
    final List<String> selectedPets = List<String>.from(
      item.targetPets.isNotEmpty ? item.targetPets : ['All Pets'],
    );
    String? validationError;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return BaseFormDialog(
              icon: isHydration
                  ? Icons.water_drop_outlined
                  : Icons.restaurant_outlined,
              title: 'Edit ${isHydration ? 'Hydration' : 'Meal'}',
              subtitle: isHydration
                  ? 'Update water intake schedule & reminders'
                  : 'Update meal portion & feeding schedule',
              validationError: validationError,
              primaryButtonText: 'Save Changes',
              primaryButtonIcon: Icons.check,
              headerAction: IconButton(
                icon: const Icon(Icons.delete_outline, color: AppTheme.error),
                tooltip: 'Delete',
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  _showDeleteConfirmation(item);
                },
              ),
              onPrimaryPressed: () {
                String title = '';
                String subtitle = '';

                if (isHydration) {
                  if (selectedFrequency == '2h') {
                    title = 'Every 2 Hours';
                  } else if (selectedFrequency == '4h') {
                    title = 'Every 4 Hours';
                  } else if (selectedFrequency == '6h') {
                    title = 'Every 6 Hours';
                  } else {
                    final hrs = customHoursController.text.trim().isNotEmpty
                        ? customHoursController.text.trim()
                        : '3';
                    title = 'Every $hrs Hours';
                  }
                  final amountText = amountController.text.trim().isNotEmpty
                      ? amountController.text.trim()
                      : '250';
                  subtitle =
                      'Daily Reminder • $amountText ${selectedUnit.toLowerCase()}';
                } else {
                  title = nameController.text.trim().isNotEmpty
                      ? nameController.text.trim()
                      : item.title;
                  final amountText = amountController.text.trim().isNotEmpty
                      ? amountController.text.trim()
                      : '1.0';
                  final formattedTime = selectedTime.format(context);
                  subtitle =
                      '$formattedTime • $amountText ${selectedUnit.toLowerCase()}';
                }

                setState(() {
                  final idx = _reminders.indexWhere((r) => r.id == item.id);
                  if (idx >= 0) {
                    _reminders[idx] = ReminderItem(
                      id: item.id,
                      title: title,
                      subtitle: subtitle,
                      targetPets: List.from(selectedPets),
                      type: item.type,
                      notes: notesController.text.trim(),
                      time: selectedTime,
                    );
                  }
                });
                _persistReminders();

                final now = DateTime.now();
                DateTime scheduledDT = DateTime(
                  now.year,
                  now.month,
                  now.day,
                  selectedTime.hour,
                  selectedTime.minute,
                );
                if (scheduledDT.isBefore(now)) {
                  scheduledDT = scheduledDT.add(const Duration(days: 1));
                }

                GlobalNotificationService().scheduleCustomEventNotification(
                  title: '${isHydration ? 'Hydration' : 'Meal'}: $title',
                  body: '$subtitle (${selectedPets.join(', ')})',
                  eventDateTime: scheduledDT,
                  reminderOffset: Duration.zero,
                  petName: selectedPets.join(', '),
                  category: isHydration
                      ? NotificationCategory.hydration
                      : NotificationCategory.feeding,
                );

                Navigator.of(dialogContext).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Reminder updated successfully & notification scheduled.',
                    ),
                    backgroundColor: AppTheme.primary,
                  ),
                );
              },
              children: [
                const FormSectionLabel('SELECT PETS'),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _buildModalPetChip(
                      'All Pets',
                      Colors.transparent,
                      selectedPets,
                      registeredPets,
                      setModalState,
                    ),
                    ...registeredPets.map((name) {
                      Color bulletColor = AppTheme.secondary;
                      if (name.toLowerCase() == 'luna') {
                        bulletColor = AppTheme.tertiary;
                      } else if (name.toLowerCase() == 'oliver') {
                        bulletColor = AppTheme.primaryFixedDim;
                      }
                      return _buildModalPetChip(
                        name,
                        bulletColor,
                        selectedPets,
                        registeredPets,
                        setModalState,
                      );
                    }),
                  ],
                ),
                const SizedBox(height: 16),
                if (isHydration) ...[
                  const FormSectionLabel('FREQUENCY'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('Every 2h'),
                        selected: selectedFrequency == '2h',
                        selectedColor: AppTheme.primary,
                        labelStyle: TextStyle(
                          color: selectedFrequency == '2h'
                              ? Colors.white
                              : AppTheme.onSurface,
                          fontSize: 12,
                        ),
                        onSelected: (val) =>
                            setModalState(() => selectedFrequency = '2h'),
                      ),
                      ChoiceChip(
                        label: const Text('Every 4h'),
                        selected: selectedFrequency == '4h',
                        selectedColor: AppTheme.primary,
                        labelStyle: TextStyle(
                          color: selectedFrequency == '4h'
                              ? Colors.white
                              : AppTheme.onSurface,
                          fontSize: 12,
                        ),
                        onSelected: (val) =>
                            setModalState(() => selectedFrequency = '4h'),
                      ),
                      ChoiceChip(
                        label: const Text('Every 6h'),
                        selected: selectedFrequency == '6h',
                        selectedColor: AppTheme.primary,
                        labelStyle: TextStyle(
                          color: selectedFrequency == '6h'
                              ? Colors.white
                              : AppTheme.onSurface,
                          fontSize: 12,
                        ),
                        onSelected: (val) =>
                            setModalState(() => selectedFrequency = '6h'),
                      ),
                      ChoiceChip(
                        label: const Text('Custom'),
                        selected: selectedFrequency == 'custom',
                        selectedColor: AppTheme.primary,
                        labelStyle: TextStyle(
                          color: selectedFrequency == 'custom'
                              ? Colors.white
                              : AppTheme.onSurface,
                          fontSize: 12,
                        ),
                        onSelected: (val) =>
                            setModalState(() => selectedFrequency = 'custom'),
                      ),
                    ],
                  ),
                  if (selectedFrequency == 'custom') ...[
                    const SizedBox(height: 10),
                    const FormSectionLabel('CUSTOM HOURS INTERVAL'),
                    TextField(
                      controller: customHoursController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        hintText: 'e.g. 3 (hours)',
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                ] else ...[
                  const FormSectionLabel('MEAL NAME'),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      hintText: 'e.g. Breakfast',
                      prefixIcon: Icon(Icons.edit_outlined),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const FormSectionLabel('REMINDER TIME'),
                  InkWell(
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: selectedTime,
                      );
                      if (picked != null) {
                        setModalState(() => selectedTime = picked);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.surfaceContainer),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            selectedTime.format(context),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Icon(Icons.access_time, color: AppTheme.primary),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                FormSectionLabel(
                  isHydration ? 'WATER VOLUME' : 'FOOD AMOUNT',
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: amountController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          hintText: isHydration ? 'e.g. 250' : 'e.g. 1.5',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    DropdownButtonFormField<String>(
                      initialValue: selectedUnit,
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      items: (isHydration
                              ? ['ml', 'Liters', 'Cups']
                              : ['Cups', 'Grams', 'Ounces', 'Scoops'])
                          .map(
                            (u) => DropdownMenuItem(
                              value: u,
                              child: Text(u),
                            ),
                          )
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setModalState(() => selectedUnit = val);
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const FormSectionLabel('ADDITIONAL NOTES'),
                TextField(
                  controller: notesController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    hintText:
                        'e.g. Special diet instructions or water bowl location...',
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }



  Widget _buildModalPetChip(
    String petName,
    Color bulletColor,
    List<String> selectedPets,
    List<String> registeredPets,
    StateSetter setModalState,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSelected = selectedPets.contains(petName);
    return ChoiceChip(
      showCheckmark: false,
      avatar: petName != 'All Pets'
          ? CircleAvatar(radius: 4, backgroundColor: bulletColor)
          : null,
      label: Text(
        petName,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 11,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected
              ? Colors.white
              : (isDark ? AppTheme.darkOnSurface : AppTheme.onSurface),
        ),
      ),
      selected: isSelected,
      selectedColor: AppTheme.primary,
      backgroundColor: isDark
          ? const Color(0xFF383634)
          : AppTheme.surfaceContainerLow,
      side: BorderSide(
        color: isSelected
            ? AppTheme.primary
            : (isDark ? const Color(0xFF4A4846) : AppTheme.surfaceContainer),
      ),
      onSelected: (bool selected) {
        setModalState(() {
          if (petName == 'All Pets') {
            selectedPets.clear();
            selectedPets.add('All Pets');
          } else {
            selectedPets.remove('All Pets');
            if (selectedPets.contains(petName)) {
              selectedPets.remove(petName);
            } else {
              selectedPets.add(petName);
            }
            if (registeredPets.every((p) => selectedPets.contains(p)) ||
                selectedPets.isEmpty) {
              selectedPets.clear();
              selectedPets.add('All Pets');
            }
          }
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final feedingList = _reminders.where((r) => r.type == 'feeding').toList();
    final hydrationList = _reminders
        .where((r) => r.type == 'hydration')
        .toList();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final foodColor = isDark ? AppTheme.foodConceptDark : AppTheme.foodConcept;
    final waterColor = isDark
        ? AppTheme.waterConceptDark
        : AppTheme.waterConcept;

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
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          ListenableBuilder(
            listenable: GlobalNotificationService(),
            builder: (context, _) {
              final unread = GlobalNotificationService().unreadCount;
              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.notifications_none,
                      color: AppTheme.primary,
                    ),
                    onPressed: () => GlobalNotificationService()
                        .showNotificationCenter(context),
                  ),
                  if (unread > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppTheme.tertiary,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          '$unread',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero Section Title
              const Text(
                'Nutrition Alerts',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                  color: AppTheme.primary,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Customize how and when you want to be reminded about your pet\'s hydration and feeding needs.',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  color: AppTheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 28),

              // Responsive Feeding & Hydration Cards
              if (ResponsiveLayout.isWide(context))
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: NutritionReminderCard(
                        title: 'Feeding',
                        icon: Icons.restaurant,
                        isEnabled: _masterFeedingEnabled,
                        onToggleChanged: (val) =>
                            setState(() => _masterFeedingEnabled = val),
                        onAddPressed: _navigateToAddMeal,
                        items: feedingList,
                        accentColor: foodColor,
                        onDeleteItem: _showDeleteConfirmation,
                        onEditItem: _showEditReminderDialog,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: NutritionReminderCard(
                        title: 'Hydration',
                        icon: Icons.water_drop,
                        isEnabled: _masterHydrationEnabled,
                        onToggleChanged: (val) =>
                            setState(() => _masterHydrationEnabled = val),
                        onAddPressed: _navigateToAddHydration,
                        items: hydrationList,
                        accentColor: waterColor,
                        onDeleteItem: _showDeleteConfirmation,
                        onEditItem: _showEditReminderDialog,
                      ),
                    ),
                  ],
                )
              else ...[
                // Feeding Reminders Bento Card
                NutritionReminderCard(
                  title: 'Feeding',
                  icon: Icons.restaurant,
                  isEnabled: _masterFeedingEnabled,
                  onToggleChanged: (val) =>
                      setState(() => _masterFeedingEnabled = val),
                  onAddPressed: _navigateToAddMeal,
                  items: feedingList,
                  accentColor: foodColor,
                  onDeleteItem: _showDeleteConfirmation,
                  onEditItem: _showEditReminderDialog,
                ),
                const SizedBox(height: 24),

                // Hydration Reminders Bento Card
                NutritionReminderCard(
                  title: 'Hydration',
                  icon: Icons.water_drop,
                  isEnabled: _masterHydrationEnabled,
                  onToggleChanged: (val) =>
                      setState(() => _masterHydrationEnabled = val),
                  onAddPressed: _navigateToAddHydration,
                  items: hydrationList,
                  accentColor: waterColor,
                  onDeleteItem: _showDeleteConfirmation,
                  onEditItem: _showEditReminderDialog,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
