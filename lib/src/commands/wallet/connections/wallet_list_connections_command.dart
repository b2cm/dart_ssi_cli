import 'package:ssi_cli/src/commands/ssi_cli_base.dart';
import 'package:ssi_cli/src/constants.dart';

/// emit a new connection DID
class WalletListConnectionsCommand extends SsiCliCommandBase {
  @override
  final name = COMMAND_WALLET_CONNECTIONS_LIST;

  @override
  final description = "List Connections";

  WalletListConnectionsCommand() { }

  @override
  run() async {
    var wallet = await loadWallet();
    var conns = await wallet.getAllConnections();
    await wallet.closeBoxes();

    writeResultJson(conns);
  }
}
