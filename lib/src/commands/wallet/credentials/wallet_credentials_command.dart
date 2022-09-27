import 'package:ssi_cli/src/commands/ssi_cli_base.dart';
import 'package:ssi_cli/src/commands/wallet/credentials/wallet_init_credential_command.dart';
import 'package:ssi_cli/src/commands/wallet/credentials/wallet_list_credentials_command.dart';
import 'package:ssi_cli/src/constants.dart';


/// administer credentials
class WalletCredentialsCommand extends SsiCliCommandBase {
  @override
  final name = COMMAND_WALLET_CREDENTIALS;

  @override
  final description = "administer wallet credentials";

  WalletCredentialsCommand() {
    addSubcommand(WalletInitCredentialCommand());
    addSubcommand(WalletListCredentialsCommand());
  }

}