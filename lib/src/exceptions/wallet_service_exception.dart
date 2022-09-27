import 'package:ssi_cli/src/exceptions/cli_exception.dart';

class WalletServiceException extends CliException {
  WalletServiceException(String message, {required int code, Exception? baseException})
      : super(message, code: code, baseException: baseException);
}
