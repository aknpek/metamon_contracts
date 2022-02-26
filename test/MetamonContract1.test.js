const readYaml = require("./readYaml.js");
const yaml_data = readYaml("./test/testCases.yml");
const Web3 = require("web3");

const item_contract_address = yaml_data["ItemContract"]["contractAddress"];

const metamon_contract_name = yaml_data["MetamonContract"]["contractName"];
const current_mint_phase = yaml_data["MetamonContract"]["currentMintPhase"];
const other_owner = yaml_data["otherOwner"];
const new_price = yaml_data["MetamonContract"]["testCase1"]["newPrice"];
const dex_id = yaml_data["MetamonContract"]["testCase1"]["dexId"];
const supply_dex_1 = yaml_data["MetamonContract"]["testCase1"]["supplyDex1"];
const new_supply_dex_1 = yaml_data["MetamonContract"]["testCase1"]["newSupplyDex1"];
const MetamonContract = artifacts.require(metamon_contract_name);

contract("Metamon", () => {
  let metamonContract = null;
  before(async () => {
    metamonContract = await MetamonContract.deployed();
    contractOwner = await metamonContract.owner.call();
  });

  // it("Check if Metamon calls Item Contract", async() => {
  //     // TODO: remove that function, it can already call the Item contract
  //     const floor_price = await metamonContract.mintSale(
  //         contractOwner,
  //         item_contract_address,
  //         2,
  //         1
  //     );

  //     console.log(floor_price);
  // });

  it("Check accessibility current mint phase", async () => {
    const currentMintPhase = await metamonContract.currentMintPhase.call();
    assert(current_mint_phase == currentMintPhase);
  });

  it("Check accessibility change floor price form other owner", async () => {
    try {
      await metamonContract.changeFloorPrice(new_price, dex_id, {
        from: otherOwner,
      });
      assert(false);
      return;
    } catch (e) {
      assert(true);
      return;
    }
  });

  it("Check accessibility change floor price as owner", async () => {
    try {
      await metamonContract.changeFloorPrice(new_price, dex_id, {
        from: contractOwner,
      });
      assert(true);
    } catch (e) {
      assert(false);
      return;
    }

    const new_floor_price = await metamonContract.getFloorPrice(dex_id, {from: other_owner});  // other owner can reach the contract
    assert(new_floor_price.toNumber() === new_price);
    return;
  });

  it("Check get supply of specific dex", async () => {
      const supply_of_dex_id_1_1 = await metamonContract.getSupplyDex(dex_id, {from: other_owner});
      const supply_of_dex_id_1_2 = await metamonContract.getSupplyDex(dex_id, {from: contractOwner});
      assert(supply_of_dex_id_1_1.toNumber() === supply_dex_1);
      assert(supply_of_dex_id_1_2.toNumber() === supply_dex_1);
  });

  it("Check change supply of specific dex", async () => {
      await metamonContract.changeSupplyDexId(new_supply_dex_1, dex_id, {from: contractOwner});
      const new_supply_of_dex_id_1_1 = await metamonContract.getSupplyDex(dex_id, {from: other_owner});
      const new_supply_of_dex_id_1_2 = await metamonContract.getSupplyDex(dex_id, {from: contractOwner});
    
      assert(new_supply_of_dex_id_1_1.toNumber() === new_supply_dex_1);
      assert(new_supply_of_dex_id_1_2.toNumber() === new_supply_dex_1);
  });
});
