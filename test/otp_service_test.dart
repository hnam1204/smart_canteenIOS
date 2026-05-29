import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:smart_canteen/services/otp_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('resetPassword sends OTP proof with the new password request', () async {
    late http.Request capturedRequest;
    final service = OtpService(
      baseUrl: 'https://api.example.test',
      client: MockClient((request) async {
        capturedRequest = request;
        return http.Response('{"success":true}', 200);
      }),
    );

    await service.resetPassword(
      email: 'student@example.com',
      verificationCode: '123456',
      newPassword: 'secure-password',
    );

    expect(capturedRequest.method, 'POST');
    expect(capturedRequest.url.path, '/reset-password');
    expect(jsonDecode(capturedRequest.body), <String, dynamic>{
      'email': 'student@example.com',
      'otp': '123456',
      'newPassword': 'secure-password',
    });
  });
}
