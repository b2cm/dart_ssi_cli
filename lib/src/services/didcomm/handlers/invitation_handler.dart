import 'package:dart_ssi/didcomm.dart';
import 'package:dart_ssi/wallet.dart';
import 'package:ssi_cli/src/exceptions/didcomm_service_exceptions.dart';
import 'package:ssi_cli/src/services/didcomm/didcomm_service.dart';
import 'package:ssi_cli/src/services/didcomm/handlers/abstract_didcomm_message_handler.dart';
import 'package:ssi_cli/src/services/didcomm/handlers/presentation_request_handler.dart';

import '../../credential_service.dart';
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
  Future<DidcommMessage?>
  handle(DidcommMessage message) async {

    var supportedAttachmentTypes =
      [DidcommMessages.offerCredential, DidcommMessages.requestPresentation];

    var supportedAttachmentTypesString = supportedAttachmentTypes
      .map((e) => e.value).toList(growable: false);

    var attachments = await getPlaintextFromOobAttachments(
        OutOfBandMessage.fromJson(message.toJson()),
        expectedAttachments: supportedAttachmentTypes);

    if (attachments.fold(0, (int i, element) => i + (element.isOk ? 1 : 0)) == 0) {
        throw DidcommServiceException(
            "No valid attachment of (any) type "
            "`${supportedAttachmentTypesString.join(', ')}` was found. "
            "Details: ${attachments.map((e) => e.error).join("\n")}",
          code: 73824723);
    }

    // found a valid attachment
    DidcommPlaintextMessage attachment = attachments.firstWhere((
        element) => element.isOk).unrwap();

    if (attachment.type == DidcommMessages.offerCredential.value) {
      return await _handleOfferCredentialAttachment(attachment);
    } else if (attachment.type == DidcommMessages.requestPresentation.value) {
      return await _handleRequestPresentationAttachment(attachment);
    } else {
      throw DidcommServiceException(
          "Attachment of type `${attachment.type}` is not supported. "
          "Supported types are: "
          "`${supportedAttachmentTypesString.join(', ')}`",
          code: 45983490);
    }

  }

  Future<DidcommMessage> _handleRequestPresentationAttachment(
      DidcommPlaintextMessage attachment) async {
      var childHandler = DidcommPresentationRequestMessageHandler();

      childHandler.connectionDid = connectionDid;
      childHandler.credentialDid = credentialDid;
      childHandler.replyTo = replyTo;
      childHandler.wallet = wallet;
      return (await childHandler.execute(attachment))!;
  }

  /// Propose a message due to an oob-offer
  Future<ProposeCredential> _handleOfferCredentialAttachment(
    DidcommPlaintextMessage attachment,

    ) async {
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

