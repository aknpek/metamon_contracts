const readYaml = require('./readYaml.js');
const yaml_data = readYaml('./test/testCases.yml');
const Metamon = artifacts.require(yaml_data('testCase'));

const contract_name = yaml_data['testCase']['contract_name'];
const contract_deployer = yaml_data['testCase']['contractDeployer'];
const contract_address = yaml_data['testCase']['contractAddress'];


contract('Metamon', () => {
    let metamon = null;
    before(async() => {
        metamon = await Metamon.deployed();
    });

    it("Test if our Contract Deployed", async() => {
        console.log("Current Contract Address", metamon.address);
        assert(metamon.address !== "");
    })


})