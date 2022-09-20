import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:dart_ssi/wallet.dart';
import 'package:ssi_cli/src/constants.dart';
import 'package:ssi_cli/src/exceptions/wallet_service_exception.dart';
import 'package:ssi_cli/src/services/wallet_service.dart';
import 'package:ssi_cli/src/utils/path_utils.dart';
import 'package:uuid/uuid.dart';
import 'package:args/args.dart';
import '../utils/did_utils.dart';

/// Wrapper around Commands
///
/// will offer some helper functionality like
/// parsing arguments by type and error handling
abstract class SsiCliCommandBase extends Command {

  /// writes the string [error] to stderr
  /// and exits the program with exit code 2 if [terminate] is true
  /// [errorCode] is a internal error code (should be unique)
  writeError(String error, int errorCode, {bool terminate = true}) {
    stderr.writeln(error);
    if (terminate) {
      exit(2);
    }
  }

  /// writes [result] to stdout if
  /// [terminate] if true, the program will exit after writing
  writeResult(String result, {bool terminate = true}) {
    stdout.writeln(result);
    if (terminate) {
      exit(0);
    }
  }

  /// converts [result] to json and writes it to stdout
  writeResultJson(Map<dynamic, dynamic> result, {bool terminate = true}) {
    var res = jsonEncode(result, toEncodable: (obj) {
      try {
        return (result as dynamic).toJson();
      } catch (e) {
        return result.toString();
      }
    });

    writeResult(res, terminate: terminate);
  }

  /// just a normal Output to stdout
  writeMessage(String message) {
    stdout.writeln(message);
  }

  /// tries to get a argument as String
  /// if the argument is not present, [orElse] is returned
  /// if [orElse] is also null, an error is written to
  /// if [nonEmpty] is true, an error is written if the argument is is empty
  /// stderr and the program exits
  String? getArgString(String name,
      {String? orElse, isOptional = false, nonEmpty=true, trim=true}) {
    String? arg = _getArgValue(name);
    if (arg == null) {
      if (orElse != null || isOptional) {
        return orElse;
      }
      writeError('Missing argument `$name`', 5983409583);
    }

    String arg_parsed = arg!;
    if (trim) {
      arg = arg_parsed.trim();
    }

    // strings like `"   "` pass iff [trim] is `false`
    if (nonEmpty && arg_parsed.length == 0) {
      writeError('Argument `$name` cannot be empty but was `$arg}`',
          29384230984);
    }

    return arg_parsed;
  }

  /// tries to parse argument as uuid
  /// if it is not available [orElse] will be returned
  /// if [orElse] is also null, an error will be written to stderr
  /// and the program will exit
  String? getArgUuid(String name, {String? orElse, isOptional = false}) {
    var arg = _getArgValue(name);
    if (arg == null) {
      if (orElse != null || isOptional) {
        return orElse;
      }

      writeError('Missing argument `$name`', 2342342365);
    }

    if (Uuid.isValidUUID(fromString: arg)) {
         return arg;
    }

    writeError("$name must be a valid UUID, however `$arg` is not", 3894328,
        terminate: true);
  }

  /// tries to parse argument as json
  /// if [isOptional] is true, null will be returned if the argument is not present
  /// if [isOptional] is false, an error will be written and the value is not
  /// a JSON, an error is is written to stderr and the program will exit
  Map<String, dynamic>? getArgJson(String name,
      {Map<String, dynamic>? orElse, isOptional = false}) {
    var arg = _getArgValue(name);
    if (arg == null) {

      // write [orElse] or null if it [isOptional] and not present
      if (orElse != null || isOptional) {
        return orElse;
      }

      writeError("Missing argument `$name`", 34534853490583);
    }

    try {
      return jsonDecode(arg) as Map<String, dynamic>;
    } catch (e) {
      writeError(
          "Argument `$name` must be a valid json string, however `$arg` is not",
          394853490);
    }
  }

  /// gets an argument as directory, optionally checks if it exists
  Directory? getArgDirectory(String name, {Directory? orElse,
    isOptional = false, mustExist = false}) {
    var arg = _getArgValue(name);
    if (arg == null) {
      if (orElse != null || isOptional) {
        return orElse;
      }
      writeError('Missing argument `$name`', 3423423);
    }

    var dir = Directory(arg);
    if (mustExist && !dir.existsSync()) {
      writeError('Directory `$arg` does not exist', 3453451324);
    }

    return dir;
  }

  /// gets an DID-argument (also checks format)
  String? getArgDid(String name,
      {String? orElse, isOptional = false}) {
    var arg = _getArgValue(name);

    if (arg == null) {
      // write [orElse] or null if it [isOptional] and not present
      if (orElse != null || isOptional) {
        return orElse;
      }
      writeError("Missing argument `$name`", 423723984);
    }

    if (!isValidDid(arg)) {
      writeError("Expected `$name` to be a did, but found $arg}",
          835490384);
    }

    return arg;
  }


  List<T>? getArgList<T>(String name, {List<T>? orElse, isOptional = false}) {
    var arg = _getArgValue(name);

    if (arg == null || arg.isEmpty) {
      // write [orElse] or null if it [isOptional] and not present
      if (orElse != null || isOptional) {
        return orElse;
      }
      writeError("Missing argument `$name`", 58345905834);
    }

    try {
      return arg.cast<T>();
    } catch (e) {
      writeError(
          "Argument `$name` ,ust be a List of ${T.runtimeType} but"
              " `$arg` is not", 394853490);
    }
  }

  /// parses the wallets' directory using standard parameter names
  /// if [dataDirMustExist] is true, an error is written if the parent directory
  /// does not exist.
  /// if [effectivePathMustExist] is true, an error is written if the effective
  /// path (data_dir / wallet_name) does not exist
  Directory getEffectiveWalletDir({isOptional = false,
    dataDirMustExist = true,
    effectivePathMustExist = true}) {

    Directory base = getArgDirectory(PARAM_DATA_DIR,
        mustExist: dataDirMustExist)!;

    String walletName = getArgString(PARAM_WALLET_NAME, isOptional: false,
        nonEmpty: true)!;

    var effectivePath  = base / walletName;
    if (effectivePathMustExist && !effectivePath.existsSync()) {
      writeError('Wallet directory `$effectivePath` does not exist',  237482374);
    }

    return effectivePath;
  }

  Future<WalletStore> loadWallet() async {
    var path = getEffectiveWalletDir(dataDirMustExist: true,
        effectivePathMustExist: true);

    var password = getArgString(PARAM_PASSWORD, isOptional: false,
        nonEmpty: true)!;

    try {
      return loadAndOpenWallet(path: path, password: password);
    } on WalletServiceException catch (e) {
      writeError("Couldn't open wallet due to `${e.message} (Code: ${e.code}",
          349823904, terminate: true);
    }
    // unreachable
    exit(2);
  }

  /// parses the key type parameter
  /// if the key type is not supported will raise
  KeyType getArgKeyType() {
    var keyType = getArgString(PARAM_KEY_TYPE, isOptional: false,
        nonEmpty: true)!;
    try {
      return keyTypeFromString(keyType);
    } catch (e) {
      writeError("Invalid key type `$keyType`. "
          "Only ${getSupportedKeyTypes().join(', ')} are supported", 239847238,
          terminate: true);
    }

    // unreachable
    exit(2);
  }

  /// tries to get an argument from the command,
  ///
  /// [commandLevel] defaults to the current Command and bubbles to parents
  /// if [checkParent] is `true`
  dynamic _getArgValue(String name, {checkParent: true, Command? commandLevel: null}) {
    commandLevel = commandLevel ?? this;
    var args = commandLevel.argResults!;
    try {
      return args[name];
    } catch (e) {
      // bubble down to parent parser if requested
      if (checkParent && commandLevel.parent != null) {
        return _getArgValue(name,
            checkParent: checkParent, commandLevel: commandLevel.parent!);
      }
      return null;
    }
  }
}
