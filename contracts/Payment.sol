// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

struct withdrawers {
    uint256 mintableAmount;
    uint256 percantage;
    bool isExist;
}

contract Payment {
    bool public concept_withdraw;
    bool public trainers_withdraw;
    bool public itemPresale_withdraw;

    address public owner;

    mapping(address => mapping(address => withdrawers)) private phaseTypes;
    mapping(address => uint256) private lockedAmountPerPhase;

    event ReceivedEth(address sender, uint256 value);
    event ConceptWithdrawn(address receiver, uint256 value);
    event TrainersWithdrawn(address receiver, uint256 value);
    event ItemPresaleWithdrawn(address receiver, uint256 value);

    constructor() payable {
        owner = msg.sender;
    }

    ///////////////////////////////////////////////////////////////////////////
    // Contract ETH Deals
    ///////////////////////////////////////////////////////////////////////////
    fallback() external payable {}

    receive() external payable {
        emit ReceivedEth(msg.sender, msg.value);
    }

    ///////////////////////////////////////////////////////////////////////////
    // Modifiers
    ///////////////////////////////////////////////////////////////////////////
    modifier onlyOwner(address sender) {
        require(sender == owner, "Not a owner call!");
        _;
    }

    function addWithdrawer(
        address phaseType,
        address withdrawer,
        uint256 percantage
    ) public onlyOwner(msg.sender) returns (bool) {
        /*Adding withdrawer addresses into specific phase types with percantage

        Args: 
            phaseType (address): specifies phase type
            withdrawer (address): specifies address of withdrawer
            percantage (uint256): specifies the percantage quantity n/100

        Returns:
            bool: if success true else false
        */
        require(
            phaseTypes[phaseType][withdrawer].isExist == true,
            "Not exist withdrawer!"
        );

        phaseTypes[phaseType][withdrawer].isExist = true;
        phaseTypes[phaseType][withdrawer].percantage = percantage;
        phaseTypes[phaseType][withdrawer].mintableAmount = 0;
    }

    function Withdraw(
        address phaseType,
        address withdrawer,
        uint256 amount
    ) public returns (bool) {
        require(
            phaseTypes[phaseType][withdrawer].isExist == true,
            "Not exist withdrawer!"
        );

        require(
            phaseTypes[phaseType][withdrawer].mintableAmount <= amount,
            "Not enough amount!"
        );
    }
}
