import 'package:flutter/material.dart';
import '../widgets/app_bottom_nav.dart';
import 'home_screen.dart';
import 'my_orders_screen.dart';
import 'profile_screen.dart';
import 'schedule_screen.dart';

/// Holds the four main tabs behind one bottom navigation bar.
/// Login, signup and splash all land here; screens in the order flow
/// (services, details, date/time, payment) open on top of it.
class MainShell extends StatefulWidget {
  const MainShell({super.key, this.initialIndex = 0});

  final int initialIndex;

  static const homeTab = 0;
  static const ordersTab = 1;
  static const scheduleTab = 2;
  static const profileTab = 3;

  /// Switches tab from any screen inside the shell.
  static void switchTab(BuildContext context, int index) {
    context.findAncestorStateOfType<_MainShellState>()?._select(index);
  }

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  late int _index = widget.initialIndex;

  void _select(int index) {
    if (index != _index) setState(() => _index = index);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Back from another tab returns to Home before leaving the app.
      canPop: _index == MainShell.homeTab,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _select(MainShell.homeTab);
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
