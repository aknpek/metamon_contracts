const readYaml = require("./readYaml.js");
const yaml_data = readYaml("./test/testCases.yml");
const Web3 = require("web3");

const payment_contract_name = yaml_data["PaymentContract"]["contractName"];
const PaymentContract = artifacts.require(payment_contract_name);

const withDrawer1 = yaml_data["PaymentContract"]["testCase2"]["withDrawer1"];
const percantage1 = yaml_data["PaymentContract"]["testCase2"]["percantage1"];

const withDrawer2 = yaml_data["PaymentContract"]["testCase2"]["withDrawer2"];
const percantage2 = yaml_data["PaymentContract"]["testCase2"]["percantage2"];

const withDrawer3 = yaml_data["PaymentContract"]["testCase2"]["withDrawer3"];
const percantage3 = yaml_data["PaymentContract"]["testCase2"]["percantage3"];

const phaseType1 = yaml_data["ItemContract"]["contractAddress"];

const moneySender = yaml_data["PaymentContract"]["testCase2"]["moneySender"];

contract("Payment", () => {
  let paymentContract = null;
  before(async () => {
    paymentContract = await PaymentContract.deployed();
    owner = await paymentContract.owner.call();
  });

  it("Add with-drawers", async () => {
    await paymentContract.addWithdrawer(phaseType1, withDrawer1, percantage1);
    await paymentContract.addWithdrawer(phaseType1, withDrawer2, percantage2);
    await paymentContract.addWithdrawer(phaseType1, withDrawer3, percantage3);

    const info_withdrawer = await paymentContract.phaseTypes.call(
      phaseType1,
      withDrawer1
    );
    console.log(
      `This is the percantage ${info_withdrawer.percantage.toNumber()}`
    );
  });

  it("Receive Amount Distribute", async () => {
    await paymentContract.receiveAmountDistribute(phaseType1, {
      from: moneySender,
      value: Web3.utils.toWei(".1", "ether"),
    });
  });

  it("Check Is-Exist With-drawer1", async () => {
    const info_about_withdrawer = await paymentContract.phaseTypes.call(
      phaseType1,
      withDrawer1
    );

    assert.equal(info_about_withdrawer.isExist, true);
  });

  it("Check Sending money to Distribute", async () => {
    await paymentContract.receiveAmountDistribute(phaseType1, {
      from: moneySender,
      value: Web3.utils.toWei(".1", "ether"),
    });

    const withdrawer_info_1 = await paymentContract.phaseTypes.call(
      phaseType1,
      withDrawer1
    );

    const withdrawer_info_2 = await paymentContract.phaseTypes.call(
      phaseType1,
      withDrawer2
    );

    const withdrawer_info_3 = await paymentContract.phaseTypes.call(
      phaseType1,
      withDrawer3
    );

    console.log(
      Web3.utils.fromWei(`${BigInt(withdrawer_info_1.payableAmount)}`, "ether"),
      " how much eth here for Drawer1"
    );
    console.log(
      Web3.utils.fromWei(`${BigInt(withdrawer_info_2.payableAmount)}`, "ether"),
      " how much eth here for Drawer2"
    );
    console.log(
      Web3.utils.fromWei(`${BigInt(withdrawer_info_3.payableAmount)}`, "ether"),
      " how much eth here for Drawer3"
    );
  });

  it("Check Locked amount per phase", async () => {
    const locked_amount = await paymentContract.checkAmounts(phaseType1);

    assert.equal(BigInt(locked_amount), Web3.utils.toWei(".2", "ether"));
  });

  it("Check withdraw as withdrawer2 from phase1", async () => {
    try {
      await paymentContract.Withdraw(
        phaseType1,
        withDrawer1,
        Web3.utils.toWei(".04", "ether"),
        {
          from: withDrawer1,
        }
      );

      assert(true);
      return;
    } catch {
      assert(false);
      return;
    }
  });

  it("Check over withdraw as withdrawer2 from phase1", async () => {
    try {
      await paymentContract.Withdraw(
        phaseType1,
        withDrawer1,
        Web3.utils.toWei("0.04", "ether"),
        {
          from: withdraw1,
        }
      );
      assert(false);
      return;
    } catch {
      assert(true);
      return;
    }
  });

  it("Check as owner withdraw everything", async () => {
    try {
      await paymentContract.ownerWithdraw(
        owner,
        Web3.utils.toWei("0.1", "ether"),
        {
          from: owner,
        }
      );
      assert(true);
      return;
    } catch {
      assert(false);
      return;
    }
  });
});
