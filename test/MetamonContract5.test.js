const readYaml = require("./readYaml.js");
const yaml_data = readYaml("./test/testCases.yml");
const Web3 = require("web3");

const item_contract_address = yaml_data["ItemContract"]["contractName"];
const metamon_contract_name = yaml_data["MetamonContract"]["contractName"];

const ItemContract = artifacts.require(item_contract_address);
const MetamonContract = artifacts.require(metamon_contract_name);

const pass_code = yaml_data["MetamonContract"]["testCase6"]["passCode"];
const mint_dex_id = yaml_data["MetamonContract"]["testCase6"]["dexId"];
const massive_quantity = yaml_data["MetamonContract"]["testCase6"]["massiveQuantity"];

contract("Metamon", () => {
    let itemContract = null;
    let metamonContract = null;

    before(async() => {
        itemContract = await ItemContract.deployed();
        metamonContract = await MetamonContract.deployed();
        contractOwner = await metamonContract.owner.call();
    });

    it("Check as owner mint massive", async() => {
        await metamonContract.mintSale(
            pass_code,
            contractOwner,
            massive_quantity,
            mint_dex_id
        )
    })

});