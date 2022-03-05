const readYaml = require("./readYaml.js");
const yaml_data = readYaml("./test/testCases.yml");
const Web3 = require("web3");

const metamon_contract_name = yaml_data["MetamonContract"]["contractName"];
const MetamonContract = artifacts.require(metamon_contract_name);



contract("Metamon", () => {
    let metamonContract = null;
    before(async () => {
        metamonContract = await MetamonContract.deployed();
        contractOwner = await metamonContract.owner.call();
    });

    it("check evalutionItemBurn", async () => {
        metamonContract.evalutionItemBurn(
            recipient,
            sendTokenId,
            sendDexId
        )
    });

})