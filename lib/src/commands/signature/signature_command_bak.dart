import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:dart_ssi/credentials.dart';
import 'package:dart_ssi/did.dart';
import 'package:dart_ssi/wallet.dart';

class SignatureCommand extends Command {
  final name = 'messages';
  final description =
      'Signs a given message-string and verifies signature at a message-string';

  SignatureCommand() {
    argParser
      ..addFlag('sign', abbr: 's', help: 'Sign a message')
      ..addFlag('detached',
          help: 'If set a detached jws (header..signature) is returned')
      ..addFlag('verify', abbr: 'v', help: 'verify a signature')
      ..addOption('message',
          abbr: 'm',
          help:
              'the message to sign or to check the signature for. If the message is included in jws as payload it must not be given separately')
      ..addOption('signature', help: 'signature to check (as jws)')
      ..addOption('did',
          help:
              'The did that should be used to sign or the did expected to have signed')
      ..addOption('wallet',
          abbr: 'w',
          help: 'Path to a Wallet the signing keys are in',
          defaultsTo: 'ssi_wallet')
      ..addOption('password', abbr: 'p', help: 'Password of the wallet')
      ..addOption('rpcUrl',
          defaultsTo: 'http://localhost:8545',
          help: 'Url for RPC-Endpoint of Ethereum-Node')
      ..addOption('erc1056Contract',
          abbr: 'e',
          help: 'Contract address of Erc1056-Contract (EthereumDIDRegistry)')
      ..addOption('jwsHeader',
          abbr: 'j',
          help:
              'Custom jws-Header (json). alg value should be ES256K-R (only supported algorithm for now)');
  }

  run() async {
    if (argResults!['sign']) {
      if (argResults!['password'] == null) {
        stderr.writeln('Wallet password missing');
        exit(2);
      }
      try {
        var wallet = WalletStore(argResults!['wallet']);
        await wallet.openBoxes(argResults!['password']);
        var sig;
        if (argResults!['jwsHeader'] == null)
          sig = signStringOrJson(
              wallet: wallet,
              didToSignWith: argResults!['did'],
              toSign: argResults!['message'],
              detached: argResults!['detached']);
        else
          sig = signStringOrJson(
              wallet: wallet,
              didToSignWith: argResults!['did'],
              toSign: argResults!['message'],
              jwsHeader: argResults!['jwsHeader'],
              detached: argResults!['detached']);
        stdout.writeln(sig);
        exit(0);
      } catch (e) {
        stderr.writeln(e);
        exit(2);
      }
    }

    if (argResults!['verify']) {
      Erc1056? erc1056;
      if (argResults!['rpcUrl'] != null &&
          argResults!['erc1056Contract'] != null) {
        try {
          erc1056 = Erc1056(argResults!['rpcUrl'],
              contractAddress: argResults!['erc1056Contract']);
        } catch (e) {
          stderr.writeln(e);
          exit(2);
        }
      }

      if (erc1056 != null) {
        try {
          var result = await verifyStringSignature(
            argResults!['signature'],
            expectedDid: argResults!['did'],
            erc1056: erc1056,
            toSign: argResults!['message'],
          );
          stdout.writeln(result);
        } catch (e) {
          stderr.writeln(e);
          exit(2);
        }
      } else {
        try {
          var result = await verifyStringSignature(argResults!['signature'],
              expectedDid: argResults!['did'], toSign: argResults!['message']);
          stdout.writeln(result);
        } catch (e) {
          stderr.writeln(e);
          exit(2);
        }
      }
    }

    exit(0);
  }
}
