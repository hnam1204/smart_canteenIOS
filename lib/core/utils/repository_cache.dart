class CacheEntry<T> {
  const CacheEntry({required this.data, required this.cachedAt});

  final T data;
  final DateTime cachedAt;

  bool isValid(Duration ttl) => DateTime.now().difference(cachedAt) < ttl;
}
