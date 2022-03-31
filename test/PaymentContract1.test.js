const readYaml = require("./readYaml.js");
const yaml_data = readYaml("./test/testCases.yml");
const Web3 = require("web3");
const payment_contract_name = yaml_data["PaymentContract"]["contractName"];
const PaymentContract = artifacts.require(payment_contract_name);

const withDrawer1 = yaml_data["PaymentContract"]["testCase1"]["withDrawer1"];
const percantage1 = yaml_data["PaymentContract"]["testCase1"]["percantage1"];

const withDrawer2 = yaml_data["PaymentContract"]["testCase1"]["withDrawer2"];
const percantage2 = yaml_data["PaymentContract"]["testCase1"]["percantage2"];

const withDrawer3 = yaml_data["PaymentContract"]["testCase1"]["withDrawer3"];
const percantage3 = yaml_data["PaymentContract"]["testCase1"]["percantage3"];

const phaseType1 = yaml_data["PaymentContract"]["testCase1"]["phaseType"];

contract("Payment", () => {
  let paymentContract = null;
  before(async () => {
    paymentContract = await PaymentContract.deployed();
    contractOwner = await paymentContract.owner.call();
  });

  it("Handle add first withdrawer", async () => {
    await paymentContract.addWithdrawer(phaseType1, withDrawer1, percantage1);
  });
});
