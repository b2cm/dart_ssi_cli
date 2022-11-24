import 'package:dart_ssi/didcomm.dart';
import 'package:ssi_cli/src/constants.dart';
import 'package:ssi_cli/src/services/cli_service.dart';
import 'package:ssi_cli/src/services/didcomm/didcomm_service.dart';

import '../ssi_cli_base.dart';

class DidCommEncryptMessageCommand extends SsiCliCommandBase {


  @override
  final name = COMMAND_DIDCOMM_ENCRYPT;

  @override
  final description =
      "Encrypt a message";

  DidCommEncryptMessageCommand() {
    addWalletNecessaryParametersToArgParser(argParser);

    argParser
      ..addOption(PARAM_DIDCOMM_MESSAGE,
          help: "JSON: Didcomm message to encrypt (must have a recipient).",
          mandatory: true)

    ..addOption(PARAM_CONNECTION_DID,
        help: "Connection DID to use (will default to messages `from` field if "
            "not explicitly set).",
        mandatory: false)

    ..addOption(PARAM_RECEIVER_DID,
        help: "DID of the receiver (will default to messages `to` field if "
            "not explicitly set).",
        mandatory: false);

  }

  @override
  run() async {
    var message = getArgJson(PARAM_DIDCOMM_MESSAGE)!;
    var wallet = await loadWalletFromArgs();
    var connectionDid = getArgDid(PARAM_CONNECTION_DID, isOptional: true);
    var receiverDid = getArgDid(PARAM_RECEIVER_DID, isOptional: true);

    if (connectionDid == null) {
      if (!message.containsKey('from')) {
        writeError("No connection did supplied and message does also not have "
            "a `from` field", 7583747534, terminate: true);
      }
      connectionDid = message['from'];
    }

    if (receiverDid == null) {
      if (!message.containsKey('to')) {
        writeError("No receiver did supplied and message does also not have "
            "a `to` field", 9834095834, terminate: true);
      }
      receiverDid = message['to'].first as String;
    }
    var plaintextMessage = DidcommPlaintextMessage.fromJson(message);
    var decryptedMessage = await encryptMessage(connectionDid: connectionDid!,
        wallet: wallet, message: plaintextMessage, receiverDid: receiverDid);

    writeResultJson(decryptedMessage.toJson());
  }
}
