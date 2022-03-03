const readYaml = require("./readYaml.js");
const yaml_data = readYaml("./test/testCases.yml");
const Web3 = require("web3");

const item_contract_address = yaml_data["ItemContract"]["contractAddress"];
const metamon_contract_name = yaml_data["MetamonContract"]["contractName"];
const mintable_dex_id = yaml_data["MetamonContract"]["testCase2"]["mintableDexId"];
const non_mintable_dex_id = yaml_data["MetamonContract"]["testCase2"]["nonMintableDexId"];
const pass_code = yaml_data["MetamonContract"]["passCode"];
const recipient = yaml_data["MetamonContract"]["testCase3"]["recipient"];
const quantity = yaml_data["MetamonContract"]["testCase3"]["quantity"];
const left_dex_quantity = yaml_data["MetamonContract"]["testCase3"]["leftDexQuantity"];

const dex_id = yaml_data["MetamonContract"]["testCase3"]["dexId"]; // TODO: this will be removed | will be from VRF



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

    it("Check mint metamon", async() => {
        await metamonContract.mintSale(
            pass_code,
            recipient,
            quantity,
            dex_id,
        )

        const balance_of = await metamonContract.balanceOf(recipient);
        assert(balance_of.toNumber() == quantity);
    });

    it("Check specific dexId supply", async() => {
        const mintable_supply = await metamonContract.getSupplyDex(
            dex_id,
        )

        assert(left_dex_quantity == mintable_supply.toNumber());
    });


});