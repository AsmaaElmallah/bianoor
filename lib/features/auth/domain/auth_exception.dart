class BayanourAuthException implements Exception {
  const BayanourAuthException(this.message);

  final String message;

  @override
  String toString() => message;
}

@Deprecated('Use BayanourAuthException')
typedef AuthException = BayanourAuthException;
