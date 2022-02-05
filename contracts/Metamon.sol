// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract CozyHomeNFT is ERC721 {

    address payable public owner;

    string private itemBaseURI;
    string private metamonBaseURI;


    uint256[7] private itemtokenTypes = [1, 2, 3, 4, 5, 6, 7]; // REPR: 7 UNIQUE ITEMS
    uint256[7] private itemtokenSupply = [1000, 2500, 1000, 2000, 3000, 5000, 2000];
    uint256[7] private itemtokenIds = [1, 1, 1, 1, 1, 1, 1];
    uint256[7] private itemtokenFloor = [0.3 ether, 0.3 ether, 0.3 ether, 0.3 ether, 0.3 ether, 0.3 ether, 0.3 ether];


    uint256[6] private metamonDax = [1, 2, 3, 4, 5, 6]; // REPR: METAMONT DEX NUMBERS
    uint256[6] private metamonSupply = [1000, 2000, 1000, 3000, 4000, 1000];
    uint256[6] private metamontIds = [1, 1, 1, 1, 1, 1];
    uint256[7] private metamonFloor = [0.3 ether, 0.3 ether, 0.3 ether, 0.3 ether, 0.3 ether, 0.3 ether, 0.3 ether];


    mapping(uint256 => uint256) private familyMetamon;

    mapping(uint256 => uint256) private itemEvaluation;
    mapping(uint256 => uint256) private burnEvaluation;

    mapping(address => uint256) private _collectedItems; // MINTING FIRST CHECK IF ADDRESS COLLEDTED ANY ITEMS BEFORE
    mapping(address => uint256) private _collectedDax;  // TOTAL COLLECTED DAX ITEMS IMPORTANT TO IDENTIFY SHINY LOGIC
    
    
    constructor() payable ERC721("Metamon NFT", "NFT") {
        owner = payable(msg.sender);
        // FILLING INFORMATION OF METAMAN AND EVALUATION
        burnEvaluation[1] = 3; burnEvaluation[2] = 3;
        familyMetamon[1] = 2; familyMetamon[2] = 3;
        // ****************
        burnEvaluation[4] = 3; burnEvaluation[5] = 3;
        familyMetamon[4] = 5; familyMetamon[5] = 6;

    }

    modifier onlyOwner(address sender) {
        require(sender == owner, "Not a owner call!");
        _;
    }

    // State Changes
    function changeFloorPrice(uint256 _new_price, uint256 _type, uint8 _index)
    // _type 1 represents "ITEMS" _type 2 represents "Metamon"
    // _index tell which "ITEM" or "Metamon" starts from 1, 2, 3, ... 7
        external
        onlyOwner(msg.sender)
    {
        if (_type == 1) {
            itemtokenFloor[_index] = _new_price;
        } else if (_type == 2) {
            metamonFloor[_index] = _new_price;
        } 
    }

    // Get Information
    function getWalletBalance()
        public
        view
        onlyOwner(msg.sender)
        returns (uint256)
    {
        return address(this).balance;
    }

    // Contract ETH Relationship
    fallback() external payable {}

    receive() external payable {
        emit ReceivedEth(msg.sender, msg.value);
    }

    function transferContractBalance(
        address payable _recipient,
        uint256 _amount
    ) external onlyOwner(msg.sender) returns (bool) {
        require(_amount <= getWalletBalance(), "Not Enough Balance!");
        _recipient.transfer(_amount);
        return true;
    }

    // NFT Minting Related
    function setBaseURI(string memory _baseURILink)
        external
        onlyOwner(msg.sender)
    {
        baseURI = _baseURILink;
    }

    function getBaseURI()
        external
        view
        onlyOwner(msg.sender)
        returns (string memory)
    {
        return baseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "Nonexistent token!");

        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json"))
                : "";
    }


}