const Contract = artifacts.require("Wardrobe");

module.exports = function (deployer) {
  deployer.deploy(Contract);
};
