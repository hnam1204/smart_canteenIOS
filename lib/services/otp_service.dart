import 'package:http/http.dart' as http;

import '../core/network/api_client.dart';
import '../core/network/api_exception.dart';

class OtpApiException implements Exception {
  const OtpApiException(this.message);

  final String message;
}

class OtpService {
  OtpService({ApiClient? apiClient, http.Client? client, String? baseUrl})
    : _client =
          apiClient ??
          ApiClient(
            client: client,
            baseUri: baseUrl == null ? null : Uri.parse(baseUrl),
            attachAuthorization: false,
          ),
      _ownsClient = apiClient == null;

  final ApiClient _client;
  final bool _ownsClient;

  Future<void> sendOtp(String email) async {
    await _call('/send-otp', {
      'email': email,
    }, fallback: 'Không thể gửi mã OTP.');
  }

  Future<void> verifyOtp({required String email, required String otp}) async {
    await _call('/verify-otp', {
      'email': email,
      'otp': otp,
    }, fallback: 'Mã OTP không chính xác.');
  }

  Future<void> resetPassword({
    required String email,
    required String verificationCode,
    required String newPassword,
  }) async {
    await _call('/reset-password', {
      'email': email,
      'otp': verificationCode,
      'newPassword': newPassword,
    }, fallback: 'Không thể đổi mật khẩu.');
  }

  Future<void> _call(
    String path,
    Map<String, String> body, {
    required String fallback,
  }) async {
    try {
      final response = await _client.postJson(
        path,
        body: body,
        authenticated: false,
      );
      if (response['success'] != true) {
        throw OtpApiException(response['message']?.toString() ?? fallback);
      }
    } on OtpApiException {
      rethrow;
    } on ApiException catch (error) {
      throw OtpApiException(error.message);
    }
  }

  void close() {
    if (_ownsClient) _client.close();
  }
}
