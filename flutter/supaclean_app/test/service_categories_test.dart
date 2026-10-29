import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supaclean/services/order_api.dart';
import 'package:supaclean/services/service_catalogue.dart';
import 'package:supaclean/viewmodels/service_viewmodel.dart';
import 'package:supaclean/views/detailed_services_screen.dart';
import 'package:supaclean/views/services_screen.dart';

ApiService svc(
  String name,
  double price, {
  String? category,
  bool active = true,
  String description = '',
}) =>
    ApiService(
      id: 'id-$name',
      name: name,
      price: price,
      description: description,
      isActive: active,
      category: category,
    );

ServiceCategory? category(List<ServiceCategory> all, String name) {
  for (final c in all) {
    if (c.name == name) return c;
  }
  return null;
}

/// The server's list for the app's own built-in items (nothing added).
List<ApiService> builtInOnLive() => [
      for (final c in ServiceViewModel().services)
        for (final i in c.items)
          if (i.price > 0) svc(i.name, i.price),
    ];

void main() {
  tearDown(ServiceCatalogue.instance.reset);

  const base = [
    ServiceCategory(
      name: 'Wash & Fold',
      description: 'Laundry',
      icon: Icons.local_laundry_service,
      startingPrice: 42,
      items: [
        ServiceItem(name: 'Laundry per kg', price: 42, description: 'Local'),
      ],
    ),
    ServiceCategory(
      name: 'Other Special Services',
      description: 'Special',
      icon: Icons.auto_awesome,
      items: [
        ServiceItem(name: 'Carpet Cleaning', price: 0, description: 'Assess'),
      ],
    ),
  ];

  Future<List<ServiceCategory>> shown(List<ApiService> list) async {
    final catalogue = ServiceCatalogue(fetch: () async => list);
    await catalogue.refresh();
    return catalogue.apply(base);
  }

  group('services the admin added', () {
    test('appear under the category the admin chose', () async {
      final all = await shown([
        svc('Laundry per kg', 42),
        svc('Pillow wash', 35, category: 'Wash & Fold', description: 'Per pillow'),
      ]);

      final names = category(all, 'Wash & Fold')!.items.map((i) => i.name);
      expect(names, ['Laundry per kg', 'Pillow wash']);
      final added = category(all, 'Wash & Fold')!.items.last;
      expect(added.price, 35);
      expect(added.description, 'Per pillow');
      expect(added.isAvailable, isTrue);
    });

    test('match a category ignoring case and spaces', () async {
      final all = await shown([
        svc('Laundry per kg', 42),
        svc('Pillow wash', 35, category: '  wash & FOLD '),
      ]);

      expect(all.length, 2); // no duplicate heading
      expect(category(all, 'Wash & Fold')!.items.length, 2);
    });

    test('get their own heading when the category is new', () async {
      final all = await shown([
        svc('Laundry per kg', 42),
        svc('Sofa clean', 250, category: 'Upholstery'),
        svc('Chair clean', 90, category: 'upholstery'),
      ]);

      final upholstery = category(all, 'Upholstery')!;
      expect(all.length, 3);
      expect(upholstery.items.map((i) => i.name), ['Chair clean', 'Sofa clean']);
      expect(upholstery.startingPrice, 90);
    });

    test('with no category are not shown (nowhere to put them)', () async {
      final all = await shown([
        svc('Laundry per kg', 42),
        svc('Mystery service', 10),
        svc('Blank one', 10, category: '   '),
      ]);

      expect(all.length, 2);
      final names = all.expand((c) => c.items).map((i) => i.name);
      expect(names, isNot(contains('Mystery service')));
      expect(names, isNot(contains('Blank one')));
    });

    test('that are switched off are listed as unavailable', () async {
      final all = await shown([
        svc('Laundry per kg', 42),
        svc('Sofa clean', 250, category: 'Upholstery', active: false),
      ]);

      final sofa = category(all, 'Upholstery')!.items.single;
      expect(sofa.isAvailable, isFalse);
      // Nothing on offer, so the heading has no "from" price.
      expect(category(all, 'Upholstery')!.startingPrice, isNull);
    });

    test('lower the "from" price of the category they join', () async {
      final all = await shown([
        svc('Laundry per kg', 42),
        svc('Sock wash', 12, category: 'Wash & Fold'),
      ]);

      expect(category(all, 'Wash & Fold')!.startingPrice, 12);
    });

    test('one the app already knows by name is not added twice', () async {
      final all = await shown([
        svc('Laundry per kg', 55, category: 'Wash & Fold'),
      ]);

      final items = category(all, 'Wash & Fold')!.items;
      expect(items.length, 1);
      expect(items.single.price, 55); // the server's price, as before
    });

    test('are not shown until the server has answered', () async {
      final catalogue = ServiceCatalogue(fetch: () async => []);
      await catalogue.refresh();

      expect(identical(catalogue.apply(base), base), isTrue);
    });
  });

  group('the screens', () {
    void bigScreen(WidgetTester tester) {
      tester.view.physicalSize = const Size(1400, 6000);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);
    }

    testWidgets('Our Services shows a category the admin made',
        (tester) async {
      bigScreen(tester);
      ServiceCatalogue.instance.useForTest([
        ...builtInOnLive(),
        svc('Sofa clean', 250, category: 'Upholstery'),
      ]);

      await tester.pumpWidget(const MaterialApp(home: ServicesScreen()));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('Upholstery'), 300,
          scrollable: find.byType(Scrollable).first);

      expect(find.text('Upholstery'), findsOneWidget);
    });

    testWidgets('its Detailed Services lists the service', (tester) async {
      bigScreen(tester);
      ServiceCatalogue.instance.useForTest([
        ...builtInOnLive(),
        svc('Sofa clean', 250,
            category: 'Upholstery', description: 'Per sofa seat'),
      ]);

      await tester.pumpWidget(const MaterialApp(
        home: DetailedServicesScreen(category: 'Upholstery'),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Sofa clean'), findsOneWidget);
      expect(find.text('Per sofa seat'), findsOneWidget);
      expect(find.text('R250.00'), findsOneWidget);
    });
  });
}
