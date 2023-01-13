import 'dart:convert';

import 'package:dart_ssi/credentials.dart';
import 'package:dart_ssi/didcomm.dart';
import 'package:ssi_cli/src/constants.dart';
import 'package:ssi_cli/src/exceptions/cli_exception.dart';
import 'package:ssi_cli/src/services/cli_service.dart';
import 'package:dart_ssi/src/didcomm/didcomm_service.dart';

import '../ssi_cli_base.dart';

class SignCommand extends SsiCliCommandBase {


  @override
  final name = COMMAND_SIGNATURE_SIGN;

  @override
  final description =
      "Creates a signature for a given message";

  SignCommand() {
    addWalletNecessaryParametersToArgParser(argParser);

    argParser
      ..addOption(PARAM_SIGNATURE_SIGN_MESSAGE,
          help: "JSON: Message to sign.",
          mandatory: true)

      ..addOption(PARAM_SIGNATURE_SIGN_DID,
          help: "DID to use for signing. "
                "Must be either `did:ethr:...` or `did:key:z6Mk...`",
          mandatory: true);

  }

  @override
  run() async {
    var message = getArgJson(PARAM_SIGNATURE_SIGN_MESSAGE, isOptional: false)!;
    var wallet = await loadWalletFromArgs();
    var did = getArgDid(PARAM_SIGNATURE_SIGN_DID, isOptional: false)!;

    var allOwned = wallet.getAllConnections().keys.toList()
      ..addAll(wallet.getAllCredentials().keys);

    if (!(allOwned.contains(did))) {
      throw CliException("DID `$did` is not owned by this wallet. "
          "(Either as a connection nor aas a credential)", code: 2348237840923);
    }

    String signed = await signStringOrJson(wallet, did, message);

    writeResult(signed);
  }
}
