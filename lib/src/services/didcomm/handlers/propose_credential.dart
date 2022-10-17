import 'package:dart_ssi/didcomm.dart';
import 'package:dart_ssi/wallet.dart';
import 'package:ssi_cli/src/exceptions/didcomm_service_exceptions.dart';
import 'package:ssi_cli/src/services/didcomm/didcomm_service.dart';
import 'package:ssi_cli/src/services/didcomm/handlers/abstract_didcomm_message_handler.dart';
import 'package:ssi_cli/src/utils/itertools.dart';

import '../oob_service.dart';

class DidcommProposeCredentialMessageHandler extends AbstractDidcommMessageHandler {

  @override
  List<String> get supportedTypes => [
    DidcommMessages.proposeCredential.value
  ];
  bool get needsConnectionDid => true;
  bool get needsCredentialDid => false;
  bool get needsReplyTo => true;
  bool get needsWallet => false;

  @override
  Future<OfferCredential?> handle(DidcommPlaintextMessage message) async {
    var propose = ProposeCredential.fromJson(message.toJson());

    // it is expected that the wallet changes the did,
    // the credential should be issued to
    var vcSubjectId = propose.detail!.first.credential.credentialSubject['id'];

    for (var ea in enumerate(propose.attachments!)) {
      var i = ea.index;
      var a = ea.value!;
      // to check, if the wallet controls the did the holder is expected
      // to sign the attachment
      try {
        if (!(await a.data.verifyJws(vcSubjectId))) {
          throw DidcommServiceException(
              "Could not verify the JWS at index ${i} because the "
              "signature is invalid",
              code: 9308490238);
        }
      } on Exception catch (e) {
        throw DidcommServiceException("The attachment at index $i is not "
            "verifiable due to `{${e.toString()}`",
            baseException: e,
            code: 4823482309);
      }
    }

    // answer with offer credential message
    var offer = OfferCredential(
        threadId: propose.threadId ?? message.id,
        detail: propose.detail,
        from: connectionDid,
        to: [propose.from!],
        replyTo: replyTo);

    return offer;
  }
}