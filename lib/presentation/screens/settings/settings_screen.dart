import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../logic/auth/auth_bloc.dart';
import '../../../logic/pet/pet_bloc.dart';
import '../../../logic/diary/diary_bloc.dart';
import '../../../logic/theme/theme_cubit.dart';
import '../../../data/repositories/repository_selector.dart';
import '../../../data/models/app_notification.dart';
import '../../../logic/notifications/global_notification_service.dart';
import '../../theme/app_theme.dart';

import '../../../data/services/google_drive_service.dart';
import '../../../core/services/local_media_service.dart';
import '../profile/profile_details_screen.dart';
import '../test/test_playground_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Hardcoded variable: set to true to manually activate Demo Mode in code
  static const bool isDemoModeEnabled = false;
  String _activeDb = 'firebase';
  String? _userAvatarPath;
  bool _medsNotifications = true;
  bool _vaccinesNotifications = true;
  bool _feedingNotifications = false;
  bool _quietHoursEnabled = true;
  TimeOfDay _quietStart = const TimeOfDay(hour: 22, minute: 0); // 10:00 PM
  TimeOfDay _quietEnd = const TimeOfDay(hour: 7, minute: 0); // 07:00 AM
  bool _isDriveLinked = false;
  String? _driveEmail;

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  @override
  void initState() {
    super.initState();
    _loadDbSource();
    _loadNotificationSettings();
    _loadGoogleDriveStatus();
  }

  Future<void> _loadGoogleDriveStatus() async {
    try {
      final isLinked = await GoogleDriveService.isDriveLinked();
      final email = await GoogleDriveService.getLinkedEmail();
      if (mounted) {
        setState(() {
          _isDriveLinked = isLinked;
          _driveEmail = email;
        });
      }
    } catch (_) {}
  }

  void _loadNotificationSettings() {
    try {
      final service = GlobalNotificationService();
      _medsNotifications = service.medsNotificationsEnabled;
      _vaccinesNotifications = service.vaccinesNotificationsEnabled;
      _feedingNotifications = service.feedingNotificationsEnabled;
      _quietHoursEnabled = service.quietHoursEnabled;
      _quietStart = service.quietStart;
      _quietEnd = service.quietEnd;
    } catch (_) {}
  }

  Future<void> _loadDbSource() async {
    final db = await RepositorySelector.getDbSource();
    final prefs = await SharedPreferences.getInstance();
    final avatar = prefs.getString('pawsncare_user_avatar_path');
    setState(() {
      _activeDb = db;
      _userAvatarPath = avatar;
    });
  }

  Future<void> _toggleDbSource(String? value) async {
    if (value == null) return;
    await RepositorySelector.setDbSource(value);
    setState(() {
      _activeDb = value;
    });

    if (!mounted) return;

    // Refresh BLoC states with new repository source
    context.read<AuthBloc>().add(AuthCheckRequested());
    context.read<PetBloc>().add(LoadPets());
    context.read<DiaryBloc>().add(const LoadDiary());

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Switched to ${value.toUpperCase()} Database source.'),
        backgroundColor: AppTheme.primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeCubit>().state;
    final cardBg = isDark ? AppTheme.darkSurface : AppTheme.surfaceContainerLow;
    final textSecondary = isDark
        ? AppTheme.darkOnSurfaceVariant
        : AppTheme.secondary;
    final dividerColor = isDark
        ? const Color(0xFF383634)
        : AppTheme.surfaceContainer;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User Profile Section
          _buildSectionHeader('User Profile', textSecondary),
          const SizedBox(height: 8),
          BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              String name = 'Alex Johnson';
              String email = 'alex.j@petcare.com';
              if (state is Authenticated) {
                name = state.name;
                email = state.email;
              }
              return InkWell(
                onTap: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          ProfileDetailsScreen(name: name, email: email),
                    ),
                  );
                  _loadDbSource();
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Stack(
                        children: [
                          CircleAvatar(
                            radius: 32,
                            backgroundColor: AppTheme.primaryContainer,
                            backgroundImage: LocalMediaService.resolveImageProvider(
                              _userAvatarPath,
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: AppTheme.primary,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.edit,
                                color: Colors.white,
                                size: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              email,
                              style: TextStyle(
                                fontSize: 13,
                                color: textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right, color: textSecondary),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),

          // Database Storage Section (Shown ONLY when DEMO mode is manually enabled in code)
          if (isDemoModeEnabled) ...[
            _buildSectionHeader('Database Storage', textSecondary),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),
              ),
              child: RadioGroup<String>(
                groupValue: _activeDb,
                onChanged: _toggleDbSource,
                child: Column(
                  children: [
                    RadioListTile<String>(
                      title: const Text('Mock Database (Local Persistence)'),
                      subtitle: Text(
                        'Runs instantly without credentials.',
                        style: TextStyle(fontSize: 12, color: textSecondary),
                      ),
                      value: 'mock',
                      activeColor: AppTheme.primary,
                    ),
                    Divider(height: 1, color: dividerColor),
                    RadioListTile<String>(
                      title: const Text('Firebase Firestore Database'),
                      subtitle: Text(
                        'Connects to real cloud services.',
                        style: TextStyle(fontSize: 12, color: textSecondary),
                      ),
                      value: 'firebase',
                      activeColor: AppTheme.primary,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Notifications Toggles Section
          _buildSectionHeader('Notifications', textSecondary),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                _buildNotificationToggle(
                  icon: Icons.medical_services,
                  iconBg: isDark
                      ? const Color(0xFF5C2B1D)
                      : AppTheme.tertiaryFixed,
                  iconColor: isDark
                      ? const Color(0xFFFFB4A3)
                      : AppTheme.onTertiaryFixedVariant,
                  title: 'Medications',
                  subtitle: 'Daily reminders for dosages',
                  textColor: textSecondary,
                  value: _medsNotifications,
                  onChanged: (val) {
                    setState(() => _medsNotifications = val);
                    GlobalNotificationService().setCategoryEnabled(
                      NotificationCategory.medication,
                      val,
                    );
                  },
                ),
                Divider(height: 1, color: dividerColor),
                _buildNotificationToggle(
                  icon: Icons.vaccines,
                  iconBg: isDark
                      ? const Color(0xFF2E4E30)
                      : AppTheme.primaryFixed,
                  iconColor: isDark
                      ? AppTheme.primaryFixedDim
                      : AppTheme.onPrimaryFixed,
                  title: 'Vaccinations',
                  subtitle: 'Upcoming appointment alerts',
                  textColor: textSecondary,
                  value: _vaccinesNotifications,
                  onChanged: (val) {
                    setState(() => _vaccinesNotifications = val);
                    GlobalNotificationService().setCategoryEnabled(
                      NotificationCategory.vaccine,
                      val,
                    );
                  },
                ),
                Divider(height: 1, color: dividerColor),
                _buildNotificationToggle(
                  icon: Icons.restaurant,
                  iconBg: isDark
                      ? const Color(0xFF383634)
                      : AppTheme.secondaryContainer,
                  iconColor: isDark
                      ? AppTheme.primaryFixedDim
                      : AppTheme.secondary,
                  title: 'Feeding Times',
                  subtitle: 'Scheduled meal notifications',
                  textColor: textSecondary,
                  value: _feedingNotifications,
                  onChanged: (val) {
                    setState(() => _feedingNotifications = val);
                    GlobalNotificationService().setCategoryEnabled(
                      NotificationCategory.feeding,
                      val,
                    );
                  },
                ),
                Divider(height: 1, color: dividerColor),
                _buildNotificationToggle(
                  icon: Icons.bedtime,
                  iconBg: isDark
                      ? const Color(0xFF383634)
                      : AppTheme.surfaceContainerHigh,
                  iconColor: isDark
                      ? AppTheme.primaryFixedDim
                      : AppTheme.primary,
                  title: 'Quiet Hours (Silent Period)',
                  subtitle: 'Silence all reminders during specified hours',
                  textColor: textSecondary,
                  value: _quietHoursEnabled,
                  onChanged: (val) {
                    setState(() => _quietHoursEnabled = val);
                    GlobalNotificationService().setQuietHours(
                      enabled: val,
                      start: _quietStart,
                      end: _quietEnd,
                    );
                  },
                ),
                if (_quietHoursEnabled) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 12.0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Start Time',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  OutlinedButton.icon(
                                    onPressed: () async {
                                      final picked = await showTimePicker(
                                        context: context,
                                        initialTime: _quietStart,
                                        builder: (context, child) {
                                          return Theme(
                                            data: Theme.of(context).copyWith(
                                              timePickerTheme:
                                                  const TimePickerThemeData(
                                                    dialTextStyle: TextStyle(
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.bold,
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
                                        setState(() => _quietStart = picked);
                                        GlobalNotificationService()
                                            .setQuietHours(
                                              enabled: _quietHoursEnabled,
                                              start: picked,
                                              end: _quietEnd,
                                            );
                                      }
                                    },
                                    icon: const Icon(
                                      Icons.access_time,
                                      size: 16,
                                    ),
                                    label: Text(_formatTimeOfDay(_quietStart)),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: isDark
                                          ? AppTheme.primaryFixedDim
                                          : AppTheme.primary,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'End Time',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  OutlinedButton.icon(
                                    onPressed: () async {
                                      final picked = await showTimePicker(
                                        context: context,
                                        initialTime: _quietEnd,
                                        builder: (context, child) {
                                          return Theme(
                                            data: Theme.of(context).copyWith(
                                              timePickerTheme:
                                                  const TimePickerThemeData(
                                                    dialTextStyle: TextStyle(
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.bold,
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
                                        setState(() => _quietEnd = picked);
                                        GlobalNotificationService()
                                            .setQuietHours(
                                              enabled: _quietHoursEnabled,
                                              start: _quietStart,
                                              end: picked,
                                            );
                                      }
                                    },
                                    icon: const Icon(
                                      Icons.access_time_filled,
                                      size: 16,
                                    ),
                                    label: Text(_formatTimeOfDay(_quietEnd)),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: isDark
                                          ? AppTheme.primaryFixedDim
                                          : AppTheme.primary,
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
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryContainer.withAlpha(50),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                size: 16,
                                color: isDark
                                    ? AppTheme.primaryFixedDim
                                    : AppTheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Reminders will be muted from ${_formatTimeOfDay(_quietStart)} to ${_formatTimeOfDay(_quietEnd)}.',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark
                                        ? AppTheme.primaryFixedDim
                                        : AppTheme.primary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Cloud Storage & Backup Section
          _buildSectionHeader('Cloud Storage & Backup', textSecondary),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: (isDark
                                ? AppTheme.primaryFixedDim
                                : AppTheme.primary)
                            .withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.cloud_upload_outlined,
                        color: isDark
                            ? AppTheme.primaryFixedDim
                            : AppTheme.primary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Link to Google Drive',
                            style: TextStyle(
                              fontFamily: 'Montserrat',
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _isDriveLinked && _driveEmail != null
                                ? 'Connected: $_driveEmail'
                                : 'Backup pet photos to your personal Google Drive for cloud access across devices.',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              color: textSecondary,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (_isDriveLinked) ...[
                      ElevatedButton.icon(
                        onPressed: () async {
                          final messenger = ScaffoldMessenger.of(context);
                          final petBloc = context.read<PetBloc>();
                          final petState = petBloc.state;

                          if (petState is PetLoaded &&
                              petState.pets.isNotEmpty) {
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Syncing pet media folders to Google Drive...',
                                ),
                              ),
                            );
                            final syncedPets =
                                await GoogleDriveService.syncAllPetsToDrive(
                              petState.pets,
                            );
                            for (final updatedPet in syncedPets) {
                              petBloc.add(UpdatePet(updatedPet));
                            }
                            if (context.mounted) {
                              if (GoogleDriveService.lastErrorMessage != null) {
                                showDialog(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Google Drive API Disabled'),
                                    content: Text(
                                      GoogleDriveService.lastErrorMessage!,
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.of(ctx).pop(),
                                        child: const Text('OK'),
                                      ),
                                    ],
                                  ),
                                );
                              } else {
                                messenger.showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Media synced to Google Drive (PawsNCare_Media)!',
                                    ),
                                    backgroundColor: AppTheme.primary,
                                  ),
                                );
                              }
                            }
                          } else {
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text('No pets found to sync.'),
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.sync, size: 16),
                        label: const Text('Sync Media'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: () async {
                          await GoogleDriveService.unlinkGoogleDrive();
                          await _loadGoogleDriveStatus();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Unlinked Google Drive.'),
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.link_off, size: 16),
                        label: const Text('Unlink'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.error,
                          side: const BorderSide(color: AppTheme.error),
                        ),
                      ),
                    ] else ...[
                      ElevatedButton.icon(
                        onPressed: () async {
                          final messenger = ScaffoldMessenger.of(context);
                          final petBloc = context.read<PetBloc>();
                          final success =
                              await GoogleDriveService.linkGoogleDrive();
                          await _loadGoogleDriveStatus();

                          if (success) {
                            final petState = petBloc.state;
                            if (petState is PetLoaded &&
                                petState.pets.isNotEmpty) {
                              messenger.showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Linked! Syncing pet media folders to Google Drive...',
                                  ),
                                ),
                              );
                              final syncedPets =
                                  await GoogleDriveService.syncAllPetsToDrive(
                                petState.pets,
                              );
                              for (final updatedPet in syncedPets) {
                                petBloc.add(UpdatePet(updatedPet));
                              }
                            }
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Google Drive linked & pet folders created!',
                                ),
                                backgroundColor: AppTheme.primary,
                              ),
                            );
                          } else {
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text('Failed to link Google Drive.'),
                                backgroundColor: AppTheme.error,
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.add_to_drive, size: 16),
                        label: const Text('Link Now'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Appearance Section
          _buildSectionHeader('Appearance', textSecondary),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF383634)
                        : AppTheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    isDark ? Icons.dark_mode : Icons.light_mode,
                    color: isDark
                        ? AppTheme.primaryFixedDim
                        : AppTheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Theme',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isDark
                            ? 'Currently in Dark Mode'
                            : 'Currently in Light Mode',
                        style: TextStyle(fontSize: 12, color: textSecondary),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    context.read<ThemeCubit>().toggleTheme();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text(
                    'Switch Mode',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // App Info Section
          _buildSectionHeader('App Info', textSecondary),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                _buildInfoTile(
                  icon: Icons.help_outline,
                  title: 'Help Center',
                  trailing: Icon(
                    Icons.open_in_new,
                    size: 18,
                    color: textSecondary,
                  ),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Opening Help Center...')),
                    );
                  },
                ),
                Divider(height: 1, color: dividerColor),
                _buildInfoTile(
                  icon: Icons.verified_user_outlined,
                  title: 'Privacy Policy',
                  trailing: Icon(Icons.chevron_right, color: textSecondary),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Opening Privacy Policy...'),
                      ),
                    );
                  },
                ),
                if (isDemoModeEnabled) ...[
                  Divider(height: 1, color: dividerColor),
                  _buildInfoTile(
                    icon: Icons.science_outlined,
                    title: 'UI Testing Playground',
                    trailing: Icon(Icons.chevron_right, color: textSecondary),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const TestPlaygroundScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Logout Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                context.read<AuthBloc>().add(LogoutRequested());
              },
              icon: const Icon(Icons.logout, color: Colors.white),
              label: const Text(
                'Logout',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.tertiaryContainer,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color textColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontFamily: 'Inter',
          fontWeight: FontWeight.bold,
          fontSize: 11,
          color: textColor,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildNotificationToggle({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    required Color textColor,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      activeThumbColor: AppTheme.primary,
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 12, color: textColor),
      ),
      secondary: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: iconBg,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: iconColor),
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required Widget trailing,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.onSurfaceVariant),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
      ),
      trailing: trailing,
      onTap: onTap,
    );
  }
}
