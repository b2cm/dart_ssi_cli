import 'package:ssi_cli/src/constants.dart';
import 'package:ssi_cli/src/services/oob_service.dart';
import 'package:uuid/uuid.dart';

import '../ssi_cli_base.dart';

class DidCommOObCommand extends SsiCliCommandBase {


  @override
  final name = COMMAND_DIDCOMM_OOB;

  @override
  final description = "Out of Band (OOB) messages";

  DidCommOObCommand() {
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
        help: "UUID: oob id id of the message. If not provided, "
              "a new one will be generated.",
        mandatory: true)

    ..addOption(
        PARAM_OFFER_CREDENTIAL,
        help: "JSON: credential to offer.",
        mandatory: true,
    )

    ..addMultiOption(PARAM_REPLY_TO,
        help: "endpoint(s) the response should be send to",
        valueHelp: '"https://example.com/didcomm"',
        // mandatory: true, <-- @TODO not supported. -->  Request to https://pub.dev/documentation/args/?
    )

    ..addOption(PARAM_CONNECTION_DID,
        valueHelp: '"did:ethr:0xF1..."',
        help: "UUID: Connection DID for oob message",
        mandatory: true);
  }

  @override
  run() async {
    String threadId = getArgUuid(PARAM_THREAD_ID,
        orElse: Uuid().v4().toString())!;
    String oobId = getArgUuid(PARAM_OOB_ID,
        orElse: Uuid().v4().toString())!;
    var offerCredential = getArgJson(PARAM_OFFER_CREDENTIAL,
        isOptional: true);
    var issuerDid = getArgDid(PARAM_ISSUER_DID, isOptional: false);
    var replyTo = getArgList<String>(PARAM_REPLY_TO, isOptional: false)!;
    var connectionDid = getArgDid(PARAM_CONNECTION_DID, isOptional: false)!;

    if (offerCredential != null) {
      var cred = oobOfferCredential(
          credential: offerCredential,
          oobId: oobId,
          issuerDid: issuerDid!,
          replyTo: replyTo,
          threadId: threadId,
          connectionDid: connectionDid
      );
      writeResult(cred.toJson().toString());
    }

    writeError("No operation given for `$name` command", 543958349853490);
  }
}
