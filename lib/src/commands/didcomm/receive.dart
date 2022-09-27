import 'package:dart_ssi/didcomm.dart';
import 'package:ssi_cli/src/constants.dart';
import 'package:ssi_cli/src/services/cli_service.dart';

import '../ssi_cli_base.dart';

class DidCommReceiveCommand extends SsiCliCommandBase {


  @override
  final name = COMMAND_DIDCOMM_RECEIVE;

  @override
  final description =
      "Didcomm endpoint (only supporting encrypted messages atm)";

  DidCommReceiveCommand() {
    addWalletNecessaryParametersToArgParser(argParser);

    argParser
      ..addOption(PARAM_DIDCOMM_MESSAGE,
          help: "JSON: Didcomm message. "
              "Only encrypted messages are supported atm.",
          mandatory: true)

      ..addMultiOption(PARAM_REPLY_TO,
          help: "endpoint(s) the response should be send to",
          valueHelp: '"https://example.com/didcomm/receive"')

      ..addOption(PARAM_CONNECTION_DID,
          valueHelp: '"did:ethr:0xF1..."',
          help: "DID: Connection DID for oob message answering. The did must "
              "be controlled by the wallet.",
          mandatory: true);
    ;

  }

  @override
  run() async {
    var message = getArgJson(PARAM_DIDCOMM_MESSAGE)!;
    var replyTo = getArgList<String>(PARAM_REPLY_TO);
    var connectionDid = getArgDid(PARAM_CONNECTION_DID)!;
    var walletName = getArgString(PARAM_WALLET_NAME)!;

    var wallet = await loadWalletFromArgs();
    if (!wallet.getAllConnections().keys.contains(connectionDid)) {
      writeError("Connection DID `$connectionDid` "
                 "not found in wallet `$walletName`", 43843);
    }

    late DidcommEncryptedMessage plain;
    try {
      // For now, we only expect encrypted messages
      var encrypted = DidcommEncryptedMessage.fromJson(message);
      // Therefore decrypt them
      plain = await encrypted.decrypt(wallet) as DidcommEncryptedMessage;
    } on Exception catch (e) {
      writeError("Could not decrypt message due to `$e`", 348290348);
      throw StateError("Could not decrypt message due to `$e`");
    }

    writeResultJson(plain.toJson());
  }
}
