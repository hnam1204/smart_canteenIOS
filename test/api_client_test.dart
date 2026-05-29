import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:smart_canteen/core/network/api_client.dart';
import 'package:smart_canteen/core/network/api_exception.dart';

void main() {
  test('api client sends bearer authorization headers', () async {
    late http.Request request;
    final client = ApiClient(
      client: MockClient((incoming) async {
        request = incoming;
        return http.Response('{"ok":true}', 200);
      }),
      baseUri: Uri.parse('https://api.example.test/v1'),
      tokenProvider: () async => 'token-value',
    );

    await client.getJson('/orders');

    expect(request.url.toString(), 'https://api.example.test/v1/orders');
    expect(request.headers['authorization'], 'Bearer token-value');
  });

  test('api client exposes normalized server errors', () async {
    final client = ApiClient(
      client: MockClient(
        (_) async => http.Response.bytes(
          utf8.encode('{"message":"Không hợp lệ"}'),
          422,
          headers: const {'content-type': 'application/json; charset=utf-8'},
        ),
      ),
      baseUri: Uri.parse('https://api.example.test/v1'),
    );

    expect(
      () => client.postJson('/orders', body: const {}),
      throwsA(
        isA<ApiException>()
            .having((error) => error.statusCode, 'statusCode', 422)
            .having((error) => error.message, 'message', 'Không hợp lệ'),
      ),
    );
  });
}
