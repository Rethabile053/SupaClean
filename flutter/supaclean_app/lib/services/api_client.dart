import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/api_config.dart';

/// A failed call to the API, with a message that is safe to show the user.
/// ASP.NET answers errors as `{ "code": "...", "message": "..." }`.
class ApiException implements Exception {
  const ApiException(this.message, {this.status = 0, this.code = ''});

  final String message;
  final int status;
  final String code;

  @override
  String toString() => message;
}

/// Small JSON client for the ASP.NET API. Adds the signed-in user's Supabase
/// access token so the API knows who is asking.
class ApiClient {
  ApiClient({
    http.Client? httpClient,
    String? baseUrl,
    Future<String?> Function()? accessToken,
  })  : _http = httpClient ?? http.Client(),
        baseUrl = baseUrl ?? ApiConfig.baseUrl,
        _accessToken = accessToken ?? _supabaseToken;

  final http.Client _http;
  final String baseUrl;
  final Future<String?> Function() _accessToken;

  static Future<String?> _supabaseToken() async =>
      Supabase.instance.client.auth.currentSession?.accessToken;

  bool get isConfigured => baseUrl.isNotEmpty;

  Future<dynamic> get(String path) => _send('GET', path);

  Future<dynamic> post(String path, [Object? body]) =>
      _send('POST', path, body);

  Future<dynamic> put(String path, [Object? body]) => _send('PUT', path, body);

  Future<dynamic> delete(String path) => _send('DELETE', path);

  Future<dynamic> _send(String method, String path, [Object? body]) async {
    if (!isConfigured) {
      throw const ApiException(
        'The SupaClean server is not set up in this version of the app yet.',
      );
    }

    final token = await _accessToken();
    final request = http.Request(method, Uri.parse('$baseUrl$path'))
      ..headers['Accept'] = 'application/json';
    if (token != null) request.headers['Authorization'] = 'Bearer $token';
    if (body != null) {
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode(body);
    }

    final http.Response response;
    try {
      final streamed = await _http.send(request).timeout(
            const Duration(seconds: 20),
          );
      response = await http.Response.fromStream(streamed);
    } on TimeoutException {
      throw const ApiException(
        'The server took too long to answer. Please try again.',
      );
    } on http.ClientException {
      throw const ApiException(
        'Could not reach the server. Please check your internet connection.',
      );
    }

    return _decode(response);
  }

  dynamic _decode(http.Response response) {
    final text = utf8.decode(response.bodyBytes);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return text.isEmpty ? null : jsonDecode(text);
    }

    var message = 'Something went wrong. Please try again.';
    var code = '';
    try {
      final json = jsonDecode(text);
      if (json is Map<String, dynamic>) {
        message = (json['message'] as String?) ?? message;
        code = (json['code'] as String?) ?? '';
      }
    } catch (_) {
      // Not JSON (for example a proxy error page): keep the generic message.
    }
    if (response.statusCode == 401) {
      message = 'Please sign in again.';
    }

    throw ApiException(message, status: response.statusCode, code: code);
  }
}
