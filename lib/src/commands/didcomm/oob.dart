import 'package:ssi_cli/src/constants.dart';
import 'package:ssi_cli/src/services/cli_service.dart';
import 'package:ssi_cli/src/services/didcomm/didcomm_service.dart';
import 'package:ssi_cli/src/services/didcomm/oob_service.dart';
import 'package:uuid/uuid.dart';

import '../ssi_cli_base.dart';

class DidCommOObCommand extends SsiCliCommandBase {


  @override
  final name = COMMAND_DIDCOMM_OOB;

  @override
  final description = "Out of Band (OOB) messages";

  DidCommOObCommand() {
    addWalletNecessaryParametersToArgParser(argParser, isMandatory: true);

    argParser
      ..addOption(PARAM_THREAD_ID,
        valueHelp: '"${Uuid().v4().toString()}"',
        help: "UUID: thread id of the message. If not provided, "
              "a new one will be generated.",
        mandatory: false,
      )

    ..addOption(PARAM_OOB_ID,
        valueHelp: '"${Uuid().v4().toString()}"',
        help: "UUID: oob id id of the message. If not provided, "
            "a new one will be generated.",
        mandatory: false,
    )

    ..addOption(PARAM_ISSUER_DID,
        valueHelp: '"did:ethr:0xF1..."',
        help: "UUID: issuer did id of the message.",
        mandatory: true)

    ..addOption(
        PARAM_OFFER_CREDENTIAL,
        help: "JSON: credential to offer.",
        mandatory: true,
    )

    ..addMultiOption(PARAM_REPLY_TO,
        help: "endpoint(s) the response should be send to",
        valueHelp: '"https://example.com/didcomm/receive"',
        // mandatory: true, <-- @TODO not supported.
        //  -->  Request to https://pub.dev/documentation/args/ ?
    )

    ..addOption(PARAM_CONNECTION_DID,
        valueHelp: '"did:ethr:0xF1..."',
        help: "UUID: Connection DID for oob message",
        mandatory: true)

    ..addFlag(PARAM_ENCRYPT_MESSAGE,
        help: "If not set, the received message will be returned unencrypted.",
    )

    ;
  }

  @override
  run() async {
    String threadId = getArgUuid(PARAM_THREAD_ID,
        orElse: Uuid().v4().toString())!;
    String oobId = getArgUuid(PARAM_OOB_ID,
        orElse: Uuid().v4().toString())!;
    var offerCredential = getArgJson(PARAM_OFFER_CREDENTIAL,
        isOptional: false);
    var issuerDid = getArgDid(PARAM_ISSUER_DID, isOptional: false);
    var replyTo = getArgList<String>(PARAM_REPLY_TO, isOptional: false)!;
    var connectionDid = getArgDid(PARAM_CONNECTION_DID, isOptional: false)!;
    var encrypt = getArgFlag(PARAM_ENCRYPT_MESSAGE);
    var walletName = getArgString(PARAM_WALLET_NAME);
    var wallet = await loadWalletFromArgs();

    // Check if stuff is controlled by the wallet
    if (!wallet
        .getAllConnections()
        .keys
        .contains(connectionDid)) {
      writeError(
          "Connection DID `$connectionDid` "
              "not found in wallet `$walletName`",
          23423094
      );
    }

    // encryption needs a connection did set
    if (offerCredential != null) {
      var cred = oobOfferCredential(
          credential: offerCredential,
          oobId: oobId,
          issuerDid: issuerDid!,
          replyTo: replyTo,
          threadId: threadId,
          connectionDid: connectionDid
      );

       if (encrypt) {

          var msg = await encryptMessage(
              connectionDid: connectionDid,
              message: cred,
              wallet: wallet,
              receiverDid: cred.from!
          );
          writeResultJson(msg.toJson());
        }
        writeResultJson(cred.toJson());
      }

    writeError("No operation given for `$name` command", 353456196);

  }
}
