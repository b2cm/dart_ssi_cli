import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:ssi_cli/src/commands/utils/did_utils.dart';
import 'package:uuid/uuid.dart';

/// Wrapper around Commands
///
/// will offer some helper functionality like
/// parsing arguments by type and error handling
abstract class SsiCliCommandBase extends Command {

  /// writes the string [error] to stderr
  /// and exits the program with exit code 2 if [terminate] is true
  /// [errorCode] is a internal error code (should be unique)
  write_error(String error, int errorCode, {bool terminate = true}) {
    stderr.writeln(error);
    if (terminate) {
      exit(2);
    }
  }

  /// writes [result] to stdout if
  /// [terminate] if true, the program will exit after writing
  write_result(String result, {bool terminate = true}) {
    stdout.writeln(result);
    if (terminate) {
      exit(0);
    }
  }

  /// the wrapper around [write_result]
  write_result_json(Map<String, dynamic> result, {bool terminate = true}) {
    var str = jsonEncode(result);
    write_result(str, terminate: terminate);
  }

  /// tries to get a argument as String
  /// if the argument is not present, [orElse] is returned
  /// if [orElse] is also null, an error is written to
  /// stderr and the program exits
  String getArgString(String name, {String? orElse}) {
    var arg = argResults![name];
    if (arg == null) {
      if (orElse != null) {
        return orElse;
      }
      write_error('Missing argument `$name`', 2342342365);
    }
    return arg;
  }

  /// tries to parse argument as uuid
  /// if it is not available [orElse] will be returned
  /// if [orElse] is also null, an error will be written to stderr
  /// and the program will exit
  String get_arg_uuid(String name, {String? orElse}) {
    var arg = argResults![name];
    if (arg == null) {
      if (orElse != null) {
        return orElse;
      }

      write_error('Missing argument `$name`', 2342342365);
    }

    if (Uuid.isValidUUID(fromString: arg)) {
         return arg;
    }

    write_error("$name must be a valid UUID, however `$arg` is not", 3894328,
        terminate: true);

    /// this cannot happen as write_error terminates the program
    /// but the compiler is not that smart
    throw StateError('no program flow to here. (Code: 4293423)');
  }

  /// tries to parse argument as json
  /// if [isOptional] is true, null will be returned if the argument is not present
  /// if [isOptional] is false, an error will be written and the value is not
  /// a JSON, an error is is written to stderr and the program will exit
  Map<String, dynamic>? getArgJson(String name,
      {Map<String, dynamic>? orElse, isOptional = false}) {
    var arg = argResults![name];
    if (arg == null) {

      // write [orElse] or null if it [isOptional] and not present
      if (orElse != null || isOptional) {
        return orElse;
      }

      write_error("Missing argument `$name`", 34534853490583);
    }

    try {
      return jsonDecode(arg) as Map<String, dynamic>;
    } catch (e) {
      write_error(
          "Argument `$name` must be a valid json string, however `$arg` is not",
          394853490);
    }

    /// this cannot happen as write_error terminates the program
    /// but the compiler is not that smart
    throw StateError('no program flow to here. (Code: 72934553)');
  }

  String? getArgDid(String name,
      {String? orElse, isOptional = false}) {
    var arg = argResults![name];

    if (arg == null) {
      // write [orElse] or null if it [isOptional] and not present
      if (orElse != null || isOptional) {
        return orElse;
      }
      write_error("Missing argument `$name`", 423723984);
    }

    if (!isValidDid(arg)) {
      write_error("Expected `$name` to be a did, but found $arg}",
          835490384);
    }

    return arg;
  }


  List<T>? getArgList<T>(String name, {List<T>? orElse, isOptional = false}) {
    var arg = argResults![name];

    if (arg == null || arg.isEmpty) {
      // write [orElse] or null if it [isOptional] and not present
      if (orElse != null || isOptional) {
        return orElse;
      }
      write_error("Missing argument `$name`", 58345905834);
    }

    try {
      return arg.cast<T>();
    } catch (e) {
      write_error(
          "Argument `$name` ,ust be a List of ${T.runtimeType} but"
              " `$arg` is not", 394853490);
    }

    /// this cannot happen as write_error terminates the program
    /// but the compiler is not that smart
    throw StateError('no program flow to here. (Code: 34278293)');
  }
}

