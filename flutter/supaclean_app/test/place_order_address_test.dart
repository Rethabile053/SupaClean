import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supaclean/models/address_rules.dart';
import 'package:supaclean/models/order_draft.dart';
import 'package:supaclean/views/date_time_screen.dart';
import 'package:supaclean/views/place_order_screen.dart';

Future<List<({String id, String name, double fee})>> zones() async => [
      (id: 'z1', name: 'Bloemfontein', fee: 50.0),
      (id: 'z2', name: 'Botshabelo', fee: 100.0),
      (id: 'z3', name: 'Thaba Nchu', fee: 150.0),
    ];

void main() {
  group('AddressRules', () {
    test('accepts a street address in a served area', () {
      expect(
        AddressRules.problem('12 Example Street, Langenhoven Park, Bloemfontein'),
        isNull,
      );
    });

    test('rejects text that is not an address', () {
      expect(AddressRules.problem('home'), AddressRules.invalidMessage);
    });

    test('rejects an address outside the areas we serve', () {
      expect(
        AddressRules.problem('12 Long Street, Sea Point, Cape Town'),
        AddressRules.unsupportedAreaMessage,
      );
    });

    test('accepts both spellings of Botshabelo and Thaba-Nchu', () {
      expect(AddressRules.problem('5 Main Road, Botsabelo'), isNull);
      expect(AddressRules.problem('5 Main Road, Thaba-Nchu'), isNull);
    });
  });

  group('Place Order address', () {
    void bigScreen(WidgetTester tester) {
      tester.view.physicalSize = const Size(800, 3000);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);
    }

    Future<void> open(WidgetTester tester) async {
      bigScreen(tester);
      await tester.pumpWidget(const MaterialApp(
        home: PlaceOrderScreen(category: 'Wash & Fold', loadZones: zones),
      ));
      await tester.pumpAndSettle();
    }

    // Opens the address sheet the way a customer does: Pickup Option, then
    // "At my address".
    Future<void> openAddressSheet(WidgetTester tester) async {
      await tester.tap(find.text('Pickup Option'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('At my address').last);
      await tester.pumpAndSettle();
    }

    testWidgets('choosing "At my address" asks for the address',
        (tester) async {
      await open(tester);
      expect(find.text('Your address'), findsNothing);

      await openAddressSheet(tester);

      expect(find.text('Your address'), findsOneWidget);
      expect(find.text('Save address'), findsOneWidget);
    });

    testWidgets('choosing "Deliver to me" asks for the address too',
        (tester) async {
      await open(tester);

      await tester.tap(find.text('Delivery Option'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Deliver to me').last);
      await tester.pumpAndSettle();

      expect(find.text('Your address'), findsOneWidget);
    });

    testWidgets('the fee for the area shows while typing', (tester) async {
      await open(tester);
      await openAddressSheet(tester);

      await tester.enterText(
          find.byType(TextField), '12 Main Road, Section A, Botshabelo');
      await tester.pump();

      expect(find.textContaining('Area: Botshabelo'), findsOneWidget);
      expect(find.textContaining('Home pickup fee: R100.00'), findsOneWidget);
      expect(find.textContaining('Home delivery fee: R100.00'), findsOneWidget);
    });

    testWidgets('saving an address in Thaba Nchu updates both fees and the total',
        (tester) async {
      await open(tester);
      await openAddressSheet(tester);

      await tester.enterText(
          find.byType(TextField), '3 Church Street, Thaba-Nchu');
      await tester.pump();
      await tester.tap(find.text('Save address'));
      await tester.pumpAndSettle();

      expect(find.text('Your address'), findsNothing);
      // The tiles show the address, and the fees follow the area.
      expect(find.text('3 Church Street, Thaba-Nchu'), findsNWidgets(2));
      expect(find.text('+ R150.00'), findsNWidgets(2));
      expect(find.text('R150.00'), findsNWidgets(2)); // the two fee rows
    });

    testWidgets('an address that is not valid is refused with a reason',
        (tester) async {
      await open(tester);
      await openAddressSheet(tester);

      await tester.enterText(find.byType(TextField), 'home');
      await tester.tap(find.text('Save address'));
      await tester.pump();

      expect(find.text(AddressRules.invalidMessage), findsOneWidget);
      expect(find.text('Your address'), findsOneWidget); // still open
    });

    testWidgets('an address outside our areas is refused', (tester) async {
      await open(tester);
      await openAddressSheet(tester);

      await tester.enterText(
          find.byType(TextField), '12 Long Street, Sea Point, Cape Town');
      await tester.tap(find.text('Save address'));
      await tester.pump();

      expect(find.text(AddressRules.unsupportedAreaMessage), findsOneWidget);
    });

    testWidgets('the Date & Time screen no longer asks for an address',
        (tester) async {
      // Wide enough for the test font, which draws every letter very wide.
      tester.view.physicalSize = const Size(1400, 3000);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(const MaterialApp(
        home: ChooseDateTimeScreen(
          orderSubtotal: 100,
          draft: OrderDraft(
            category: 'Wash & Fold',
            lines: [OrderLine(name: 'Caps', unitPrice: 50, quantity: 2)],
            pickupFee: 100,
            deliveryFee: 100,
            address: '12 Main Road, Botshabelo',
          ),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Pickup Date & Time'), findsOneWidget);
      expect(find.text('Delivery Date & Time'), findsOneWidget);
      expect(find.text('Pickup Address'), findsNothing);
      expect(find.byType(TextField), findsOneWidget); // special instructions only
      // The fees chosen on Place Order carry through to the total.
      expect(find.text('Total including fees'), findsOneWidget);
      expect(find.text('R300.00'), findsOneWidget);
    });

    testWidgets('Continue without an address asks for it instead of moving on',
        (tester) async {
      await open(tester);

      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(find.text('Your address'), findsOneWidget);
      expect(find.text('Choose Date & Time'), findsNothing);
    });
  });
}
