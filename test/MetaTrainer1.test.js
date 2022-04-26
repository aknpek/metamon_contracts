const readYaml = require("./readYaml.js");
const yaml_data = readYaml("./test/testCases.yml");
const Web3 = require("web3");

const meta_trainer_contract_name = yaml_data["MetaTrainer"]["testCase1"];
const MetaTrainer = artifacts.require(meta_trainer_contract_name);

contract("MetaTrainer", () => {
  let trainerContract = null;

  before(async () => {
    trainerContract = await MetaTrainer.deployed();
    contractOwner = await trainerContract.owner.call();
  });

  it("", async () => {});
});
