import 'dart:convert';

import 'package:ssi_cli/src/commands/ssi_cli_base.dart';
import 'package:ssi_cli/src/constants.dart';

/// emit a new connection DID
class WalletListCredentialsCommand extends SsiCliCommandBase {
  @override
  final name = COMMAND_WALLET_CREDENTIALS_LIST;

  @override
  final description = "List Credentials";

  WalletListCredentialsCommand() { }

  @override
  run() async {
    var wallet = await loadWalletFromArgs();
    var creds = await wallet.getAllCredentials();
    await wallet.closeBoxes();

    Map<String, dynamic> result = {};
    for (var entry in creds.entries) {
      var did = entry.key;
      var credential = entry.value;
      result[did] = {
        'w3cCredential': credential.w3cCredential != '' ? jsonDecode(credential.w3cCredential) : null,
        'plaintextCredential': credential.plaintextCredential != '' ? jsonDecode(credential.plaintextCredential) : null,
        'hdPath': credential.hdPath,
      };
    }
    writeResultJson(result);
  }
}

