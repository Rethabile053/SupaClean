import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supaclean/models/user_model.dart';
import 'package:supaclean/services/api_client.dart';
import 'package:supaclean/services/customer_sync.dart';
import 'package:supaclean/services/order_api.dart';

class Server {
  Server({this.existing});

  /// What GET /customers/me answers; null means "no customer yet" (404).
  final Map<String, dynamic>? existing;

  final requests = <String>[];
  final bodies = <String, Map<String, dynamic>>{};

  OrderApi get api => OrderApi(
        client: ApiClient(
          baseUrl: 'http://server',
          accessToken: () async => 'token',
          httpClient: MockClient((request) async {
            final key = '${request.method} ${request.url.path}';
            requests.add(key);
            if (request.body.isNotEmpty) {
              bodies[key] = jsonDecode(request.body) as Map<String, dynamic>;
            }
            if (key == 'GET /api/v1/customers/me') {
              return existing == null
                  ? http.Response('{"message":"Customer profile not found."}', 404)
                  : http.Response(jsonEncode(existing), 200);
            }
            if (key == 'POST /api/v1/customers') {
              return http.Response('"new-customer-id"', 200);
            }
            return http.Response('', 204);
          }),
        ),
      );
}

UserModel thandi() => UserModel(
      fullName: 'Thandi Mokoena',
      email: 'thandi@example.com',
      phoneNumber: '0821234567',
      password: '',
    );

void main() {
  setUp(CustomerSync.reset);

  test('a new sign-in becomes a customer on the server', () async {
    final server = Server();

    await CustomerSync.ensure(thandi(), api: server.api, savedAddress: () => '');

    expect(server.requests, [
      'GET /api/v1/customers/me',
      'POST /api/v1/customers',
    ]);
    final sent = server.bodies['POST /api/v1/customers']!;
    expect(sent['firstName'], 'Thandi');
    expect(sent['lastName'], 'Mokoena');
    expect(sent['email'], 'thandi@example.com');
    expect(sent['phoneNumber'], '0821234567');
    // No address yet: the server needs one, so a clear placeholder is used.
    expect(sent['address'], OrderApi.unknownAddress);
  });

  test('uses the saved address when there is one', () async {
    final server = Server();

    await CustomerSync.ensure(
      thandi(),
      api: server.api,
      savedAddress: () => '12 Main Road, Botshabelo',
    );

    expect(server.bodies['POST /api/v1/customers']!['address'],
        '12 Main Road, Botshabelo');
  });

  test('an existing customer is left alone', () async {
    final server = Server(existing: {
      'customerId': 'c1',
      'address': '5 Church Street, Thaba Nchu',
      'city': 'Thaba Nchu',
    });

    await CustomerSync.ensure(thandi(), api: server.api, savedAddress: () => '');

    expect(server.requests, ['GET /api/v1/customers/me']);
  });

  test('does not ask the server again for the same person', () async {
    final server = Server();

    await CustomerSync.ensure(thandi(), api: server.api, savedAddress: () => '');
    await CustomerSync.ensure(thandi(), api: server.api, savedAddress: () => '');

    expect(server.requests.where((r) => r.startsWith('POST')).length, 1);
    expect(server.requests.where((r) => r.startsWith('GET')).length, 1);
  });

  test('does nothing when nobody is signed in', () async {
    final server = Server();

    await CustomerSync.ensure(null, api: server.api);

    expect(server.requests, isEmpty);
  });

  test('a server problem is ignored and tried again next time', () async {
    var down = true;
    var posts = 0;
    final api = OrderApi(
      client: ApiClient(
        baseUrl: 'http://server',
        accessToken: () async => 'token',
        httpClient: MockClient((request) async {
          if (down) return http.Response('oops', 500);
          if (request.method == 'POST') posts++;
          return request.method == 'GET'
              ? http.Response('{"message":"x"}', 404)
              : http.Response('"id"', 200);
        }),
      ),
    );

    await CustomerSync.ensure(thandi(), api: api, savedAddress: () => '');
    expect(posts, 0);

    down = false;
    // Would be skipped if the failed attempt had been remembered as done.
    await CustomerSync.ensure(thandi(), api: api, savedAddress: () => '');
    expect(posts, 1);
  });

  test('a customer saved without an address gets the first real one', () async {
    final server = Server(existing: {
      'customerId': 'c1',
      'address': OrderApi.unknownAddress,
      'city': 'Bloemfontein',
    });

    await server.api.ensureCustomer(
      fullName: 'Thandi Mokoena',
      email: 'thandi@example.com',
      phone: '0821234567',
      address: '12 Main Road, Botshabelo',
    );

    final put = server.bodies['PUT /api/v1/customers/me']!;
    expect(put['customerId'], 'c1');
    expect(put['address'], '12 Main Road, Botshabelo');
    expect(put['fullName'], 'Thandi Mokoena');
    expect(put['phoneNumber'], '0821234567');
  });

  test('a real address on file is never overwritten', () async {
    final server = Server(existing: {
      'customerId': 'c1',
      'address': '5 Church Street, Thaba Nchu',
      'city': 'Thaba Nchu',
    });

    await server.api.ensureCustomer(
      fullName: 'Thandi Mokoena',
      email: 'thandi@example.com',
      phone: '0821234567',
      address: '12 Main Road, Botshabelo',
    );

    expect(server.requests, ['GET /api/v1/customers/me']);
  });
}
