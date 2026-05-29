class Result<T> {
  Result.success(this.data) : error = null, isSuccess = true;
  Result.failure(this.error) : data = null, isSuccess = false;

  final T? data;
  final String? error;
  final bool isSuccess;
}
