import 'cli_exception.dart';

class DidcommServiceException extends CliException {
  DidcommServiceException(String message,
      {required int code, Exception? baseException}) : super(message, code: code);
}

