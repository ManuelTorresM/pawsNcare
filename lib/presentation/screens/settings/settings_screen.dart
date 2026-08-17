import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../logic/auth/auth_bloc.dart';
import '../../../logic/pet/pet_bloc.dart';
import '../../../logic/diary/diary_bloc.dart';
import '../../../logic/theme/theme_cubit.dart';
import '../../../data/repositories/repository_selector.dart';
import '../../theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _activeDb = 'mock';
  bool _medsNotifications = true;
  bool _vaccinesNotifications = true;
  bool _feedingNotifications = false;

  @override
  void initState() {
    super.initState();
    _loadDbSource();
  }

  Future<void> _loadDbSource() async {
    final db = await RepositorySelector.getDbSource();
    setState(() {
      _activeDb = db;
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

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User Profile Section
          _buildSectionHeader('User Profile'),
          const SizedBox(height: 8),
          BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              String name = 'Alex Johnson';
              String email = 'alex.j@petcare.com';
              if (state is Authenticated) {
                name = state.name;
                email = state.email;
              }
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 32,
                          backgroundColor: AppTheme.primaryContainer,
                          backgroundImage: const NetworkImage(
                            'https://lh3.googleusercontent.com/aida-public/AB6AXuBVmzVQ6tXgL8wUyrhW01rg5PG8buMnmSCeWMY5Q1uxZFHHOCyaK3SQnW91Iju-_SLGZ-9CuaIGrS3Hk-0dnEQhbAOyfT_wpUfVn74Vd1plaCxaNvuu9qBmlt-96BkGXCYnXvaT9O2WnRIPn90-pPE4vXP9wnRt5UXGlwTyTOLwu7B9LrGZG0-mAunb-B-ZZJshFbabnpKyiLiXFpU7uyIJoqkJJSOLAL60eu-0kC_dKa2bZG8rLZkb_qUQkB8WkVKomI0nv9xMm4o',
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
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppTheme.secondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: AppTheme.secondary),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 24),

          // Database Storage Section
          _buildSectionHeader('Database Storage'),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16),
            ),
            child: RadioGroup<String>(
              groupValue: _activeDb,
              onChanged: _toggleDbSource,
              child: Column(
                children: [
                  RadioListTile<String>(
                    title: const Text('Mock Database (Local Persistence)'),
                    subtitle: const Text(
                      'Runs instantly without credentials.',
                      style: TextStyle(fontSize: 12),
                    ),
                    value: 'mock',
                    activeColor: AppTheme.primary,
                  ),
                  const Divider(height: 1, color: AppTheme.surfaceContainer),
                  RadioListTile<String>(
                    title: const Text('Firebase Firestore Database'),
                    subtitle: const Text(
                      'Connects to real cloud services.',
                      style: TextStyle(fontSize: 12),
                    ),
                    value: 'firebase',
                    activeColor: AppTheme.primary,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Notifications Toggles Section
          _buildSectionHeader('Notifications'),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                _buildNotificationToggle(
                  icon: Icons.medical_services,
                  iconBg: AppTheme.tertiaryFixed,
                  iconColor: AppTheme.onTertiaryFixedVariant,
                  title: 'Medications',
                  subtitle: 'Daily reminders for dosages',
                  value: _medsNotifications,
                  onChanged: (val) {
                    setState(() => _medsNotifications = val);
                  },
                ),
                const Divider(height: 1, color: AppTheme.surfaceContainer),
                _buildNotificationToggle(
                  icon: Icons.vaccines,
                  iconBg: AppTheme.primaryFixed,
                  iconColor: AppTheme.onPrimaryFixed,
                  title: 'Vaccinations',
                  subtitle: 'Upcoming appointment alerts',
                  value: _vaccinesNotifications,
                  onChanged: (val) {
                    setState(() => _vaccinesNotifications = val);
                  },
                ),
                const Divider(height: 1, color: AppTheme.surfaceContainer),
                _buildNotificationToggle(
                  icon: Icons.restaurant,
                  iconBg: AppTheme.secondaryContainer,
                  iconColor: AppTheme.secondary,
                  title: 'Feeding Times',
                  subtitle: 'Scheduled meal notifications',
                  value: _feedingNotifications,
                  onChanged: (val) {
                    setState(() => _feedingNotifications = val);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Appearance Section
          _buildSectionHeader('Appearance'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    isDark ? Icons.dark_mode : Icons.light_mode,
                    color: AppTheme.onSurfaceVariant,
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
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.secondary,
                        ),
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
          _buildSectionHeader('App Info'),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                _buildInfoTile(
                  icon: Icons.help_outline,
                  title: 'Help Center',
                  trailing: const Icon(
                    Icons.open_in_new,
                    size: 18,
                    color: AppTheme.secondary,
                  ),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Opening Help Center...')),
                    );
                  },
                ),
                const Divider(height: 1, color: AppTheme.surfaceContainer),
                _buildInfoTile(
                  icon: Icons.verified_user_outlined,
                  title: 'Privacy Policy',
                  trailing: const Icon(
                    Icons.chevron_right,
                    color: AppTheme.secondary,
                  ),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Opening Privacy Policy...'),
                      ),
                    );
                  },
                ),
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

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontFamily: 'Inter',
          fontWeight: FontWeight.bold,
          fontSize: 11,
          color: AppTheme.secondary,
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
        style: const TextStyle(fontSize: 12, color: AppTheme.secondary),
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
