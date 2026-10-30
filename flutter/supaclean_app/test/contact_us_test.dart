import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supaclean/views/contact_us_screen.dart';

void main() {
  void bigScreen(WidgetTester tester) {
    tester.view.physicalSize = const Size(1400, 4000);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
  }

  testWidgets('Contact Us lists every depot with its number', (tester) async {
    bigScreen(tester);
    await tester.pumpWidget(const MaterialApp(home: ContactUsScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Contact Us'), findsOneWidget);
    for (final name in [
      'Mimosa Mall',
      'Fleurdal Mall',
      'Preller Square',
      'Bloem Plaza',
      'Main Factory - Hamilton',
      'Botshabelo',
      'Thaba Nchu',
    ]) {
      expect(find.text(name), findsOneWidget, reason: name);
    }

    // Mimosa Mall and the main factory share a number, so it shows twice.
    expect(find.text('051 430 4241'), findsNWidgets(2));
    for (final phone in [
      '081 456 2999',
      '081 503 9427',
      '083 417 3561',
      '081 338 5843',
      '081 338 5873',
    ]) {
      expect(find.text(phone), findsOneWidget, reason: phone);
    }
    expect(ContactUsScreen.depots.length, 7);
  });

  testWidgets('the copy button puts the number on the clipboard',
      (tester) async {
    bigScreen(tester);
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String?;
        }
        return null;
      },
    );
    addTearDown(() => tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null));

    await tester.pumpWidget(const MaterialApp(home: ContactUsScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Copy Thaba Nchu number'));
    await tester.pumpAndSettle();

    expect(copied, '081 338 5873');
    expect(find.textContaining('Thaba Nchu number copied'), findsOneWidget);
  });
}
