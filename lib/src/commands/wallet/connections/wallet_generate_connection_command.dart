import 'dart:io';

import 'package:ssi_cli/src/commands/ssi_cli_base.dart';
import 'package:ssi_cli/src/constants.dart';
import 'package:ssi_cli/src/services/wallet_service.dart';

/// emit a new connection DID
class WalletGenerateConnectionCommand extends SsiCliCommandBase {
  @override
  final name = COMMAND_WALLET_CONNECTION_GENERATE;

  @override
  final description = "Generates a new connection";

  WalletGenerateConnectionCommand() {
    argParser
      ..addOption(PARAM_KEY_TYPE,
          help: "Keytype to generate",
          allowed: getSupportedWalletKeyTypesAsString(),
          defaultsTo: getSupportedWalletKeyTypesAsString()[0],
          mandatory: false);
  }

  @override
  run() async {
    var wallet = await loadWalletFromArgs();
    var did = await wallet.getNextConnectionDID(getArgKeyType());
    writeResult(did);
  } 
}
