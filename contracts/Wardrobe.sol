// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// address => ID => Integer
// address => tokenId => balance
contract Wardrobe is ERC1155, Ownable, ReentrancyGuard {
    using Strings for uint256;

    address payable public paymentContractAddress;

    string public name;
    string public symbol;

    uint256[] public itemTypes;
    //Map from item type to price
    mapping(uint256 => uint256) itemPrices;

    mapping(uint256 => string) private _uris;

    ///////////////////////////////////////////////////////////////////////////
    // Events
    ///////////////////////////////////////////////////////////////////////////
    event ReceivedEth(address _sender, uint256 _value);
    event ItemMinted(address _reciever, uint256 _tokenId);

    ///////////////////////////////////////////////////////////////////////////
    // Cons
    ///////////////////////////////////////////////////////////////////////////
    constructor() payable ERC1155("https://gateway.pinata.cloud/ipfs/INSERT_IPFS_HASH_HERE/{id}.json") {
        name = "Metamon Wardrobe Collection";
        symbol = "Minimetamon-WC";
    }

    fallback() external payable {}

    receive() external payable {
        emit ReceivedEth(msg.sender, msg.value);
    }

    ///////////////////////////////////////////////////////////////////////////
    // Pre-Function Conditions
    ///////////////////////////////////////////////////////////////////////////
    modifier itemTypeCheck(uint256 _itemType) {
        require(1 <= _itemType && _itemType <= itemTypes.length, "Item Type out of scope!");
        _;
    }

    modifier itemTypesCheck(uint256[] memory _itemTypes){
        for(uint i = 0; i < itemTypes.length; i++){
            require(1 <= _itemTypes[i] && _itemTypes[i] <= itemTypes.length, "Item Type is out of scope!");
        }
        _;
    }

    ///////////////////////////////////////////////////////////////////////////
    // Pre-Function Conditions
    ///////////////////////////////////////////////////////////////////////////
    function addWardrobeItem(uint256 _itemType, uint256 _itemPrice) external onlyOwner{
        //Do we want control of where the itemType appears in the array?
        //Do we want the types to just increment linearly, or do we want to mark out certain parts?
        //For examples hats are item type 0 - 100, hair is 101-200 etc? Might be easier to handle?

        for(uint256 i = 0; i < itemTypes.length; i++ ){
            if(_itemType == itemTypes[i]){
                revert("Item type already exists");
            }
        }

        //We have checked if it exists, so let's make this entry
        itemTypes.push(_itemType);
        itemPrices[_itemType] = _itemPrice;
    }

    ///////////////////////////////////////////////////////////////////////////
    // Get/Set State Changes
    ///////////////////////////////////////////////////////////////////////////
    function changeItemPrice(uint256 _new_price, uint256 _itemType)
        external
        onlyOwner
        itemTypeCheck(_itemType)
    {
        itemPrices[_itemType] = _new_price;
    }

    function getItemPrice(uint256 _itemType)
        public
        view
        itemTypeCheck(_itemType)
        returns (uint256)
    {
        return itemPrices[_itemType];
    }

    function totalItemTypes() public view returns (uint256) {
        return itemTypes.length;
    }

    function setPayableAddress(address payable _paymentContractAddress)
        external
        onlyOwner
    {
        paymentContractAddress = _paymentContractAddress;
    }

    ///////////////////////////////////////////////////////////////////////////
    // Mint Tokens
    ///////////////////////////////////////////////////////////////////////////

    // Do we even want to mint tokens via a payable?

    function mintSale(
        address _recipient,
        uint256 _itemType,
        uint256 _quantity
    ) external payable itemTypeCheck(_itemType) nonReentrant {
        _mint(_recipient, _itemType, _quantity, "");
    }

    function mintMultipleSale(
        address _recipient,
        uint256[] memory _itemTypes,
        uint256[] memory _quantity
    ) external payable itemTypesCheck(_itemTypes) nonReentrant {
        _mintBatch(_recipient, _itemTypes, _quantity, "");
    }

    // How should we decide who can claim the item?
    // Merkletree? Signatures? Based on another item that they hold?
    function claimItem(
        address _recipient,
        uint256 _itemType,
        uint256 _quantity
    ) external itemTypeCheck(_itemType) nonReentrant {
        _mint(_recipient, _itemType, _quantity, "");
    }

    function claimMultipleItems(
        address _recipient,
        uint256[] memory _itemTypes,
        uint256[] memory _quantity
    ) external itemTypesCheck(_itemTypes) nonReentrant {
        _mintBatch(_recipient, _itemTypes, _quantity, "");
    }

    function airdropItem(
        address _recipient,
        uint256 _itemType,
        uint256 _quantity
    ) external itemTypeCheck(_itemType) nonReentrant {
        _mint(_recipient, _itemType, _quantity, "");
    }

    function airdropMultipleItems(
        address _recipient,
        uint256[] memory _itemTypes,
        uint256[] memory _quantity
    ) external payable itemTypesCheck(_itemTypes) nonReentrant {
        _mintBatch(_recipient, _itemTypes, _quantity, "");
    }

    ///////////////////////////////////////////////////////////////////////////
    // Backend URIs
    ///////////////////////////////////////////////////////////////////////////
    function uri(uint256 tokenId) override public view returns (string memory){
        return(_uris[tokenId]);
    }
    function setTokenUri(uint256 tokenId, string memory newUri) external onlyOwner 
    {
        _uris[tokenId] = newUri;
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
