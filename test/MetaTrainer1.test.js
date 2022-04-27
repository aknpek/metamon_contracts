const readYaml = require("./readYaml.js");
const yaml_data = readYaml("./test/testCases.yml");
const Web3 = require("web3");

const meta_trainer_contract_name = yaml_data["MetaTrainer"]["contractName"];
const MetaTrainer = artifacts.require(meta_trainer_contract_name);

const base_uri = yaml_data["MetaTrainer"]["baseUri"];
const foreigner = yaml_data["MetaTrainer"]["testCase1"]["foreigner"];
const amount_minted = yaml_data["MetaTrainer"]["testCase1"]["amountMinted"];

const foreigner_second = yaml_data["MetaTrainer"]["testCase2"]["foreigner"];
const amount_minted_2 = yaml_data["MetaTrainer"]["testCase2"]["amountMinted"];

contract("MetaTrainer", () => {
  let trainerContract = null;

  before(async () => {
    trainerContract = await MetaTrainer.deployed();
    contractOwner = await trainerContract.owner.call();
  });

  it("Set Example Token URI for erc1155 as owner", async () => {
    await trainerContract.setTokenUri(base_uri);
    const token_uri = await trainerContract.baseUri.call();

    assert(base_uri == token_uri);
  });

  it("Mint Trainer as foreigner", async () => {
    await trainerContract.mintTrainer(foreigner, amount_minted, {
      from: foreigner,
    });

    const balance_of_foreigner = await trainerContract.balanceOf(foreigner, 0);
    assert.equal(balance_of_foreigner, amount_minted);
  });

  it("Mint Trainer as foreigner again", async () => {
    try {
      await trainerContract.mintTrainer(foreigner, amount_minted, {
        from: foreigner,
      });
      assert(false);
      return;
    } catch {
      assert(true);
      return;
    }
  });

  it("Try to mint multiple as another foreigner", async () => {
    try {
      await trainerContract.mintTrainer(foreigner_second, amount_minted_2, {
        from: foreigner_second,
      });
      assert(false);
      return;
    } catch {
      assert(true);
      return;
    }
  });

  it("Try to withdraw as owner", async () => {
    await trainerContract.sendTransaction({
      from: foreigner,
      value: Web3.utils.toWei("0.1", "ether"),
    });

    await trainerContract.withdraw(
      contractOwner,
      Web3.utils.toWei("0.1", "ether"),
      {
        from: contractOwner,
      }
    );
  });
});
