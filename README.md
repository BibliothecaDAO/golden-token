# Golden Token

## VSCode Setup

### Devcontainer Initialization

The .devcontainer container will automatically generate key pair and deploy a dev account just follow prompts

### Contract Deployment
```bash
/bin/bash /workspaces/golden-token/scripts/deploy_contract.sh
```

## Non-VSCode Setup
```console
starkli declare target/dev/goldenToken_ERC721.sierra.json --account ./account --keystore ./keys

export GOLDEN_TOKEN_NAME=86359915354906848020620654
export GOLDEN_TOKEN_SYMBOL=78543885460846
export OWNER=0x020b96923a9e60f63a1829d440a03cf680768cadbc8fe737f71380258817d85b
export DAO_ADDRESS=0x020b96923a9e60f63a1829d440a03cf680768cadbc8fe737f71380258817d85b

starkli deploy 0x007ccf8c0a9a27392a68ec91db0d8005fd6d10ce0039a0627c8e0b0af7a73d7d $GOLDEN_TOKEN_NAME $GOLDEN_TOKEN_SYMBOL $OWNER $DAO_ADDRESS --account ./account --keystore ./keys
```

