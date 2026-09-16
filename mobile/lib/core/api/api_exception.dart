/// A typed exception carrying the `message` from CONTRACT.md's error shape:
/// ```json
/// { "timestamp": "...", "status": 400, "error": "Bad Request",
///   "message": "...", "path": "/api/..." }
/// ```
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final String? path;

  const ApiException(this.message, {this.statusCode, this.path});

  /// True for connectivity-type failures (no response from the server at
  /// all), as opposed to a well-formed error response.
  bool get isNetworkError => statusCode == null;

  @override
  String toString() => 'ApiException($statusCode): $message';
}
