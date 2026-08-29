import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../logic/theme/theme_cubit.dart';
import '../../../logic/pet/pet_bloc.dart';
import '../../../data/models/pet.dart';
import '../../../data/models/medication.dart';
import '../../theme/app_theme.dart';
import '../pet/pet_profile_screen.dart';

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

  void _onAddEventPressed(BuildContext context, PetState petState) {
    if (petState is PetLoaded && petState.pets.isNotEmpty) {
      if (petState.pets.length == 1) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => PetProfileScreen(pet: petState.pets.first),
          ),
        );
      } else {
        showModalBottomSheet(
          context: context,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          builder: (modalContext) {
            return Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Select Pet for Event',
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: AppTheme.primary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Choose a pet profile to add or manage scheduled events',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: AppTheme.secondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...petState.pets.map((pet) {
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      leading: CircleAvatar(
                        backgroundColor: AppTheme.primaryFixed.withValues(
                          alpha: 0.3,
                        ),
                        child: Text(
                          pet.name.substring(0, 1).toUpperCase(),
                          style: const TextStyle(
                            color: AppTheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(
                        pet.name,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text('${pet.breed} • ${pet.species}'),
                      trailing: const Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: AppTheme.secondary,
                      ),
                      onTap: () {
                        Navigator.of(modalContext).pop();
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => PetProfileScreen(pet: pet),
                          ),
                        );
                      },
                    );
                  }),
                ],
              ),
            );
          },
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No registered pets found. Add a pet first.'),
        ),
      );
    }
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
            if (isVaccine) {
              realEvents.add({
                'time': '09:00 AM',
                'title': 'Vaccine Due: ${med.name} (${pet.name})',
                'subtitle': 'Booster administration',
                'location': 'Veterinary Clinic',
                'icon': Icons.vaccines,
                'color': AppTheme.tertiary,
              });
            } else {
              if (med.hasStartTime) {
                final start = med.startDate ?? med.nextDoseDate;
                final times = _getEventTimesForFrequency(start, med.frequency);
                for (final time in times) {
                  realEvents.add({
                    'time': time,
                    'title': 'Meds Due: ${med.name} (${pet.name})',
                    'subtitle':
                        'Dose: ${med.dose.isNotEmpty ? med.dose : '1 Tablet'} (${med.route.isNotEmpty ? med.route : 'Oral'})',
                    'location': 'Home',
                    'icon': Icons.medication,
                    'color': AppTheme.primary,
                  });
                }
              } else {
                // No start time: add exactly two events without time
                for (int i = 0; i < 2; i++) {
                  realEvents.add({
                    'time': 'No Time',
                    'title': 'Meds Due: ${med.name} (${pet.name})',
                    'subtitle':
                        'Dose: ${med.dose.isNotEmpty ? med.dose : '1 Tablet'} (${med.route.isNotEmpty ? med.route : 'Oral'})',
                    'location': 'Home',
                    'icon': Icons.medication,
                    'color': AppTheme.primary,
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Calendar & Schedules',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _onAddEventPressed(context, petState),
                icon: const Icon(Icons.add_circle_outline, size: 16),
                label: const Text(
                  'Add Event',
                  style: TextStyle(
                    fontFamily: 'Inter',
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
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 0,
                ),
              ),
            ],
          ),
        ),

        // Complete Month Calendar Box
        Container(
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

                  final petsList = petState is PetLoaded
                      ? petState.pets
                      : <Pet>[];
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
                                    : (isToday
                                          ? headerColor
                                          : AppTheme.tertiary),
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
        ),
        const SizedBox(height: 24),

        // List of events header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            scheduleTitle,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ),
        const SizedBox(height: 12),

        // Events list
        Expanded(
          child: displayEvents.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 48,
                        color: textSecondary.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No events scheduled for this day.',
                        style: TextStyle(
                          fontStyle: FontStyle.italic,
                          color: textSecondary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () => _onAddEventPressed(context, petState),
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Add Event to Pet Profile'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: displayEvents.length,
                  itemBuilder: (context, index) {
                    final ev = displayEvents[index];
                    return _buildScheduleCard(
                      time: ev['time'],
                      title: ev['title'],
                      subtitle: ev['subtitle'],
                      location: ev['location'],
                      icon: ev['icon'],
                      color: ev['color'],
                      isDark: isDark,
                      cardBg: cardBg,
                      textSecondary: textSecondary,
                      textPrimary: textPrimary,
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildScheduleCard({
    required String time,
    required String title,
    required String subtitle,
    required String location,
    required IconData icon,
    required Color color,
    required bool isDark,
    required Color cardBg,
    required Color textSecondary,
    required Color textPrimary,
  }) {
    return Card(
      color: cardBg,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  time,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDark && color == AppTheme.primary
                        ? AppTheme.primaryFixedDim
                        : color,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'EVENT',
                  style: TextStyle(fontSize: 10, color: textSecondary),
                ),
              ],
            ),
            const SizedBox(width: 16),
            Container(
              height: 48,
              width: 1,
              color: isDark
                  ? const Color(0xFF383634)
                  : AppTheme.surfaceContainer,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 13, color: textSecondary),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 14, color: textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        location,
                        style: TextStyle(fontSize: 11, color: textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(
              icon,
              color: isDark && color == AppTheme.primary
                  ? AppTheme.primaryFixedDim
                  : color.withValues(alpha: 0.8),
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}
