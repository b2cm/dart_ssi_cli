import 'dart:io';

import 'package:ssi_cli/src/commands/ssi_cli_base.dart';
import 'package:ssi_cli/src/commands/wallet/connections/wallet_generate_connection_command.dart';
import 'package:ssi_cli/src/constants.dart';
import 'package:ssi_cli/src/exceptions/wallet_service_exception.dart';
import 'package:ssi_cli/src/services/wallet_service.dart';
import 'package:ssi_cli/src/utils/path_utils.dart';

import 'wallet_list_connections_command.dart';

/// administer connections
class WalletConnectionsCommand extends SsiCliCommandBase {
  @override
  final name = COMMAND_WALLET_CONNECTIONS;

  @override
  final description = "administer wallet connections";

  WalletConnectionsCommand() {
    addSubcommand(WalletGenerateConnectionCommand());
    addSubcommand(WalletListConnectionsCommand());
  }

}