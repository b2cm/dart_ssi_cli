import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:dart_ssi/credentials.dart';
import 'package:dart_ssi/wallet.dart';
import 'package:ssi_cli/src/definitions.dart';

/***
 * Will accept a JSON document (credential) and signs it using the given wallet
 * Returns the Signed Credential in W3c format and the plaintext credential
 * - both inside single JSON structure as in
 * ```json
 * {
 *  'signedCredential: {},
 *  'plaintextCredential: {}'
 * }
 * ```
 */
class CredentialCommand extends Command {
  static const String CREDENTIAL_PARAMETER_NAME = 'credential';
  static const String WALLET_PATH_PARAMETER_NAME = 'wallet-path';
  static const String WALLET_PASSWORD_PARAMETER_NAME = 'wallet-password';
  final name = 'credentials';
  final description = 'Create and sign credentials';

  CredentialCommand() {
    argParser
      ..addOption(CREDENTIAL_PARAMETER_NAME,
          help: 'JSON structure which should be signed.')
      ..addOption(WALLET_PATH_PARAMETER_NAME,
          help: 'Location of the wallet to use', defaultsTo: 'wallet/issuer')
      ..addOption(WALLET_PASSWORD_PARAMETER_NAME,
          help: '(Optional) password for encrypting the wallet');
    ;
  }

  run() async {
    var maybeCredential = _tryParseCredential();
    if (maybeCredential.isError) {
      stderr.writeln(maybeCredential.unrwap());
      exit(2);
    }

    String walletPath = argResults![WALLET_PATH_PARAMETER_NAME];
    String? walletPassword = argResults![WALLET_PASSWORD_PARAMETER_NAME];
    Map<String, dynamic> credential = maybeCredential.unrwap();
    WalletStore wallet = WalletStore(walletPath);

    try {
      await wallet.openBoxes(walletPassword);
      if (!wallet.isInitialized()) {
        await wallet.initialize();
      }
      if (wallet.getStandardIssuerDid() == null) {
        await wallet.initializeIssuer();
      }
    } catch (e, _) {
      stderr.writeln('Couldn\'t open wallet due to `${e.toString()}` '
          '(Code: 2834092384)');
      exit(2);
    }

    try {
      if (!credential.containsKey('id')) {
        stderr.writeln('No `id` field given in credential (Code: 9530945834)');
        exit(2);
      }
      String holderDid = credential['id'];
      credential.remove('id');

      var plainTextCredential =
          buildPlaintextCredential(credential, holderDid);

      var w3cCredential = buildW3cCredentialwithHashes(
          plainTextCredential, wallet.getStandardIssuerDid());

      var signedCredential = await signCredential(wallet, w3cCredential);
      stdout.write(jsonEncode({
        'plaintextCredential': jsonDecode(plainTextCredential),
        'signedCredential': jsonDecode(signedCredential)
      }));
    } catch (e) {
      stderr.writeln(
          'Could not generate credential due to `${e.toString()}` (Code: 8240380)');
      exit(2);
    }
  }

  /// Tries to fetch the [CREDENTIAL_PARAMETER_NAME] and parse it as JSON
  Result<Map<String, dynamic>, String> _tryParseCredential() {
    if (argResults![CREDENTIAL_PARAMETER_NAME] == null) {
      return Result.Error(
          'Please provide a credential to sign using the --$CREDENTIAL_PARAMETER_NAME option (Code: 5938495384)');
    }
    String credentialString = argResults![CREDENTIAL_PARAMETER_NAME];

    try {
      Map<String, dynamic> credentialMap = jsonDecode(credentialString);
      return Result.Ok(credentialMap);
    } catch (e, _) {
      return Result.Error(
          "Couldn't parse credential as a valid JSON due to: \n${e.toString()}\n(Code: 385490348)");
    }
  }
}
