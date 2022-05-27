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
});
