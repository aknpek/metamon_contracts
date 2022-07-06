// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract Item is ERC1155Supply, ERC1155Burnable, Ownable, ReentrancyGuard {
    using Strings for string;

    //Set contract name and symbol
    string public name;
    string public symbol;

    address payable public paymentContractAddress;
    uint8 public currentPhase;
    
    struct ItemTypeInfo {
        uint256 itemPrice;
        uint256 maxMintable;
        uint256 itemSupply;
        bool itemBurnable;
        string uri;
        bool valid;
    }
   
    //Need to add wallet limits per phase and max ownable

    mapping(uint256 => ItemTypeInfo) public itemTypes;
    mapping(address => mapping(uint256 => uint256)) public itemsMinted; // Represents owner's different type of tokens' ids

    uint256 numberOfItemTypes;

    ///////////////////////////////////////////////////////////////////////////
    // Events
    ///////////////////////////////////////////////////////////////////////////
    
    event ReceivedEth(address _sender, uint256 _value);
    event ItemsMinted(address _receiver, uint256[] _tokenIds, uint256[] _quantity);
    event ItemsBurned(address _burner, uint256[] _tokenIds, uint256[] _quantity);

    ///////////////////////////////////////////////////////////////////////////
    // Cons
    ///////////////////////////////////////////////////////////////////////////
    
    constructor() 
        payable 
        ERC1155("https://gateway.pinata.cloud/ipfs/INSERT_IPFS_HASH_HERE/{id}.json") 
        {
             name = "MiniMetamon Item";
             symbol = "MiniMetamon-Item";
        }

    fallback() external payable {}

    receive() external payable {
        emit ReceivedEth(msg.sender, msg.value);
    }

    ///////////////////////////////////////////////////////////////////////////
    // Pre-Function Conditions
    ///////////////////////////////////////////////////////////////////////////
    
    modifier itemTypeCheck(uint256 _itemType) {
        require(itemTypes[_itemType].valid, "Item Type out of scope!");
        _;
    }

    modifier itemTypesCheck(uint256[] memory _itemTypes) {
        for (uint i = 0; i < _itemTypes.length; i++) {
            require(
                itemTypes[_itemTypes[i]].valid,
                "Item Type is out of scope!"
            );
        }
        _;
    }

    modifier maxMintableCheck(uint256 _itemType, uint256 _quantity) {
        require(
            itemsMinted[msg.sender][_itemType] + _quantity <=
                itemTypes[_itemType].maxMintable,
            "User is trying to mint more than allocated."
        );
        require(
            totalSupply(_itemType) + _quantity <=
                itemTypes[_itemType].itemSupply,
            "User is trying to mint more than total supply."
        );
        _;
    }

    ///////////////////////////////////////////////////////////////////////////
    // Get/Set State Changes
    ///////////////////////////////////////////////////////////////////////////
    
    function getItemPrice(uint256 _itemType)
        public
        view
        itemTypeCheck(_itemType)
        returns (uint256)
    {
        return itemTypes[_itemType].itemPrice;
    }

    function setMaxMintable(uint256 _maxMintable, uint256 _itemType)
        external
        onlyOwner
        itemTypeCheck(_itemType)
    {
        itemTypes[_itemType].maxMintable = _maxMintable;
    }

    function getMaxMintable(uint256 _itemType)
        public
        view
        itemTypeCheck(_itemType)
        returns (uint256)
    {
        return itemTypes[_itemType].maxMintable;
    }

    function setItemSupply(uint256 _itemSupply, uint256 _itemType)
        external
        onlyOwner
        itemTypeCheck(_itemType)
    {
        itemTypes[_itemType].itemSupply = _itemSupply;
    }

    function getItemSupply(uint256 _itemType)
        public
        view
        itemTypeCheck(_itemType)
        returns (uint256)
    {
        return itemTypes[_itemType].itemSupply;
    }

    function setItemBurnable(bool _burnable, uint256 _itemType)
        external
        onlyOwner
        itemTypeCheck(_itemType)
    {
        itemTypes[_itemType].itemBurnable = _burnable;
    }

    function getItemBurnable(uint256 _itemType)
        public
        view
        itemTypeCheck(_itemType)
        returns (bool)
    {
        return itemTypes[_itemType].itemBurnable;
    }

    function totalItemTypes() public view returns (uint256) {
        return numberOfItemTypes;
    }

    function setPayableAddress(address payable _paymentContractAddress)
        external
        onlyOwner
    {
        paymentContractAddress = _paymentContractAddress;
    }

    ///////////////////////////////////////////////////////////////////////////
    // Burn Tokens
    ///////////////////////////////////////////////////////////////////////////

    function burnItems(uint256[] memory _itemTypes, uint256[] memory _quantities)
        external
        itemTypesCheck(_itemTypes)
    {
        //We need to probably make this so only the metamon contract can actually burn
        //rather than any user
        _burnBatch(msg.sender, _itemTypes, _quantities);
        emit ItemsBurned(msg.sender, _itemTypes, _quantities);
    }

    ///////////////////////////////////////////////////////////////////////////
    // Mint Tokens
    ///////////////////////////////////////////////////////////////////////////
    
    function mintSale(
        uint256[] memory _itemTypes,
        uint256[] memory _quantity
    ) external payable itemTypesCheck(_itemTypes) nonReentrant {
        uint256 totalMintCost;

        for (uint i = 0; i < _itemTypes.length; i++) {
            require(
                itemsMinted[msg.sender][_itemTypes[i]] + _quantity[i] <=
                    itemTypes[_itemTypes[i]].maxMintable,
                "User is trying to mint more than allocated."
            );

            require(
                totalSupply(_itemTypes[i]) + _quantity[i] <=
                    itemTypes[_itemTypes[i]].itemSupply,
                "User is trying to mint more than total supply."
            );

            totalMintCost += itemTypes[_itemTypes[i]].itemPrice * _quantity[i];
        }

        require(msg.value == totalMintCost, "Not enough ETH to mint!");

        for (uint i = 0; i < _itemTypes.length; i++) {
            itemsMinted[msg.sender][_itemTypes[i]] += _quantity[i];
        }

        _mintBatch(msg.sender, _itemTypes, _quantity, "");
        emit ItemsMinted(msg.sender, _itemTypes, _quantity);
    }

    ///////////////////////////////////////////////////////////////////////////
    // Backend URIs
    ///////////////////////////////////////////////////////////////////////////
    
    function uri(uint256 _itemType) public view override returns (string memory) {
        return (itemTypes[_itemType].uri);
    }

    function setTokenUri(uint256 _itemType, string memory newUri)
        external
        onlyOwner
    {
        itemTypes[_itemType].uri = newUri;
    }

    ///////////////////////////////////////////////////////////////////////////
    // Withdraw
    ///////////////////////////////////////////////////////////////////////////
    
    function withdraw() external onlyOwner nonReentrant {
        (bool success, ) = paymentContractAddress.call{
            value: address(this).balance
        }("");
        require(success, "Transfer failed.");
    }
}
