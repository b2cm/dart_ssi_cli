import 'package:dart_ssi/credentials.dart';
import 'package:dart_ssi/didcomm.dart';
import 'package:dart_ssi/wallet.dart';
import 'package:ssi_cli/src/exceptions/json_exceptions.dart';
import 'package:ssi_cli/src/services/json_service.dart';

import '../../definitions.dart';
import '../../exceptions/oob_exception.dart';

/// offers a credential using oob
///
/// a credential is understood as a template having the following syntax
/// ```json
/// {
///   "@context": ["context1", "context2"],
///   "type": ["type1", "type2"],
///
/// }
/// ```
OutOfBandMessage oobOfferCredential({
  required Map<String, dynamic> credential,
  required String oobId,
  required String threadId,
  required List<String> replyTo,
  required String issuerDid,
  required String connectionDid,
  String proofType = 'Ed25519Signature',
}) {

  try {
    addElementToListOrInit(credential, ['@context'],
        'https://www.w3.org/2018/credentials/v1');
  } on JsonPathException catch (e) {
    throw OobTemplateWrongValueException('The @context field is invalid.\n'
        'Details: $e',
        code: 234234543);
  }

  try {
    forceAsList(credential, ['type']);
  } on JsonPathException catch (e) {
    throw OobTemplateMissingValueException('The credential must have a `type`'
        ' field set.\nDetails: $e',
        code: 34583495834);
  }

  /// @TODO why that?
  if (!credential.containsKey('id')) {
    credential['id'] = 'did:key:000';
  }
  var vc = VerifiableCredential(
      context: (credential.remove('@context') as List).cast<String>(),
      type: ['VerifiableCredential', ...credential.remove('type')],
      issuer: issuerDid,
      credentialSubject: credential,
      issuanceDate: DateTime.now());

  var offer = OfferCredential(id: oobId, threadId: threadId, detail: [
    LdProofVcDetail(
        credential: vc,
        options: LdProofVcDetailOptions(proofType: proofType))
  ], replyTo: replyTo);

  return OutOfBandMessage(
      id: oobId,
      threadId: threadId,
      from: connectionDid,
      replyTo: replyTo,
      attachments: [Attachment(data: AttachmentData(json: offer.toJson()))]);
}

/// Resolves the attachments and returns them as PlainTextMessages
/// Each message is tried to be resolved. An error is reported for each message
/// if it could not be resolved or parsed.
Future<List<Result<DidcommPlaintextMessage, String>>>
  getPlaintextFromOobAttachments(OutOfBandMessage message,
    {DidcommMessages? expectedAttachment}) async {

  List<Result<DidcommPlaintextMessage, String>> res = [];
  if (message.attachments!.isNotEmpty) {
    for (var a in message.attachments!) {
      bool isOk = true;
      if (a.data.json == null) {
        try {
          await a.data.resolveData();
        } catch (e) {
          res.add(Result.Error(
              "Could not resolve attachment due to `${e.toString()}` "
              "(Code: 348923084)")
          );
          isOk = false;
        }
      }

      if (isOk) {
        try {
          var plain = DidcommPlaintextMessage.fromJson(
              a.data.json!);
          plain.from ??= message.from;
          res.add(Result.Ok(plain));
        } catch (e) {
          res.add(Result.Error(
              "Could not parse message from OOB "
              "attachment due to `${e.toString()}` "
              "(Code: 4853094)"));
        }
      }
    }

  }

  // filter by type (optionally)
  if (expectedAttachment != null) {
    for (var i = 0; i < res.length; i++) {
      if (res[i].isOk) {
        DidcommPlaintextMessage r = res[i].unrwap();
        if (r.type != expectedAttachment.value) {
          res[i] = Result.Error(
              "Attachment is of type `${r.type}` but expected "
              "`$expectedAttachment` (Code: 3583457348)");
        }
      }
    }
  }

  return res;
}
