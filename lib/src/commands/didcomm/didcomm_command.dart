import 'package:ssi_cli/src/commands/didcomm/decrypt.dart';
import 'package:ssi_cli/src/commands/didcomm/encrypt.dart';
import 'package:ssi_cli/src/commands/didcomm/receive.dart';
import 'package:ssi_cli/src/commands/didcomm/verify_presentation.dart';
import 'package:ssi_cli/src/commands/ssi_cli_base.dart';

import '../../constants.dart';
import 'oob.dart';

/// Didcomm related commands
class DidCommCommand extends SsiCliCommandBase {

  @override
  final name = COMMAND_DIDCOMM;

  @override
  final description = "Didcomm (Message based Communication protocol)";

  DidCommCommand() {
    addSubcommand(DidCommOObCommand());
    addSubcommand(DidCommReceiveCommand());
    addSubcommand(DidCommDecryptMessageCommand());
    addSubcommand(DidCommEncryptMessageCommand());
    addSubcommand(DidCommVerifyPresentationCommand());
  }
}
