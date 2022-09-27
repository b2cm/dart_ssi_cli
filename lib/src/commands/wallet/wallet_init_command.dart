import 'dart:io';

import 'package:ssi_cli/src/commands/ssi_cli_base.dart';
import 'package:ssi_cli/src/constants.dart';
import 'package:ssi_cli/src/exceptions/wallet_service_exception.dart';
import 'package:ssi_cli/src/services/wallet_service.dart';

class WalletInitCommand extends SsiCliCommandBase {
  @override
  final name = COMMAND_WALLET_INIT;

  @override
  final description = "Initialize a new wallet";

  WalletInitCommand() {
    argParser
      ..addOption(PARAM_MNEMONIC,
          help: "Mnemonic to restore a wallet from. If not given, "
                "a new one will be generated",
          mandatory: false)
        ..addFlag(PARAM_INIT_ISSUERS,
            help: "Initialize issuers for all supported key types",
            defaultsTo: true,
        );
  }

  @override
  run() async {
    String? mnemonic = getArgString(PARAM_MNEMONIC, isOptional: true);

    String password = getArgString(PARAM_WALLET_PASSWORD,
        isOptional: false,
        nonEmpty: true)!;

    Directory effectivePath = getEffectiveWalletDir(dataDirMustExist: true,
        effectivePathMustExist: false);

    bool initIssuers = getArgFlag(PARAM_INIT_ISSUERS);

    // create an empty directory if it does not exist (parent should exist here)
    // will just raise if someone deleted the directory meanwhile (we do not
    // lock it)
    if (!effectivePath.existsSync()) {
      effectivePath.createSync(recursive: false);
    }

    try {
      mnemonic = await initWallet(
        path: effectivePath,
        mnemonic: mnemonic,
        password: password,
        initIssuers: initIssuers,
      );
      writeResult("Created a new wallet at `$effectivePath` "
          "with mnemonic:\n --> `$mnemonic` <-- \n"
          "Notes: \n------\n"
          "⚠️ Please write down the mnemonic as it can be used to recover the "
          "wallet. Also keep it safe.\n"
          "⚠️ Everyone in control of the mnemomic may impersonate you.\n"
          "⚠️ The wallet itself is secured by your provided password.");
    } on WalletServiceException catch (e) {
      writeError(e.toString(), 4322323645);
    }finally {
    }
  }
}