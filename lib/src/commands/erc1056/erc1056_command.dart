import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:dart_ssi/did.dart';
import 'package:dart_ssi/wallet.dart';

class Erc1056Command extends Command {
  final name = 'didRegistry';
  final description =
      'Interacting with an instance of erc1056 - Contract (EthereumDIDRegistry)';

  Erc1056Command() {
    argParser
      ..addOption('rpcUrl',
          defaultsTo: 'http://localhost:8545',
          help: 'Url for RPC-Endpoint of Ethereum-Node')
      ..addOption('erc1056Contract',
          abbr: 'e',
          help: 'Contract address of ErC1056-Contract (EthereumDIDRegistry)')
      ..addOption('did',
          abbr: 'd',
          help:
          'The did to get identity information for / to change identity information for')
      ..addOption('newDid', abbr: 'n', help: 'Did to rotate to')
      ..addFlag('getAddress',
          abbr: 'a', help: 'Get the current ethereum address or an identity')
      ..addFlag('doc', help: 'get a minimal did-Document for an identity')
      ..addOption('wallet',
          abbr: 'w',
          help: 'Path to a Wallet the signing keys are in',
          defaultsTo: 'ssi_wallet')
      ..addOption('password', abbr: 'p', help: 'Password of the wallet');
  }

  run() async {
    var erc1056 = Erc1056(argResults!['rpcUrl'],
        contractAddress: argResults!['erc1056Contract']);

    if (argResults!['getAddress']) {
      try {
        var controller = await erc1056.identityOwner(argResults!['did']);
        stdout.writeln(controller);
        exit(0);
      } catch (e) {
        stderr.writeln(e);
        exit(2);
      }
    }
    if (argResults!['doc']) {
      try {
        var doc = await erc1056.didDocument(argResults!['did']);
        stdout.writeln(doc);
        exit(0);
      } catch (e) {
        stderr.writeln(e);
        exit(2);
      }
    }
    if (argResults!['newDid'] != null) {
      try {
        if (argResults!['password'] == null)
          throw Exception('Wallet-Password missing');
        var wallet = WalletStore(argResults!['wallet']);
        await wallet.openBoxes(argResults!['password']);
        var privKey = await wallet.getPrivateKeyForCredentialDid(argResults!['did']);
        if (privKey == null) {
          privKey = await wallet.getPrivateKeyForConnectionDid(argResults!['did']);
        }
        if (privKey == null) {
          throw Exception('Could not find a private Key to the given did');
        }
        await erc1056.changeOwner(
            privKey, argResults!['did'], argResults!['newDid']);
        stdout.writeln('Successfully changed did-owner');
        exit(0);
      } catch (e) {
        stderr.writeln(e);
        exit(2);
      }
    }
  }
}
