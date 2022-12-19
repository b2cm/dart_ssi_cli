import 'package:ssi_cli/src/constants.dart';
import 'package:ssi_cli/src/services/cli_service.dart';
import 'package:dart_ssi/src/didcomm/didcomm_service.dart';

import '../ssi_cli_base.dart';

class DidCommDecryptMessageCommand extends SsiCliCommandBase {


  @override
  final name = COMMAND_DIDCOMM_DECRYPT;

  @override
  final description =
      "Decrypt a message";

  DidCommDecryptMessageCommand() {
    addWalletNecessaryParametersToArgParser(argParser)
        .addOption(PARAM_DIDCOMM_ENCRYPTED_MESSAGE,
          help: "JSON: Encrypted Didcomm message.",
          mandatory: true);

    /*argParser
        ..addOption(PARAM_DIDCOMM_ENCRYPTED_MESSAGE,
          help: "JSON: Encrypted Didcomm message (may be base64 encoded).",
          mandatory: true);*/

  }

  @override
  run() async {
    var message = getArgJson(PARAM_DIDCOMM_MESSAGE)!;
    var wallet = await loadWalletFromArgs();
    var decryptedMessage = await decryptMessage(message, wallet);
    writeResultJson(decryptedMessage.toJson());
  }
}
