import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/app_notification.dart';
import '../../data/models/pet.dart';
import '../../presentation/theme/app_theme.dart';

class GlobalNotificationService extends ChangeNotifier {
  static final GlobalNotificationService _instance =
      GlobalNotificationService._internal();

  factory GlobalNotificationService() => _instance;

  GlobalNotificationService._internal();

  final List<AppNotification> _notifications = [];
  final _bannerStreamController = StreamController<AppNotification>.broadcast();

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  bool medsNotificationsEnabled = true;
  bool vaccinesNotificationsEnabled = true;
  bool feedingNotificationsEnabled = true;

  bool quietHoursEnabled = true;
  TimeOfDay quietStart = const TimeOfDay(hour: 22, minute: 0); // 10:00 PM
  TimeOfDay quietEnd = const TimeOfDay(hour: 7, minute: 0); // 07:00 AM

  List<AppNotification> get notifications => List.unmodifiable(_notifications);
  Stream<AppNotification> get bannerStream => _bannerStreamController.stream;

  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  Future<void> init() async {
    if (_isInitialized) return;

    try {
      tz.initializeTimeZones();

      const androidSettings = AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      );
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _localNotifications.initialize(initSettings);

      final androidPlugin = _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

      if (androidPlugin != null) {
        await androidPlugin.requestNotificationsPermission();
        await androidPlugin.requestExactAlarmsPermission();
      }

      await _loadPreferences();
      _isInitialized = true;
    } catch (e) {
      debugPrint(
        '[GlobalNotificationService] Error initializing notifications: $e',
      );
    }
  }

  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      medsNotificationsEnabled = prefs.getBool('notif_meds_enabled') ?? true;
      vaccinesNotificationsEnabled =
          prefs.getBool('notif_vaccines_enabled') ?? true;
      feedingNotificationsEnabled =
          prefs.getBool('notif_feeding_enabled') ?? true;
      quietHoursEnabled = prefs.getBool('notif_quiet_hours_enabled') ?? true;

      final quietStartHour = prefs.getInt('notif_quiet_start_hour') ?? 22;
      final quietStartMin = prefs.getInt('notif_quiet_start_min') ?? 0;
      final quietEndHour = prefs.getInt('notif_quiet_end_hour') ?? 7;
      final quietEndMin = prefs.getInt('notif_quiet_end_min') ?? 0;

      quietStart = TimeOfDay(hour: quietStartHour, minute: quietStartMin);
      quietEnd = TimeOfDay(hour: quietEndHour, minute: quietEndMin);

      notifyListeners();
    } catch (e) {
      debugPrint('[GlobalNotificationService] Error loading preferences: $e');
    }
  }

  bool isCategoryEnabled(NotificationCategory category) {
    switch (category) {
      case NotificationCategory.medication:
        return medsNotificationsEnabled;
      case NotificationCategory.vaccine:
        return vaccinesNotificationsEnabled;
      case NotificationCategory.feeding:
        return feedingNotificationsEnabled;
      default:
        return true;
    }
  }

  Future<void> setCategoryEnabled(
    NotificationCategory category,
    bool enabled,
  ) async {
    switch (category) {
      case NotificationCategory.medication:
        medsNotificationsEnabled = enabled;
        break;
      case NotificationCategory.vaccine:
        vaccinesNotificationsEnabled = enabled;
        break;
      case NotificationCategory.feeding:
        feedingNotificationsEnabled = enabled;
        break;
      default:
        break;
    }
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      if (category == NotificationCategory.medication) {
        await prefs.setBool('notif_meds_enabled', enabled);
      } else if (category == NotificationCategory.vaccine) {
        await prefs.setBool('notif_vaccines_enabled', enabled);
      } else if (category == NotificationCategory.feeding) {
        await prefs.setBool('notif_feeding_enabled', enabled);
      }
    } catch (e) {
      debugPrint(
        '[GlobalNotificationService] Error saving category preference: $e',
      );
    }
  }

  Future<void> setQuietHours({
    required bool enabled,
    required TimeOfDay start,
    required TimeOfDay end,
  }) async {
    quietHoursEnabled = enabled;
    quietStart = start;
    quietEnd = end;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('notif_quiet_hours_enabled', enabled);
      await prefs.setInt('notif_quiet_start_hour', start.hour);
      await prefs.setInt('notif_quiet_start_min', start.minute);
      await prefs.setInt('notif_quiet_end_hour', end.hour);
      await prefs.setInt('notif_quiet_end_min', end.minute);
    } catch (e) {
      debugPrint(
        '[GlobalNotificationService] Error saving quiet hours preference: $e',
      );
    }
  }

  bool isQuietHoursActive([DateTime? target]) {
    if (!quietHoursEnabled) return false;

    final dt = target ?? DateTime.now();
    final nowMinutes = dt.hour * 60 + dt.minute;
    final startMinutes = quietStart.hour * 60 + quietStart.minute;
    final endMinutes = quietEnd.hour * 60 + quietEnd.minute;

    if (startMinutes > endMinutes) {
      // Overnight quiet period, e.g. 22:00 to 07:00
      return nowMinutes >= startMinutes || nowMinutes < endMinutes;
    } else if (startMinutes < endMinutes) {
      // Daytime quiet period, e.g. 13:00 to 15:00
      return nowMinutes >= startMinutes && nowMinutes < endMinutes;
    } else {
      return true;
    }
  }

  void triggerNotification({
    required String title,
    required String body,
    required NotificationCategory category,
    String petName = '',
    String petAvatarUrl = '',
  }) {
    if (!isCategoryEnabled(category)) {
      debugPrint(
        '[GlobalNotificationService] Suppressed notification for $category (disabled in settings)',
      );
      return;
    }
    final notification = AppNotification(
      id: 'notif_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      body: body,
      petName: petName,
      petAvatarUrl: petAvatarUrl,
      category: category,
      timestamp: DateTime.now(),
      isRead: false,
    );

    _notifications.insert(0, notification);

    // 1. Emit native OS status bar notification
    _showNativeNotification(notification);

    // 2. Emit in-app banner overlay if NOT in Quiet Hours
    if (!isQuietHoursActive()) {
      _bannerStreamController.add(notification);
    }

    notifyListeners();
  }

  void scheduleCustomEventNotification({
    required String title,
    required String body,
    required DateTime eventDateTime,
    required Duration reminderOffset,
    String petName = '',
    String petAvatarUrl = '',
    NotificationCategory category = NotificationCategory.medication,
  }) {
    final notifyAt = eventDateTime.subtract(reminderOffset);
    final delay = notifyAt.difference(DateTime.now());

    // Immediate notification confirming event reminder has been scheduled
    triggerNotification(
      title: 'Event Scheduled: $title',
      body:
          'Reminder configured for ${petName.isNotEmpty ? petName : 'all pets'}.',
      category: category,
      petName: petName,
      petAvatarUrl: petAvatarUrl,
    );

    if (!delay.isNegative && delay.inSeconds > 5) {
      Timer(delay, () {
        triggerNotification(
          title: 'Upcoming Event: $title',
          body: body,
          category: category,
          petName: petName,
          petAvatarUrl: petAvatarUrl,
        );
      });
    }
  }

  Future<void> _showNativeNotification(AppNotification notif) async {
    try {
      const androidDetails = AndroidNotificationDetails(
        'paws_n_care_channel',
        'Paws & Care Notifications',
        channelDescription: 'Notifications for pet care, meds, and vaccines',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: true,
      );
      const iosDetails = DarwinNotificationDetails();
      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      final notifId = DateTime.now().millisecondsSinceEpoch.remainder(100000);
      await _localNotifications.show(notifId, notif.title, notif.body, details);
    } catch (e) {
      debugPrint('[GlobalNotificationService] Native notification error: $e');
    }
  }

  void markAsRead(String id) {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index >= 0) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      notifyListeners();
    }
  }

  void markAllAsRead() {
    for (int i = 0; i < _notifications.length; i++) {
      _notifications[i] = _notifications[i].copyWith(isRead: true);
    }
    notifyListeners();
  }

  void clearAll() {
    _notifications.clear();
    notifyListeners();
  }

  void syncPetEvents(List<Pet> pets) {
    final now = DateTime.now();

    for (final pet in pets) {
      for (final med in pet.medications) {
        // Check if next dose/event is due within current window
        final diffInMinutes = med.nextDoseDate.difference(now).inMinutes;
        if (diffInMinutes >= -15 && diffInMinutes <= 15) {
          final type = med.type.toLowerCase();
          final String title;
          final String body;
          final NotificationCategory category;

          if (type == 'vaccine') {
            title = 'Booster Due: ${med.name}';
            body = 'Scheduled vaccine booster for ${pet.name}.';
            category = NotificationCategory.vaccine;
          } else if (type == 'medication') {
            title = 'Medication Due: ${med.name}';
            body =
                'Dose: ${med.dose.isNotEmpty ? med.dose : '1 Tablet'} for ${pet.name}.';
            category = NotificationCategory.medication;
          } else if (type == 'feeding') {
            title = 'Feeding Due: ${med.name}';
            body = med.dose.isNotEmpty
                ? med.dose
                : 'Meal time for ${pet.name}.';
            category = NotificationCategory.feeding;
          } else if (type == 'hydration') {
            title = 'Hydration Reminder: ${med.name}';
            body = med.dose.isNotEmpty
                ? med.dose
                : 'Fresh water reminder for ${pet.name}.';
            category = NotificationCategory.hydration;
          } else if (type == 'appointment' || type == 'vet') {
            title = 'Vet Appointment: ${med.name}';
            body = med.dose.isNotEmpty
                ? med.dose
                : 'Scheduled vet visit for ${pet.name}.';
            category = NotificationCategory.system;
          } else if (type == 'grooming') {
            title = 'Grooming Care: ${med.name}';
            body = med.dose.isNotEmpty
                ? med.dose
                : 'Grooming session for ${pet.name}.';
            category = NotificationCategory.system;
          } else {
            title = 'Calendar Reminder: ${med.name}';
            body = med.dose.isNotEmpty
                ? med.dose
                : 'Upcoming event for ${pet.name}.';
            category = NotificationCategory.system;
          }

          final notifId = 'event_${pet.id}_${med.id}_${med.nextDoseDate.day}';

          final alreadyFired = _notifications.any((n) => n.id == notifId);
          if (!alreadyFired) {
            triggerNotification(
              title: title,
              body: body,
              category: category,
              petName: pet.name,
              petAvatarUrl: pet.avatarUrl,
            );
          }
        }
      }
    }
  }

  void showNotificationCenter(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final cardBg = isDark
                ? AppTheme.darkSurface
                : AppTheme.surfaceContainerLowest;

            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  // Header Bar
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Row(
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
                              child: const Icon(
                                Icons.notifications_active,
                                color: AppTheme.primary,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Notifications Center',
                              style: TextStyle(
                                fontFamily: 'Montserrat',
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                        if (_notifications.isNotEmpty)
                          TextButton(
                            onPressed: () {
                              markAllAsRead();
                              setModalState(() {});
                            },
                            child: const Text('Mark All Read'),
                          ),
                      ],
                    ),
                  ),
                  if (quietHoursEnabled)
                    Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 4,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isQuietHoursActive()
                            ? AppTheme.tertiary.withValues(alpha: 0.15)
                            : AppTheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isQuietHoursActive()
                              ? AppTheme.tertiary.withValues(alpha: 0.5)
                              : AppTheme.surfaceContainer,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isQuietHoursActive()
                                ? Icons.do_not_disturb_on
                                : Icons.bedtime_outlined,
                            size: 16,
                            color: isQuietHoursActive()
                                ? AppTheme.tertiary
                                : AppTheme.secondary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              isQuietHoursActive()
                                  ? 'Quiet Hours Active (${_formatTimeOfDay(quietStart)} - ${_formatTimeOfDay(quietEnd)}). Banners silenced.'
                                  : 'Quiet Hours Set (${_formatTimeOfDay(quietStart)} - ${_formatTimeOfDay(quietEnd)}).',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 11,
                                fontWeight: isQuietHoursActive()
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: isQuietHoursActive()
                                    ? AppTheme.tertiary
                                    : AppTheme.secondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const Divider(height: 16),

                  // Notifications List
                  Expanded(
                    child: _notifications.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(
                                  Icons.notifications_off_outlined,
                                  size: 48,
                                  color: AppTheme.secondary,
                                ),
                                SizedBox(height: 12),
                                Text(
                                  'No new notifications',
                                  style: TextStyle(
                                    fontFamily: 'Montserrat',
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.secondary,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: _notifications.length,
                            separatorBuilder: (ctx, idx) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final item = _notifications[index];
                              return Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: item.isRead
                                      ? AppTheme.surfaceContainerLow
                                      : AppTheme.primaryFixed.withValues(
                                          alpha: 0.15,
                                        ),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: item.isRead
                                        ? AppTheme.surfaceContainer
                                        : AppTheme.primary.withValues(
                                            alpha: 0.4,
                                          ),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: AppTheme.primary,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        _getCategoryIcon(item.category),
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                item.title,
                                                style: const TextStyle(
                                                  fontFamily: 'Montserrat',
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                ),
                                              ),
                                              Text(
                                                _formatTimestamp(
                                                  item.timestamp,
                                                ),
                                                style: const TextStyle(
                                                  fontFamily: 'Inter',
                                                  fontSize: 10,
                                                  color: AppTheme.secondary,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            item.body,
                                            style: const TextStyle(
                                              fontFamily: 'Inter',
                                              fontSize: 12,
                                              color: AppTheme.onSurfaceVariant,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  IconData _getCategoryIcon(NotificationCategory cat) {
    switch (cat) {
      case NotificationCategory.medication:
        return Icons.medication;
      case NotificationCategory.vaccine:
        return Icons.vaccines;
      case NotificationCategory.feeding:
        return Icons.restaurant;
      case NotificationCategory.hydration:
        return Icons.water_drop;
      case NotificationCategory.system:
        return Icons.notifications;
    }
  }

  String _formatTimestamp(DateTime dt) {
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final min = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$min $period';
  }

  String _formatTimeOfDay(TimeOfDay tod) {
    final hour = tod.hourOfPeriod == 0 ? 12 : tod.hourOfPeriod;
    final minute = tod.minute.toString().padLeft(2, '0');
    final period = tod.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  @override
  void dispose() {
    _bannerStreamController.close();
    super.dispose();
  }
}
