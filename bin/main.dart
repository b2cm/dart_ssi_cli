import 'package:args/command_runner.dart';

import '../lib/commands.dart';

void main(List<String> args) {
  CommandRunner('main', 'Some description')
    ..addCommand(VerifyCommand())
    ..addCommand(WalletCommand())
    ..addCommand(SignatureCommand())
    ..addCommand(Erc1056Command())
    ..addCommand(RevocationCommand())
    ..addCommand(CredentialCommand())
    ..addCommand(DidCommCommand())
    ..run(args);
}

