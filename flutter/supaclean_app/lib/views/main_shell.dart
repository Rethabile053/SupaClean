
import 'package:flutter/material.dart';

import '../services/push_notification_service.dart';
import '../widgets/app_bottom_nav.dart';
import 'home_screen.dart';
import 'my_orders_screen.dart';
import 'profile_screen.dart';
import 'schedule_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({
    super.key,
    this.initialIndex = 0,
  });

  final int initialIndex;

  static const int homeTab = 0;
  static const int ordersTab = 1;
  static const int scheduleTab = 2;
  static const int profileTab = 3;

  // Switch tabs when this screen is inside MainShell.
  // If it is a separate route, open MainShell at the requested tab.
  static void switchTab(BuildContext context, int index) {
    if (index < homeTab || index > profileTab) return;

    final shellState =
        context.findAncestorStateOfType<_MainShellState>();

    if (shellState != null) {
      shellState._select(index);
      return;
    }

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(
        builder: (_) => MainShell(initialIndex: index),
      ),
      (route) => false,
    );
  }

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  late int _index = widget.initialIndex;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        PushNotificationService.instance.registerDevice();
      }
    });
  }

  void _select(int index) {
    if (index < MainShell.homeTab ||
        index > MainShell.profileTab) {
      return;
    }

    if (_index != index) {
      setState(() {
        _index = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _index == MainShell.homeTab,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _index != MainShell.homeTab) {
          _select(MainShell.homeTab);
        }
      },
      child: Scaffold(
        body: IndexedStack(
          index: _index,
          children: const [
            HomeScreen(),
            MyOrdersScreen(),
            ScheduleScreen(),
            ProfileScreen(),
          ],
        ),
        bottomNavigationBar: AppBottomNav(
          selectedIndex: _index,
          onTap: _select,
        ),
      ),
    );
  }
}

// Bottom navigation for screens that are outside MainShell.
class FlowBottomNav extends StatelessWidget {
  const FlowBottomNav({
    super.key,
    this.selected = MainShell.homeTab,
  });

  final int selected;

  @override
  Widget build(BuildContext context) {
    return AppBottomNav(
      selectedIndex: selected,
      onTap: (index) => MainShell.switchTab(context, index),
    );
  }
}
