const readYaml = require("./readYaml.js");
const yaml_data = readYaml("./test/testCases.yml");

const contract_name = yaml_data["ItemContract"]["contractName"];
const Contract = artifacts.require(contract_name);

const total_item_types = yaml_data["ItemContract"]["totalItemTypes"];
const item_burnable = yaml_data["ItemContract"]["itemBurnable"];
const item_types = yaml_data["ItemContract"]["itemTypes"];
const max_ownable = yaml_data["ItemContract"]["maxOwnable"];
const item_supplies = yaml_data["ItemContract"]["itemSupplies"];
const item_floors = yaml_data["ItemContract"]["itemFloor"];
const total_supply = yaml_data["ItemContract"]["itemTotalSupply"];

contract("Item", () => {
  let deployedContract = null;
  before(async () => {
    deployedContract = await Contract.deployed();
    contractOwner = await deployedContract.owner.call();
  });

  it("Check Total Item Types", async () => {
    const totalItemTypes = await deployedContract.totalItemTypes();
    assert(totalItemTypes.toNumber() === total_item_types);
  });

  it("Check Burnable Items", async () => {
    for (i = 0; i < item_burnable.length; i++) {
      const itemBurnable = await deployedContract.itemBurnable.call(i);
      assert(itemBurnable.toNumber() === item_burnable[i]);
    }
  });

  it("Check Item Types", async () => {
    for (i = 0; i < item_types.length; i++) {
      const itemTypes = await deployedContract.itemTypes.call(i);
      assert(itemTypes.toNumber() === item_types[i]);
    }
  });

  it("Check Max Ownable", async () => {
    for (i = 0; i < max_ownable.length; i++) {
      const maxOwnable = await deployedContract.maxOwnable.call(i);
      assert(maxOwnable.toNumber() === max_ownable[i]);
    }
  });

  it("Check Max Supplies", async () => {
    for (i = 0; i < item_supplies.length; i++) {
      const itemSupplies = await deployedContract.itemSupplies.call(i);
      assert(itemSupplies.toNumber() === item_supplies[i]);
    }
  });

  it("Check Max Supplies Func", async () => {
    for (i = 0; i < item_supplies.length; i++) {
      const itemSupplies = await deployedContract.getSupplyLeft(i + 1);
      assert(itemSupplies.toNumber() === item_supplies[i]);
    }
  });

  it("Check Item Floors", async () => {
    for (i = 0; i < item_floors; i++) {
      const itemFloors = await deployedContract.getFloorPrice(i + 1);
      assert(itemFloors.toNumber() === item_floors[i]);
    }
  });

  it("Check Change Floor Price", async () => {
    for (i = 0; i < item_floors; i++) {
      const new_floor = 0.5;
      await deployedContract.changeFloorPrice(new_floor, {
        from: contractOwner,
      });

      const itemFloor = await deployedContract.getFloorPrice(i + 1);
      const itemFloorFromList = await deployedContract.itemFloor.call(i);

      assert(itemFloor === new_floor);
      assert(itemFloorFromList === new_floor);
    }
  });

  it("Check Change Floor Price as Foreigner", async () => {
    try {
      await deployedContract.changeFloorPrice(new_floor);
      assert(false);
      return;
    } catch {
      assert(true);
      return;
    }
  });

  it("Check Total Supply", async () => {
    const totalSupply = await deployedContract.itemTotalSupply.call();
    assert(totalSupply.toNumber() === total_supply);
  });
});
