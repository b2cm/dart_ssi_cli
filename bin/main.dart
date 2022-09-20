import 'package:args/command_runner.dart';

import '../lib/commands.dart';

void main(List<String> args) {
  CommandRunner('main', 'SSI Wallet Agent')
    /*..addCommand(VerifyCommand())
    ..addCommand(SignatureCommand())
    ..addCommand(Erc1056Command())
    ..addCommand(RevocationCommand())
    ..addCommand(CredentialCommand())*/
    ..addCommand(WalletCommand())
    ..addCommand(DidCommCommand())
    ..run(args);
}

