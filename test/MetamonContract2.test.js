const readYaml = require("./readYaml.js");
const yaml_data = readYaml("./test/testCases.yml");
const Web3 = require("web3");

const item_contract_address = yaml_data["ItemContract"]["contractAddress"];
const metamon_contract_name = yaml_data["MetamonContract"]["contractName"];
const mintable_dex_id = yaml_data["MetamonContract"]["testCase2"]["mintableDexId"];
const non_mintable_dex_id = yaml_data["MetamonContract"]["testCase2"]["nonMintableDexId"];

const MetamonContract = artifacts.require(metamon_contract_name);



contract("Metamon", () => {
    let metamonContract = null;
    before(async () => {
        metamonContract = await MetamonContract.deployed();
        contractOwner = await metamonContract.owner.call(); 
    });

    it("Check mintable dex for current metamon mint phase", async() => {
        const mintableDex = await metamonContract.mintableDex(mintable_dex_id);
        assert(mintableDex == true);

        const nonMintableDex = await metamonContract.mintableDex(non_mintable_dex_id);
        assert(nonMintableDex == false);
    });
});