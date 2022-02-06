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


