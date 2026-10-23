import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supaclean/views/detailed_services_screen.dart';
import 'package:supaclean/views/place_order_screen.dart';

void main() {
  Future<void> pumpDetails(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(home: DetailedServicesScreen(category: 'Wash & Fold')),
    );
  }

  testWidgets('Place Order asks to tick an item first', (tester) async {
    await pumpDetails(tester);

    await tester.tap(find.text('Place Order'));
    await tester.pump();

    expect(find.text('Please tick at least one item.'), findsOneWidget);
    expect(find.byType(PlaceOrderScreen), findsNothing);
  });

  testWidgets('ticking and unticking updates the button count',
      (tester) async {
    await pumpDetails(tester);

    await tester.tap(find.text('Laundry per kg'));
    await tester.tap(find.text('Shorts'));
    await tester.pump();
    expect(find.text('Place Order (2)'), findsOneWidget);

    await tester.tap(find.text('Shorts'));
    await tester.pump();
    expect(find.text('Place Order (1)'), findsOneWidget);

    await tester.tap(find.text('Laundry per kg'));
    await tester.pump();
    expect(find.text('Place Order'), findsOneWidget);
  });

  testWidgets('ticked items arrive on Place Order with the right subtotal',
      (tester) async {
    await pumpDetails(tester);

    await tester.tap(find.text('Laundry per kg'));
    await tester.tap(find.text('Shorts'));
    await tester.pump();
    await tester.tap(find.text('Place Order (2)'));
    await tester.pumpAndSettle();

    expect(find.byType(PlaceOrderScreen), findsOneWidget);
    // Laundry per kg R42.00 + Shorts R28.90, one of each to start.
    expect(find.text('Laundry per kg'), findsWidgets);
    expect(find.text('Shorts'), findsWidgets);
    expect(find.text('R70.90'), findsWidgets);
  });
}
