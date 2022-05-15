const readYaml = require("../test/readYaml.js");

const yaml_data = readYaml("../test/testCases.yml");
const contractConcensus = yaml_data["PaymentContract"]["contractConcensus"];

const Contract = artifacts.require("Payment");

module.exports = function (deployer) {
  deployer.deploy(Contract, (concensus = contractConcensus));
};
