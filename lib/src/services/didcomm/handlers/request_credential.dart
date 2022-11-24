import 'package:dart_ssi/credentials.dart';
import 'package:dart_ssi/didcomm.dart';
import 'package:ssi_cli/src/exceptions/didcomm_service_exceptions.dart';
import 'package:ssi_cli/src/services/didcomm/didcomm_service.dart';
import 'package:ssi_cli/src/services/didcomm/handlers/abstract_didcomm_message_handler.dart';

class DidcommRequestCredentialMessageHandler extends AbstractDidcommMessageHandler {

  @override
  List<String> get supportedTypes => [
    DidcommMessages.requestCredential.value
  ];

  bool get needsConnectionDid => false;
  bool get needsCredentialDid => false;
  bool get needsReplyTo => true;
  bool get needsWallet => true;

  @override
  Future<IssueCredential?> handle(DidcommMessage message) async {
    message as DidcommPlaintextMessage;

    var request = RequestCredential.fromJson(message.toJson());
    var credential = request.detail!.first.credential;
    if (!credential.context.contains('https://schema.org')) {
      credential.context.add('https://schema.org');
    }

    // sign the requested credential
    // (normally we had to check before that,
    // that the data in it is the same we offered)
    // Hint: the REST API does some very basic check for that (see handler there)
    late String signed;
    try {
        signed = await signCredential(wallet!,
        credential,
        challenge: request.detail!.first.options.challenge);
    } on Exception catch (e) {
      throw DidcommServiceException("Could not sign the credential "
          "due to `${e.toString()}`",
          baseException: e,
          code: 3459340);
    }

    // issue the credential
    var issue = IssueCredential(
        threadId: message.threadId ?? message.id,
        from: getConversationDid(message, wallet!),
        to: [message.from!],
        replyTo: replyTo,
        pleaseAck: true,
        credentials: [VerifiableCredential.fromJson(signed)]);

    // patch ack as per didcomm spec (make sure the message contains
    // itself to be acked)
    if(issue.pleaseAck == null) {
      issue.pleaseAck = [];
    }

    if (!(issue.pleaseAck!.contains('') || issue.pleaseAck!.contains(issue.id))) {
      issue.pleaseAck!.add(issue.id);
    }
    return issue;
  }
}
