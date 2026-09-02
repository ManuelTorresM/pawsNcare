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
import 'add_meal_screen.dart';
import 'add_hydration_screen.dart';

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

  Future<void> _navigateToAddMeal() async {
    final newItem = await Navigator.of(context).push<ReminderItem>(
      MaterialPageRoute(builder: (_) => const AddMealScreen()),
    );
    if (newItem != null) {
      setState(() {
        _reminders.add(newItem);
      });
      _persistReminders();
    }
  }

  Future<void> _navigateToAddHydration() async {
    final newItem = await Navigator.of(context).push<ReminderItem>(
      MaterialPageRoute(builder: (_) => const AddHydrationScreen()),
    );
    if (newItem != null) {
      setState(() {
        _reminders.add(newItem);
      });
      _persistReminders();
    }
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

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 420),
                padding: const EdgeInsets.all(20),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryFixed.withValues(
                                    alpha: 0.3,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  isHydration
                                      ? Icons.water_drop
                                      : Icons.restaurant,
                                  color: AppTheme.primary,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Edit ${isHydration ? 'Hydration' : 'Meal'}',
                                style: const TextStyle(
                                  fontFamily: 'Montserrat',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: AppTheme.primary,
                                ),
                              ),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.close,
                              color: AppTheme.secondary,
                            ),
                            onPressed: () => Navigator.of(dialogContext).pop(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Target Pets Selection Chips
                      const Text(
                        'SELECT PETS',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                          color: AppTheme.onSurfaceVariant,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 6),
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
                      const SizedBox(height: 18),

                      if (isHydration) ...[
                        // Hydration Frequency Section
                        const Text(
                          'FREQUENCY',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                            color: AppTheme.onSurfaceVariant,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 8),
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
                              onSelected: (val) => setModalState(
                                () => selectedFrequency = 'custom',
                              ),
                            ),
                          ],
                        ),
                        if (selectedFrequency == 'custom') ...[
                          const SizedBox(height: 10),
                          _buildBentoDialogCard(
                            label: 'Custom Hours Interval',
                            accentColor: AppTheme.tertiary,
                            child: TextField(
                              controller: customHoursController,
                              keyboardType: TextInputType.number,
                              style: const TextStyle(fontFamily: 'Inter'),
                              decoration: const InputDecoration(
                                hintText: 'e.g. 3 (hours)',
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                      ] else ...[
                        // Meal Input 1: Name
                        _buildBentoDialogCard(
                          label: 'Meal Name',
                          accentColor: AppTheme.primary,
                          child: TextField(
                            controller: nameController,
                            style: const TextStyle(fontFamily: 'Inter'),
                            decoration: InputDecoration(
                              hintText: 'e.g. Breakfast',
                              hintStyle: TextStyle(
                                color: AppTheme.secondary.withValues(
                                  alpha: 0.4,
                                ),
                              ),
                              suffixIcon: const Icon(
                                Icons.edit,
                                size: 18,
                                color: AppTheme.secondary,
                              ),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Meal Input 2: Time Picker
                        _buildBentoDialogCard(
                          label: 'Reminder Time',
                          accentColor: AppTheme.tertiary,
                          child: InkWell(
                            onTap: () async {
                              final picked = await showTimePicker(
                                context: context,
                                initialTime: selectedTime,
                                builder: (context, child) {
                                  return Theme(
                                    data: Theme.of(context).copyWith(
                                      timePickerTheme:
                                          const TimePickerThemeData(
                                            padding: EdgeInsets.all(12),
                                            dialTextStyle: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                    ),
                                    child: Transform.scale(
                                      scale: 1.15,
                                      child: child!,
                                    ),
                                  );
                                },
                              );
                              if (picked != null) {
                                setModalState(() => selectedTime = picked);
                              }
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    selectedTime.format(context),
                                    style: const TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const Icon(
                                    Icons.access_time,
                                    color: AppTheme.tertiary,
                                    size: 20,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],

                      // Bento Input 3: Portion / Volume Amount
                      _buildBentoDialogCard(
                        label: isHydration ? 'Water Volume' : 'Food Amount',
                        accentColor: AppTheme.secondary,
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: amountController,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                style: const TextStyle(fontFamily: 'Inter'),
                                decoration: InputDecoration(
                                  hintText: isHydration
                                      ? 'e.g. 250'
                                      : 'e.g. 1.5',
                                  hintStyle: TextStyle(
                                    color: AppTheme.secondary.withValues(
                                      alpha: 0.4,
                                    ),
                                  ),
                                  border: InputBorder.none,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            DropdownButton<String>(
                              value: selectedUnit,
                              underline: const SizedBox.shrink(),
                              items:
                                  (isHydration
                                          ? ['ml', 'Liters', 'Cups']
                                          : [
                                              'Cups',
                                              'Grams',
                                              'Ounces',
                                              'Scoops',
                                            ])
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
                      ),
                      const SizedBox(height: 12),

                      // Bento Input 4: Additional Notes
                      _buildBentoDialogCard(
                        label: 'Additional Notes',
                        accentColor: AppTheme.primary,
                        child: TextField(
                          controller: notesController,
                          maxLines: 2,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.onSurface,
                          ),
                          decoration: InputDecoration(
                            hintText:
                                'e.g. Mix with warm water or special diet instructions...',
                            hintStyle: TextStyle(
                              color: AppTheme.onSurfaceVariant.withValues(
                                alpha: 0.7,
                              ),
                              fontSize: 12,
                            ),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Action buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () =>
                                  Navigator.of(dialogContext).pop(),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
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
                                    final hrs =
                                        customHoursController.text
                                            .trim()
                                            .isNotEmpty
                                        ? customHoursController.text.trim()
                                        : '3';
                                    title = 'Every $hrs Hours';
                                  }
                                  final amountText =
                                      amountController.text.trim().isNotEmpty
                                      ? amountController.text.trim()
                                      : '250';
                                  subtitle =
                                      'Daily Reminder • $amountText ${selectedUnit.toLowerCase()}';
                                } else {
                                  title = nameController.text.trim().isNotEmpty
                                      ? nameController.text.trim()
                                      : item.title;
                                  final amountText =
                                      amountController.text.trim().isNotEmpty
                                      ? amountController.text.trim()
                                      : '1.0';
                                  final formattedTime = selectedTime.format(
                                    context,
                                  );
                                  subtitle =
                                      '$formattedTime • $amountText ${selectedUnit.toLowerCase()}';
                                }

                                setState(() {
                                  final idx = _reminders.indexWhere(
                                    (r) => r.id == item.id,
                                  );
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

                                // Schedule system notification alarm
                                final now = DateTime.now();
                                DateTime scheduledDT = DateTime(
                                  now.year,
                                  now.month,
                                  now.day,
                                  selectedTime.hour,
                                  selectedTime.minute,
                                );
                                if (scheduledDT.isBefore(now)) {
                                  scheduledDT = scheduledDT.add(
                                    const Duration(days: 1),
                                  );
                                }

                                GlobalNotificationService()
                                    .scheduleCustomEventNotification(
                                      title:
                                          '${isHydration ? 'Hydration' : 'Meal'}: $title',
                                      body:
                                          '$subtitle (${selectedPets.join(', ')})',
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
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Save Changes',
                                style: TextStyle(fontWeight: FontWeight.bold),
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
        );
      },
    );
  }

  Widget _buildBentoDialogCard({
    required String label,
    required Color accentColor,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.surfaceContainer),
      ),
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: Container(
              width: 4,
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(
              left: 14,
              right: 12,
              top: 8,
              bottom: 8,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.bold,
                    fontSize: 9,
                    color: accentColor,
                    letterSpacing: 0.8,
                  ),
                ),
                child,
              ],
            ),
          ),
        ],
      ),
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
                        title: 'Feeding Schedule for All',
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
                  title: 'Feeding Schedule for All',
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
