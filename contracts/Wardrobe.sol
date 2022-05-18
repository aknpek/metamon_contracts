// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

   interface IMetamon {
        function metamonOwnership(address owner, uint256 requiredMetamon) external returns(bool);
   }

// address => ID => Integer
// address => tokenTypeId => balance
contract Wardrobe is ERC1155, Ownable, ReentrancyGuard {
    using Strings for uint256;

    IMetamon public metamonContract;
//Add later - wont compile if we have this atm as we don't have the contract.
    //Metamon metamonContract;

    struct ItemTypeInfo{
        uint256 itemPrice;
        uint256 maxMintable;
        uint256[] requiredMetamon;
        string uri;
        bool valid;
    }

    address payable public paymentContractAddress;

    bytes32 public merkleRoot;

    string public name;
    string public symbol;

    // token type to itemTypeInfo map
    mapping(uint256 => ItemTypeInfo) itemTypes;
    
    mapping(address => mapping(uint256 => uint256)) itemsMinted;

    uint256 numberOfItemTypes;
    ///////////////////////////////////////////////////////////////////////////
    // Events
    ///////////////////////////////////////////////////////////////////////////
    event ReceivedEth(address _sender, uint256 _value);
    event ItemMinted(address _receiver, uint256 _tokenId);

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

    function setMetamonContractAddress(address _metamonContractAddress)
        external
        onlyOwner
    {
        metamonContract = IMetamon(_metamonContractAddress);
    }

    ///////////////////////////////////////////////////////////////////////////
    // Pre-Function Conditions
    ///////////////////////////////////////////////////////////////////////////
    modifier itemTypeCheck(uint256 _itemType) {
        require(itemTypes[_itemType].valid, "Item Type out of scope!");
        _;
    }

    modifier itemTypesCheck(uint256[] memory _itemTypes){
        for(uint i = 0; i < _itemTypes.length; i++){
            require(itemTypes[i].valid, "Item Type is out of scope!");
        }
        _;
    }

    modifier requiredMetamonCheck(uint256 _itemType){
        uint256[] memory requiredMetamon = itemTypes[_itemType].requiredMetamon;
        for(uint256 i; i< requiredMetamon.length; i++){
            if(!metamonContract.metamonOwnership(msg.sender, requiredMetamon[i])){
                revert("Required metamon not owned by sender");
            }
        }
        _;
    }

    modifier requiredMetamonChecks(uint256[] memory _itemTypes){
        for(uint i = 0; i < _itemTypes.length; i++){
            uint256[] memory _requiredMetamon = itemTypes[_itemTypes[i]].requiredMetamon;
            for(uint256 j; j < _requiredMetamon.length; i++){
                if(!metamonContract.metamonOwnership(msg.sender, _requiredMetamon[j])){
                    revert("Required metamon not owned by sender");
                }
            }
        }
        _;
    }
    ///////////////////////////////////////////////////////////////////////////
    // Pre-Function Conditions
    ///////////////////////////////////////////////////////////////////////////
    function addWardrobeItem(uint256 _itemType,  uint256 _itemPrice, uint256 _maxMintable, uint256[] memory _requiredMetamon, string memory _uri) external onlyOwner{
        //Do we want the types to just increment linearly, or do we want to mark out certain parts?
        //For examples hats are item type 0 - 100, hair is 101-200 etc? Might be easier to handle?

        //Maybe we don't care about the token types being in order - easier to handle.

        ItemTypeInfo memory newItemTypeInfo = ItemTypeInfo(_itemPrice, _maxMintable, _requiredMetamon, _uri, true);
        itemTypes[_itemType] = newItemTypeInfo;
        numberOfItemTypes++;
    }

    ///////////////////////////////////////////////////////////////////////////
    // Get/Set State Changes
    ///////////////////////////////////////////////////////////////////////////
    function setItemPrice(uint256 _newPrice, uint256 _itemType)
        external
        onlyOwner
        itemTypeCheck(_itemType)
    {
        itemTypes[_itemType].itemPrice = _newPrice;
    }

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

    function setRequiredMetamon(uint256[] memory _requiredMetamon, uint256 _itemType)
        external
        onlyOwner
        itemTypeCheck(_itemType)
    {
        itemTypes[_itemType].requiredMetamon = _requiredMetamon;
    }

    function getRequiredMetamon(uint256 _itemType)
        public
        view
        itemTypeCheck(_itemType)
        returns (uint256[] memory)
    {
        return itemTypes[_itemType].requiredMetamon;
    }

    function setMerkleRoot(bytes32 newMerkleRoot) external onlyOwner {
        merkleRoot = newMerkleRoot;
    }

    function getMerkleRoot() external view onlyOwner returns (bytes32)  {
        return merkleRoot;
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
    // Mint Tokens
    ///////////////////////////////////////////////////////////////////////////

    function mintSale(
        uint256 _itemType,
        uint256 _quantity
    ) external payable itemTypeCheck(_itemType) nonReentrant {
        require(itemsMinted[msg.sender][_itemType] + _quantity <= itemTypes[_itemType].maxMintable, "User is trying to mint more than allocated.");
        require(itemTypes[_itemType].requiredMetamon.length == 0, "User is trying to mint a wardrobe item with metamon requirements - Claim only!");
        require(msg.value == itemTypes[_itemType].itemPrice * _quantity, "Not enough ETH to mint!");

        itemsMinted[msg.sender][_itemType] += _quantity;

        _mint(msg.sender, _itemType, _quantity, "");
    }

    function mintMultipleSale(
        uint256[] memory _itemTypes,
        uint256[] memory _quantity
    ) external payable itemTypesCheck(_itemTypes) nonReentrant {
        uint256 totalMintCost;
        for(uint i = 0; i < _itemTypes.length; i++){
                require(itemsMinted[msg.sender][i] + _quantity[i] <= itemTypes[i].maxMintable, "User is trying to mint more than allocated.");
                require(itemTypes[i].requiredMetamon.length == 0, "User is trying to mint a wardrobe item with metamon requirements - Claim only!");
                totalMintCost += itemTypes[i].itemPrice * _quantity[i];
        }

        // Messy, don't like this but we can't update these in the original for loop as it might fail a require
        for(uint i = 0; i < _itemTypes.length; i++){
            itemsMinted[msg.sender][i] += _quantity[i];
        }

        require(msg.value == totalMintCost, "Not enough ETH to mint!");
        _mintBatch(msg.sender, _itemTypes, _quantity, "");
    }

    function mintSpecialItem(
        uint256 _itemType,
        uint256 _quantity,
        bytes32[] calldata _merkleProof
    ) external payable itemTypeCheck(_itemType) nonReentrant {
        require(MerkleProof.verify(_merkleProof, merkleRoot, keccak256(abi.encodePacked(msg.sender))), "Invalid proof - Caller not whitelisted");
        require(itemsMinted[msg.sender][_itemType] + _quantity <= itemTypes[_itemType].maxMintable, "User is trying to mint more than allocated.");
        require(itemTypes[_itemType].requiredMetamon.length == 0, "User is trying to mint a wardrobe item with metamon requirements - Claim only!");
        require(msg.value == itemTypes[_itemType].itemPrice * _quantity, "Not enough ETH to mint!");
        _mint(msg.sender, _itemType, _quantity, "");
    }

    function claimItem(
        uint256 _itemType,
        uint256 _quantity
    ) external itemTypeCheck(_itemType) requiredMetamonCheck(_itemType) nonReentrant {
        require(itemsMinted[msg.sender][_itemType] + _quantity <= itemTypes[_itemType].maxMintable, "User is claming more items than allocated.");
        require(itemTypes[_itemType].itemPrice == 0, "Item being claimed must be a free mint");

        itemsMinted[msg.sender][_itemType] += _quantity;
        _mint(msg.sender, _itemType, _quantity, "");
    }

    function claimMultipleItems(
        uint256[] memory _itemTypes,
        uint256[] memory _quantity
    ) external itemTypesCheck(_itemTypes) requiredMetamonChecks(_itemTypes) nonReentrant {
        for(uint i = 0; i < _itemTypes.length; i++){
            require(itemsMinted[msg.sender][i] + _quantity[i] <= itemTypes[i].maxMintable, "User is claming more items than allocated.");
            require(itemTypes[i].itemPrice == 0, "Item being claimed must be a free mint");
        }

        // Messy, don't like this but we can't update these in the original for loop as it might fail a require
        for(uint i = 0; i < _itemTypes.length; i++){
            itemsMinted[msg.sender][i] += _quantity[i];
        }

        _mintBatch(msg.sender, _itemTypes, _quantity, "");
    }

    function specialRewardForUser(
        address _user,
        uint256 _quantity,
        uint256 _itemType
    ) external itemTypeCheck(_itemType) nonReentrant {
        require(msg.sender == address(this) || msg.sender == address(metamonContract), "Caller not valid");
        require(itemsMinted[msg.sender][_itemType] + _quantity <= itemTypes[_itemType].maxMintable, "User is claming more items than allocated.");
        itemsMinted[msg.sender][_itemType] += _quantity;
        _mint(_user, _itemType, _quantity, "");
    }

    ///////////////////////////////////////////////////////////////////////////
    // Backend URIs
    ///////////////////////////////////////////////////////////////////////////
    function uri(uint256 tokenId) override public view returns (string memory) {
        return(itemTypes[tokenId].uri);
    }
    function setTokenUri(uint256 tokenId, string memory newUri) external onlyOwner 
    {
        itemTypes[tokenId].uri = newUri;
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
