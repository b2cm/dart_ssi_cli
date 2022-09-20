import 'dart:io';

import 'package:dart_ssi/wallet.dart';
import 'package:ssi_cli/src/commands/ssi_cli_base.dart';
import 'package:ssi_cli/src/constants.dart';
import 'package:ssi_cli/src/exceptions/wallet_service_exception.dart';
import 'package:ssi_cli/src/services/wallet_service.dart';
import 'package:ssi_cli/src/utils/path_utils.dart';

/// emit a new connection DID
class WalletInitIssuerConnectionCommand extends SsiCliCommandBase {
  @override
  final name = COMMAND_WALLET_INIT_ISSUER;

  @override
  final description = "Init issuer for a given key type";

  WalletInitIssuerConnectionCommand() {
    argParser
      ..addOption(PARAM_KEY_TYPE,
          help: "Key Type for Issuing.",
          allowed: supportedIssuerKeyTypes(),
          defaultsTo: supportedIssuerKeyTypes()[0]
      );
  }

  @override
  run() async {
    var wallet = await loadWallet();
    var keyType = getArgKeyType();
    var issuer = await wallet.initializeIssuer(keyType);
    await wallet.closeBoxes();

    writeResult(issuer);
  } 
}
