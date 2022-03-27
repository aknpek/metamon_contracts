const readYaml = require("./readYaml.js");
const yaml_data = readYaml("./test/testCases.yml");
const Web3 = require("web3");

const contract_name = yaml_data["ItemContract"]["contractName"];
const Contract = artifacts.require(contract_name);

const item_supplies = yaml_data["ItemContract"]["itemSupplies"];
const item_floors = yaml_data["ItemContract"]["itemFloor"];
const first_mint_phase = yaml_data["ItemContract"]["mintPhaseFirst"];
const pass_code = yaml_data["ItemContract"]["passCode"];
const complex_mint_phase = yaml_data["ItemContract"]["mintComplex"];

contract("Item", () => {
  let deployedContract = null;
  before(async () => {
    deployedContract = await Contract.deployed();
    contractOwner = await deployedContract.owner.call();
  });

  it("Check Mint as Owner", async () => {
    await deployedContract.mintSale(
      pass_code,
      first_mint_phase["recipient"],
      first_mint_phase["itemType"],
      first_mint_phase["mintQuantity"]
    );
    const balance = await deployedContract.balanceOf(
      first_mint_phase["recipient"]
    );
    assert(balance.toNumber() === first_mint_phase["mintQuantity"]);
  });

  it("Check Mint as Other Contract Not Whitelisted", async () => {
    let total_minted = first_mint_phase["mintQuantity"]; // We are still in the same state, therefore, we need to consider the first test function

    for (i = 0; i < complex_mint_phase.length; i++) {
      let _floor = item_floors[complex_mint_phase[i]["itemType"] - 1];
      let _send_eth = _floor * complex_mint_phase[i]["mintQuantity"];

      await deployedContract.mintSale(
        pass_code,
        complex_mint_phase[i]["recipient"],
        complex_mint_phase[i]["itemType"],
        complex_mint_phase[i]["mintQuantity"],
        {
          from: complex_mint_phase[i]["recipient"],
          value: Web3.utils.toWei(`${_send_eth}`, "ether"),
        }
      );
      total_minted += complex_mint_phase[i]["mintQuantity"];
    }

    const balance = await deployedContract.balanceOf(
      complex_mint_phase[1]["recipient"]
    );
    assert(balance.toNumber() === total_minted);
  });

  it("Check Adding Contract Caller to Whitelist", async () => {
    await deployedContract.allowlistAddress(first_mint_phase["recipient"], true);

    let promise = deployedContract.isAllowlistAddress(first_mint_phase["recipient"]);
    let whitelisted = false;
    Promise.resolve(promise).then(function(value) {
      whitelisted = value;

      assert(whitelisted === true);
    });
  
  })

  it("Check Adding Multiple Contract Caller to Whitelist", async () => {

    let complexMintPhaseAddresses = [];
    let complexMintPhaseAddressesWhitelisted = [];
    for(i = 0; i < complex_mint_phase.length; i++){
      complexMintPhaseAddresses.push(complex_mint_phase[i].recipient);
    }

    await deployedContract.allowlistAddresses(complexMintPhaseAddresses, true);

    for(i = 0; i< complexMintPhaseAddresses; i++){
      let promise = deployedContract.isAllowlistAddress(complexMintPhaseAddresses[i]);
      let whitelisted = false;
      Promise.resolve(promise).then(function(value) {
        whitelisted = value;
        complexMintPhaseAddressesWhitelisted.push(whitelisted);
        
      });
    }

    assert(complexMintPhaseAddressesWhitelisted.every((x) => x.should.equal(true)));
  })

  it("Check Mint as Contract Whitelisted", async () => {
    let total_minted = first_mint_phase["mintQuantity"]; // We are still in the same state, therefore, we need to consider the first test function

    for (i = 0; i < complex_mint_phase.length; i++) {
      let _floor = item_floors[complex_mint_phase[i]["itemType"] - 1];
      let _send_eth = _floor * complex_mint_phase[i]["mintQuantity"];

      await deployedContract.mintSale(
        pass_code,
        complex_mint_phase[i]["recipient"],
        complex_mint_phase[i]["itemType"],
        complex_mint_phase[i]["mintQuantity"],
        {
          from: complex_mint_phase[i]["recipient"],
          value: Web3.utils.toWei(`${_send_eth}`, "ether"),
        }
      );
      total_minted += complex_mint_phase[i]["mintQuantity"];
    }

    const balance = await deployedContract.balanceOf(
      complex_mint_phase[1]["recipient"]
    );
    assert(balance.toNumber() === total_minted);
  });



  it("Check Minted Item Types Balances (*should be decreased already)", async () => {
    let item_type = 1;

    let total_balance = item_supplies[item_type - 1];
    const total_left = await deployedContract.getSupplyLeft(item_type);

    assert(
      total_balance - first_mint_phase["mintQuantity"] === total_left.toNumber()
    );
  });

  it("Check Minted Token Type", async () => {
    const tokenId = 1;
    const item_type = await deployedContract.tokenItemTypes.call(tokenId);
    assert(item_type.toNumber() === 1);
  });

  it("Check Burning Operation for Non-Burnable Token", async () => {
    const tokenId = 22; // this tokenId is not burnable

    try {
      const before_burn_balance = await deployedContract.balanceOf(
        complex_mint_phase[1]["recipient"]
      );
      await deployedContract.burn(complex_mint_phase[1]["recipient"], tokenId);
      const after_burn_balance = await deployedContract.balanceOf(
        complex_mint_phase[1]["recipient"]
      );
      assert(after_burn_balance.toNumber() < before_burn_balance.toNumber());
      assert(false)
      return;
    } catch {
      assert(true);
      return;
    }
  });

  it("Check Burning Operation for Burnable Token", async () => {
    const tokenId = 1; // Since in the testCases yml, we first mint tokenType 1 tokens, therefore, they are burnable

    const before_burn_balance = await deployedContract.balanceOf(
      complex_mint_phase[1]["recipient"]
    );
    await deployedContract.burn(complex_mint_phase[1]["recipient"], tokenId);

    const after_burn_balance = await deployedContract.balanceOf(
      complex_mint_phase[1]["recipient"]
    );

    assert(after_burn_balance.toNumber() < before_burn_balance.toNumber());
  });
});
