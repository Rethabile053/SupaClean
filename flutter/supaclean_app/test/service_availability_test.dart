import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supaclean/services/api_client.dart';
import 'package:supaclean/services/order_api.dart';
import 'package:supaclean/services/service_catalogue.dart';
import 'package:supaclean/viewmodels/service_viewmodel.dart';
import 'package:supaclean/views/detailed_services_screen.dart';
import 'package:supaclean/views/place_order_screen.dart';

ApiService svc(String name, double price, {bool active = true}) => ApiService(
      id: 'id-$name',
      name: name,
      price: price,
      isActive: active,
    );

ServiceItem? item(List<ServiceCategory> categories, String name) {
  for (final category in categories) {
    for (final i in category.items) {
      if (i.name == name) return i;
    }
  }
  return null;
}

/// Every Wash & Fold item the app has, with [off] switched off by the admin.
List<ApiService> washAndFold({String? off}) => [
      for (final entry in const {
        'Laundry per kg': 42.0,
        'Shirts, T-shirts, Polo': 28.9,
        'Shorts': 28.9,
        'Socks': 28.9,
      }.entries)
        svc(entry.key, entry.value, active: entry.key != off),
    ];

void main() {
  tearDown(ServiceCatalogue.instance.reset);

  group('the services call', () {
    OrderApi apiAnswering(List<Map<String, Object>> data, List<Uri> asked) =>
        OrderApi(
          client: ApiClient(
            baseUrl: 'http://server',
            accessToken: () async => null,
            httpClient: MockClient((request) async {
              asked.add(request.url);
              return http.Response(jsonEncode(data), 200,
                  headers: {'content-type': 'application/json'});
            }),
          ),
        );

    test('asks for switched-off services too when told to', () async {
      final asked = <Uri>[];
      final api = apiAnswering([
        {'serviceId': 'a', 'serviceName': 'Socks', 'price': 10, 'isActive': false},
        {'serviceId': 'b', 'serviceName': 'Shorts', 'price': 20, 'isActive': true},
      ], asked);

      final list = await api.services(includeInactive: true);

      expect(asked.single.queryParameters['includeInactive'], 'true');
      expect(list.map((s) => s.isActive), [false, true]);
    });

    test('by default asks for the active ones only', () async {
      final asked = <Uri>[];
      final api = apiAnswering([
        {'serviceId': 'a', 'serviceName': 'Socks', 'price': 10},
      ], asked);

      final list = await api.services();

      expect(asked.single.queryParameters, isEmpty);
      expect(list.single.isActive, isTrue); // missing means active
    });
  });

  group('the catalogue', () {
    const base = [
      ServiceCategory(
        name: 'Wash & Fold',
        description: 'Laundry',
        icon: Icons.local_laundry_service,
        startingPrice: 42,
        items: [
          ServiceItem(name: 'Laundry per kg', price: 42, description: 'a'),
          ServiceItem(name: 'Socks', price: 28.9, description: 'b'),
        ],
      ),
    ];

    test('keeps a switched-off item listed but unavailable', () async {
      final catalogue = ServiceCatalogue(
        fetch: () async => [
          svc('Laundry per kg', 42),
          svc('Socks', 30, active: false),
        ],
      );
      await catalogue.refresh();
      final shown = catalogue.apply(base);

      expect(item(shown, 'Socks'), isNotNull);
      expect(item(shown, 'Socks')!.isAvailable, isFalse);
      expect(item(shown, 'Laundry per kg')!.isAvailable, isTrue);
    });

    test('the starting price ignores switched-off items', () async {
      final catalogue = ServiceCatalogue(
        fetch: () async => [
          svc('Laundry per kg', 42),
          svc('Socks', 30, active: false), // cheapest, but off
        ],
      );
      await catalogue.refresh();

      expect(catalogue.apply(base).single.startingPrice, 42);
    });

    test('an item switched back on is available again', () async {
      var off = true;
      final catalogue = ServiceCatalogue(
        fetch: () async => [
          svc('Laundry per kg', 42),
          svc('Socks', 30, active: !off),
        ],
      );
      await catalogue.refresh();
      expect(item(catalogue.apply(base), 'Socks')!.isAvailable, isFalse);

      off = false;
      await catalogue.refresh(force: true);
      expect(item(catalogue.apply(base), 'Socks')!.isAvailable, isTrue);
    });
  });

  group('Detailed Services', () {
    Future<void> open(WidgetTester tester) async {
      tester.view.physicalSize = const Size(1400, 4000);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(const MaterialApp(
        home: DetailedServicesScreen(category: 'Wash & Fold'),
      ));
      await tester.pumpAndSettle();
    }

    testWidgets('shows a switched-off item as currently unavailable',
        (tester) async {
      ServiceCatalogue.instance.useForTest(washAndFold(off: 'Socks'));
      await open(tester);

      expect(find.text('Socks'), findsOneWidget);
      expect(find.text('Currently unavailable'), findsOneWidget);
    });

    testWidgets('it cannot be ticked, an available one can', (tester) async {
      ServiceCatalogue.instance.useForTest(washAndFold(off: 'Socks'));
      await open(tester);
      expect(find.text('Place Order'), findsOneWidget);

      await tester.tap(find.text('Socks'));
      await tester.pump();
      expect(find.text('Place Order'), findsOneWidget); // still nothing ticked

      await tester.tap(find.text('Shorts'));
      await tester.pump();
      expect(find.text('Place Order (1)'), findsOneWidget);
    });

    testWidgets('an item switched off while ticked is un-ticked',
        (tester) async {
      ServiceCatalogue.instance.useForTest(washAndFold());
      await open(tester);

      await tester.tap(find.text('Socks'));
      await tester.pump();
      expect(find.text('Place Order (1)'), findsOneWidget);

      // The admin switches it off and the app hears about it.
      ServiceCatalogue.instance.useForTest(washAndFold(off: 'Socks'));
      await tester.pump();

      expect(find.text('Place Order'), findsOneWidget);
      expect(find.text('Currently unavailable'), findsOneWidget);
    });
  });

  group('Place Order', () {
    testWidgets('does not start with a switched-off item', (tester) async {
      tester.view.physicalSize = const Size(800, 3000);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);
      ServiceCatalogue.instance.useForTest(washAndFold(off: 'Socks'));

      await tester.pumpWidget(MaterialApp(
        home: PlaceOrderScreen(
          category: 'Wash & Fold',
          initialItems: const ['Socks'],
          loadZones: () async => [],
        ),
      ));
      await tester.pumpAndSettle();

      // Socks was asked for, but it is off, so the first available item is
      // picked instead.
      expect(find.text('Socks'), findsNothing);
      expect(find.text('Laundry per kg'), findsWidgets);
    });
  });
}
