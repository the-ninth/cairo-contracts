# The Ninth cairo contracts

Contracts deployed on StarkNet

## Compile

Compile Cairo contracts. Compilation artifacts are written into the `artifacts/` directory.
```sh
nile compile # compiles all contracts under contracts/
nile compile --directory my_contracts # compiles all contracts under my_contracts/
nile compile contracts/MyContract.cairo # compiles single contract
```

## Deploy

```sh
nile deploy contract --alias my_contract

🚀 Deploying contract
🌕 artifacts/contract.json successfully deployed to 0x07ec10eb0758f7b1bc5aed0d5b4d30db0ab3c087eba85d60858be46c1a5e4680
📦 Registering deployment as my_contract in localhost.deployments.txt
```