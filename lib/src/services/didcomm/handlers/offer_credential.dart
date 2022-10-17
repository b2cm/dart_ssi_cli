import 'package:dart_ssi/credentials.dart';
import 'package:dart_ssi/didcomm.dart';
import 'package:ssi_cli/src/services/didcomm/handlers/abstract_didcomm_message_handler.dart';

import '../didcomm_service.dart';

class DidcommOfferCredentialMessageHandler extends AbstractDidcommMessageHandler {

  @override
  List<String> get supportedTypes => [
    DidcommMessages.offerCredential.value
  ];

  bool get needsConnectionDid => false;
  bool get needsCredentialDid => true;
  bool get needsReplyTo => true;
  bool get needsWallet => true;

  @override
  Future<RequestCredential> handle(DidcommPlaintextMessage message) async {
    var offer = OfferCredential.fromJson(message.toJson());

    var request = generateRequestCredentialMessageFromOffer(
        offer: offer,
        replyTo: replyTo!,
        credentialDid: credentialDid!);

    return request;
  }
}