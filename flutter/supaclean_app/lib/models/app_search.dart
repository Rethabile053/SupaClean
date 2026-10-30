import 'package:flutter/material.dart';

import '../viewmodels/service_viewmodel.dart';
import 'app_notification.dart';
import 'laundry_order.dart';

/// What a search result is, which is also the heading it is listed under.
enum SearchKind {
  page('Pages'),
  service('Services'),
  order('My orders'),
  notification('Notifications');

  const SearchKind(this.heading);
  final String heading;
}

/// One thing the search found. [source] is what it was made from (a
/// [LaundryOrder], an [AppNotification], a [ServiceCategory] or an [AppPage]),
/// so the screen knows where tapping it should go.
class SearchResult {
  const SearchResult({
    required this.kind,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.source,
  });

  final SearchKind kind;
  final String title;
  final String subtitle;
  final IconData icon;
  final Object source;
}

/// A place in the app a person can jump to.
enum AppPage {
  home('Home', 'The home screen', Icons.home_outlined,
      'home start welcome'),
  services('Our Services', 'Everything we clean, with prices',
      Icons.local_laundry_service_outlined,
      'services price prices laundry catalogue menu cost'),
  myOrders('My Orders', 'Your active, completed and cancelled orders',
      Icons.receipt_long_outlined,
      'orders history active completed cancelled cancel'),
  schedule('Schedule', 'Your pickups and deliveries by date',
      Icons.calendar_month_outlined,
      'schedule calendar pickup delivery date time booking'),
  profile('Profile', 'Your account and settings', Icons.person_outline,
      'profile account name email phone password logout sign out'),
  addresses('My Addresses', 'Saved pickup and delivery addresses',
      Icons.location_on_outlined,
      'address addresses location pickup delivery home'),
  notifications('Notifications', 'Updates about your orders',
      Icons.notifications_none_outlined,
      'notifications alerts updates messages read'),
  terms('Terms and Conditions',
      'Discounts, items at your own risk, turnaround and guarantees',
      Icons.description_outlined,
      'terms conditions rules discount risk guarantee turnaround policy '
          'advance payment caps white clothing beads sequins shoe repair');

  const AppPage(this.title, this.subtitle, this.icon, this.keywords);
  final String title;
  final String subtitle;
  final IconData icon;

  /// Extra words that should find this page.
  final String keywords;
}

/// Looks through everything the app knows for [query].
///
/// Every word typed has to appear somewhere in an item, in any order, ignoring
/// capital letters and punctuation, so "sc 1012", "SC-1012" and "1012" all find
/// order SC-1012. An empty query finds nothing.
List<SearchResult> searchApp(
  String query, {
  required List<ServiceCategory> services,
  List<LaundryOrder> orders = const [],
  List<AppNotification> notifications = const [],
  int perKind = 8,
}) {
  final words = _words(query);
  if (words.isEmpty) return const [];

  bool matches(String text) {
    final spaced = ' ${_clean(text)} ';
    final joined = spaced.replaceAll(' ', '');
    return words.every((w) => spaced.contains(w) || joined.contains(w));
  }

  final found = <SearchResult>[];

  for (final page in AppPage.values) {
    if (matches('${page.title} ${page.subtitle} ${page.keywords}')) {
      found.add(SearchResult(
        kind: SearchKind.page,
        title: page.title,
        subtitle: page.subtitle,
        icon: page.icon,
        source: page,
      ));
    }
  }

  var serviceCount = 0;
  for (final category in services) {
    for (final item in category.items) {
      if (serviceCount >= perKind) break;
      if (!matches('${item.name} ${item.description} ${category.name}')) {
        continue;
      }
      serviceCount++;
      found.add(SearchResult(
        kind: SearchKind.service,
        title: item.name,
        subtitle: item.isAvailable
            ? '${category.name} · ${_price(item)}'
            : '${category.name} · Currently unavailable',
        icon: category.icon,
        source: category,
      ));
    }
  }

  var orderCount = 0;
  for (final order in orders) {
    if (orderCount >= perKind) break;
    if (!matches('${order.orderId} ${order.service} ${order.status} '
        '${order.statusDetail} ${order.date}')) {
      continue;
    }
    orderCount++;
    found.add(SearchResult(
      kind: SearchKind.order,
      title: 'Order #${order.orderId}',
      subtitle: '${order.service} · ${order.status}',
      icon: Icons.receipt_long_outlined,
      source: order,
    ));
  }

  var notificationCount = 0;
  for (final n in notifications) {
    if (notificationCount >= perKind) break;
    if (!matches(n.title)) continue;
    notificationCount++;
    found.add(SearchResult(
      kind: SearchKind.notification,
      title: n.title,
      subtitle: n.timeAgo,
      icon: n.status.icon,
      source: n,
    ));
  }

  return found;
}

String _price(ServiceItem item) =>
    item.price == 0
        ? 'Price confirmed after assessment'
        : 'R${item.price.toStringAsFixed(2)}';

/// Lower case, with everything but letters and numbers turned into spaces.
String _clean(String text) =>
    text.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();

List<String> _words(String query) {
  final cleaned = _clean(query);
  return cleaned.isEmpty ? const [] : cleaned.split(' ');
}
