const readYaml = require("./readYaml.js");
const yaml_data = readYaml("./test/testCases.yml");
const Web3 = require("web3");

const item_contract_address = yaml_data["ItemContract"]["contractAddress"];

const metamon_contract_name = yaml_data["MetamonContract"]["contractName"];
const MetamonContract = artifacts.require(metamon_contract_name);

contract("Metamon", () => {
    let metamonContract = null;
    before(async() => {
        metamonContract = await MetamonContract.deployed();
        contractOwner = await metamonContract.owner.call();
    });

    it("Check if Metamon calls Item Contract", async() => {
        const floor_price = await metamonContract.mintSale(
            contractOwner, 
            item_contract_address,
            2,
            1
        );

        console.log(floor_price);
    });

})