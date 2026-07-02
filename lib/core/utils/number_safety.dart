double safeFiniteDouble(num? value, {double fallback = 0}) {
  final v = value?.toDouble();
  if (v == null || v.isNaN || v.isInfinite) return fallback;
  return v;
}
