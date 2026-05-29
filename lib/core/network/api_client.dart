import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../security/secure_storage_service.dart';
import 'api_exception.dart';
import 'retry_interceptor.dart';

typedef TokenProvider = Future<String?> Function();

class ApiClient {
  ApiClient({
    http.Client? client,
    Uri? baseUri,
    Duration? timeout,
    RetryInterceptor retryInterceptor = const RetryInterceptor(),
    SecureStorageService? secureStorage,
    TokenProvider? tokenProvider,
    this.attachAuthorization = true,
  }) : _client = client ?? http.Client(),
       _ownsClient = client == null,
       _baseUri = baseUri ?? AppConfig.apiBaseUri,
       _timeout =
           timeout ??
           (baseUri == null
               ? AppConfig.requestTimeout
               : const Duration(seconds: 15)),
       _retryInterceptor = retryInterceptor,
       _tokenProvider = tokenProvider ?? secureStorage?.readAccessToken;

  final http.Client _client;
  final bool _ownsClient;
  final Uri _baseUri;
  final Duration _timeout;
  final RetryInterceptor _retryInterceptor;
  final TokenProvider? _tokenProvider;
  final bool attachAuthorization;

  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, String>? queryParameters,
    bool authenticated = true,
  }) {
    return _requestJson(
      'GET',
      path,
      queryParameters: queryParameters,
      authenticated: authenticated,
      retryable: true,
    );
  }

  Future<Map<String, dynamic>> postJson(
    String path, {
    Object? body,
    bool authenticated = true,
    bool retryable = false,
  }) {
    return _requestJson(
      'POST',
      path,
      body: body,
      authenticated: authenticated,
      retryable: retryable,
    );
  }

  Future<Map<String, dynamic>> _requestJson(
    String method,
    String path, {
    Object? body,
    Map<String, String>? queryParameters,
    required bool authenticated,
    required bool retryable,
  }) async {
    final uri = _buildUri(path, queryParameters);
    final headers = await _headers(authenticated);

    try {
      final response = await _retryInterceptor.execute(
        () => _send(method, uri, headers, body).timeout(_timeout),
        retryable: retryable,
        statusCodeOf: (value) => value.statusCode,
      );
      return _parseResponse(response);
    } on ApiException {
      rethrow;
    } on TimeoutException catch (error) {
      throw ApiException(
        message: 'Yêu cầu đã quá thời gian chờ.',
        cause: error,
      );
    } on http.ClientException catch (error) {
      throw ApiException(
        message: kDebugMode
            ? 'Không thể kết nối ${uri.origin}. Hãy chạy OTP Flask API.'
            : 'Không thể kết nối máy chủ.',
        cause: error,
      );
    } catch (error) {
      throw ApiException(
        message: 'Có lỗi kết nối không xác định.',
        cause: error,
      );
    }
  }

  Future<Map<String, String>> _headers(bool authenticated) async {
    final headers = <String, String>{
      'accept': 'application/json',
      'content-type': 'application/json; charset=utf-8',
    };
    if (attachAuthorization && authenticated) {
      final token = await _tokenProvider?.call();
      if (token != null && token.isNotEmpty) {
        headers['authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  Future<http.Response> _send(
    String method,
    Uri uri,
    Map<String, String> headers,
    Object? body,
  ) {
    if (kDebugMode) debugPrint('API $method ${uri.path}');
    final encodedBody = body == null ? null : jsonEncode(body);
    return switch (method) {
      'GET' => _client.get(uri, headers: headers),
      'POST' => _client.post(uri, headers: headers, body: encodedBody),
      _ => throw UnsupportedError('Unsupported HTTP method: $method'),
    };
  }

  Map<String, dynamic> _parseResponse(http.Response response) {
    Map<String, dynamic> json = const {};
    if (response.body.isNotEmpty) {
      try {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        if (decoded is Map<String, dynamic>) json = decoded;
      } on FormatException {
        if (response.statusCode >= 200 && response.statusCode < 300) {
          throw const ApiException(message: 'Phản hồi máy chủ không hợp lệ.');
        }
      }
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        message: json['message']?.toString() ?? 'Yêu cầu không thành công.',
        statusCode: response.statusCode,
        code: json['code']?.toString(),
      );
    }
    return json;
  }

  Uri _buildUri(String path, Map<String, String>? queryParameters) {
    final normalizedBase = _baseUri.toString().replaceFirst(RegExp(r'/$'), '');
    final normalizedPath = path.replaceFirst(RegExp(r'^/'), '');
    return Uri.parse(
      '$normalizedBase/$normalizedPath',
    ).replace(queryParameters: queryParameters);
  }

  void close() {
    if (_ownsClient) _client.close();
  }
}
