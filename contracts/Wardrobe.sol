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
        bytes32 merkleRoot;
        string uri;
        bool valid;
    }

    address payable public paymentContractAddress;

    string public name;
    string public symbol;

    // token type to itemTypeInfo map
    mapping(uint256 => ItemTypeInfo) itemTypes;

    uint256 numberOfItemTypes;
    ///////////////////////////////////////////////////////////////////////////
    // Events
    ///////////////////////////////////////////////////////////////////////////
    event ReceivedEth(address _sender, uint256 _value);
    event ItemMinted(address _receiver, uint256 _tokenId);

    ///////////////////////////////////////////////////////////////////////////
    // Cons
    ///////////////////////////////////////////////////////////////////////////
    constructor(address metamonAddress) payable ERC1155("https://gateway.pinata.cloud/ipfs/INSERT_IPFS_HASH_HERE/{id}.json") {
        name = "Metamon Wardrobe Collection";
        symbol = "Minimetamon-WC";
        metamonContract = IMetamon(metamonAddress);
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

    modifier requiredWhitelist(uint256 _itemType, bytes32[] calldata _merkleProof){
        if(itemTypes[_itemType].merkleRoot.length > 0){
            require(MerkleProof.verify(_merkleProof, itemTypes[_itemType].merkleRoot, keccak256(abi.encodePacked(msg.sender))), "Invalid proof - Caller not whitelisted");
        }
        _;
    }

    modifier requiredWhitelists(uint256[] memory _itemTypes, bytes32[][] calldata _merkleProofs){
        for(uint i = 0; i < _itemTypes.length; i++){
            if(itemTypes[_itemTypes[i]].merkleRoot.length > 0){
                require(MerkleProof.verify(_merkleProofs[i], itemTypes[i].merkleRoot, keccak256(abi.encodePacked(msg.sender))), "Invalid proof - caller not whitelisted");
            }
        }
        _;
    }

    ///////////////////////////////////////////////////////////////////////////
    // Pre-Function Conditions
    ///////////////////////////////////////////////////////////////////////////
    function addWardrobeItem(uint256 _itemType,  uint256 _itemPrice, uint256 _maxMintable, uint256[] memory _requiredMetamon, bytes32 _merkleRoot, string memory _uri) external onlyOwner{
        //Do we want the types to just increment linearly, or do we want to mark out certain parts?
        //For examples hats are item type 0 - 100, hair is 101-200 etc? Might be easier to handle?

        //Maybe we don't care about the token types being in order - easier to handle.

        ItemTypeInfo memory newItemTypeInfo = ItemTypeInfo(_itemPrice, _maxMintable, _requiredMetamon, _merkleRoot, _uri, true);
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

    function setMerkleRoot(bytes32 _merkleRoot, uint256 _itemType) external onlyOwner itemTypeCheck(_itemType){
        itemTypes[_itemType].merkleRoot = _merkleRoot;
    }

    function getMerkleRoot(uint256 _itemType) external view onlyOwner returns (bytes32)  {
        return itemTypes[_itemType].merkleRoot;
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

    // Do we even want to mint tokens via a payable?
    // If msg.sender == owner then we can aidrop to a recipient address (no mint price)
    function mintSale(
        address _recipient,
        uint256 _itemType,
        uint256 _quantity,
        bytes32[] calldata _merkleProof
    ) external payable itemTypeCheck(_itemType) requiredMetamonCheck(_itemType) requiredWhitelist(_itemType, _merkleProof) nonReentrant {
        _mint(_recipient, _itemType, _quantity, "");
    }

    function mintMultipleSale(
        address _recipient,
        uint256[] memory _itemTypes,
        uint256[] memory _quantity,
        bytes32[][] calldata _merkelProofs
    ) external payable itemTypesCheck(_itemTypes) requiredMetamonChecks(_itemTypes) requiredWhitelists(_itemTypes, _merkelProofs) nonReentrant {
        _mintBatch(_recipient, _itemTypes, _quantity, "");
    }

    // How should we decide who can claim the item?
    // Merkletree? Signatures? Based on another item that they hold?
    //Speak to metamon contract... need prerequisite per item type (array of token ids for metamons)
    function claimItem(
        address _recipient,
        uint256 _itemType,
        uint256 _quantity,
        bytes32[] calldata _merkleProof
    ) external itemTypeCheck(_itemType) requiredMetamonCheck(_itemType) requiredWhitelist(_itemType, _merkleProof) nonReentrant {
        _mint(_recipient, _itemType, _quantity, "");
    }

    function claimMultipleItems(
        address _recipient,
        uint256[] memory _itemTypes,
        uint256[] memory _quantity,
        bytes32[][] calldata _merkleProofs
    ) external itemTypesCheck(_itemTypes) requiredMetamonChecks(_itemTypes) requiredWhitelists(_itemTypes, _merkleProofs) nonReentrant {
        _mintBatch(_recipient, _itemTypes, _quantity, "");
    }

    ///////////////////////////////////////////////////////////////////////////
    // Backend URIs
    ///////////////////////////////////////////////////////////////////////////
    function uri(uint256 tokenId) override public view returns (string memory){
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
