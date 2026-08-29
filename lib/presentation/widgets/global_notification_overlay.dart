import 'dart:async';
import 'package:flutter/material.dart';
import '../../data/models/app_notification.dart';
import '../../logic/notifications/global_notification_service.dart';
import '../theme/app_theme.dart';

class GlobalNotificationOverlay extends StatefulWidget {
  final Widget child;

  const GlobalNotificationOverlay({super.key, required this.child});

  @override
  State<GlobalNotificationOverlay> createState() =>
      _GlobalNotificationOverlayState();
}

class _GlobalNotificationOverlayState
    extends State<GlobalNotificationOverlay> with SingleTickerProviderStateMixin {
  late StreamSubscription<AppNotification> _subscription;
  late AnimationController _animController;
  late Animation<Offset> _offsetAnimation;

  AppNotification? _currentNotification;
  Timer? _dismissTimer;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0, -1.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutBack,
    ));

    _subscription = GlobalNotificationService().bannerStream.listen(_showBanner);
  }

  void _showBanner(AppNotification notification) {
    _dismissTimer?.cancel();
    setState(() {
      _currentNotification = notification;
    });

    _animController.forward();

    _dismissTimer = Timer(const Duration(milliseconds: 4500), () {
      _dismissBanner();
    });
  }

  void _dismissBanner() {
    _animController.reverse().then((_) {
      if (mounted) {
        setState(() {
          _currentNotification = null;
        });
      }
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    _dismissTimer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notif = _currentNotification;

    return Stack(
      children: [
        widget.child,

        if (notif != null)
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 16,
            right: 16,
            child: SlideTransition(
              position: _offsetAnimation,
              child: Material(
                color: Colors.transparent,
                elevation: 10,
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceContainerLowest.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: AppTheme.primary.withValues(alpha: 0.4),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.primary,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _getIcon(notif.category),
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              notif.title,
                              style: const TextStyle(
                                fontFamily: 'Montserrat',
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: AppTheme.primary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              notif.body,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 12,
                                color: AppTheme.onSurfaceVariant,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(
                          Icons.close,
                          size: 18,
                          color: AppTheme.secondary,
                        ),
                        onPressed: _dismissBanner,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  IconData _getIcon(NotificationCategory cat) {
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
        return Icons.notifications_active;
    }
  }
}
