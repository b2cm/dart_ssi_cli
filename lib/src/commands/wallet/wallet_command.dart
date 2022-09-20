import 'dart:io';

import 'package:dart_ssi/wallet.dart';
import 'package:ssi_cli/src/commands/wallet/connections/wallet_connections_command.dart';

import '../../constants.dart';
import '../ssi_cli_base.dart';
import 'issuer/wallet_issuer_command.dart';
import 'wallet_init_command.dart';

class WalletCommand extends SsiCliCommandBase {
  final name = COMMAND_WALLET;
  final description = "Interacting with a ssi-wallet";

  WalletCommand() {
    argParser
      ..addOption(PARAM_PASSWORD,
          help: "Password the wallet is secured with",
          mandatory: true)

      ..addOption(PARAM_DATA_DIR,
          help: "Directory in Filesystem to store Wallet-Files. "
                "Will be the current directory if not given. "
                "The Directory MUST exist (will not be created)",
          defaultsTo: Directory.current.path)

      ..addOption(PARAM_WALLET_NAME,
          help: "Name of the wallet", defaultsTo: "default-wallet")
    ;
      addSubcommand(WalletInitCommand());
      addSubcommand(WalletConnectionsCommand());
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
    if (argResults!['password'] == null) {
      stderr.writeln('Problem occurred: Password should be given');
      exit(2);
    }

    var wallet = WalletStore(argResults!['directory']);
    await wallet.openBoxes(argResults!['password']);

    if (argResults!['init']) {
      try {
        var mn = wallet.initialize();
        stdout.writeln(
            'The keys in this wallet could be restored with this mnemonic (store it at a safe place): $mn');
      } catch (e) {
        stderr.writeln(e);
        exit(2);
      }
    }

    if (argResults!['mnemonic'] != null) {
      try {
        var mn = wallet.initialize(mnemonic: argResults!['mnemonic']);
        stdout.writeln('Successfully restored wallet with mnemonic: $mn');
      } catch (e) {
        stderr.writeln(e);
        exit(2);
      }
    }

    if (argResults!['generateConnectionDid']) {
      try {
        var did = await wallet.getNextConnectionDID();
        stdout.writeln(did);
      } catch (e) {
        stderr.writeln(e);
        exit(2);
      }
    }

    if (argResults!['list']) {
      var all = wallet.getAllConnections();
      stdout.writeln(all.keys.toList());
    }

    await wallet.closeBoxes();
    exit(0);
  }
}
