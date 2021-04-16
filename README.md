# ssi_cli

Build executable: 
```
mkdir build
dart compile exe lib/main.dart -o build/main
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
