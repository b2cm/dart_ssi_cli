import 'package:args/command_runner.dart';
import 'package:ssi_cli/src/commands/ssi_cli_base.dart';

import 'oob.dart';

/// Didcomm related commands
class DidCommCommand extends SsiCliCommandBase {
  static const String DIDCOMM_COMMAND_NAME = 'didcomm';

  @override
  final name = DIDCOMM_COMMAND_NAME;

  @override
  final description = 'Didcomm (Message based Communication protocol)';

  DidCommCommand() {
    addSubcommand(DidCommOObCommand());
  }
}
