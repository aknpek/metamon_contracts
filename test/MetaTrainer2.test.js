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

  it("Mint One Trainer as Owner", async () => {
    const owner_trainer = await trainerContract.mintTrainer(
      contractOwner,
      amount_minted,
      {
        from: contractOwner,
      }
    );
  });

  it("Mint Trainer as foreigner", async () => {
    const owner_trainer_2 = await trainerContract.mintTrainer(
      foreigner,
      amount_minted,
      {
        from: foreigner,
      }
    );
  });

  it("Try to transfer token from Foreigner", async () => {
    try {
      const transfer_from = await trainerContract.safeTransferFrom(
        foreigner,
        contractOwner,
        1,
        1,
        "x0a"
      );
      assert(false);
    } catch {
      assert(true);
      return;
    }
  });
});
