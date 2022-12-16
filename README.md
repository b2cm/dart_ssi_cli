# SSI Wallet
This application an SSI-focussed crypto wallet, which is able to store and generate credentials, build Didcomm v2 Message and handle Key materials, Connection and Communication information.

### Usage
The application can be invoked via CLI as in
```bash
./ssi-wallet [--parameters] subcommand [subcommand parameters]
```
Each command has its own help, which can be invoked via
```bash
./ssi-wallet subcommand --help
```

(or `./ssi-wallet --help` for a list of all commands)

Many of the parameters have a reasonable default value, whilst some **must** be specified. This is documented in the `--help` output.

### Installation
This application is a standalone-app written in Dartlang.
Build executable: 
```shell
mkdir build
compile exe bin/main.dart -o ./ssi-wallet.exe
```


# Implemented Functions
- verify : check if verifiable credential or presentation is correct
- messages: sign strings and verify the signatures
- wallet: 
    - initialize one 
    - generate new connection-dids
    - list connection dids
    - recover keys from mnemonic
- didRegistry: 
    - get Identity owner for a given did
    - rotate key
- Revocation Registry:
    - deploy a new one
    - check, if credential is revoked
    - revoke a credential


### References
- [Dartlang](https://dart.dev/)
- [DIDComm specs](https://identity.foundation/didcomm-messaging/spec/)