import 'dart:io';

import 'package:dart_ssi/wallet.dart';
import 'package:ssi_cli/src/exceptions/wallet_service_exception.dart';

/// Will init a fresh wallet
/// if [password] is given, it will be used to secure the wallet
/// if [mnemonic] is given, it will be used to restore the wallet
/// if no [mnemonic] is given, a new one will be generated
/// if [initIssuers] is true all default-issuers will be auto-generated (on for
/// each issuer in [getSupportedIssuerKeyTypes])
///
/// returns the mnemonic of the wallet (randomly generated or your passed-in one)
Future<String> initWallet({
  required Directory path,
  String? mnemonic,
  String? password,
  network = 'mainnet',
  initIssuers = true,
  silent = false,
}) async {
  if (path.existsSync() && path.listSync(recursive: false).isNotEmpty) {
      throw WalletServiceException("Directory at `$path` exists already and is "
          "non-empty. If you want to init a new wallet there please "
          "delete the directory or its contents.", code: 4732);
    }

    var wallet = await loadAndOpenWallet(path: path, password: password);
    if (!silent) print("✅ Opened Wallet");
    var mne = (await wallet.initialize(mnemonic: mnemonic, network: network))!;
    if(!silent) print("✅ Initialized Stores");

    if (initIssuers) {
      // I do not know why the boxes are closed here, but they are -> reopen
      await wallet.openBoxes(password);
      for (var keyType in getSupportedIssuerKeyTypes()) {
        await wallet.initializeIssuer(keyType);
        if(!silent) print("✅ Initialized Issuer for Key Type "
            "`${keyTypeToString(keyType)}`");
      }
    }

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
  } on Exception catch (e) {
    throw WalletServiceException("Could not open wallet at `$path`",
        baseException: e,
        code: 4238293048);
  }
}


/// Transforms a Key Type String to a Wallet Native presentation.
///
/// throws a [WalletServiceException] if the key type is not supported
KeyType keyTypeFromString(String keyType) {
  try {
    return KeyType.values.firstWhere((e) => keyTypeToString(e) == keyType);
  } on Exception catch (e) {
    throw WalletServiceException("Unknown key type `$keyType`", code: 87348923,
        baseException: e);
  }
}

/// String representation of a [KeyType].
String keyTypeToString(KeyType keyType) {
  return keyType.toString().split('.').last.toLowerCase();
}

/// Key types supported by the SSI wallet for issuing.
List<KeyType> getSupportedIssuerKeyTypes() {
  return const [KeyType.secp256k1, KeyType.ed25519];
}

/// Shorthand around [getSupportedIssuerKeyTypes].
List<String> getSupportedIssuerKeyTypesAsString() {
  return getSupportedIssuerKeyTypes().map((e) => keyTypeToString(e)).toList();
}

/// Key types supported by the SSI wallet for storing credentials.
List<KeyType> getSupportedCredentialKeyTypes() {
  return const [KeyType.secp256k1, KeyType.ed25519];
}

/// Shorthand around [getSupportedCredentialKeyTypes].
List<String> getSupportedCredentialTypesAsString() {
  return getSupportedCredentialKeyTypes().map(
          (e) => keyTypeToString(e)).toList();
}

/// Gets all Key Types which are supported by the SSI wallet.
Iterable<KeyType> getSupportedWalletKeyTypes() {
  return KeyType.values;
}

/// Shorthand around [getSupportedWalletKeyTypes].
List<String> getSupportedWalletKeyTypesAsString() {
  return getSupportedWalletKeyTypes().map((kt) => keyTypeToString(kt)).toList();
}
