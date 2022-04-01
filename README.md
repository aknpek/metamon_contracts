# metamon_contracts
Whole Contracts of the Metamon Project

# Truffle Runs:

- Make sure you have "ganache" installed already
- Run "ganache" and check "truffle-config.js" file comment-out

```bash
        development: {
            host: "127.0.0.1",     // Localhost (default: none)
            port: 7545,            // Standard Ethereum port (default: none)
            network_id: "*",       // Any network (default: none)
            },
```

- Make sure your contract inside ./contracts folder.
- Make sure ./migrations/2_deploy_contract.js set to current contract.

- Run migration and test codes;

```bash

truffle migrate --network development
```

- Get the contract details and update ./test/

```bash

truffle test
```

- Inside the ./test folder we have testCases, where you should update **itemContractAddress** and **metamonContractAddress** variables.


# VRF Explanation

1.) We have an example contract **VRF_Example.sol**
2.) Add **LINK** balance to your wallet from faucets at https://faucets.chain.link/rinkeby
3.) We need to create a subscription at https://vrf.chain.link/rinkeby/ for *rinkeby
4.) Add **LINK** amount to created subscription
5.) Add *SubscriptionID into contract (either within deployment or have a dedicated *function)
6.) Add deployed **Contract Address** to **subscription** in Chainlink
7.) Send a request to deployed contract to trigger VRF function

