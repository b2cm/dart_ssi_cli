import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:dart_ssi/wallet.dart';

class WalletCommand extends Command {
  final name = 'wallet';
  final description = 'Interacting with a ssi-wallet';

  WalletCommand() {
    argParser
      ..addFlag('init', abbr: 'i', help: 'Initialize a new wallet')
      ..addOption('directory',
          abbr: 'd',
          help: 'Directory in Filesystem to store Wallet-Files',
          defaultsTo: 'ssi_wallet')
      ..addOption('password',
          abbr: 'p', help: 'Password the wallet is secured with')
      ..addFlag('generateConnectionDid',
          abbr: 'c', help: 'generates a new DID for a Connection')
      ..addOption('mnemonic',
          abbr: 'm', help: 'restore a wallet with that mnemonic')
      ..addFlag('list', abbr: 'l', help: 'list all connections');
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
