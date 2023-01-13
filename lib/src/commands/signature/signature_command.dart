import 'package:ssi_cli/src/commands/signature/sign.dart';
import 'package:ssi_cli/src/commands/signature/verify.dart';
import 'package:ssi_cli/src/commands/ssi_cli_base.dart';
import 'package:ssi_cli/src/constants.dart';

class SignatureCommand extends SsiCliCommandBase {


  @override
  final name = COMMAND_SIGNATURE;

  @override
  final description =
      "Signs data or verifies signatures";

  SignatureCommand() {
    addSubcommand(SignCommand());
    addSubcommand(VerifyCommand());
  }

}
