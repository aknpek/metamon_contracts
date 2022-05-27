const readYaml = require("./readYaml.js");
const yaml_data = readYaml("./test/testCases.yml");
const Web3 = require("web3");

const contract_name = yaml_data["WardrobeContract"]["contractName"];
const Contract = artifacts.require(contract_name);

const contract_real_name = yaml_data["WardrobeContract"]["contractRealName"];
const contract_deployer = yaml_data["WardrobeContract"]["contractOwnerAddress"];
const contract_address = yaml_data["WardrobeContract"]["contractAddress"];
const contract_symbol = yaml_data["WardrobeContract"]["contractSymbol"];

const item3 = yaml_data["WardrobeContract"]["item3"];
const item4 = yaml_data["WardrobeContract"]["item4"];
const item5 = yaml_data["WardrobeContract"]["item5"];

contract("Wardrobe", () => {
  let deployedContract = null;
  before(async () => {
    deployedContract = await Contract.deployed();
  });

  it("Add items into the Contract", async () => {
    await deployedContract.addWardrobeItem(
      item3["_itemType"],
      Web3.utils.toWei(`${item3["_itemPrice"]}`, "ether"),
      item3["_maxMintable"],
      item3["_itemSupply"],
      item3["_requiredMetamon"],
      item3["_proof"],
      item3["_uri"]
    );
    assert(true);
  });

  it("Mint sale", async () => {
    await deployedContract.mintSale(item3["_itemType"], item3["_maxMintable"], {
      from: contract_deployer,
      value: Web3.utils.toWei(
        `${item3["_itemPrice"] * item3["_maxMintable"]}`,
        "ether"
      ),
    });
  });

  it("Mint sale second time", async () => {
    try {
      await deployedContract.mintSale(item3["_itemType"], 5, {
        from: contract_deployer,
        value: Web3.utils.toWei(`${item3["_itemPrice"] * 5}`, "ether"),
      });
      assert(false);
      return;
    } catch {
      assert(true);
      return;
    }
  });

  it("Add more items for mint", async () => {
    await deployedContract.addWardrobeItem(
      item4["_itemType"],
      Web3.utils.toWei(`${item4["_itemPrice"]}`, "ether"),
      item4["_maxMintable"],
      item4["_itemSupply"] * 2,
      item4["_requiredMetamon"],
      item4["_proof"],
      item4["_uri"]
    );
    await deployedContract.addWardrobeItem(
      item5["_itemType"],
      Web3.utils.toWei(`${item5["_itemPrice"]}`, "ether"),
      item5["_maxMintable"],
      item5["_itemSupply"],
      item5["_requiredMetamon"],
      item5["_proof"],
      item5["_uri"]
    );
  });

  it("Mint multiple-items", async () => {
    await deployedContract.mintMultipleSale(
      [item4["_itemType"], item5["_itemType"]],
      [5, 5],
      {
        from: contract_deployer,
        value: Web3.utils.toWei(
          `${item4["_itemPrice"] * 5 + item5["_itemPrice"] * 5}`,
          "ether"
        ),
      }
    );
  });

  it("Total Item Types", async () => {
    const totalItemTypes = await deployedContract.totalItemTypes();
    assert.equal(totalItemTypes, 3);
  });
});
