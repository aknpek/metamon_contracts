const readYaml = require("../test/readYaml.js");
const Contract = artifacts.require("MetaTrainer");

module.exports = function (deployer) {
  deployer.deploy(Contract);
};
