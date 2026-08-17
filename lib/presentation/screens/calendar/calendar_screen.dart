import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../logic/pet/pet_bloc.dart';
import '../../../data/models/medication.dart';
import '../../theme/app_theme.dart';

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
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
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
    final sel = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
    
    if (med.type == 'vaccine') {
      // Vaccines occur on their nextDoseDate (next booster due)
      final nextBooster = DateTime(med.nextDoseDate.year, med.nextDoseDate.month, med.nextDoseDate.day);
      return sel.isAtSameMomentAs(nextBooster);
    }

    // Medications
    final start = med.startDate != null
        ? DateTime(med.startDate!.year, med.startDate!.month, med.startDate!.day)
        : DateTime(med.nextDoseDate.year, med.nextDoseDate.month, med.nextDoseDate.day);

    if (sel.isBefore(start)) {
      return false;
    }

    if (med.endDate != null) {
      final end = DateTime(med.endDate!.year, med.endDate!.month, med.endDate!.day);
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
        return sel.isAtSameMomentAs(DateTime(med.nextDoseDate.year, med.nextDoseDate.month, med.nextDoseDate.day));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final petState = context.watch<PetBloc>().state;

    // Calendar Calculations
    final startOffset = DateTime(_currentMonth.year, _currentMonth.month, 1).weekday - 1;
    final daysInMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 0).day;
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
              final start = med.startDate ?? med.nextDoseDate;
              final times = _getEventTimesForFrequency(start, med.frequency);
              for (final time in times) {
                realEvents.add({
                  'time': time,
                  'title': 'Meds Due: ${med.name} (${pet.name})',
                  'subtitle': 'Dose: ${med.dose.isNotEmpty ? med.dose : '1 Tablet'} (${med.route.isNotEmpty ? med.route : 'Oral'})',
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

    // Sort events by time chronologically
    realEvents.sort((a, b) {
      int getMinutes(String t) {
        final parts = t.split(' ');
        final hm = parts[0].split(':');
        int hour = int.parse(hm[0]);
        final min = int.parse(hm[1]);
        final ampm = parts[1];
        if (ampm == 'PM' && hour != 12) hour += 12;
        if (ampm == 'AM' && hour == 12) hour = 0;
        return hour * 60 + min;
      }
      return getMinutes(a['time']).compareTo(getMinutes(b['time']));
    });

    // Fallback Mock Events if selected date has no BLoC events
    final List<Map<String, dynamic>> displayEvents = List.from(realEvents);
    if (displayEvents.isEmpty) {
      // Return some mock schedule items based on the day of the week to keep the screen alive
      if (_selectedDate.weekday == DateTime.friday) {
        displayEvents.add({
          'time': '10:00 AM',
          'title': 'Vet Checkup: Luna',
          'subtitle': 'Routine vaccines & health review',
          'location': 'City Animal Hospital',
          'icon': Icons.local_hospital,
          'color': AppTheme.primary,
        });
      } else if (_selectedDate.weekday == DateTime.monday) {
        displayEvents.add({
          'time': '08:00 AM',
          'title': 'Luna\'s Heartworm Chew',
          'subtitle': 'Administer monthly protection chewable',
          'location': 'Home',
          'icon': Icons.healing,
          'color': AppTheme.tertiary,
        });
      } else if (_selectedDate.weekday == DateTime.wednesday) {
        displayEvents.add({
          'time': '12:00 PM',
          'title': 'Grooming: Bella',
          'subtitle': 'Nail trim and bath appointment',
          'location': 'Happy Paws Groomers',
          'icon': Icons.brush,
          'color': AppTheme.secondary,
        });
      }
    }

    final isSelectedDateToday = _selectedDate.year == DateTime.now().year &&
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
          child: Text(
            'Calendar & Schedules',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 22,
            ),
          ),
        ),

        // Complete Month Calendar Box
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
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
                    icon: const Icon(Icons.chevron_left, color: AppTheme.secondary),
                    onPressed: () {
                      setState(() {
                        _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
                      });
                    },
                  ),
                  Text(
                    '${_getMonthName(_currentMonth.month)} ${_currentMonth.year}',
                    style: const TextStyle(
                      fontFamily: 'Montserrat',
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppTheme.primary,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right, color: AppTheme.secondary),
                    onPressed: () {
                      setState(() {
                        _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
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
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                        color: AppTheme.secondary,
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
                  final date = DateTime(_currentMonth.year, _currentMonth.month, day);
                  final isSelected = _selectedDate.year == date.year &&
                      _selectedDate.month == date.month &&
                      _selectedDate.day == date.day;
                  final isToday = DateTime.now().year == date.year &&
                      DateTime.now().month == date.month &&
                      DateTime.now().day == date.day;

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
                            : (isToday ? AppTheme.primaryFixedDim.withValues(alpha: 0.3) : Colors.transparent),
                        border: isToday && !isSelected
                            ? Border.all(color: AppTheme.primary, width: 1.5)
                            : null,
                      ),
                      child: Text(
                        day.toString(),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: isSelected
                              ? Colors.white
                              : (isToday ? AppTheme.primary : AppTheme.onSurface),
                        ),
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
                      Icon(Icons.calendar_today_outlined, size: 48, color: AppTheme.secondary.withValues(alpha: 0.5)),
                      const SizedBox(height: 12),
                      const Text(
                        'No events scheduled for this day.',
                        style: TextStyle(
                          fontStyle: FontStyle.italic,
                          color: AppTheme.secondary,
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
  }) {
    return Card(
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
                    color: color,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'EVENT',
                  style: TextStyle(fontSize: 10, color: AppTheme.secondary),
                ),
              ],
            ),
            const SizedBox(width: 16),
            Container(height: 48, width: 1, color: AppTheme.surfaceContainer),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 14,
                        color: AppTheme.secondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        location,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.secondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(icon, color: color.withValues(alpha: 0.8), size: 24),
          ],
        ),
      ),
    );
  }
}
