/// Most general Exception generated from this module
class CliException implements Exception {
  final String message;
  final int code;

  CliException(this.message, {required this.code});

  @override
  String toString() => "$message (Code: $code)";
}