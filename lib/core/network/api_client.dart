import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:flutter/foundation.dart';
import 'http_client_io.dart' if (dart.library.js_interop) 'http_client_web.dart'
    as platform;

class ApiException implements Exception {
  final int statusCode;
  final String? message;
  const ApiException(this.statusCode, [this.message]);

  @override
  String toString() => message == null ? 'HTTP $statusCode' : 'HTTP $statusCode: $message';
}

class ApiClient {
  // In development flutter web, we can use the same host via relative URL, or point to localhost:5001
  static const String baseUrl = kReleaseMode ? '' : 'http://localhost:5001';

  final http.Client _client;
  String? _csrfToken;

  ApiClient({http.Client? client})
      : _client = client ?? platform.createHttpClient();

  Uri _uri(String endpoint) => Uri.parse('$baseUrl$endpoint');

  Future<dynamic> get(String endpoint) async =>
      _decode(await _client.get(_uri(endpoint)));

  Future<void> fetchCsrf() async {
    final data = await get('/api/admin/auth/csrf');
    _csrfToken = data['token'] as String;
  }

  Future<dynamic> post(String endpoint, Map<String, dynamic> body) async =>
      _json('POST', endpoint, body);
  Future<dynamic> put(String endpoint, Map<String, dynamic> body) async =>
      _json('PUT', endpoint, body);
  Future<dynamic> patch(String endpoint, Map<String, dynamic> body) async =>
      _json('PATCH', endpoint, body);

  Future<void> delete(String endpoint) async {
    final request = http.Request('DELETE', _uri(endpoint));
    if (_csrfToken != null) request.headers['X-CSRF-TOKEN'] = _csrfToken!;
    _decode(await http.Response.fromStream(await _client.send(request)));
  }

  Future<dynamic> _json(
      String method, String endpoint, Map<String, dynamic> body) async {
    final request = http.Request(method, _uri(endpoint));
    request.headers['Content-Type'] = 'application/json';
    if (_csrfToken != null) request.headers['X-CSRF-TOKEN'] = _csrfToken!;
    request.body = jsonEncode(body);
    return _decode(
      await http.Response.fromStream(await _client.send(request)),
      notifyUnauthorized: endpoint != '/api/admin/auth/login' &&
          endpoint != '/api/admin/auth/mfa/verify' &&
          endpoint != '/api/admin/auth/mfa/recovery',
    );
  }

  Future<dynamic> upload(
      String endpoint, Uint8List bytes, String filename) async {
    final request = http.MultipartRequest('POST', _uri(endpoint));
    if (_csrfToken != null) request.headers['X-CSRF-TOKEN'] = _csrfToken!;
    final extension = filename.split('.').last.toLowerCase();
    final mimeType = switch (extension) {
      'jpg' || 'jpeg' => 'jpeg',
      'png' => 'png',
      'webp' => 'webp',
      _ => null,
    };
    request.files.add(http.MultipartFile.fromBytes('image', bytes,
        filename: filename,
        contentType: mimeType == null ? null : MediaType('image', mimeType)));
    return _decode(await http.Response.fromStream(await _client.send(request)));
  }

  void Function()? onUnauthorized;
  void Function()? onForbidden;

  dynamic _decode(http.Response response, {bool notifyUnauthorized = true}) {
    if (response.statusCode == 401 && notifyUnauthorized) {
      onUnauthorized?.call();
    }
    if (response.statusCode == 403) onForbidden?.call();

    if (response.statusCode < 200 || response.statusCode >= 300) {
      String? message;
      try {
        final body = jsonDecode(response.body);
        if (body is Map<String, dynamic> && body['message'] is String) {
          message = body['message'] as String;
        }
      } catch (_) {}
      throw ApiException(response.statusCode, message);
    }
    if (response.body.isEmpty) return null;
    return jsonDecode(response.body);
  }

  void dispose() => _client.close();
}
