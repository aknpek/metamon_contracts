// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

struct withdrawers {
    uint256 payableAmount;
    uint256 percantage;
    bool isExist;
}

struct concensusFlag {
    bool isConsent;
    bool isAuthority;
}

contract Payment {
    bool public concept_withdraw;
    bool public trainers_withdraw;
    bool public itemPresale_withdraw;

    address public owner;
    address[] public concensusGroupMap;

    /*
    allPhaseTypes = [1, 2, 3, 4, 5];

        1: Item Presale
        2: Metamon Mint
        3: Item Metamon Secondary Sales
        4: Trainers
        5: Concept Art
    */

    mapping(address => concensusFlag) public concensusGroup;
    mapping(address => mapping(address => withdrawers)) public phaseTypes;
    mapping(address => address[]) public phaseOwners;
    mapping(address => uint256) private lockedAmountPerPhase;

    event ReceivedEth(address sender, uint256 value);
    event ConceptWithdrawn(address receiver, uint256 value);
    event TrainersWithdrawn(address receiver, uint256 value);
    event ItemPresaleWithdrawn(address receiver, uint256 value);

    constructor(address[] memory concensus) payable {
        owner = msg.sender;
        for (uint256 i = 0; i < concensus.length; i++) {
            concensusGroup[concensus[i]] = concensusFlag(false, true);
            concensusGroupMap.push(concensus[i]);
        }
    }

    ///////////////////////////////////////////////////////////////////////////
    // Contract ETH Deals
    ///////////////////////////////////////////////////////////////////////////
    fallback() external payable {}

    receive() external payable {
        emit ReceivedEth(msg.sender, msg.value);
    }

    function concensusRate() internal view returns (bool) {
        uint256 vote_accept = 0;
        uint256 vote_reject = 0;

        for (uint i = 0; i < concensusGroupMap.length; i++) {
            if (concensusGroup[concensusGroupMap[i]].isAuthority) {
                if (concensusGroup[concensusGroupMap[i]].isConsent) {
                    vote_accept++;
                } else {
                    vote_reject++;
                }
            }
        }
        if (vote_accept > vote_reject) {
            return true;
        } else {
            return false;
        }
    }

    function receiveAmountDistribute(address phaseType) public payable {
        // TODO: check if phase exist
        lockedAmountPerPhase[phaseType] += msg.value;

        address[] memory _phaseOwners = phaseOwners[phaseType];
        for (uint256 i = 0; i < _phaseOwners.length; i++) {
            uint256 _percantage = phaseTypes[phaseType][_phaseOwners[i]]
                .percantage;
            phaseTypes[phaseType][_phaseOwners[i]].payableAmount +=
                msg.value *
                (_percantage / 100);
        }
    }

    ///////////////////////////////////////////////////////////////////////////
    // Modifiers
    ///////////////////////////////////////////////////////////////////////////
    modifier onlyConsensus() {
        require(concensusRate(), "Not concensus!");
        _;
    }

    modifier onlyOwner(address sender) {
        require(sender == owner, "Not a owner call!");
        _;
    }

    modifier withdrawerCheck(
        address phaseType,
        address withdrawer,
        bool exists
    ) {
        require(
            phaseTypes[phaseType][withdrawer].isExist == exists,
            "Withdrawer!"
        );
        _;
    }

    function addWithdrawer(
        address phaseType,
        address withdrawer,
        uint256 percantage
    ) public onlyOwner(msg.sender) {
        /*Adding withdrawer addresses into specific phase types with percantage

        Args: 
            phaseType (address): specifies phase type
            withdrawer (address): specifies address of withdrawer
            percantage (uint256): specifies the percantage quantity n/100

        Returns:
            bool: if success true else false
        */
        phaseOwners[phaseType].push(withdrawer);

        phaseTypes[phaseType][withdrawer].isExist = true;
        phaseTypes[phaseType][withdrawer].percantage = percantage;
        phaseTypes[phaseType][withdrawer].payableAmount = 0;
    }

    function removeWithdrawer(address phaseType, address withdrawer)
        public
        onlyOwner(msg.sender)
        withdrawerCheck(phaseType, withdrawer, false)
    {
        delete phaseOwners[phaseType];
        delete phaseTypes[phaseType][withdrawer];
    }

    function withDraw(
        address phaseType,
        address payable withdrawer,
        uint256 amount
    ) public {
        require(msg.sender == withdrawer, "Not withdrawer!"); // validate user itself

        require(
            phaseTypes[phaseType][withdrawer].isExist == true,
            "Not exist withdrawer!"
        ); // validate user

        require(
            phaseTypes[phaseType][withdrawer].payableAmount <= amount,
            "Not enough amount!"
        ); // validate amount

        withdrawer.transfer(amount);
    }

    function ownerWithdraw(address payable receiver, uint256 amount)
        public
        onlyOwner(msg.sender)
    {
        require(amount <= address(this).balance, "Too much asked!");
        receiver.transfer(amount);
    }
}
