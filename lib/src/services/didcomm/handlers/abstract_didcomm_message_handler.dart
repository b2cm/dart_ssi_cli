import 'package:dart_ssi/didcomm.dart';
import 'package:dart_ssi/wallet.dart';
import 'package:ssi_cli/src/exceptions/didcomm_service_exceptions.dart';
import 'package:ssi_cli/src/services/didcomm/handlers/offer_credential.dart';
import 'package:ssi_cli/src/services/didcomm/handlers/propose_credential.dart';
import 'package:ssi_cli/src/services/didcomm/handlers/request_credential.dart';

import 'invitation_handler.dart';

/// Abstract class for handling DidComm messages
abstract class AbstractDidcommMessageHandler {
  String? connectionDid;
  String? credentialDid;
  List<String>? replyTo;
  WalletStore? wallet;

  List<String> get supportedTypes;

  bool get needsConnectionDid;
  bool get needsCredentialDid;
  bool get needsReplyTo;
  bool get needsWallet;

  AbstractDidcommMessageHandler();
  Future<DidcommPlaintextMessage?> execute(DidcommPlaintextMessage message) {
    if (needsConnectionDid && connectionDid == null) {
      throw DidcommServiceException(
          "Handler for ${message.type}  needs a connection did.",
          code: 3249823);
    }
    if (needsCredentialDid && credentialDid == null) {
      throw DidcommServiceException(
          "Handler for ${message.type} needs a credential did.",
          code: 23498239402);
    }
    if (needsWallet && wallet == null) {
      throw DidcommServiceException(
          "Handler for ${message.type} needs a wallet.",
          code: 823490835);
    }

    if (needsReplyTo && (replyTo == null || replyTo!.isEmpty)) {
      throw DidcommServiceException(
          "Handler for ${message.type} needs a replyTo.",
          code: 9583490);
    }

    if (!supportedTypes.contains(message.type)) {
      throw DidcommServiceException(
          "Handler cannot handle ${message.type} messages.",
          code: 234238920);
    }

    return handle(message);
  }

  /// Actual handling method.
  /// variables can be expected to be non-null as configured
  Future<DidcommPlaintextMessage?> handle(DidcommPlaintextMessage message);
}

var ALL_HANDLERS = [
  DidcommInvitationMessageHandler(),
  DidcommProposeCredentialMessageHandler(),
  DidcommRequestCredentialMessageHandler(),
  DidcommOfferCredentialMessageHandler(),
];