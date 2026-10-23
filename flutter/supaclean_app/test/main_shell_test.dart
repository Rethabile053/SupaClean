import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
// ignore: depend_on_referenced_packages
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:supaclean/viewmodels/auth_viewmodel.dart';
import 'package:supaclean/views/main_shell.dart';
import 'package:supaclean/views/notification_center_screen.dart';
import 'package:supaclean/widgets/app_header.dart';
import 'package:supaclean/widgets/app_bottom_nav.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'https://example.supabase.co',
      // ignore: deprecated_member_use
      anonKey: 'test-key',
      authOptions: const FlutterAuthClientOptions(
        localStorage: EmptyLocalStorage(),
        autoRefreshToken: false,
      ),
    );
  });

  Future<void> pumpShell(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AuthViewModel(),
        child: const MaterialApp(home: MainShell()),
      ),
    );
  }

  Finder navItem(String label) => find.descendant(
        of: find.byType(AppBottomNav),
        matching: find.text(label),
      );

  testWidgets('one bottom bar switches between the four tabs', (tester) async {
    await pumpShell(tester);

    expect(find.byType(AppBottomNav), findsOneWidget);
    expect(find.text('Quick Actions'), findsOneWidget);

    await tester.tap(navItem('Orders'));
    await tester.pump();
    expect(find.text('Order #1024'), findsOneWidget);
    expect(find.text('Quick Actions'), findsNothing);

    await tester.tap(navItem('Schedule'));
    await tester.pump();
    expect(find.text('Your upcoming pickups and deliveries.'), findsOneWidget);
    expect(find.text('Wash & Fold'), findsOneWidget);

    await tester.tap(navItem('Profile'));
    await tester.pump();
    expect(find.byIcon(Icons.settings_outlined), findsNothing);
    expect(find.text('Help & Support'), findsNothing);

    await tester.tap(navItem('Home'));
    await tester.pump();
    expect(find.text('Quick Actions'), findsOneWidget);
  });

  testWidgets('Home quick actions switch tab inside the shell',
      (tester) async {
    await pumpShell(tester);

    await tester.tap(find.text('My Orders'));
    await tester.pump();
    expect(find.text('Order #1024'), findsOneWidget);

    await tester.tap(navItem('Home'));
    await tester.pump();
    await tester.tap(find.text('Schedule').first);
    await tester.pump();
    expect(find.text('Your upcoming pickups and deliveries.'), findsOneWidget);
  });

  testWidgets('every tab shows the shared header with a notification bell',
      (tester) async {
    await pumpShell(tester);

    for (final label in ['Home', 'Orders', 'Schedule', 'Profile']) {
      await tester.tap(navItem(label));
      await tester.pump();
      expect(find.byType(AppHeader), findsOneWidget, reason: label);
      expect(find.byIcon(Icons.notifications_none_outlined), findsOneWidget,
          reason: label);
      // Every tab has the back arrow except Home.
      expect(
        find.byIcon(Icons.arrow_back),
        label == 'Home' ? findsNothing : findsOneWidget,
        reason: label,
      );
    }

    // The arrow on another tab returns to Home.
    await tester.tap(navItem('Orders'));
    await tester.pump();
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pump();
    expect(find.text('Quick Actions'), findsOneWidget);
    await tester.tap(navItem('Profile'));
    await tester.pump();
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pump();
    expect(find.text('Quick Actions'), findsOneWidget);

  });

  testWidgets('the bell opens the Notification Center and back returns',
      (tester) async {
    await pumpShell(tester);

    await tester.tap(find.byIcon(Icons.notifications_none_outlined));
    await tester.pumpAndSettle();
    expect(find.byType(NotificationCenterScreen), findsOneWidget);
    // No server in tests, so nothing is made up: just the empty state.
    expect(find.text('No notifications yet'), findsOneWidget);
    expect(find.text('Your order #1024 is now in cleaning'), findsNothing);
    // No second bell on the page itself.
    expect(find.byTooltip('Notifications'), findsNothing);
    expect(find.byIcon(Icons.arrow_back), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    expect(find.byType(NotificationCenterScreen), findsNothing);
    expect(find.text('Quick Actions'), findsOneWidget);
  });

  testWidgets('screens opened from a tab have a back arrow and the bell',
      (tester) async {
    await pumpShell(tester);

    await tester.tap(find.text('See All'));
    await tester.pumpAndSettle();
    expect(find.text('Our Services'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    expect(find.byIcon(Icons.notifications_none_outlined), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    expect(find.text('Quick Actions'), findsOneWidget);
  });

  testWidgets('system back from another tab returns to Home', (tester) async {
    await pumpShell(tester);

    await tester.tap(navItem('Orders'));
    await tester.pump();
    await tester.binding.handlePopRoute();
    await tester.pump();

    expect(find.text('Quick Actions'), findsOneWidget);
  });
}
