import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supaclean/models/address_rules.dart';
import 'package:supaclean/views/my_addresses_screen.dart';

void main() {
  Future<void> openAddDialog(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1400, 3000);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MaterialApp(home: MyAddressesScreen()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add new address'));
    await tester.pumpAndSettle();
  }

  testWidgets('Add new address opens a box for the address', (tester) async {
    await openAddDialog(tester);

    expect(find.text('Add address'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('an address that is not valid is refused with a reason',
      (tester) async {
    await openAddDialog(tester);

    await tester.enterText(find.byType(TextField), 'home');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text(AddressRules.invalidMessage), findsOneWidget);
    expect(find.text('Add address'), findsOneWidget); // still open
  });

  testWidgets('an address outside our areas is refused', (tester) async {
    await openAddDialog(tester);

    await tester.enterText(
        find.byType(TextField), '12 Long Street, Sea Point, Cape Town');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text(AddressRules.unsupportedAreaMessage), findsOneWidget);
  });

  testWidgets('a valid address closes the box', (tester) async {
    await openAddDialog(tester);

    await tester.enterText(
        find.byType(TextField), '3 Church Street, Thaba-Nchu');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Add address'), findsNothing);
  });
}
