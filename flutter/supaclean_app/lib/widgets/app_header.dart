import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../core/constants.dart';
import '../views/notification_center_screen.dart';

/// The app bar used by every screen, styled after the Profile screen.
/// It always ends with the notification bell.
class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  const AppHeader({
    super.key,
    required this.title,
    this.showBack = true,
    this.showNotifications = true,
    this.actions = const [],
  });

  final String title;

  /// False only on Home. On the other tabs the arrow returns to Home
  /// (see MainShell); on pushed screens it goes back one screen.
  final bool showBack;

  /// False only on the Notification Center page itself.
  final bool showNotifications;

  /// Extra buttons shown after the notification bell.
  final List<Widget> actions;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  void _openNotifications(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NotificationCenterScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.canvas,
      elevation: 0,
      scrolledUnderElevation: 0,
      automaticallyImplyLeading: false,
      leading: showBack
          ? Center(
              child: Material(
                color: const Color(0xFFFFEBEE),
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => Navigator.maybePop(context),
                  child: const SizedBox(
                    width: 40,
                    height: 40,
                    child: Icon(
                      Icons.arrow_back,
                      color: AppColors.primary,
                      size: 22,
                    ),
                  ),
                ),
              ),
            )
          : null,
      title: Text(
        title,
        overflow: TextOverflow.ellipsis,
        style: AppText.title,
      ),
      actions: [
        if (showNotifications)
          IconButton(
            tooltip: 'Notifications',
            icon: const Icon(
              Icons.notifications_none_outlined,
              color: AppColors.primary,
            ),
            onPressed: () => _openNotifications(context),
          ),
        ...actions,
      ],
    );
  }
}
