import 'package:dart_ssi/credentials.dart';
import 'package:dart_ssi/didcomm.dart';
import 'package:ssi_cli/src/constants.dart';
import 'package:ssi_cli/src/services/cli_service.dart';
import 'package:dart_ssi/src/didcomm/didcomm_service.dart';
import 'package:uuid/uuid.dart';

import '../ssi_cli_base.dart';

class DidCommOObCommand extends SsiCliCommandBase {

  @override
  final name = COMMAND_DIDCOMM_OOB;

  @override
  final description =
      "Out of Band (OOB) messages. "
      "Currently supports Credential Offers and Presentation Requests.";

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
        help:
            "UUID: issuer did id of the message. "
            "Should be in control of the wallet. "
            "If not given, the wallets standard issuing did will be used ",
        mandatory: false)

    ..addOption(
        PARAM_OFFER_CREDENTIAL,
        help: "JSON: credential to offer. If you want to offer some",
        mandatory: false,
    )

    ..addOption(
        PARAM_CHALLENGE,
        help: "Challenge to use for the OOB message. "
              "Only used if ${PARAM_PRESENTATION_DEFINITION} is set. "
              "If not given, a random challenge will be generated.",
        mandatory: false,
    )

    ..addOption(
        PARAM_PRESENTATION_DEFINITION,
        help: "JSON: credential to request; If you want to request one.",
        mandatory: false)

    ..addOption(
        PARAM_DOMAIN,
        help: "Domain to use for the OOB message. Only used if ${PARAM_PRESENTATION_DEFINITION} is set.",
        mandatory: false)

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
        help: "If not set, the received message will be returned unencrypted. "
            "Likely not useful. Only works if you know the receiver_did",
    )

    ..addOption(PARAM_RECEIVER_DID,
        valueHelp: '"did:ethr:0xF1..."',
        help: "UUID: Receiver DID for oob message. "
              "Must be set when using option `--${PARAM_ENCRYPT_MESSAGE}`",
        mandatory: false)

    ;
  }

  @override
  run() async {
    String threadId = getArgUuid(PARAM_THREAD_ID,
        orElse: Uuid().v4().toString())!;
    String oobId = getArgUuid(PARAM_OOB_ID,
        orElse: Uuid().v4().toString())!;
    var offerCredential = getArgJson(PARAM_OFFER_CREDENTIAL,
        isOptional: true);
    var domain = getArgString(PARAM_DOMAIN, isOptional: true);
    var requestCredential = getArgJson(PARAM_PRESENTATION_DEFINITION,
        isOptional: true);
    var wallet = await loadWalletFromArgs();
    var issuerDid = getArgDid(PARAM_ISSUER_DID, isOptional: true,
        orElse: wallet.getStandardIssuerDid());
    var replyTo = getArgList<String>(PARAM_REPLY_TO, isOptional: false)!;
    var connectionDid = getArgDid(PARAM_CONNECTION_DID, isOptional: false)!;
    var encrypt = getArgFlag(PARAM_ENCRYPT_MESSAGE);
    var walletName = getArgString(PARAM_WALLET_NAME);
    var receiverDid = getArgDid(PARAM_RECEIVER_DID, isOptional: true);

    if (encrypt && receiverDid == null) {
      writeResult(
          "When encrypting the message, the receiver must be known. "
          "Use `--${PARAM_RECEIVER_DID}` (Code: 843276)"
      );
    }

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

      // Remember the conversation so we can decrypt the response
      await wallet.storeConversationEntry(cred, cred.from ?? connectionDid);

      if (encrypt) {
         var msg = await encryptMessage(
             connectionDid: connectionDid,
             message: cred,
             wallet: wallet,
             receiverDid: receiverDid!,
         );
         writeResultJson(msg.toJson());
       }
       writeResultJson(cred.toJson());

    } else if (requestCredential != null) {
      if (domain == null) {
        writeError(
            "When requesting a credential, the domain must be set. "
            "Use `--${PARAM_DOMAIN}`", 234234
        );
      }

      String challenge = getArgString(PARAM_CHALLENGE, isOptional: true,
          orElse: Uuid().v4().toString())!;

      var oob = oobRequestPresentation(
          presentationDefinition: PresentationDefinition.fromJson(requestCredential),
          oobId: oobId,
          threadId: threadId,
          replyTo: replyTo,
          issuerDid: issuerDid!,
          connectionDid: connectionDid,
          challenge: challenge,
          domain: domain!);

      await wallet.storeConversationEntry(oob, oob.from ?? connectionDid);

      if (encrypt) {
        var msg = await encryptMessage(
             connectionDid: connectionDid,
             message: oob,
             wallet: wallet,
             receiverDid: receiverDid!,
         );
         writeResultJson(msg.toJson());
       }
      writeResultJson(oob.toJson());
    }
    writeError("No operation given for `$name` command", 353456196);
  }
}
