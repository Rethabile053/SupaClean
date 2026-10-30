import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supaclean/models/app_notification.dart';
import 'package:supaclean/models/laundry_order.dart';
import 'package:supaclean/views/search_screen.dart';
import 'package:supaclean/widgets/empty_state.dart';

/// A small phone with the on-screen keyboard open, like the Samsung A3.
Future<void> openOnSmallPhone(WidgetTester tester) async {
  tester.view.physicalSize = const Size(720, 1280); // 360 x 640 logical
  tester.view.devicePixelRatio = 2;
  // The keyboard takes roughly the bottom 40% of the screen.
  tester.view.viewInsets = const FakeViewPadding(bottom: 520);
  addTearDown(tester.view.reset);

  await tester.pumpWidget(MaterialApp(
    home: SearchScreen(
      loadOrders: () async => <LaundryOrder>[],
      loadNotifications: () async => <AppNotification>[],
    ),
  ));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('the hint does not overflow with the keyboard open',
      (tester) async {
    await openOnSmallPhone(tester);

    expect(find.text('Search SupaClean'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('"Nothing found" does not overflow with the keyboard open',
      (tester) async {
    await openOnSmallPhone(tester);

    await tester.enterText(find.byType(TextField), 'qqqq');
    await tester.pumpAndSettle();

    expect(find.text('Nothing found'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('an empty state still sits in the middle when there is room',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: EmptyState(icon: Icons.search, title: 'Title', message: 'Message'),
      ),
    ));

    final centre = tester.getCenter(find.text('Title'));
    expect(centre.dx, closeTo(200, 1)); // middle of 400 logical width
    expect(centre.dy, greaterThan(250)); // vertically around the middle, not the top
    expect(tester.takeException(), isNull);
  });

  testWidgets('a short empty state can be scrolled to see all of it',
      (tester) async {
    tester.view.physicalSize = const Size(720, 400); // very short
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: EmptyState(
          icon: Icons.search,
          title: 'Title',
          message: 'A longer message that wraps over a few lines on a small screen.',
          actionLabel: 'Try again',
          onAction: _noop,
        ),
      ),
    ));

    expect(tester.takeException(), isNull);
    await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -300));
    await tester.pump();
    expect(find.text('Try again'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

void _noop() {}
