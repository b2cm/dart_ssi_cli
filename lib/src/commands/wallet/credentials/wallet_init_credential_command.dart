import 'package:ssi_cli/src/commands/ssi_cli_base.dart';
import 'package:ssi_cli/src/constants.dart';
import 'package:ssi_cli/src/services/wallet_service.dart';

/// emit a new credential DID
class WalletInitCredentialCommand extends SsiCliCommandBase {
  @override
  final name = COMMAND_WALLET_CREDENTIAL_INIT;

  @override
  final description = "Inits a new credential DID";

  WalletInitCredentialCommand() {
    argParser
      ..addOption(PARAM_KEY_TYPE,
          help: "Keytype init the credential store to",
          allowed: getSupportedCredentialTypesAsString(),
          defaultsTo: getSupportedCredentialTypesAsString()[0],
          mandatory: false);
  }

  @override
  run() async {
    var wallet = await loadWalletFromArgs();
    var did = await wallet.getNextCredentialDID(getArgKeyType());
    writeResult(did);
  } 
}
