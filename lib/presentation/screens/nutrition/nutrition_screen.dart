import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'add_meal_screen.dart';
import 'add_hydration_screen.dart';

class ReminderItem {
  final String id;
  final String title;
  final String subtitle;
  final List<String> targetPets;
  final String type; // 'feeding' or 'hydration'

  ReminderItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.targetPets,
    required this.type,
  });
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
  bool _specialDietAlertsEnabled = false;

  // Preferences Toggles
  bool _soundNotificationsEnabled = true;
  bool _vibrationEnabled = true;
  String _selectedAlertTone = 'Gentle Chime (Default)';

  // Reminders List
  final List<ReminderItem> _reminders = [
    ReminderItem(
      id: 'f1',
      title: 'Breakfast',
      subtitle: '07:30 AM • 1.5 cups',
      targetPets: ['All Pets'],
      type: 'feeding',
    ),
    ReminderItem(
      id: 'f2',
      title: 'Lunch',
      subtitle: '12:30 PM • 1.0 cup',
      targetPets: ['Luna', 'Oliver'],
      type: 'feeding',
    ),
    ReminderItem(
      id: 'f3',
      title: 'Dinner',
      subtitle: '06:00 PM • 1.5 cups',
      targetPets: ['All Pets'],
      type: 'feeding',
    ),
    ReminderItem(
      id: 'h1',
      title: 'Every 4 Hours',
      subtitle: 'Daily Reminder',
      targetPets: ['All Pets'],
      type: 'hydration',
    ),
  ];

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
    }
  }

  @override
  Widget build(BuildContext context) {
    final feedingList = _reminders.where((r) => r.type == 'feeding').toList();
    final hydrationList = _reminders
        .where((r) => r.type == 'hydration')
        .toList();

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
          IconButton(
            icon: const Icon(Icons.notifications_none, color: AppTheme.primary),
            onPressed: () {},
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

              // Feeding Reminders Bento Card
              _buildReminderCard(
                title: 'Feeding Schedule for All',
                icon: Icons.restaurant,
                isEnabled: _masterFeedingEnabled,
                onToggleChanged: (val) =>
                    setState(() => _masterFeedingEnabled = val),
                onAddPressed: _navigateToAddMeal,
                items: feedingList,
                accentColor: AppTheme.primary,
              ),
              const SizedBox(height: 24),

              // Hydration Reminders Bento Card
              _buildReminderCard(
                title: 'Hydration',
                icon: Icons.water_drop,
                isEnabled: _masterHydrationEnabled,
                onToggleChanged: (val) =>
                    setState(() => _masterHydrationEnabled = val),
                onAddPressed: _navigateToAddHydration,
                items: hydrationList,
                accentColor: AppTheme.primaryContainer,
              ),
              const SizedBox(height: 24),

              // Special Diet Alerts Card (Grayscale if disabled)
              _buildSpecialDietCard(),
              const SizedBox(height: 24),

              // Atmospheric Image Card
              Container(
                height: 160,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  image: const DecorationImage(
                    image: NetworkImage(
                      'https://lh3.googleusercontent.com/aida-public/AB6AXuDF1srscWg0EMSXyBwOrgQdY7YbyVFwlTPkNqQz0B7rAxfTYerFe9sraC3UB7mCbUOzkDaa5a3UIK4m7XAtNDYidFVZZQ457V1QXU2x5s-KqlI-Vc9FdKyCD9MGKljmiCCAr3-hDmn6zg4o3zPPWH84JL5cyQRZnCxXfsU_nRzaojBaAdY1even-CwueqSi0cwY_6GWIeJNWFxU7id-CTwix_9VDwHurwO-eG8JH00UHx6AEUaqdWgVY6pgO0gKZL60Kq8F1I9Gyrc',
                    ),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.7),
                      ],
                    ),
                  ),
                  padding: const EdgeInsets.all(16),
                  alignment: Alignment.bottomLeft,
                  child: const Text(
                    'Healthy Habits',
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Notification Preferences Panel
              _buildNotificationPreferencesCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReminderCard({
    required String title,
    required IconData icon,
    required bool isEnabled,
    required ValueChanged<bool> onToggleChanged,
    required VoidCallback onAddPressed,
    required List<ReminderItem> items,
    required Color accentColor,
  }) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: isEnabled ? 1.0 : 0.5,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.surfaceContainer),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(2),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Accent stripe on the left
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: Container(width: 5, color: accentColor),
              ),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryFixed.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                icon,
                                color: AppTheme.primary,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              title,
                              style: const TextStyle(
                                fontFamily: 'Montserrat',
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        Switch(
                          value: isEnabled,
                          activeColor: AppTheme.primary,
                          onChanged: onToggleChanged,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Add Reminders Button (only visible/active if master switch is on)
                    IgnorePointer(
                      ignoring: !isEnabled,
                      child: OutlinedButton.icon(
                        onPressed: onAddPressed,
                        icon: const Icon(Icons.add, size: 16),
                        label: Text(
                          'Add ${title == 'Hydration' ? 'Hydration' : 'Meal'}',
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.primary,
                          backgroundColor: AppTheme.primaryFixed.withOpacity(
                            0.1,
                          ),
                          side: BorderSide.none,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // List Items
                    if (items.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          'No reminders active.',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontStyle: FontStyle.italic,
                            color: AppTheme.secondary,
                          ),
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final r = items[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        r.title,
                                        style: const TextStyle(
                                          fontFamily: 'Inter',
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        r.subtitle,
                                        style: const TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: 12,
                                          color: AppTheme.onSurfaceVariant,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Wrap(
                                        spacing: 4,
                                        children: r.targetPets.map((p) {
                                          return Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color:
                                                  AppTheme.secondaryContainer,
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              p.toUpperCase(),
                                              style: const TextStyle(
                                                fontFamily: 'Inter',
                                                fontSize: 8,
                                                fontWeight: FontWeight.bold,
                                                color:
                                                    AppTheme.onSurfaceVariant,
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isEnabled)
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      color: AppTheme.secondary,
                                      size: 20,
                                    ),
                                    onPressed: () => _showDeleteConfirmation(r),
                                  ),
                                const Icon(
                                  Icons.chevron_right,
                                  color: AppTheme.secondary,
                                  size: 20,
                                ),
                              ],
                            ),
                          );
                        },
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

  Widget _buildSpecialDietCard() {
    final cardContent = AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: _specialDietAlertsEnabled ? 1.0 : 0.5,
      child: Container(
        padding: const EdgeInsets.all(20),
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
                Row(
                  children: const [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: AppTheme.tertiary,
                      size: 24,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Special Diet Alerts (All Pets)',
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
                Switch(
                  value: _specialDietAlertsEnabled,
                  activeColor: AppTheme.primary,
                  onChanged: (val) =>
                      setState(() => _specialDietAlertsEnabled = val),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Alerts for food allergens or strict prescription diet windows.',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: AppTheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );

    if (_specialDietAlertsEnabled) {
      return cardContent;
    } else {
      return ColorFiltered(
        colorFilter: const ColorFilter.matrix(<double>[
          0.2126,
          0.7152,
          0.0722,
          0,
          0,
          0.2126,
          0.7152,
          0.0722,
          0,
          0,
          0.2126,
          0.7152,
          0.0722,
          0,
          0,
          0,
          0,
          0,
          1,
          0,
        ]),
        child: cardContent,
      );
    }
  }

  Widget _buildNotificationPreferencesCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.surfaceContainer),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(
                Icons.settings_suggest_outlined,
                color: AppTheme.primary,
                size: 24,
              ),
              SizedBox(width: 8),
              Text(
                'Notification Preferences',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Sound Toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(
                    Icons.volume_up_outlined,
                    color: AppTheme.secondary,
                    size: 20,
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Sound Notifications',
                    style: TextStyle(fontFamily: 'Inter'),
                  ),
                ],
              ),
              Switch(
                value: _soundNotificationsEnabled,
                activeColor: AppTheme.primary,
                onChanged: (val) =>
                    setState(() => _soundNotificationsEnabled = val),
              ),
            ],
          ),
          const Divider(),

          // Vibration Toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(
                    Icons.vibration_outlined,
                    color: AppTheme.secondary,
                    size: 20,
                  ),
                  SizedBox(width: 12),
                  Text('Vibration', style: TextStyle(fontFamily: 'Inter')),
                ],
              ),
              Switch(
                value: _vibrationEnabled,
                activeColor: AppTheme.primary,
                onChanged: (val) => setState(() => _vibrationEnabled = val),
              ),
            ],
          ),
          const Divider(),
          const SizedBox(height: 12),

          // Alert Tone Selector
          const Text(
            'ALERT TONE',
            style: TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.bold,
              fontSize: 11,
              color: AppTheme.onSurfaceVariant,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.surfaceContainer),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButtonFormField<String>(
                value: _selectedAlertTone,
                icon: const Icon(Icons.music_note, color: AppTheme.primary),
                decoration: const InputDecoration(border: InputBorder.none),
                items: const [
                  DropdownMenuItem(
                    value: 'Gentle Chime (Default)',
                    child: Text('Gentle Chime (Default)'),
                  ),
                  DropdownMenuItem(
                    value: 'Playful Bark',
                    child: Text('Playful Bark'),
                  ),
                  DropdownMenuItem(
                    value: 'Nature Morning',
                    child: Text('Nature Morning'),
                  ),
                  DropdownMenuItem(
                    value: 'Electronic Beep',
                    child: Text('Electronic Beep'),
                  ),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _selectedAlertTone = val);
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
