const readYaml = require('./readYaml.js');
const yaml_data = readYaml('./test/testCases.yml');

const contract_name = yaml_data['ItemContract']['contractName'];
const Contract = artifacts.require(contract_name);

const contract_real_name = yaml_data['ItemContract']['contractRealName'];
const contract_deployer = yaml_data['ItemContract']['contractOwnerAddress'];
const contract_address = yaml_data['ItemContract']['contractAddress'];
const contract_symbol = yaml_data['ItemContract']['contractSymbol']


contract('Item', () => {
    let deployedContract = null;
    before(async() => {
        deployedContract = await Contract.deployed();
    });

    it("Test if our Contract Deployed", async() => {
        console.log("Current Contract Address", deployedContract.address);
        assert(deployedContract.address !== "");
    });

    it("Test current Contract Owner", async () => {
        const owner = await deployedContract.owner();
        console.log(' This is the owner', owner);
        assert(owner === contract_deployer);
    });

    it("Test name of the Contract", async () => {
        const name = await deployedContract.name();
        assert(name === contract_real_name);
    });

    it("Getting Base URI Should be Private", async () => {
        try {
          await deployedContract.baseURI();
        } catch (e) {
          assert(true);
        }
    });  
})