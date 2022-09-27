import 'dart:io';

import 'package:dart_ssi/wallet.dart';
import 'package:ssi_cli/src/commands/ssi_cli_base.dart';
import 'package:ssi_cli/src/constants.dart';
import 'package:ssi_cli/src/exceptions/wallet_service_exception.dart';
import 'package:ssi_cli/src/services/wallet_service.dart';
import 'package:ssi_cli/src/utils/path_utils.dart';

/// emit a new connection DID
class WalletShowIssuerCommand extends SsiCliCommandBase {
  @override
  final name = COMMAND_WALLET_SHOW_ISSUER;

  @override
  final description = "Writes the issuer DID for the given key type. If a"
      "issuer is not initialized an error will be written out.";

  WalletShowIssuerCommand() {
    argParser
      ..addOption(PARAM_KEY_TYPE,
          help: "Key Type for Issuing.",
          allowed: getSupportedIssuerKeyTypesAsString(),
          defaultsTo: getSupportedIssuerKeyTypesAsString()[0]
      );
  }

  @override
  run() async {
    var wallet = await loadWalletFromArgs();
    var keyType = getArgKeyType();
    var issuer = await wallet.getStandardIssuerDid(keyType);
    await wallet.closeBoxes();

    if (issuer == null) {
      writeError("No issuer for $keyType initialized.", 6234234234);
    }
    writeResult(issuer!);

  }
}
