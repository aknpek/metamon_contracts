const Contract = artifacts.require('Item');

module.exports = function(deployer){
    deployer.deploy(Contract);
}