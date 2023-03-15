import 'package:dart_ssi/credentials.dart';
import 'package:ssi_cli/src/constants.dart';

import '../ssi_cli_base.dart';

class VerifyCommand extends SsiCliCommandBase {
  @override
  final name = COMMAND_SIGNATURE_VERIFY;

  @override
  final description = "Verifies JWS signed data";

  VerifyCommand() {
    argParser
      ..addOption(PARAM_SIGNATURE_VERIFY_SIGNATURE_MESSAGE,
          help: "String: message to verify. Must be in default JWS format"
              "(header.payload.signature)",
          mandatory: true)
      ..addOption(PARAM_SIGNATURE_VERIFY_EXPECTED_DID,
          help: "Did which is the expected signer. "
              "Must be either `did:ethr:...` or `did:key:z6Mk...`",
          mandatory: true);
  }

  @override
  run() async {
    var message = getArgString(PARAM_SIGNATURE_VERIFY_SIGNATURE_MESSAGE,
        isOptional: false)!;
    var expectedDid =
        getArgDid(PARAM_SIGNATURE_VERIFY_EXPECTED_DID, isOptional: false)!;

    var signed = false;
    try {
      signed = await verifyStringSignature(message, expectedDid: expectedDid);
    } catch (e) {
      writeError(e.toString(), 3249202);
    }

    if (signed) {
      writeResult('valid');
    } else {
      writeResult('invalid');
    }
  }
}
