import 'package:flutter/material.dart';
import '../core/constants.dart';

/// The app bar used by every screen, styled after the Profile screen.
/// It always ends with the notification bell.
class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  const AppHeader({
    super.key,
    required this.title,
    this.showBack = true,
    this.actions = const [],
  });

  final String title;

  /// False only on Home. On the other tabs the arrow returns to Home
  /// (see MainShell); on pushed screens it goes back one screen.
  final bool showBack;

  /// Extra buttons shown after the notification bell.
  final List<Widget> actions;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  void _openNotifications(BuildContext context) {
    // TODO: open the notifications screen.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Notifications coming soon')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: const Color(0xFFF8FBFC),
      elevation: 0,
      scrolledUnderElevation: 0,
      automaticallyImplyLeading: false,
      leading: showBack
          ? IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.primary),
              onPressed: () => Navigator.maybePop(context),
            )
          : null,
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
