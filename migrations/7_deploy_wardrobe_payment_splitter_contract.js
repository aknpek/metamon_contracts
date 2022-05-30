const Contract = artifacts.require("WardrobePaymentSplitter");

module.exports = function (deployer) {
  deployer.deploy(
    Contract,
    ["0x90F8bf6A479f320ead074411a4B0e7944Ea8c9C1"],
    [100]
  );
};
