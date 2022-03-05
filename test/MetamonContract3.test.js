const readYaml = require("./readYaml.js");
const yaml_data = readYaml("./test/testCases.yml");
const Web3 = require("web3");

const item_contract_address = yaml_data["ItemContract"]["contractName"];
const metamon_contract_name = yaml_data["MetamonContract"]["contractName"];

const ItemContract = artifacts.require(item_contract_address);
const MetamonContract = artifacts.require(metamon_contract_name);

const recipient = yaml_data["MetamonContract"]["testCase4"]["recipient"];
const quantity_mint_metamon = yaml_data["MetamonContract"]["testCase4"]["quantityMintMetamon"];
const mint_dex_id = yaml_data["MetamonContract"]["testCase4"]["mintDexId"];

const quantity_mint_item = yaml_data["MetamonContract"]["testCase4"]["quantityMintItem"];
const mint_item_type = yaml_data["MetamonContract"]["testCase4"]["mintItemType"];
const pass_code = yaml_data["MetamonContract"]["testCase4"]["passCode"];


contract("Metamon", () => {
    let itemContract = null;
    let metamonContract = null;

    before(async () => {
        itemContract = await ItemContract.deployed();
        metamonContract = await MetamonContract.deployed();
        contractOwner = await metamonContract.owner.call();
    });

    
    it("Check Item Mint", async() => {
        await itemContract.mintSale(
            pass_code,
            recipient,
            mint_item_type,
            quantity_mint_item
        );
        
        const howManyItemMinted = await itemContract.balanceOf(recipient, {from: recipient});
        assert(howManyItemMinted.toNumber() == quantity_mint_item);
    });


})