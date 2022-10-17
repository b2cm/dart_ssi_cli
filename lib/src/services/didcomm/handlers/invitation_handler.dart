import 'package:dart_ssi/didcomm.dart';
import 'package:dart_ssi/wallet.dart';
import 'package:ssi_cli/src/exceptions/didcomm_service_exceptions.dart';
import 'package:ssi_cli/src/services/didcomm/didcomm_service.dart';
import 'package:ssi_cli/src/services/didcomm/handlers/abstract_didcomm_message_handler.dart';

import '../oob_service.dart';

class DidcommInvitationMessageHandler extends AbstractDidcommMessageHandler {
  @override
  List<String> get supportedTypes => [
    DidcommMessages.invitation.value
  ];

  bool get needsConnectionDid => true;
  bool get needsCredentialDid => true;
  bool get needsReplyTo => true;
  bool get needsWallet => true;

  @override
  Future<ProposeCredential?>
  handle(DidcommPlaintextMessage message) async {

    var  attachments = (await getPlaintextFromOobAttachments(
        OutOfBandMessage.fromJson(message.toJson()),
        expectedAttachment: DidcommMessages.offerCredential));
    if (attachments.fold(0, (int i, element) => i + (element.isOk ? 1 : 0)) == 0) {
        throw DidcommServiceException(
            "No valid attachment of type "
            "${DidcommMessages.offerCredential.value} was found in attachments. "
            "Details: ${attachments.map((e) => e.error).join("\n")}",
          code: 73824723);
    }

    // found a valid attachment
    var attachment = attachments.firstWhere((
        element) => element.isOk).unrwap();

    late OfferCredential offer;
    try {
      offer = OfferCredential.fromJson(attachment.toJson());
    } catch (e) {
      throw DidcommServiceException("The Attachment needs to be a valid Credential Offer message. "
          "However, I could not "
          "parse it as Credential Offer due to `$e`",
      code: 234234);
    }
    var proposal = await generateProposeCredentialMessage(
        offer: offer,
        wallet: wallet!,
        connectionDid: connectionDid!,
        credentialDid: credentialDid!,
        replyTo: replyTo!,
    );

    return proposal;
  }
}