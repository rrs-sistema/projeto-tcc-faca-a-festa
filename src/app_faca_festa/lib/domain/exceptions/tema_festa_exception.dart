class TemaFestaException implements Exception {
  const TemaFestaException(this.code, [this.message]);

  final String code;
  final String? message;

  @override
  String toString() =>
      message?.trim().isNotEmpty == true ? '$code: $message' : code;
}
