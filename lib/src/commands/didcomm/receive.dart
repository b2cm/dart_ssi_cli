import 'package:dart_ssi/didcomm.dart';
import 'package:ssi_cli/src/constants.dart';
import 'package:ssi_cli/src/services/cli_service.dart';
import 'package:ssi_cli/src/services/didcomm/didcomm_service.dart';

import '../ssi_cli_base.dart';

class DidCommReceiveCommand extends SsiCliCommandBase {


  @override
  final name = COMMAND_DIDCOMM_RECEIVE;

  @override
  final description =
      "Didcomm endpoint (only supporting encrypted messages atm)";

  DidCommReceiveCommand() {
    addWalletNecessaryParametersToArgParser(
        argParser,
        isMandatory: true
    );

    argParser
      ..addOption(PARAM_DIDCOMM_MESSAGE,
          help: "JSON: Didcomm message. A message may be in JSON format or"
              " in a base64 encoded json. The message can be in plain text"
              " or encrypted.",
          mandatory: true)

      ..addMultiOption(PARAM_REPLY_TO,
          help: "endpoint(s) the response should be send to",
          valueHelp: '"https://example.com/didcomm/receive"',
      )

      ..addFlag(PARAM_ENCRYPT_MESSAGE,
          help: "If not set, the received message will be returned unencrypted.",
      )

      ..addOption(PARAM_CONNECTION_DID,
          valueHelp: '"did:ethr:0xF1..."',
          help: "DID: Connection DID. The did must "
              "be controlled by the wallet.",
          mandatory: false)

      ..addOption(PARAM_CREDENTIAL_DID,
          valueHelp: '"did:ethr:0xF1..."',
          help: "Credential did to use for. The did must "
                "be controlled by the wallet.",
          mandatory: false);
    ;

  }

  @override
  run() async {
    var message = getArgJson(PARAM_DIDCOMM_MESSAGE)!;
    var replyTo = getArgList<String>(PARAM_REPLY_TO, isOptional: true);
    var connectionDid = getArgDid(PARAM_CONNECTION_DID, isOptional: true);
    var credentialDid = getArgDid(PARAM_CREDENTIAL_DID, isOptional: true);
    bool encrypt = getArgFlag(PARAM_ENCRYPT_MESSAGE);
    var walletName = getArgString(PARAM_WALLET_NAME)!;
    var wallet = await loadWalletFromArgs();

    // Check if stuff is controlled by the wallet
    if (connectionDid != null) {
          if (!wallet.getAllConnections().keys.contains(connectionDid)) {
            writeError(
                "Connection DID `$connectionDid` "
                "not found in wallet `$walletName`", 43843
            );
          }
    }

    if (credentialDid != null) {
      if (!wallet.getAllCredentials().keys.contains(credentialDid)) {
        writeError(
            "Credential DID `$credentialDid` "
            "not found in wallet `$walletName`", 590834905
        );
      }
    }

    // encryption needs a connection did set
    if (connectionDid == null && encrypt) {
      writeError(
          "If you want to encrypt a message, you need to provide a connection DID.",
          43958349058
      );
    }

    late DidcommPlaintextMessage plain;
    // try to decrypt the message if it looks like an encrypted message
    if (message.containsKey('ciphertext')) {
      try {
        var encrypted = DidcommEncryptedMessage.fromJson(message);
        // Therefore decrypt them
        plain = await encrypted.decrypt(wallet) as DidcommPlaintextMessage;
      } on Exception catch (e) {
        writeError("Could not decrypt message due to `$e` (Code: 348209348)",
            348290348);
        //throw StateError("Could not decrypt message due to `$e`");
      }
    } else {
      // otherwise just use the message as is
      plain = DidcommPlaintextMessage.fromJson(message);
    }
    try {
      var m = await handleDidcommMessage(plain,
          wallet: wallet,
          replyTo: replyTo,
          credentialDid: credentialDid,
          connectionDid: connectionDid);
      if (m != null) {
        if (encrypt) {
          var msg = await encryptMessage(
              connectionDid: connectionDid!,
              message: m,
              wallet: wallet,
              receiverDid: m.from!
          );
          writeResultJson(msg.toJson());
        }
        writeResultJson(m.toJson());
      }
      // default message if no message was returned
      writeResult("Ack");
    } on Exception catch (e) {
      writeError("Could not handle didcomm message due to `$e`", 234234234);
    }

    writeResultJson(plain.toJson());
  }
}
