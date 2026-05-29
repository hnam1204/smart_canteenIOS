import 'dart:async';
import 'package:http/http.dart' as http;

class RetryInterceptor {
  const RetryInterceptor({
    this.maxAttempts = 3,
    this.baseDelay = const Duration(milliseconds: 350),
  }) : assert(maxAttempts > 0);

  final int maxAttempts;
  final Duration baseDelay;

  Future<T> execute<T>(
    Future<T> Function() request, {
    required bool retryable,
    int? Function(T value)? statusCodeOf,
  }) async {
    var attempt = 0;
    while (true) {
      attempt++;
      try {
        final result = await request();
        final status = statusCodeOf?.call(result);
        if (retryable &&
            attempt < maxAttempts &&
            status != null &&
            _retryStatus(status)) {
          await Future<void>.delayed(_delayFor(attempt));
          continue;
        }
        return result;
      } on TimeoutException catch (_) {
        if (!retryable || attempt >= maxAttempts) rethrow;
        await Future<void>.delayed(_delayFor(attempt));
      } on http.ClientException catch (_) {
        if (!retryable || attempt >= maxAttempts) rethrow;
        await Future<void>.delayed(_delayFor(attempt));
      }
    }
  }

  bool _retryStatus(int statusCode) {
    return statusCode == 408 || statusCode == 429 || statusCode >= 500;
  }

  Duration _delayFor(int attempt) => baseDelay * attempt;
}
