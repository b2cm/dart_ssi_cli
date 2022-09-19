import 'package:args/command_runner.dart';

import 'dart:io';

import 'package:dart_ssi/credentials.dart';
import 'package:dart_ssi/did.dart';
import 'package:dart_ssi/util.dart';

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
    if (argResults!['signedJson'] == null) {
      stderr.writeln('Checkable json-object missing');
      exit(2);
    }

    Erc1056? erc1056;
    if (argResults!['erc1056Contract'] != null && argResults!['rpcUrl'] != null)
      erc1056 = Erc1056(argResults!['rpcUrl'],
          contractAddress: argResults!['erc1056Contract']);

    Map<String, dynamic> givenJson = credentialToMap(argResults!['signedJson']);
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
      if (argResults!['checkForRevocation'] && erc1056 != null) {
        try {
          res = await verifyPresentation(givenJson, argResults!['challenge'],
              erc1056: erc1056,
          );
        } catch (e) {
          stderr.writeln(e);
          exit(2);
        }
      } else if (!argResults!['checkForRevocation'] && erc1056 != null) {
        try {
          res = await verifyPresentation(givenJson, argResults!['challenge'],
              erc1056: erc1056);
        } catch (e) {
          stderr.writeln(e);
          exit(2);
        }
      } else if (argResults!['checkForRevocation'] && erc1056 == null) {
        try {
          res = await verifyPresentation(givenJson, argResults!['challenge'],
              // rpcUrl: argResults!['rpcUrl']
              );
        } catch (e) {
          stderr.writeln(e);
          exit(2);
        }
      } else {
        try {
          res = await verifyPresentation(givenJson, argResults!['challenge']);
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

      if (argResults!['plaintextCredential'].length > 0) {
        List<String> plaintextCreds = argResults!['plaintextCredential'];
        var id = '';
        plaintextCreds.forEach((plain) {
          try {
            var map = credentialToMap(plain);
            id = map['id'];
            var idx = indexToId[id]!;
            compare =
                compareW3cCredentialAndPlaintext(credsInPresentation[idx], map);
          } catch (e) {
            stderr.writeln('Problem in credential with id $id : $e');
            exit(2);
          }
        });
      }
    } else {
      if (argResults!['checkForRevocation'] && erc1056 != null) {
        try {
          res = await verifyCredential(givenJson,
              erc1056: erc1056, //rpcUrl: argResults!['rpcUrl']
          );
        } catch (e) {
          stderr.writeln(e);
          exit(2);
        }
      } else if (!argResults!['checkForRevocation'] && erc1056 != null) {
        try {
          res = await verifyCredential(givenJson, erc1056: erc1056);
        } catch (e) {
          stderr.writeln(e);
          exit(2);
        }
      } else if (argResults!['checkForRevocation'] && erc1056 == null) {
        try {
          res =
              await verifyCredential(givenJson,
                  // rpcUrl: argResults!['rpcUrl']
                  );
        } catch (e) {
          stderr.writeln(e);
          exit(2);
        }
      } else {
        try {
          res = await verifyCredential(givenJson);
        } catch (e) {
          stderr.writeln(e);
          exit(2);
        }
      }

      if (argResults!['plaintextCredential'].length > 0) {
        try {
          compare = compareW3cCredentialAndPlaintext(
              givenJson, argResults!['plaintextCredential'][0]);
        } catch (e) {
          stderr.writeln(e);
        }
      }
    }
    stdout.writeln('Signature Check: $res');
    if (argResults!['plaintextCredential'].length > 0)
      stdout.writeln('Comparision: $compare');
    if (res && compare)
      exit(0);
    else
      exit(2);
  }
}
