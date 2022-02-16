const readYaml = require('./readYaml.js');
const yaml_data = readYaml('./test/testCases.yml');
const Web3 = require('web3');

const contract_name = yaml_data['ItemContract']['contractName'];
const Contract = artifacts.require(contract_name);

const item_supplies = yaml_data['ItemContract']['itemSupplies'];
const item_floors = yaml_data['ItemContract']['itemFloor']
const first_mint_phase = yaml_data['ItemContract']['mintPhaseFirst'];
const pass_code = yaml_data['ItemContract']['passCode'];
const complex_mint_phase = yaml_data['ItemContract']['mintComplex'];

contract('Item', () => {
    let deployedContract = null;
    before(async() => {
        deployedContract = await Contract.deployed();
        contractOwner = await deployedContract.owner.call();
    });

    it('Check Mint as Other Conract', async() => {
        await deployedContract.mintSale(
            pass_code,
            first_mint_phase['recipient'],
            first_mint_phase['itemType'],
            first_mint_phase['mintQuantity']
        )
        const balance = await deployedContract.balanceOf(
            first_mint_phase['recipient']
        )
        assert(balance.toNumber() === first_mint_phase['mintQuantity']);
    });

    it('Check Mint as Owner', async() => {
        let total_minted = first_mint_phase['mintQuantity']; // We are still in the same state, therefore, we need to consider the first test function

        for (i = 0; i < (complex_mint_phase.length); i++){
            let _floor = item_floors[complex_mint_phase[i]['itemType'] - 1];
            let _send_eth = _floor * complex_mint_phase[i]['mintQuantity'];
            
            await deployedContract.mintSale(
                pass_code,
                complex_mint_phase[i]['recipient'],
                complex_mint_phase[i]['itemType'],
                complex_mint_phase[i]['mintQuantity'],
                {
                    from: complex_mint_phase[i]['recipient'],
                    value: Web3.utils.toWei(`${_send_eth}`, 'ether')
                }
            )
            total_minted += complex_mint_phase[i]['mintQuantity']     
        }

        const balance = await deployedContract.balanceOf(
            complex_mint_phase[1]['recipient']
        );
        assert(balance.toNumber() === total_minted);
    });

    it('Check Minted Item Types Balances (*should be decreased already)', async() => {
        let item_type = 1;

        let total_balance = item_supplies[item_type - 1];
        const total_left = await deployedContract.getSupplyLeft(item_type); 

        assert((total_balance - first_mint_phase['mintQuantity']) === total_left.toNumber());
    });

    it('Check Minted Token Type', async() => { 
        const tokenId = 1;
        const item_type = await deployedContract.tokenItemTypes.call(tokenId);
        assert(item_type.toNumber() === 1);
    });

    it('Check Burning Operation', async() => {
        const tokenId = 22;  

        const berfore_burn_balance = await deployedContract.balanceOf(contractOwner);
        await deployedContract.burn(complex_mint_phase[1]['recipient'], tokenId);
        
        const after_burn_balance = await deployedContract.balanceOf(contractOwner);

        assert(after_burn_balance > berfore_burn_balance);
    });
})