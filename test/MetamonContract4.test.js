const readYaml = require("./readYaml.js");
const yaml_data = readYaml("./test/testCases.yml");
const Web3 = require("web3");

const item_contract_address = yaml_data["ItemContract"]["contractName"];
const metamon_contract_name = yaml_data["MetamonContract"]["contractName"];

const ItemContract = artifacts.require(item_contract_address);
const MetamonContract = artifacts.require(metamon_contract_name);


const pass_code = yaml_data["MetamonContract"]["testCase5"]["passCode"];
const quantity_mint = yaml_data["MetamonContract"]["testCase5"]["quantityMintMetamon"];
const recipient = yaml_data["MetamonContract"]["testCase5"]["recipient"];
const mint_dex_ids = yaml_data["MetamonContract"]["testCase5"]["mintDexIds"];


contract("Metamon", () => {
    let itemContract = null;
    let metamonContract = null;
    
    before(async() => {
        itemContract = await ItemContract.deployed();
        metamonContract = await MetamonContract.deployed();
        contractOwner = await metamonContract.owner.call();
    });

    it("Check mint all phase dex ids", async() => {
        let numberOfMinted = 0

        for(i = 0; i < mint_dex_ids.length; i++) {
            await metamonContract.mintSale(
                pass_code,
                recipient,
                quantity_mint,
                mint_dex_ids[i]
            );
            numberOfMinted += quantity_mint * i;
        }
        const howManyMetamonMinted = await metamonContract.balanceOf(recipient, {from: recipient});
        assert(howManyMetamonMinted.toNumber() === numberOfMinted);
    });

    it("Check as owner change artifact mintable", async() => {

    })

    it("Check artifact mint logic", async() => {

    });
})