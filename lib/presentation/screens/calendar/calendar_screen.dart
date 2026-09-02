import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../logic/theme/theme_cubit.dart';
import '../../../logic/pet/pet_bloc.dart';
import '../../../logic/notifications/global_notification_service.dart';
import '../../../data/models/app_notification.dart';
import '../../../data/models/pet.dart';
import '../../../data/models/medication.dart';
import '../../theme/app_theme.dart';
import '../../../core/utils/responsive_layout.dart';
import '../../widgets/calendar/calendar_schedule_card.dart';
import '../../widgets/base_form_dialog.dart';
import '../pet/meds_vaccines_screen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _selectedDate = DateTime.now();
  DateTime _currentMonth = DateTime.now();

  final daysOfWeek = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  String _getMonthName(int month) {
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
    return months[month - 1];
  }

  String _formatDate(DateTime dt) {
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
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  List<String> _getEventTimesForFrequency(DateTime start, String frequency) {
    String formatTime(int hour, int minute) {
      final ampm = hour >= 12 ? 'PM' : 'AM';
      int displayHour = hour % 12;
      if (displayHour == 0) displayHour = 12;
      final minuteStr = minute.toString().padLeft(2, '0');
      return '$displayHour:$minuteStr $ampm';
    }

    final startHour = start.hour;
    final startMinute = start.minute;

    switch (frequency) {
      case 'Every 8h':
        return [
          formatTime(startHour, startMinute),
          formatTime((startHour + 8) % 24, startMinute),
          formatTime((startHour + 16) % 24, startMinute),
        ];
      case 'Every 12h':
        return [
          formatTime(startHour, startMinute),
          formatTime((startHour + 12) % 24, startMinute),
        ];
      case 'Every 24h':
      case 'Weekly':
      case 'Monthly':
      case 'One-time':
      default:
        return [formatTime(startHour, startMinute)];
    }
  }

  bool _isMedicationScheduledOn(Medication med, DateTime selectedDate) {
    // Normalize dates to midnight (excluding time)
    final sel = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
    );

    if (med.type == 'vaccine') {
      // Vaccines occur on their nextDoseDate (next booster due)
      final nextBooster = DateTime(
        med.nextDoseDate.year,
        med.nextDoseDate.month,
        med.nextDoseDate.day,
      );
      return sel.isAtSameMomentAs(nextBooster);
    }

    // Medications
    final start = med.startDate != null
        ? DateTime(
            med.startDate!.year,
            med.startDate!.month,
            med.startDate!.day,
          )
        : DateTime(
            med.nextDoseDate.year,
            med.nextDoseDate.month,
            med.nextDoseDate.day,
          );

    if (sel.isBefore(start)) {
      return false;
    }

    if (med.endDate != null) {
      final end = DateTime(
        med.endDate!.year,
        med.endDate!.month,
        med.endDate!.day,
      );
      if (sel.isAfter(end)) {
        return false;
      }
    }

    final differenceInDays = sel.difference(start).inDays;

    switch (med.frequency) {
      case 'One-time':
        return differenceInDays == 0;
      case 'Every 8h':
      case 'Every 12h':
      case 'Every 24h':
        // Daily, so occurs every day between start and end
        return true;
      case 'Weekly':
        return differenceInDays % 7 == 0;
      case 'Monthly':
        // Occurs on same day-of-month, e.g. 15th
        return sel.day == start.day;
      default:
        // Fallback
        return sel.isAtSameMomentAs(
          DateTime(
            med.nextDoseDate.year,
            med.nextDoseDate.month,
            med.nextDoseDate.day,
          ),
        );
    }
  }

  bool _hasEventsOnDate(DateTime date, List<Pet> pets) {
    for (final pet in pets) {
      for (final med in pet.medications) {
        if (_isMedicationScheduledOn(med, date)) {
          return true;
        }
      }
    }
    return false;
  }

  void _showAddEventDialog(BuildContext context, PetState petState) {
    if (petState is! PetLoaded || petState.pets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No registered pets found. Add a pet first.'),
        ),
      );
      return;
    }

    final isDark = context.read<ThemeCubit>().state;
    final textPrimary = isDark ? AppTheme.darkOnSurface : AppTheme.onSurface;
    final textSecondary = isDark
        ? AppTheme.darkOnSurfaceVariant
        : AppTheme.secondary;
    final cardBg = isDark ? AppTheme.darkSurface : Colors.white;
    final headerColor = isDark ? AppTheme.primaryFixedDim : AppTheme.primary;

    final titleController = TextEditingController();
    final noteController = TextEditingController();

    DateTime selectedDate = _selectedDate;
    TimeOfDay selectedTime = TimeOfDay.now();

    // Required pet selection options: 'All' (first option) + registered pets
    final List<String> petOptions = [
      'All',
      ...petState.pets.map((p) => p.name),
    ];
    String selectedPetTarget = petOptions[0]; // Defaults to 'All'

    // Early reminder timing options
    final Map<String, Duration> reminderOptions = {
      'At time of event': Duration.zero,
      '15 minutes before': const Duration(minutes: 15),
      '30 minutes before': const Duration(minutes: 30),
      '1 hour before': const Duration(hours: 1),
      '2 hours before': const Duration(hours: 2),
      '1 day before': const Duration(days: 1),
    };
    String selectedReminderKey = '15 minutes before';

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setModalState) {
            return BaseFormDialog(
              icon: Icons.event_note,
              title: 'Add Event',
              subtitle: 'Schedule a pet event or reminder',
              primaryButtonText: 'Save Event',
              onPrimaryPressed: () {
                final eventTitle = titleController.text.trim().isNotEmpty
                    ? titleController.text.trim()
                    : 'Scheduled Event';
                final eventNote = noteController.text.trim().isNotEmpty
                    ? noteController.text.trim()
                    : 'Calendar Event';

                final eventDateTime = DateTime(
                  selectedDate.year,
                  selectedDate.month,
                  selectedDate.day,
                  selectedTime.hour,
                  selectedTime.minute,
                );

                final reminderOffset =
                    reminderOptions[selectedReminderKey] ?? Duration.zero;

                final petBloc = context.read<PetBloc>();

                final newEvent = Medication(
                  id: 'event_${DateTime.now().millisecondsSinceEpoch}',
                  name: eventTitle,
                  nextDoseDate: eventDateTime,
                  type: 'event',
                  dose: eventNote,
                  frequency: 'One-time',
                  hasStartTime: true,
                  remindersEnabled: true,
                );

                if (selectedPetTarget == 'All') {
                  for (final pet in petState.pets) {
                    final updatedMeds = List<Medication>.from(
                      pet.medications,
                    )..add(newEvent);
                    petBloc.add(
                      UpdatePet(pet.copyWith(medications: updatedMeds)),
                    );
                  }
                  GlobalNotificationService()
                      .scheduleCustomEventNotification(
                        title: eventTitle,
                        body: '$eventNote (For All Pets)',
                        eventDateTime: eventDateTime,
                        reminderOffset: reminderOffset,
                        petName: 'All Pets',
                        category: NotificationCategory.system,
                      );
                } else {
                  final matchedPet = petState.pets.firstWhere(
                    (p) => p.name == selectedPetTarget,
                    orElse: () => petState.pets.first,
                  );
                  final updatedMeds = List<Medication>.from(
                    matchedPet.medications,
                  )..add(newEvent);
                  petBloc.add(
                    UpdatePet(
                      matchedPet.copyWith(medications: updatedMeds),
                    ),
                  );
                  GlobalNotificationService()
                      .scheduleCustomEventNotification(
                        title: eventTitle,
                        body: '$eventNote for ${matchedPet.name}',
                        eventDateTime: eventDateTime,
                        reminderOffset: reminderOffset,
                        petName: matchedPet.name,
                        petAvatarUrl: matchedPet.avatarUrl,
                        category: NotificationCategory.system,
                      );
                }

                Navigator.of(dialogContext).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Event "$eventTitle" saved! Reminder set ($selectedReminderKey).',
                    ),
                    backgroundColor: AppTheme.primary,
                  ),
                );
              },
              children: [
                // 1. Pet Selection Dropdown
                const FormSectionLabel('Select Pet'),
                DropdownButtonFormField<String>(
                  initialValue: selectedPetTarget,
                  dropdownColor: cardBg,
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
                  items: petOptions.map((name) {
                    return DropdownMenuItem(
                      value: name,
                      child: Text(name == 'All' ? 'All Pets' : name),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setModalState(() => selectedPetTarget = val);
                    }
                  },
                ),
                const SizedBox(height: 14),

                // 2. Event Title Input
                const FormSectionLabel('Event Title / Type'),
                TextField(
                  controller: titleController,
                  style: TextStyle(color: textPrimary, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'e.g. Vet Visit, Grooming, Vaccination',
                    hintStyle: TextStyle(
                      color: textSecondary.withValues(alpha: 0.6),
                      fontSize: 13,
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
                  ),
                ),
                const SizedBox(height: 14),

                // 3. Date & Time Selection Buttons Row
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const FormSectionLabel('Date'),
                          OutlinedButton.icon(
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: selectedDate,
                                firstDate: DateTime.now().subtract(
                                  const Duration(days: 365),
                                ),
                                lastDate: DateTime.now().add(
                                  const Duration(days: 1825),
                                ),
                              );
                              if (picked != null) {
                                setModalState(() => selectedDate = picked);
                              }
                            },
                            icon: Icon(
                              Icons.calendar_today,
                              size: 16,
                              color: headerColor,
                            ),
                            label: Text(
                              '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                              style: TextStyle(
                                fontSize: 12,
                                color: textPrimary,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const FormSectionLabel('Time'),
                          OutlinedButton.icon(
                            onPressed: () async {
                              final picked = await showTimePicker(
                                context: context,
                                initialTime: selectedTime,
                              );
                              if (picked != null) {
                                setModalState(() => selectedTime = picked);
                              }
                            },
                            icon: Icon(
                              Icons.access_time,
                              size: 16,
                              color: headerColor,
                            ),
                            label: Text(
                              selectedTime.format(context),
                              style: TextStyle(
                                fontSize: 12,
                                color: textPrimary,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // 4. Early Reminder Notification Option
                const FormSectionLabel('Notification Reminder'),
                DropdownButtonFormField<String>(
                  initialValue: selectedReminderKey,
                  dropdownColor: cardBg,
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
                  items: reminderOptions.keys.map((optionLabel) {
                    return DropdownMenuItem(
                      value: optionLabel,
                      child: Text(optionLabel),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setModalState(() => selectedReminderKey = val);
                    }
                  },
                ),
                const SizedBox(height: 14),

                // 5. Note / Description Input
                const FormSectionLabel('Note / Location'),
                TextField(
                  controller: noteController,
                  style: TextStyle(color: textPrimary, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'e.g. Clinic address, prep instructions',
                    hintStyle: TextStyle(
                      color: textSecondary.withValues(alpha: 0.6),
                      fontSize: 13,
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
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showEditEventDialog(
    BuildContext context,
    PetState petState,
    Pet ownerPet,
    Medication targetMedication,
  ) {
    if (petState is! PetLoaded) return;

    final isDark = context.read<ThemeCubit>().state;
    final textPrimary = isDark ? AppTheme.darkOnSurface : AppTheme.onSurface;
    final textSecondary = isDark
        ? AppTheme.darkOnSurfaceVariant
        : AppTheme.secondary;
    final cardBg = isDark ? AppTheme.darkSurface : Colors.white;
    final headerColor = isDark ? AppTheme.primaryFixedDim : AppTheme.primary;

    final titleController = TextEditingController(text: targetMedication.name);
    final noteController = TextEditingController(text: targetMedication.dose);

    DateTime selectedDate = targetMedication.nextDoseDate;
    TimeOfDay selectedTime = TimeOfDay.fromDateTime(
      targetMedication.nextDoseDate,
    );

    final List<String> petOptions = [
      'All',
      ...petState.pets.map((p) => p.name),
    ];
    String selectedPetTarget = ownerPet.name;

    final Map<String, Duration> reminderOptions = {
      'At time of event': Duration.zero,
      '15 minutes before': const Duration(minutes: 15),
      '30 minutes before': const Duration(minutes: 30),
      '1 hour before': const Duration(hours: 1),
      '2 hours before': const Duration(hours: 2),
      '1 day before': const Duration(days: 1),
    };
    String selectedReminderKey = '15 minutes before';

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              backgroundColor: cardBg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              title: Row(
                children: [
                  Icon(Icons.edit_calendar, color: headerColor),
                  const SizedBox(width: 10),
                  Text(
                    'Edit Calendar Event',
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: textPrimary,
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Pet Selection Dropdown
                    Text(
                      'Select Pet',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      initialValue: selectedPetTarget,
                      dropdownColor: cardBg,
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
                      items: petOptions.map((name) {
                        return DropdownMenuItem(
                          value: name,
                          child: Text(name == 'All' ? 'All Pets' : name),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setModalState(() => selectedPetTarget = val);
                        }
                      },
                    ),
                    const SizedBox(height: 14),

                    // 2. Event Title Input
                    Text(
                      'Event Title / Type',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: titleController,
                      style: TextStyle(color: textPrimary, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'e.g. Vet Visit, Grooming, Vaccination',
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
                    ),
                    const SizedBox(height: 14),

                    // 3. Date & Time Selection
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Date',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: textSecondary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              OutlinedButton.icon(
                                onPressed: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: selectedDate,
                                    firstDate: DateTime.now().subtract(
                                      const Duration(days: 365),
                                    ),
                                    lastDate: DateTime.now().add(
                                      const Duration(days: 1825),
                                    ),
                                  );
                                  if (picked != null) {
                                    setModalState(() => selectedDate = picked);
                                  }
                                },
                                icon: Icon(
                                  Icons.calendar_today,
                                  size: 16,
                                  color: headerColor,
                                ),
                                label: Text(
                                  '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: textPrimary,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Time',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: textSecondary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              OutlinedButton.icon(
                                onPressed: () async {
                                  final picked = await showTimePicker(
                                    context: context,
                                    initialTime: selectedTime,
                                  );
                                  if (picked != null) {
                                    setModalState(() => selectedTime = picked);
                                  }
                                },
                                icon: Icon(
                                  Icons.access_time,
                                  size: 16,
                                  color: headerColor,
                                ),
                                label: Text(
                                  selectedTime.format(context),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: textPrimary,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // 4. Notification Reminder Option
                    Text(
                      'Notification Reminder',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      initialValue: selectedReminderKey,
                      dropdownColor: cardBg,
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
                      items: reminderOptions.keys.map((optionLabel) {
                        return DropdownMenuItem(
                          value: optionLabel,
                          child: Text(optionLabel),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setModalState(() => selectedReminderKey = val);
                        }
                      },
                    ),
                    const SizedBox(height: 14),

                    // 5. Note / Description Input
                    Text(
                      'Note / Location',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: noteController,
                      style: TextStyle(color: textPrimary, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'e.g. Clinic address, prep instructions',
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
                    ),
                  ],
                ),
              ),
              actions: [
                OutlinedButton.icon(
                  onPressed: () {
                    // Delete event
                    final petBloc = context.read<PetBloc>();
                    for (final p in petState.pets) {
                      final updatedMeds = List<Medication>.from(p.medications)
                        ..removeWhere((m) => m.id == targetMedication.id);
                      petBloc.add(
                        UpdatePet(p.copyWith(medications: updatedMeds)),
                      );
                    }
                    Navigator.of(dialogContext).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Calendar event deleted.')),
                    );
                  },
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Color(0xFFFFB4A3),
                    size: 16,
                  ),
                  label: const Text(
                    'Delete',
                    style: TextStyle(color: Color(0xFFFFB4A3)),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    final eventTitle = titleController.text.trim().isNotEmpty
                        ? titleController.text.trim()
                        : 'Scheduled Event';
                    final eventNote = noteController.text.trim().isNotEmpty
                        ? noteController.text.trim()
                        : 'Calendar Event';

                    final eventDateTime = DateTime(
                      selectedDate.year,
                      selectedDate.month,
                      selectedDate.day,
                      selectedTime.hour,
                      selectedTime.minute,
                    );

                    final reminderOffset =
                        reminderOptions[selectedReminderKey] ?? Duration.zero;

                    final petBloc = context.read<PetBloc>();

                    final updatedEvent = Medication(
                      id: targetMedication.id,
                      name: eventTitle,
                      nextDoseDate: eventDateTime,
                      type: 'event',
                      dose: eventNote,
                      frequency: 'One-time',
                      hasStartTime: true,
                      remindersEnabled: true,
                    );

                    for (final p in petState.pets) {
                      final filtered = List<Medication>.from(p.medications)
                        ..removeWhere((m) => m.id == targetMedication.id);

                      if (selectedPetTarget == 'All' ||
                          p.name == selectedPetTarget) {
                        filtered.add(updatedEvent);
                      }
                      petBloc.add(UpdatePet(p.copyWith(medications: filtered)));
                    }

                    GlobalNotificationService().scheduleCustomEventNotification(
                      title: eventTitle,
                      body:
                          '$eventNote (${selectedPetTarget == 'All' ? 'All Pets' : selectedPetTarget})',
                      eventDateTime: eventDateTime,
                      reminderOffset: reminderOffset,
                      petName: selectedPetTarget,
                    );

                    Navigator.of(dialogContext).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Event "$eventTitle" updated! Reminder set ($selectedReminderKey).',
                        ),
                        backgroundColor: AppTheme.primary,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Save Changes'),
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
    final cardBg = isDark
        ? AppTheme.darkSurface
        : AppTheme.surfaceContainerLowest;
    final headerColor = isDark ? AppTheme.primaryFixedDim : AppTheme.primary;
    final theme = Theme.of(context);
    final petState = context.watch<PetBloc>().state;

    // Calendar Calculations
    final startOffset =
        DateTime(_currentMonth.year, _currentMonth.month, 1).weekday - 1;
    final daysInMonth = DateTime(
      _currentMonth.year,
      _currentMonth.month + 1,
      0,
    ).day;
    final totalSlots = startOffset + daysInMonth;

    // Gather real events from Pet BLoC
    final List<Map<String, dynamic>> realEvents = [];
    if (petState is PetLoaded) {
      for (final pet in petState.pets) {
        for (final med in pet.medications) {
          if (_isMedicationScheduledOn(med, _selectedDate)) {
            final isVaccine = med.type == 'vaccine';
            final isEvent = med.type == 'event';
            if (isVaccine) {
              realEvents.add({
                'time': '09:00 AM',
                'title': 'Vaccine Due: ${med.name}',
                'subtitle': 'Booster administration',
                'location': 'Veterinary Clinic',
                'icon': Icons.vaccines,
                'color': AppTheme.tertiary,
                'pet': pet,
                'medication': med,
                'isCalendarEvent': false,
              });
            } else if (isEvent) {
              final start = med.startDate ?? med.nextDoseDate;
              final times = _getEventTimesForFrequency(start, med.frequency);
              for (final time in times) {
                realEvents.add({
                  'time': time,
                  'title': med.name,
                  'subtitle': med.dose.isNotEmpty
                      ? med.dose
                      : 'Scheduled Event',
                  'location': 'Calendar Event',
                  'icon': Icons.event_note,
                  'color': AppTheme.primary,
                  'pet': pet,
                  'medication': med,
                  'isCalendarEvent': true,
                });
              }
            } else {
              if (med.hasStartTime) {
                final start = med.startDate ?? med.nextDoseDate;
                final times = _getEventTimesForFrequency(start, med.frequency);
                for (final time in times) {
                  realEvents.add({
                    'time': time,
                    'title': 'Meds Due: ${med.name}',
                    'subtitle':
                        'Dose: ${med.dose.isNotEmpty ? med.dose : '1 Tablet'} (${med.route.isNotEmpty ? med.route : 'Oral'})',
                    'location': 'Home',
                    'icon': Icons.medication,
                    'color': AppTheme.primary,
                    'pet': pet,
                    'medication': med,
                    'isCalendarEvent': false,
                  });
                }
              } else {
                // No start time: add exactly two events without time
                for (int i = 0; i < 2; i++) {
                  realEvents.add({
                    'time': 'No Time',
                    'title': 'Meds Due: ${med.name}',
                    'subtitle':
                        'Dose: ${med.dose.isNotEmpty ? med.dose : '1 Tablet'} (${med.route.isNotEmpty ? med.route : 'Oral'})',
                    'location': 'Home',
                    'icon': Icons.medication,
                    'color': AppTheme.primary,
                    'pet': pet,
                    'medication': med,
                    'isCalendarEvent': false,
                  });
                }
              }
            }
          }
        }
      }
    }

    // Sort events by time chronologically
    realEvents.sort((a, b) {
      int getMinutes(String t) {
        if (t == 'No Time') return 0;
        final parts = t.split(' ');
        if (parts.length < 2) return 0;
        final hm = parts[0].split(':');
        if (hm.length < 2) return 0;
        int hour = int.tryParse(hm[0]) ?? 0;
        final min = int.tryParse(hm[1]) ?? 0;
        final ampm = parts[1];
        if (ampm == 'PM' && hour != 12) hour += 12;
        if (ampm == 'AM' && hour == 12) hour = 0;
        return hour * 60 + min;
      }

      return getMinutes(a['time']).compareTo(getMinutes(b['time']));
    });

    // Real Events list from Pet BLoC
    final List<Map<String, dynamic>> displayEvents = List.from(realEvents);

    final isSelectedDateToday =
        _selectedDate.year == DateTime.now().year &&
        _selectedDate.month == DateTime.now().month &&
        _selectedDate.day == DateTime.now().day;

    final scheduleTitle = isSelectedDateToday
        ? "Today's Schedule"
        : "${_formatDate(_selectedDate)}'s Schedule";

    final monthCalendarBox = Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Month navigation header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: Icon(Icons.chevron_left, color: textSecondary),
                onPressed: () {
                  setState(() {
                    _currentMonth = DateTime(
                      _currentMonth.year,
                      _currentMonth.month - 1,
                    );
                  });
                },
              ),
              Text(
                '${_getMonthName(_currentMonth.month)} ${_currentMonth.year}',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: headerColor,
                ),
              ),
              IconButton(
                icon: Icon(Icons.chevron_right, color: textSecondary),
                onPressed: () {
                  setState(() {
                    _currentMonth = DateTime(
                      _currentMonth.year,
                      _currentMonth.month + 1,
                    );
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Weekdays Labels
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: daysOfWeek.map((day) {
              return SizedBox(
                width: 32,
                child: Text(
                  day,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                    color: textSecondary,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),

          // Calendar Days Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
              childAspectRatio: 1.1,
            ),
            itemCount: totalSlots,
            itemBuilder: (context, index) {
              if (index < startOffset) {
                return const SizedBox.shrink();
              }
              final day = index - startOffset + 1;
              final date = DateTime(
                _currentMonth.year,
                _currentMonth.month,
                day,
              );
              final isSelected =
                  _selectedDate.year == date.year &&
                  _selectedDate.month == date.month &&
                  _selectedDate.day == date.day;
              final isToday =
                  DateTime.now().year == date.year &&
                  DateTime.now().month == date.month &&
                  DateTime.now().day == date.day;

              final petsList = petState is PetLoaded ? petState.pets : <Pet>[];
              final hasEvents = _hasEventsOnDate(date, petsList);

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedDate = date;
                  });
                },
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected
                        ? AppTheme.primary
                        : (isToday
                              ? headerColor.withValues(alpha: 0.3)
                              : Colors.transparent),
                    border: isToday && !isSelected
                        ? Border.all(color: headerColor, width: 1.5)
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        day.toString(),
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: isSelected
                              ? Colors.white
                              : (isToday ? headerColor : textPrimary),
                        ),
                      ),
                      if (hasEvents) ...[
                        const SizedBox(height: 2),
                        Container(
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected
                                ? Colors.white
                                : (isToday ? headerColor : AppTheme.tertiary),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );

    Widget buildEventsListWidget({bool shrinkWrap = false}) {
      if (displayEvents.isEmpty) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 24,
                    color: textSecondary.withValues(alpha: 0.6),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'No events scheduled for this day.',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontStyle: FontStyle.italic,
                      fontSize: 14,
                      color: textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        shrinkWrap: shrinkWrap,
        physics: shrinkWrap ? const NeverScrollableScrollPhysics() : null,
        itemCount: displayEvents.length,
        itemBuilder: (context, index) {
          final ev = displayEvents[index];
          final Pet? pet = ev['pet'];
          final petName = pet?.name ?? 'All Pets';
          final isCalendarEvent = ev['isCalendarEvent'] == true;
          final Medication? med = ev['medication'];

          return CalendarScheduleCard(
            time: ev['time'],
            title: ev['title'],
            subtitle: ev['subtitle'],
            petName: petName,
            icon: ev['icon'],
            color: ev['color'],
            isDark: isDark,
            cardBg: cardBg,
            textSecondary: textSecondary,
            textPrimary: textPrimary,
            onTap: () {
              if (isCalendarEvent && pet != null && med != null) {
                _showEditEventDialog(context, petState, pet, med);
              } else if (pet != null) {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => MedsVaccinesScreen(pet: pet),
                  ),
                );
              }
            },
          );
        },
      );
    }

    final isWide = ResponsiveLayout.isWide(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEventDialog(context, petState),
        icon: const Icon(Icons.add_circle_outline, color: Colors.white, size: 20),
        label: const Text(
          'Add Event',
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppTheme.primary,
        elevation: 4,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Text(
              'Calendar & Schedules',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ),

          // Main Content View (Dual Pane on Wide / Tablet screens, Scrollable Column on Mobile)
          if (isWide)
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 380,
                    child: SingleChildScrollView(child: monthCalendarBox),
                  ),
                  const VerticalDivider(width: 1, thickness: 1),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Text(
                            scheduleTitle,
                            style: const TextStyle(
                              fontFamily: 'Montserrat',
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: buildEventsListWidget(shrinkWrap: false),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
          else
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    monthCalendarBox,
                    const SizedBox(height: 24),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        scheduleTitle,
                        style: const TextStyle(
                          fontFamily: 'Montserrat',
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    buildEventsListWidget(shrinkWrap: true),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
