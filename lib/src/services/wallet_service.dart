import 'dart:io';

import 'package:dart_ssi/wallet.dart';
import 'package:ssi_cli/src/exceptions/wallet_service_exception.dart';

/// Will init a fresh wallet
/// if [password] is given, it will be used to secure the wallet
/// if [mnemonic] is given, it will be used to restore the wallet
/// if no [mnemonic] is given, a new one will be generated
///
/// returns the mnemonic of the wallet (maybe generated or your passed-in one)
Future<String> initWallet({
  required Directory path,
  String? mnemonic,
  String? password,
  network = 'mainnet',
}) async {
  if (path.existsSync() && path.listSync(recursive: false).isNotEmpty) {
      throw WalletServiceException("Directory at `$path` exists already and is "
          "non-empty. If you want to init a new wallet there please "
          "delete the directory or its contents.", code: 4732);
    }

    var wallet = await loadAndOpenWallet(path: path, password: password);
    var mne = (await wallet.initialize(mnemonic: mnemonic, network: network))!;
    await wallet.closeBoxes();

    return mne;
  }

Future<WalletStore> loadAndOpenWallet({
    required Directory path,
    String? password,
}) async {
  try {
    var wallet = WalletStore(path.path);
    var res = await wallet.openBoxes(password);
    if (!res) {
      throw WalletServiceException(
          "Could not open wallet at `$path`. Please make"
              "sure the directory the password are correct.", code: 2348239);
    }
    return wallet;
  } catch (e) {
    throw WalletServiceException("Could not open wallet at `$path`. Details: $e",
        code: 4238293048);
  }
}

/// Gets all Key Types which are supported by the SSI wallet as string
List<String> getSupportedKeyTypes() {
  return KeyType.values.map((e) => e.toString().split('.').last.toLowerCase()).toList();
}

/// transform a Key Type String to a Wallet Native presentation
///
/// throws a [WalletServiceException] if the key type is not supported
KeyType keyTypeFromString(String keyType) {
  try {
    return KeyType.values.firstWhere((e) => e.toString().split('.').last.toLowerCase() == keyType);
  } catch (e) {
    throw WalletServiceException("Unknown key type `$keyType`", code: 87348923);
  }
}

/// Key types supported by the SSI wallet for issuing
List<String> supportedIssuerKeyTypes() {
  return const ['secp256k1', 'ed25519'];
}
