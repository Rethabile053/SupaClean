import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../views/notification_center_screen.dart';
import '../views/search_screen.dart';
import 'back_circle_button.dart';

/// The app bar used by every screen, styled after the Profile screen.
/// It always ends with the notification bell.
class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  const AppHeader({
    super.key,
    required this.title,
    this.showBack = true,
    this.showNotifications = true,
    this.showSearch = true,
    this.actions = const [],
  });

  final String title;

  /// False only on Home. On the other tabs the arrow returns to Home
  /// (see MainShell); on pushed screens it goes back one screen.
  final bool showBack;

  /// False only on the Notification Center page itself.
  final bool showNotifications;

  /// The magnifier before the bell. False only on the Search page itself.
  final bool showSearch;

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

  void _openSearch(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SearchScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: const Color(0xFFF8FBFC),
      elevation: 0,
      scrolledUnderElevation: 0,
      automaticallyImplyLeading: false,
      leading: showBack ? const BackCircleButton() : null,
      title: Text(
        title,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Colors.black,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: [
        if (showSearch)
          IconButton(
            tooltip: 'Search',
            icon: const Icon(
              Icons.search,
              color: AppColors.primary,
            ),
            onPressed: () => _openSearch(context),
          ),
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
