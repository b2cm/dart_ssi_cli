import 'package:dart_ssi/credentials.dart';
import 'package:dart_ssi/did.dart';
import 'package:dart_ssi/didcomm.dart';
import 'package:dart_ssi/wallet.dart';
import 'package:ssi_cli/src/exceptions/didcomm_service.dart';
import 'package:dart_ssi/credentials.dart';

import '../../definitions.dart';

/// will decrypt a message and return the decrypted message
Future<DidcommMessage> decryptMessage(
    Map<String, dynamic> encryptedMessage, WalletStore wallet) async {
  try {
     var encrypted = DidcommEncryptedMessage.fromJson(encryptedMessage);
     return await encrypted.decrypt(wallet);
  } on Exception catch (e) {
    throw DidcommServiceException("Could not decrypt Didcomm message",
        baseException: e,
        code: 9823904);
  }
}


void handleDidcommMessage(DidcommMessage message,{
  required WalletStore wallet,
  required
}) async {
  // For now, we only expect encrypted messages
  if (message is! DidcommPlaintextMessage) throw Exception('Unexpected message');

  // handle the messages according to their type
  if (message.type ==
      'https://didcomm.org/issue-credential/3.0/propose-credential') {
    //handleProposeCredential(ProposeCredential.fromJson(message.toJson()), connectionDid: conn, wallet: wallet););
  } else if (message.type ==
      'https://didcomm.org/issue-credential/3.0/request-credential') {
    // handleRequestCredential(RequestCredential.fromJson(message.toJson()));
  } else if (message.type == 'https://didcomm.org/empty/1.0') {
    if (message.ack != null) {
      //running.remove(plain.threadId); @TODO bring this to API
      //print('this is an ack for ${plain.ack}, thread: ${plain.threadId}');
    }
  }
}



Future<OfferCredential> handleProposeCredential(
    ProposeCredential message,
    {
      required String connectionDid,
      required List<String> replyTo
    }
    ) async {
  print('Received ProposeCredential: thread: ${message.threadId}');
  // it is expected that the wallet changes the did, the credential should be issued to
  var vcSubjectId = message.detail!.first.credential.credentialSubject['id'];
  for (var a in message.attachments!) {
    // to check, if the wallet controls the did it is expected to sign the attachment
    if (!(await a.data.verifyJws(vcSubjectId))) {
      throw Exception('not verifiable');
    }
  }

  // answer with offer credential message
  var offer = OfferCredential(
      threadId: message.threadId ?? message.id,
      detail: message.detail,
      from: connectionDid,
      to: [message.from!],
      replyTo: replyTo);
  return offer;
  // send(message.from!, offer, message.replyUrl!);
}


Future<IssueCredential> handleRequestCredential(RequestCredential message,
    WalletStore wallet,
    KeyType keyType,
    List<String> replyTo,
    String connectionDid
    ) async {
  print('received RequestCredential, thread: ${message.threadId}');
  var credential = message.detail!.first.credential;
  // sign the requested credential (normally we had to check before that, that the data in it is the same we offered)
  var signed = await signCredential(wallet, credential,
      challenge: message.detail!.first.options.challenge);
  // answer with issue credential message

  // issue the credential
  var issue = IssueCredential(
      threadId: message.threadId ?? message.id,
      from: connectionDid,
      to: [message.from!],
      replyTo: replyTo,
      credentials: [VerifiableCredential.fromJson(signed)]);

  //  send(message.from!, issue, message.replyUrl!);
  return issue;
}


/// Will resolve all attachments inside a PlaintextMessage
/// results will be reported as appropriate
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

Future<DidcommEncryptedMessage> encryptMessage({
    required String connectionDid,
    required WalletStore wallet,
    required DidcommPlaintextMessage message,
    required String receiverDid}) async {
  var myPrivateKey = await wallet.getPrivateKeyForConnectionDidAsJwk(
      connectionDid);

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

