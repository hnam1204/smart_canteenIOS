import 'package:flutter/foundation.dart';

T traceSync<T>(String label, T Function() action) {
  if (!kDebugMode && !kProfileMode) return action();
  final sw = Stopwatch()..start();
  try {
    return action();
  } finally {
    debugPrint('[PERF] $label took ${sw.elapsedMilliseconds}ms');
  }
}

Future<T> traceAsync<T>(String label, Future<T> Function() action) async {
  if (!kDebugMode && !kProfileMode) return action();
  final sw = Stopwatch()..start();
  try {
    return await action();
  } finally {
    debugPrint('[PERF] $label took ${sw.elapsedMilliseconds}ms');
  }
}
