import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class CalendarScreen extends StatelessWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final daysOfWeek = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final dates = [10, 11, 12, 13, 14, 15, 16]; // Mock dates of current week

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

        // Weekly Calendar strip
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: AppTheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(7, (index) {
              final isToday = index == 4; // Mock today is Friday (index 4)
              return Column(
                children: [
                  Text(
                    daysOfWeek[index],
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isToday ? AppTheme.primary : AppTheme.secondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: isToday
                        ? AppTheme.primary
                        : Colors.transparent,
                    child: Text(
                      dates[index].toString(),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isToday ? Colors.white : AppTheme.onSurface,
                      ),
                    ),
                  ),
                ],
              );
            }),
          ),
        ),
        const SizedBox(height: 24),

        // List of events
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Upcoming Schedule',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ),
        const SizedBox(height: 12),

        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            children: [
              _buildScheduleCard(
                time: '10:00 AM',
                title: 'Vet Checkup: Luna',
                subtitle: 'Routine vaccines & health review',
                location: 'City Animal Hospital',
                icon: Icons.local_hospital,
                color: AppTheme.primary,
              ),
              _buildScheduleCard(
                time: '08:00 AM',
                title: 'Luna\'s Flea Dose',
                subtitle: 'Administer oral flea & tick chewable',
                location: 'Home',
                icon: Icons.vaccines,
                color: AppTheme.tertiary,
              ),
              _buildScheduleCard(
                time: '12:00 PM',
                title: 'Grooming: Bella',
                subtitle: 'Nail trim and bath appointment',
                location: 'Happy Paws Groomers',
                icon: Icons.brush,
                color: AppTheme.secondary,
              ),
            ],
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
                  'TODAY',
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
            Icon(icon, color: color.withOpacity(0.8), size: 24),
          ],
        ),
      ),
    );
  }
}
