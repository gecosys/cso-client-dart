class Result<T> {
  final int errorCode;
  final T data;
  Result({
    required this.errorCode,
    required this.data,
  });
}
