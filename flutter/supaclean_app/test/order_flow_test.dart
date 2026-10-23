import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supaclean/views/detailed_services_screen.dart';
import 'package:supaclean/views/place_order_screen.dart';
import 'package:supaclean/widgets/primary_button.dart';

void main() {
  Future<void> pumpDetails(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(home: DetailedServicesScreen(category: 'Wash & Fold')),
    );
  }

  PrimaryButton placeOrderButton(WidgetTester tester) =>
      tester.widget<PrimaryButton>(find.byType(PrimaryButton));

  testWidgets('Place order stays disabled until something is ticked',
      (tester) async {
    await pumpDetails(tester);

    expect(find.text('Tick what you need'), findsOneWidget);
    expect(placeOrderButton(tester).onPressed, isNull);

    await tester.tap(find.text('Laundry per kg'));
    await tester.pump();

    expect(find.text('1 item selected'), findsOneWidget);
    expect(placeOrderButton(tester).onPressed, isNotNull);
  });

  testWidgets('ticking again unticks, and the count follows', (tester) async {
    await pumpDetails(tester);

    await tester.tap(find.text('Laundry per kg'));
    await tester.tap(find.text('Shorts'));
    await tester.pump();
    expect(find.text('2 items selected'), findsOneWidget);

    await tester.tap(find.text('Shorts'));
    await tester.pump();
    expect(find.text('1 item selected'), findsOneWidget);

    await tester.tap(find.text('Laundry per kg'));
    await tester.pump();
    expect(find.text('Tick what you need'), findsOneWidget);
  });

  testWidgets('ticked items arrive on Place Order with the right subtotal',
      (tester) async {
    await pumpDetails(tester);

    await tester.tap(find.text('Laundry per kg'));
    await tester.tap(find.text('Shorts'));
    await tester.pump();
    await tester.tap(find.text('Place order'));
    await tester.pumpAndSettle();

    expect(find.byType(PlaceOrderScreen), findsOneWidget);
    // Laundry per kg R42.00 + Shorts R28.90, one of each to start.
    expect(find.text('Laundry per kg'), findsWidgets);
    expect(find.text('Shorts'), findsWidgets);
    expect(find.text('R70.90'), findsWidgets);
  });
}
