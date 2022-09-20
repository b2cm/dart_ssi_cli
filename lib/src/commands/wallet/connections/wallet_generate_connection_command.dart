import 'dart:io';

import 'package:dart_ssi/wallet.dart';
import 'package:ssi_cli/src/commands/ssi_cli_base.dart';
import 'package:ssi_cli/src/constants.dart';
import 'package:ssi_cli/src/exceptions/wallet_service_exception.dart';
import 'package:ssi_cli/src/services/wallet_service.dart';
import 'package:ssi_cli/src/utils/path_utils.dart';

/// emit a new connection DID
class WalletGenerateConnectionCommand extends SsiCliCommandBase {
  @override
  final name = COMMAND_WALLET_CONNECTION_GENERATE;

  @override
  final description = "Generates a new connection";

  WalletGenerateConnectionCommand() {
    argParser
      ..addOption(PARAM_KEY_TYPE,
          help: "Keytype to generate to use.",
          allowed: getSupportedKeyTypes(),
          defaultsTo: getSupportedKeyTypes()[0],
          mandatory: false);
  }

  @override
  run() async {
    var wallet = await loadWallet();
    var did = await wallet.getNextConnectionDID(getArgKeyType());
    writeResult(did);
  } 
}
