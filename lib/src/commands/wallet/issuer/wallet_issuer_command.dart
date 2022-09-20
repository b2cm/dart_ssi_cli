import 'dart:io';

import 'package:ssi_cli/src/commands/ssi_cli_base.dart';
import 'package:ssi_cli/src/commands/wallet/issuer/wallet_init_issuer.dart';
import 'package:ssi_cli/src/commands/wallet/issuer/wallet_show_issuer_command.dart';
import 'package:ssi_cli/src/constants.dart';


/// administer connections
class WalletIssuerCommand extends SsiCliCommandBase {
  @override
  final name = COMMAND_WALLET_ISSUER;

  @override
  final description = "administer issuing";

  WalletIssuerCommand() {
    addSubcommand(WalletInitIssuerConnectionCommand());
    addSubcommand(WalletShowIssuerCommand());
  }

}