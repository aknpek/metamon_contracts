// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

struct withdrawers {
    uint256 payableAmount;
    uint256 percantage;
    bool isExist;
}

contract Payment is ERC721 {
    bool public concept_withdraw;
    bool public trainers_withdraw;
    bool public itemPresale_withdraw;

    address public owner;

    /*
    allPhaseTypes = [1, 2, 3, 4, 5];

        1: Item Presale
        2: Metamon Mint
        3: Item Metamon Secondary Sales
        4: Trainers
        5: Concept Art
    */

    mapping(address => mapping(address => withdrawers)) private phaseTypes;
    mapping(address => address[]) private phaseOwners;
    mapping(address => uint256) private lockedAmountPerPhase;

    event ReceivedEth(address sender, uint256 value);
    event ConceptWithdrawn(address receiver, uint256 value);
    event TrainersWithdrawn(address receiver, uint256 value);
    event ItemPresaleWithdrawn(address receiver, uint256 value);

    constructor() payable ERC721("NFT Payments", "Payment") {
        owner = msg.sender;
    }

    ///////////////////////////////////////////////////////////////////////////
    // Contract ETH Deals
    ///////////////////////////////////////////////////////////////////////////
    fallback() external payable {}

    receive() external payable {
        emit ReceivedEth(msg.sender, msg.value);
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
    modifier onlyOwner(address sender) {
        require(sender == owner, "Not a owner call!");
        _;
    }

    modifier withdrawerCheck(address phaseType, address withdrawer) {
        require(
            phaseTypes[phaseType][withdrawer].isExist == true,
            "Not exist withdrawer!"
        );
        _;
    }

    function addWithdrawer(
        address phaseType,
        address withdrawer,
        uint256 percantage
    ) public onlyOwner(msg.sender) withdrawerCheck(phaseType, withdrawer) {
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
        withdrawerCheck(phaseType, withdrawer)
    {
        require(
            phaseTypes[phaseType][withdrawer].isExist == true,
            "Not exists withdrawer!"
        );
        delete phaseOwners[phaseType];
        delete phaseTypes[phaseType][withdrawer];
    }

    function Withdraw(
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
