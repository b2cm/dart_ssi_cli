import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:dart_ssi/credentials.dart';
import 'package:dart_ssi/wallet.dart';

class RevocationCommand extends Command {
  final name = 'revocation';
  final description = 'Interaction with Revocation registry Contract';

  RevocationCommand() {
    argParser
      ..addOption('rpcUrl',
          defaultsTo: 'http://localhost:8545',
          help: 'Url for RPC-Endpoint of Ethereum-Node')
      ..addOption('revocationContract',
          abbr: 'r', help: 'Contract address of Revocation-Contract')
      ..addFlag('init',
          abbr: 'i',
          help:
          'Initialize (deploy) new Revocation-Registry-Contract to Ethereum')
      ..addOption('isRevoked',
          help: 'Id of credential thats revocation status should be checked')
      ..addOption('revoke', help: 'id of credential that should be revoked')
      ..addOption('wallet',
          abbr: 'w',
          help: 'Path to a Wallet the signing keys are in',
          defaultsTo: 'ssi_wallet')
      ..addOption('password', abbr: 'p', help: 'Password of the wallet')
      ..addOption('did',
          abbr: 'd',
          help:
          'The did of which the private key should be used to authorize deployment and revocation operations. If this is not given, the standard-issuer-key is used');
  }

  run() async {
    //Initialize new Revocation Registry
    if (argResults!['init']) {
      var registry = RevocationRegistry(argResults!['rpcUrl']);
      var wallet = await _openWallet();
      String privKey = await _getPrivateKey(wallet);
      try {
        var address = await registry.deploy(privKey);
        stdout.writeln(address);
        exit(0);
      } catch (e) {
        stderr.writeln('Unable to deploy');
        stderr.writeln(e);
        exit(2);
      }
    }

    if (argResults!['revocationContract'] == null) {
      stderr.writeln('no contract address for Revocation contract given');
      exit(2);
    }
    var registry = RevocationRegistry(argResults!['rpcUrl'],
        contractAddress: argResults!['revocationContract']);

    // Check for Revocation
    if (argResults!['isRevoked'] != null) {
      try {
        var res = await registry.isRevoked(argResults!['isRevoked']);
        stdout.writeln(res);
        exit(0);
      } catch (e) {
        stderr.writeln('Unable to call revocation Registry');
        stderr.writeln(e);
        exit(2);
      }
    }

    //Revoke a credential
    if (argResults!['revoke'] != null) {
      var wallet = await _openWallet();
      var privKey = await _getPrivateKey(wallet);
      try {
        await registry.revoke(privKey, argResults!['revoke']);
        stdout.writeln('Credential revoked');
        exit(0);
      } catch (e) {
        stderr.writeln('Unable to call revocation Registry');
        stderr.writeln(e);
        exit(2);
      }
    }
  }

  Future<WalletStore> _openWallet() async {
    if (argResults!['password'] == null) {
      stderr.writeln('Wallet-Password missing');
      exit(2);
    }
    var wallet = WalletStore(argResults!['wallet']);
    await wallet.openBoxes(argResults!['password']);
    return wallet;
  }

  Future<String> _getPrivateKey(WalletStore wallet) async {
    String? privKey;
    if (argResults!['did'] == null) {
      privKey = await wallet.getStandardIssuerPrivateKey();
      if (privKey == null) {
        await wallet.initializeIssuer();
        privKey = await wallet.getStandardIssuerPrivateKey();
      }
    } else {
      privKey = await wallet.getPrivateKeyForCredentialDid(argResults!['did']);
      if (privKey == null) {
        privKey = await wallet.getPrivateKeyForConnectionDid(argResults!['did']);
      }
    }

    if (privKey == null) {
      stderr.writeln('Could not find a private Key');
      exit(2);
    }
    return privKey;
  }
}
