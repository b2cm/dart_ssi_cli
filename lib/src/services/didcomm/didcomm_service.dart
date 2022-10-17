import 'package:dart_ssi/credentials.dart';
import 'package:dart_ssi/did.dart';
import 'package:dart_ssi/didcomm.dart';
import 'package:dart_ssi/wallet.dart';
import 'package:ssi_cli/src/exceptions/didcomm_service_exceptions.dart';
import 'package:ssi_cli/src/services/didcomm/handlers/abstract_didcomm_message_handler.dart';
import 'package:uuid/uuid.dart';

import '../../definitions.dart';


/// main entry point for handling didcomm messages
/// will not send the messages itself, but will return the message to be sent
/// in an unencrypted format
Future<DidcommPlaintextMessage?> handleDidcommMessage(
    DidcommMessage message, {
      String? connectionDid,
      String? credentialDid,
      List<String>? replyTo,
      WalletStore? wallet,
}) async {
  // For now, we only expect encrypted messages
  if (message is! DidcommPlaintextMessage) throw DidcommServiceException(
      "The supplied message is no valid plaintext message", code: 290482390);

  DidcommPlaintextMessage? result;
  bool foundHandler = false;
  for (var handler in ALL_HANDLERS) {
    if (handler.supportedTypes.contains(message.type)) {
      handler.connectionDid = connectionDid;
      handler.credentialDid = credentialDid;
      handler.replyTo = replyTo;
      handler.wallet = wallet;
      result = await handler.execute(message);
      foundHandler = true;
    }
  }

  if (foundHandler == false) {
    throw DidcommServiceException(
        "No handler found for message type `${message.type}`. "
        "Available handlers: `" + getSupportedMessageTypes().join('`, `'),
        code: 23498234);
  }

  if (message.ack != null) {
    //running.remove(plain.threadId); @TODO bring this to API
    //print('this is an ack for ${plain.ack}, thread: ${plain.threadId}');
  }

  return foundHandler ? result : null;
}

/// Will resolve all attachments inside a [DidcommPlaintextMessage]
/// results will be reported as appropriate as [Result] for each attachment
Future<List<Result<void, String>>> resolveAttachments(DidcommPlaintextMessage message) async {
  var results = <Result<void, String>>[];
  if (message.attachments != null && message.attachments!.isNotEmpty) {
    for (var a in message.attachments!) {
      try {
        await a.data.resolveData();
        results.add(Result.Ok(null));
      } catch (e) {
         results.add(Result.Error(e.toString()));
      }
    }
  }

  return results;
}

/// will encrypt the [message] using the resolved [connectionDid]
/// (must be available in the [wallet]).
Future<DidcommEncryptedMessage> encryptMessage({
    required String connectionDid,
    required WalletStore wallet,
    required DidcommPlaintextMessage message,
    required String receiverDid}) async {

  var myPrivateKey = await wallet.getPrivateKeyForConnectionDidAsJwk(
      connectionDid);

  // @TODO what is that for? Replace me with some useful information
  var recipientDDO = (await resolveDidDocument(receiverDid))
      .resolveKeyIds()
      .convertAllKeysToJwk();

  if (message.type != DidcommMessages.emptyMessage.value) {
    await wallet.storeConversationEntry(message, connectionDid);
  }
  var encrypted = DidcommEncryptedMessage.fromPlaintext(
      senderPrivateKeyJwk: myPrivateKey!,
      recipientPublicKeyJwk: [
        (recipientDDO.keyAgreement!.first as VerificationMethod).publicKeyJwk!
      ],
      plaintext: message);

  return encrypted;
}


/// will decrypt a message and return the decrypted message
Future<DidcommMessage> decryptMessage(
    Map<String, dynamic> encryptedMessage, WalletStore wallet) async {
  try {
     var encrypted = DidcommEncryptedMessage.fromJson(encryptedMessage);
     return await encrypted.decrypt(wallet);
  } on Exception catch (e) {
    throw DidcommServiceException("Could not decrypt Didcomm message due to ${e.toString()}",
        baseException: e,
        code: 9823904);
  }
}

/// will sign the [offer] using the key derived in [credentialDid]
/// resulting in a [VerifiableCredential]. The result is wrapped in a
/// [ProposeCredential] message,
/// while the offer itself is added as an attachment
///
/// this flow is `Holder --> Issuer`
Future<ProposeCredential> generateProposeCredentialMessage({
  required OfferCredential offer,
  required WalletStore wallet,
  required String connectionDid,
  required List<String> replyTo,
  required String credentialDid,
}
) async {
  var offeredCred = offer.detail!.first.credential;
  var credSubject = offeredCred.credentialSubject;

  // substitute the did in the credential (i.e., claim it)
  credSubject['id'] = credentialDid;
  var newCred = VerifiableCredential(
      id: credentialDid,              // new did here also
      context: offeredCred.context,
      type: offeredCred.type,
      issuer: offeredCred.issuer,
      credentialSubject: credSubject,
      issuanceDate: offeredCred.issuanceDate,
      credentialSchema: offeredCred.credentialSchema,
      expirationDate: offeredCred.expirationDate);

  var message = ProposeCredential(
      threadId: offer.threadId ?? offer.id,
      from: connectionDid,
      to: [offer.from!],
      replyTo: replyTo,
      detail: [
        LdProofVcDetail(
            credential: newCred, options: offer.detail!.first.options)
      ]);

  //Sign attachment with credentialDid
  for (var a in message.attachments!) {
    await a.data.sign(wallet, credentialDid);
  }

  return message;
}

/// Response from the holder for a offer credential message
RequestCredential generateRequestCredentialMessageFromOffer({
  required OfferCredential offer,
  required List<String> replyTo,
  required credentialDid,
}){
  var message = RequestCredential(
      detail: [
        LdProofVcDetail(
            credential: offer.detail!.first.credential,
            options: LdProofVcDetailOptions(
                proofType: offer.detail!.first.options.proofType,
                challenge: const Uuid().v4()))
      ],
      replyTo: replyTo,
      threadId: offer.threadId ?? offer.id,
      from: credentialDid,
      to: [offer.from!]);

  return message;
}

/***
 * Will issue a credential to the user
 */
Future<IssueCredential> generateIssueCredentialMessageFromRequest(
  {
    required RequestCredential message,
    required WalletStore wallet,
    required String connectionDid,
    required List<String> replyTo,
  }) async {
  var credential = message.detail!.first.credential;

  // sign the requested credential (normally we had to check before that,
  // that the data in it is the same we offered)
  // @TODO add checks!
  var signed = await signCredential(wallet, credential,
      challenge: message.detail!.first.options.challenge);

  // issue the credential
  var issue = IssueCredential(
      threadId: message.threadId ?? message.id,
      from: connectionDid,
      to: [message.from!],
      replyTo: replyTo,
      credentials: [VerifiableCredential.fromJson(signed)]);

  return issue;
}

/// gets a list of supported messages types
/// which the handlers are able to handle
List<String> getSupportedMessageTypes() {
 List<String> types = [];
 for (var handler in ALL_HANDLERS) {
   types.addAll(handler.supportedTypes);
 }

 return types;
}