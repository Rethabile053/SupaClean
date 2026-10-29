import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supaclean/views/terms_screen.dart';

void main() {
  testWidgets('Terms and Conditions lists every term', (tester) async {
    tester.view.physicalSize = const Size(1400, 3000);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MaterialApp(home: TermsScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Terms and Conditions'), findsOneWidget);
    expect(find.textContaining('15% discount'), findsOneWidget);
    expect(find.textContaining('caps, white clothing'), findsOneWidget);
    expect(find.textContaining('same day'), findsOneWidget);
    expect(find.text('Laundry takes two days.'), findsOneWidget);
    expect(find.textContaining('3 month guarantee'), findsOneWidget);
  });
}
