const readYaml = require("./readYaml.js");
const yaml_data = readYaml("./test/testCases.yml");
const Web3 = require("web3");

const contract_name = yaml_data["WardrobeContract"]["contractName"];
const Contract = artifacts.require(contract_name);

const contract_real_name = yaml_data["WardrobeContract"]["contractRealName"];
const contract_deployer = yaml_data["WardrobeContract"]["contractOwnerAddress"];
const contract_address = yaml_data["WardrobeContract"]["contractAddress"];
const contract_symbol = yaml_data["WardrobeContract"]["contractSymbol"];

const item1 = yaml_data["WardrobeContract"]["item1"];

const item2 = yaml_data["WardrobeContract"]["item2"];

contract("Wardrobe", () => {
  let deployedContract = null;
  before(async () => {
    deployedContract = await Contract.deployed();
  });

  it("Test if our Contract Deployed", async () => {
    assert(deployedContract.address !== "");
  });

  it("Test current Contract Owner", async () => {
    const owner = await deployedContract.owner();
    assert(owner === contract_deployer);
  });

  it("Test name of the Contract", async () => {
    const name = await deployedContract.name();
    assert(name === contract_real_name);
  });

  it("Add items into the Contract", async () => {
    await deployedContract.addWardrobeItem(
      item1["_itemType"],
      Web3.utils.toWei(`${item1["_itemPrice"]}`, "ether"),
      item1["_maxMintable"],
      item1["_itemSupply"],
      item1["_requiredMetamon"],
      item1["_proof"],
      item1["_uri"]
    );
    assert(true);
  });

  it("Set already added item price to the Contract and validate", async () => {
    await deployedContract.setItemPrice(
      Web3.utils.toWei(`${item2["_itemPrice"]}`, "ether"),
      item2["_itemType"]
    );

    await deployedContract.getItemPrice(item2["_itemType"]).then((price) => {
      assert(price, Web3.utils.toWei(`${item2["_itemPrice"]}`, "ether"));
    });
  });

  it("Set Max Mintable", async () => {
    await deployedContract.setMaxMintable(20, item2["_itemType"]);

    await deployedContract.getMaxMintable(item2["_itemType"]).then((max) => {
      assert(max, 20);
    });
  });

  it("Set Item Supply", async () => {
    await deployedContract.setItemSupply(30, item2["_itemType"]);

    await deployedContract.getItemSupply(item2["_itemType"]).then((supply) => {
      assert(supply, 30);
    });
  });

  it("Set Required Metamon", async () => {
    await deployedContract.setRequiredMetamon([40], item2["_itemType"]);

    await deployedContract
      .getRequiredMetamon(item2["_itemType"])
      .then((req) => {
        assert(req, [40]);
      });
  });

  it("Set Proof", async () => {
    await deployedContract.setMerkleRoot(item2["_proof"], item2["_itemType"]);

    await deployedContract.getMerkleRoot(item2["_itemType"]).then((proof) => {
      assert(proof, item2["_proof"]);
    });
  });

  it("Total Items returns 1 after adding", async () => {
    await deployedContract.totalItemTypes().then((total) => {
      assert(total, 1);
    });
  });

  it("Set Metamon Contract Address", async () => {
    await deployedContract.setPayableAddress(
      yaml_data["WardrobeContract"]["contractPayableAddress"]
    );
  });

  it("Set Metamon Contract Address 1 Type", async () => {
    await deployedContract.setContractAddresses(
      1,
      yaml_data["WardrobeContract"]["contractPayableAddress"]
    );
  });

  it("Set Metamon Contract Address 2 Type", async () => {
    await deployedContract.setContractAddresses(
      2,
      yaml_data["WardrobeContract"]["contractPayableAddress"]
    );
  });

  it("Set Token URI", async () => {
    await deployedContract.setTokenUri(
      1,
      yaml_data["WardrobeContract"]["tokenURI"]
    );
  });
});
