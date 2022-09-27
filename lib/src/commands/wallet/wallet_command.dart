import 'dart:io';

import 'package:dart_ssi/wallet.dart';
import 'package:ssi_cli/src/commands/wallet/connections/wallet_connections_command.dart';
import 'package:ssi_cli/src/commands/wallet/credentials/wallet_credentials_command.dart';

import '../../constants.dart';
import '../../services/cli_service.dart';
import '../ssi_cli_base.dart';
import 'issuer/wallet_issuer_command.dart';
import 'wallet_init_command.dart';

class WalletCommand extends SsiCliCommandBase {
  final name = COMMAND_WALLET;
  final description = "Interacting with a ssi-wallet";

  WalletCommand() {
      addWalletNecessaryParametersToArgParser(argParser);
      addSubcommand(WalletInitCommand());
      addSubcommand(WalletConnectionsCommand());
      addSubcommand(WalletCredentialsCommand());
      addSubcommand(WalletIssuerCommand());

      /*
      ..addFlag(
          abbr: 'c', help: 'generates a new DID for a Connection')

      //..addOption('mnemonic',
          abbr: 'm', help: 'restore a wallet with that mnemonic')

      //..addFlag('list', abbr: 'l', help: 'list all connections')
      */

  }

  run() async {

  }
}
