import 'dart:io';

import 'package:args/args.dart';

import '../constants.dart';

/// CLI options to find and open the SSI Wallet
ArgParser addWalletNecessaryParametersToArgParser(ArgParser argParser,
    {isMandatory = true}) {
  argParser
    ..addOption(PARAM_WALLET_PASSWORD,
          help: "Password the wallet is secured with",
          mandatory: isMandatory)

    ..addOption(PARAM_WALLET_DATA_DIR,
        help: "Directory in Filesystem to store Wallet-Files. "
              "Will be the current directory if not given. "
              "The Directory MUST exist (will not be created)",
        defaultsTo: Directory.current.path)

    ..addOption(PARAM_WALLET_NAME,
        help: "Name of the wallet",
        defaultsTo: "default-wallet"
    )
  ;

  // just for chaining
  return argParser;
}