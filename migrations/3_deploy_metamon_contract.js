const Contract = artifacts.require('Metamon');

module.exports = function(deployer){
    deployer.deploy(Contract);
}