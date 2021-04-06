import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:flutter_ssi_wallet/flutter_ssi_wallet.dart';

void main(List<String> args) {
  var runner = CommandRunner('main', 'Some description')
    ..addCommand(VerifyCommand())
    ..addCommand(WalletCommand())
    ..addCommand(SignatureCommand())
    ..addCommand(Erc1056Command())
    ..addCommand(RevocationCommand())
    ..run(args);
}

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
    if (argResults['init']) {
      var registry = RevocationRegistry(argResults['rpcUrl']);
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

    if (argResults['revocationContract'] == null) {
      stderr.writeln('no contract address for Revocation contract given');
      exit(2);
    }
    var registry = RevocationRegistry(argResults['rpcUrl'],
        contractAddress: argResults['revocationContract']);

    // Check for Revocation
    if (argResults['isRevoked'] != null) {
      try {
        var res = await registry.isRevoked(argResults['isRevoked']);
        stdout.writeln(res);
        exit(0);
      } catch (e) {
        stderr.writeln('Unable to call revocation Registry');
        stderr.writeln(e);
        exit(2);
      }
    }

    //Revoke a credential
    if (argResults['revoke'] != null) {
      var wallet = await _openWallet();
      var privKey = await _getPrivateKey(wallet);
      try {
        await registry.revoke(privKey, argResults['revoke']);
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
    if (argResults['password'] == null) {
      stderr.writeln('Wallet-Password missing');
      exit(2);
    }
    var wallet = WalletStore(argResults['wallet']);
    await wallet.openBoxes(argResults['password']);
    return wallet;
  }

  Future<String> _getPrivateKey(WalletStore wallet) async {
    String privKey;
    if (argResults['did'] == null) {
      privKey = wallet.getStandardIssuerPrivateKey();
      if (privKey == null) {
        await wallet.initializeIssuer();
        privKey = wallet.getStandardIssuerPrivateKey();
      }
    } else {
      privKey = wallet.getPrivateKeyToCredentialDid(argResults['did']);
      if (privKey == null) {
        privKey = wallet.getPrivateKeyToConnectionDid(argResults['did']);
      }
    }

    if (privKey == null) {
      stderr.writeln('Could not find a private Key');
      exit(2);
    }
    return privKey;
  }
}

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
      ..addOption('wallet',
          abbr: 'w',
          help: 'Path to a Wallet the signing keys are in',
          defaultsTo: 'ssi_wallet')
      ..addOption('password', abbr: 'p', help: 'Password of the wallet');
  }

  run() async {
    var erc1056 = Erc1056(argResults['rpcUrl'],
        contractAddress: argResults['erc1056Contract']);

    if (argResults['getAddress']) {
      try {
        var controller = await erc1056.identityOwner(argResults['did']);
        stdout.writeln(controller);
        exit(0);
      } catch (e) {
        stderr.writeln(e);
        exit(2);
      }
    }
    if (argResults['newDid'] != null) {
      try {
        if (argResults['password'] == null)
          throw Exception('Wallet-Password missing');
        var wallet = WalletStore(argResults['wallet']);
        await wallet.openBoxes(argResults['password']);
        var privKey = wallet.getPrivateKeyToCredentialDid(argResults['did']);
        if (privKey == null) {
          privKey = wallet.getPrivateKeyToConnectionDid(argResults['did']);
        }
        if (privKey == null) {
          throw Exception('Could not find a private Key to the given did');
        }
        await erc1056.changeOwner(
            privKey, argResults['did'], argResults['newDid']);
        stdout.writeln('Successfully changed did-owner');
        exit(0);
      } catch (e) {
        stderr.writeln(e);
        exit(2);
      }
    }
  }
}

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
    if (argResults['password'] == null) {
      stderr.writeln('Problem occurred: Password should be given');
      exit(2);
    }

    var wallet = WalletStore(argResults['directory']);
    await wallet.openBoxes(argResults['password']);

    if (argResults['init']) {
      try {
        var mn = wallet.initialize();
        stdout.writeln(
            'The keys in this wallet could be restored with this mnemonic (store it at a safe place): $mn');
      } catch (e) {
        stderr.writeln(e);
        exit(2);
      }
    }

    if (argResults['mnemonic'] != null) {
      try {
        var mn = wallet.initialize(argResults['mnemonic']);
        stdout.writeln('Successfully restored wallet with mnemonic: $mn');
      } catch (e) {
        stderr.writeln(e);
        exit(2);
      }
    }

    if (argResults['generateConnectionDid']) {
      try {
        var did = await wallet.getNextConnectionDID();
        stdout.writeln(did);
      } catch (e) {
        stderr.writeln(e);
        exit(2);
      }
    }

    if (argResults['list']) {
      var all = wallet.getAllConnections();
      stdout.writeln(all.keys.toList());
    }

    await wallet.closeBoxes();
    exit(0);
  }
}

class SignatureCommand extends Command {
  final name = 'messages';
  final description =
      'Signs a given message-string and verifies signature at a message-string';

  SignatureCommand() {
    argParser
      ..addFlag('sign', abbr: 's', help: 'Sign a message')
      ..addFlag('verify', abbr: 'v', help: 'verify a signature')
      ..addOption('message',
          abbr: 'm', help: 'the message to sign or to check the signature for')
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
          help: 'Contract address of Erc1056-Contract (EthereumDIDRegistry)');
  }

  run() async {
    if (argResults['sign']) {
      if (argResults['password'] == null) {
        stderr.writeln('Wallet password missing');
        exit(2);
      }
      var wallet = WalletStore(argResults['wallet']);
      await wallet.openBoxes(argResults['password']);
      var sig = signString(wallet, argResults['did'], argResults['message']);
      stdout.writeln(sig);
      exit(0);
    }

    if (argResults['verify']) {
      Erc1056 erc1056;
      if (argResults['rpcUrl'] != null &&
          argResults['erc1056Contract'] != null) {
        try {
          erc1056 = Erc1056(argResults['rpcUrl'],
              contractAddress: argResults['erc1056Contract']);
        } catch (e) {
          stderr.writeln(e);
          exit(2);
        }
      }

      if (erc1056 != null) {
        try {
          var result = await verifyStringSignature(
              argResults['message'], argResults['signature'], argResults['did'],
              erc1056: erc1056);
          stdout.writeln(result);
        } catch (e) {
          stderr.writeln(e);
          exit(2);
        }
      } else {
        try {
          var result = await verifyStringSignature(argResults['message'],
              argResults['signature'], argResults['did']);
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

class VerifyCommand extends Command {
  final name = 'verify';
  final description = 'Verifying credentials and presentations';

  VerifyCommand() {
    argParser
      ..addOption('rpcUrl',
          defaultsTo: 'http://localhost:8545',
          help: 'Url for RPC-Endpoint of Ethereum-Node')
      ..addFlag('checkForRevocation',
          abbr: 'r',
          help:
              'Indicates if the revocation status of credentials should be checked')
      ..addOption('erc1056Contract',
          abbr: 'e',
          help: 'Contract address of ErC1056-Contract (EthereumDIDRegistry)')
      ..addOption('challenge',
          abbr: 'c',
          help:
              'Expected challenge in a presentation. Therefor this option is only needed if you check a presentation.')
      ..addMultiOption('plaintextCredential',
          abbr: 'p',
          splitCommas: false,
          help:
              'The (disclosed) plaintext credentials. Multiple plaintext credentials allowed, but use -p every time; separating by comma wont work.')
      ..addOption('signedJson',
          abbr: 's',
          help: 'The signed json-object (credential or presentation) to check');
  }

  run() async {
    if (argResults['erc1056Contract'] == null) {
      stderr.writeln('Contract address for ERC1056 Contract missing');
      exit(2);
    }
    if (argResults['signedJson'] == null) {
      stderr.writeln('Checkable json-object missing');
      exit(2);
    }

    Erc1056 erc1056;
    erc1056 = Erc1056(argResults['rpcUrl'],
        contractAddress: argResults['erc1056Contract']);

    Map<String, dynamic> givenJson = credentialToMap(argResults['signedJson']);
    bool presentation = true;
    if (givenJson.containsKey('type')) {
      if ((givenJson['type'] as List).first == 'VerifiableCredential')
        presentation = false;
    } else if (givenJson.containsKey('@type')) {
      if ((givenJson['@type'] as List).first == 'VerifiableCredential')
        presentation = false;
    } else {
      stderr.writeln(
          'Could not determine if given Json-Object is presentation or credential');
      exit(2);
    }

    bool res = true;
    bool compare = true;
    if (presentation) {
      if (argResults['checkForRevocation']) {
        try {
          res = await verifyPresentation(givenJson, argResults['challenge'],
              erc1056: erc1056, rpcUrl: argResults['rpcUrl']);
        } catch (e) {
          stderr.writeln(e);
          exit(2);
        }
      } else {
        try {
          res = await verifyPresentation(givenJson, argResults['challenge'],
              erc1056: erc1056);
        } catch (e) {
          stderr.writeln(e);
          exit(2);
        }
      }
      List<dynamic> credsInPresentation = givenJson['verifiableCredential'];
      Map<String, int> indexToId = {};
      for (var i = 0; i < credsInPresentation.length; i++) {
        var id = credsInPresentation[i]['credentialSubject']['id'];
        indexToId[id] = i;
      }

      if (argResults['plaintextCredential'].length > 0) {
        List<String> plaintextCreds = argResults['plaintextCredential'];
        var id = '';
        plaintextCreds.forEach((plain) {
          try {
            var map = credentialToMap(plain);
            id = map['id'];
            var idx = indexToId[id];
            compare =
                compareW3cCredentialAndPlaintext(credsInPresentation[idx], map);
          } catch (e) {
            stderr.writeln('Problem in credential with id $id : $e');
            exit(2);
          }
        });
      }
    } else {
      if (argResults['checkForRevocation']) {
        res = await verifyCredential(givenJson,
            erc1056: erc1056, rpcUrl: argResults['rpcUrl']);
      } else {
        res = await verifyCredential(givenJson, erc1056: erc1056);
      }
      if (argResults['plaintextCredential'].length > 0) {
        try {
          compare = compareW3cCredentialAndPlaintext(
              givenJson, argResults['plaintextCredential'][0]);
        } catch (e) {
          stderr.writeln(e);
        }
      }
    }
    stdout.writeln('Signature Check: $res');
    if (argResults['plaintextCredential'].length > 0)
      stdout.writeln('Comparision: $compare');
    if (res && compare)
      exit(0);
    else
      exit(2);
  }
}
