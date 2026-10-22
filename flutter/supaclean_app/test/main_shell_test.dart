import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
// ignore: depend_on_referenced_packages
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:supaclean/viewmodels/auth_viewmodel.dart';
import 'package:supaclean/views/main_shell.dart';
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
    expect(find.byIcon(Icons.settings_outlined), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back), findsNothing);

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

  testWidgets('system back from another tab returns to Home', (tester) async {
    await pumpShell(tester);

    await tester.tap(navItem('Orders'));
    await tester.pump();
    await tester.binding.handlePopRoute();
    await tester.pump();

    expect(find.text('Quick Actions'), findsOneWidget);
  });
}
