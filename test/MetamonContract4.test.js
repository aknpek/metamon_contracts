const readYaml = require("./readYaml.js");
const yaml_data = readYaml("./test/testCases.yml");
const Web3 = require("web3");

const item_contract_address = yaml_data["ItemContract"]["contractName"];
const metamon_contract_name = yaml_data["MetamonContract"]["contractName"];

const ItemContract = artifacts.require(item_contract_address);
const MetamonContract = artifacts.require(metamon_contract_name);


contract("Metamon", () => {
    let itemContract = null;
    let metamonContract = null;
    
    before(async() => {
        itemContract = await ItemContract.deployed();
        metamonContract = await MetamonContract.deployed();
        contractOwner = await metamonContract.owner.call();
    });

    it("Check mint all phase dex ids", async() => {

    });

    it("Check as owner change artifact mintable", async() => {
        
    })

    it("Check artifact mint logic", async() => {

    });
})