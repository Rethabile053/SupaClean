import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supaclean/services/order_api.dart';
import 'package:supaclean/services/service_catalogue.dart';
import 'package:supaclean/viewmodels/service_viewmodel.dart';

ApiService api(String name, double price, [String description = '']) =>
    ApiService(
      id: 'id-$name',
      name: name,
      price: price,
      description: description,
    );

ServiceItem? find(List<ServiceCategory> categories, String name) {
  for (final category in categories) {
    for (final item in category.items) {
      if (item.name == name) return item;
    }
  }
  return null;
}

void main() {
  const base = [
    ServiceCategory(
      name: 'Wash & Fold',
      description: 'Laundry',
      icon: Icons.local_laundry_service,
      startingPrice: 42,
      items: [
        ServiceItem(name: 'Laundry per kg', price: 42, description: 'Local'),
        ServiceItem(name: 'Socks', price: 28.9, description: 'Local socks'),
      ],
    ),
    ServiceCategory(
      name: 'Other',
      description: 'Special',
      icon: Icons.auto_awesome,
      items: [
        ServiceItem(name: 'Carpet Cleaning', price: 0, description: 'Assess'),
      ],
    ),
  ];

  group('ServiceCatalogue.apply', () {
    test('shows the built-in list until the server has answered', () async {
      final catalogue = ServiceCatalogue(fetch: () async => []);
      await catalogue.refresh();

      expect(catalogue.isLive, isFalse);
      expect(identical(catalogue.apply(base), base), isTrue);
    });

    test('uses the server\'s price and description', () async {
      final catalogue = ServiceCatalogue(
        fetch: () async => [
          api('Laundry per kg', 55, 'Per kilogram, from the admin'),
          api('Socks', 30),
        ],
      );
      await catalogue.refresh();
      final shown = catalogue.apply(base);

      expect(find(shown, 'Laundry per kg')!.price, 55);
      expect(find(shown, 'Laundry per kg')!.description,
          'Per kilogram, from the admin');
      // No description on the server: keep the app's wording.
      expect(find(shown, 'Socks')!.price, 30);
      expect(find(shown, 'Socks')!.description, 'Local socks');
    });

    test('matches names ignoring case and spaces', () async {
      final catalogue = ServiceCatalogue(
        fetch: () async => [api('  laundry PER kg ', 60), api('Socks', 30)],
      );
      await catalogue.refresh();

      expect(find(catalogue.apply(base), 'Laundry per kg')!.price, 60);
    });

    test('hides an item the server no longer offers', () async {
      final catalogue =
          ServiceCatalogue(fetch: () async => [api('Laundry per kg', 42)]);
      await catalogue.refresh();
      final shown = catalogue.apply(base);

      expect(find(shown, 'Socks'), isNull);
      expect(find(shown, 'Laundry per kg'), isNotNull);
    });

    test('keeps items priced after assessment', () async {
      final catalogue =
          ServiceCatalogue(fetch: () async => [api('Laundry per kg', 42)]);
      await catalogue.refresh();

      expect(find(catalogue.apply(base), 'Carpet Cleaning'), isNotNull);
    });

    test('starting price follows the cheapest item on the server', () async {
      final catalogue = ServiceCatalogue(
        fetch: () async => [api('Laundry per kg', 60), api('Socks', 35)],
      );
      await catalogue.refresh();
      final shown = catalogue.apply(base);

      expect(shown.first.startingPrice, 35);
      expect(shown.last.startingPrice, isNull);
    });

    test('keeps the categories, icons and descriptions of the app', () async {
      final catalogue =
          ServiceCatalogue(fetch: () async => [api('Socks', 30)]);
      await catalogue.refresh();
      final shown = catalogue.apply(base);

      expect(shown.map((c) => c.name), ['Wash & Fold', 'Other']);
      expect(shown.first.icon, Icons.local_laundry_service);
      expect(shown.first.description, 'Laundry');
    });
  });

  group('ServiceCatalogue.refresh', () {
    test('keeps what it has when the server cannot be reached', () async {
      var fail = false;
      final catalogue = ServiceCatalogue(
        refreshEvery: Duration.zero,
        fetch: () async {
          if (fail) throw Exception('offline');
          return [api('Socks', 30)];
        },
      );
      await catalogue.refresh();
      fail = true;
      await catalogue.refresh();

      expect(catalogue.isLive, isTrue);
      expect(find(catalogue.apply(base), 'Socks')!.price, 30);
    });

    test('does not ask again while the list is fresh', () async {
      var calls = 0;
      final catalogue = ServiceCatalogue(fetch: () async {
        calls++;
        return [api('Socks', 30)];
      });
      await catalogue.refresh();
      await catalogue.refresh();
      expect(calls, 1);

      await catalogue.refresh(force: true);
      expect(calls, 2);
    });

    test('tells listeners when new prices arrive', () async {
      final catalogue =
          ServiceCatalogue(fetch: () async => [api('Socks', 30)]);
      var notified = 0;
      catalogue.addListener(() => notified++);

      await catalogue.refresh();
      expect(notified, 1);
    });
  });
}
