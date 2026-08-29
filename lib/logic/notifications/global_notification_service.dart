import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
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

      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
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

      final androidPlugin =
          _localNotifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

      if (androidPlugin != null) {
        await androidPlugin.requestNotificationsPermission();
        await androidPlugin.requestExactAlarmsPermission();
      }

      _isInitialized = true;
    } catch (e) {
      debugPrint('[GlobalNotificationService] Error initializing notifications: $e');
    }
  }

  void setQuietHours({
    required bool enabled,
    required TimeOfDay start,
    required TimeOfDay end,
  }) {
    quietHoursEnabled = enabled;
    quietStart = start;
    quietEnd = end;
    notifyListeners();
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
      await _localNotifications.show(
        notifId,
        notif.title,
        notif.body,
        details,
      );
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
        // Check if next dose is due within current window
        final diffInMinutes = med.nextDoseDate.difference(now).inMinutes;
        if (diffInMinutes >= -15 && diffInMinutes <= 15) {
          final isVaccine = med.type == 'vaccine';
          final notifId = 'event_${pet.id}_${med.id}_${med.nextDoseDate.day}';

          final alreadyFired = _notifications.any((n) => n.id == notifId);
          if (!alreadyFired) {
            triggerNotification(
              title: isVaccine
                  ? 'Booster Due: ${med.name}'
                  : 'Medication Due: ${med.name}',
              body: isVaccine
                  ? 'Scheduled booster for ${pet.name}.'
                  : 'Dose: ${med.dose.isNotEmpty ? med.dose : '1 Tablet'} for ${pet.name}.',
              category: isVaccine
                  ? NotificationCategory.vaccine
                  : NotificationCategory.medication,
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
