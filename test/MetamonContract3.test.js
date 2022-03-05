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
const mint_item_token_id = yaml_data["MetamonContract"]["testCase4"]["mintItemTokenId"];
const pass_code = yaml_data["MetamonContract"]["testCase4"]["passCode"];

const quantity_sent = yaml_data["MetamonContract"]["testCase4"]["quantitySend"];
const send_dex_token_id_burnable = yaml_data["MetamonContract"]["testCase4"]["sendTokenDexIdBurnable"];
const send_dex_token_id_non_burnable = yaml_data["MetamonContract"]["testCase4"]["sendTokenDexIdNonBurnable"];


contract("Metamon", () => {
    let itemContract = null;
    let metamonContract = null;
    let numberMetamonLeft = 0;

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

    it("Check Metamon Mint", async() => {
        await metamonContract.mintSale(
            pass_code,
            recipient,
            quantity_mint_metamon,
            mint_dex_id
        );
        const howManyMetamonMinted = await metamonContract.balanceOf(recipient, {from: recipient});
        assert(howManyMetamonMinted.toNumber() == quantity_mint_metamon);
    });

    it("Check first evalution meta burn non-burnable logic", async() => {
        try{
            await metamonContract.evalutionMetaBurn(
                recipient,
                send_dex_token_id_non_burnable,
                quantity_sent,
                {
                    from: recipient,
                }
            );
            assert(false);
            return;
        } catch{
            assert(true);
            return;
        }
    });
    
    it("Check first evalution meta-burn logic", async() => {
        await metamonContract.evalutionMetaBurn(
            recipient,
            send_dex_token_id_burnable,
            quantity_sent,
            {
                from: recipient
            }
        );
        const howManyMetamonMintedLeft = await metamonContract.balanceOf(recipient, {from: recipient});
        numberMetamonLeft = howManyMetamonMintedLeft;
    });

    it("Check first evalution item burn logic", async() => {
        await metamonContract.evalutionItemBurn(
            recipient,
            send_dex_token_id_burnable,
            mint_item_token_id,
            {
                from: recipient,
            }
        ); 
        const howManyMetamonMintedLeft = await metamonContract.balanceOf(recipient, {from: recipient});
        console.log(howManyMetamonMintedLeft.toNumber())
        assert(howManyMetamonMintedLeft.toNumber() == numberMetamonLeft); // one burned one received therefore no changes
    });

})