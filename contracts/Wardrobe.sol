// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

interface IMetamon {
    function metamonOwnership(address owner, uint256 requiredMetamon)
        external
        returns (bool);
}

struct ItemTypeInfo {
    uint256 itemPrice;
    uint256 maxMintable;
    uint256[] requiredMetamon;
    string uri;
    bool valid;
}

contract Wardrobe is ERC1155, Ownable, ReentrancyGuard {
    using Strings for uint256;

    IMetamon public metamonContract;

    address payable public breedingContractAddress;
    address payable public paymentContractAddress;

    bytes32 public merkleRoot;

    string public name;
    string public symbol;

    mapping(uint256 => ItemTypeInfo) itemTypes;

    uint256 numberOfItemTypes;

    ///////////////////////////////////////////////////////////////////////////
    // Events
    ///////////////////////////////////////////////////////////////////////////
    event ReceivedEth(address _sender, uint256 _value);
    event ItemMinted(address _receiver, uint256 _tokenId);

    constructor()
        payable
        ERC1155(
            "https://gateway.pinata.cloud/ipfs/INSERT_IPFS_HASH_HERE/{id}.json"
        )
    {
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
        require(itemTypes[_itemType].valid, "Item Type out of scope!");
        _;
    }

    modifier itemTypesCheck(uint256[] memory _itemTypes) {
        for (uint i = 0; i < _itemTypes.length; i++) {
            require(itemTypes[i].valid, "Item Type is out of scope!");
        }
        _;
    }

    modifier requiredMetamonCheck(uint256 _itemType) {
        uint256[] memory requiredMetamon = itemTypes[_itemType].requiredMetamon;
        for (uint256 i; i < requiredMetamon.length; i++) {
            if (
                !metamonContract.metamonOwnership(
                    msg.sender,
                    requiredMetamon[i]
                )
            ) {
                revert("Required metamon not owned by sender");
            }
        }
        _;
    }

    modifier requiredMetamonChecks(uint256[] memory _itemTypes) {
        for (uint i = 0; i < _itemTypes.length; i++) {
            uint256[] memory _requiredMetamon = itemTypes[_itemTypes[i]]
                .requiredMetamon;
            for (uint256 j; j < _requiredMetamon.length; i++) {
                if (
                    !metamonContract.metamonOwnership(
                        msg.sender,
                        _requiredMetamon[j]
                    )
                ) {
                    revert("Required metamon not owned by sender");
                }
            }
        }
        _;
    }

    ///////////////////////////////////////////////////////////////////////////
    // Add/Del State Changes
    ///////////////////////////////////////////////////////////////////////////
    function addWardrobeItem(
        uint256 _itemType,
        uint256 _itemPrice,
        uint256 _maxMintable,
        uint256[] memory _requiredMetamon,
        string memory _uri
    ) external onlyOwner {
        itemTypes[_itemType] = ItemTypeInfo(
            _itemPrice,
            _maxMintable,
            _requiredMetamon,
            _uri,
            true
        );
        numberOfItemTypes++;
    }

    function setWardrobeItemValid(uint256 _itemType, bool _valid)
        external
        onlyOwner
    {
        itemTypes[_itemType].valid = _valid;
    }

    ///////////////////////////////////////////////////////////////////////////
    // Get/Set/Add State Changes
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

    function setRequiredMetamon(
        uint256[] memory _requiredMetamon,
        uint256 _itemType
    ) external onlyOwner itemTypeCheck(_itemType) {
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

    function getMerkleRoot() external view onlyOwner returns (bytes32) {
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

    function setMetamonContractAddress(address _metamonContractAddress)
        external
        onlyOwner
    {
        metamonContract = IMetamon(_metamonContractAddress);
    }

    function setContractAddresses(
        uint256 _type,
        address payable _contractAddress
    ) external onlyOwner {
        if (_type == 1) {
            paymentContractAddress = _contractAddress;
        } else if (_type == 2) {
            breedingContractAddress = _contractAddress;
        }
    }

    ///////////////////////////////////////////////////////////////////////////
    // Mint Tokens
    ///////////////////////////////////////////////////////////////////////////
    function mintSale(uint256 _itemType, uint256 _quantity)
        external
        payable
        itemTypeCheck(_itemType)
        nonReentrant
    {
        require(
            balanceOf(msg.sender, _itemType) + _quantity <=
                itemTypes[_itemType].maxMintable,
            "Max Mintable"
        );
        require(itemTypes[_itemType].requiredMetamon.length == 0, "Claim only");
        require(
            msg.value == itemTypes[_itemType].itemPrice * _quantity,
            "Not enough ETH"
        );

        _mint(msg.sender, _itemType, _quantity, "");
    }

    function mintMultipleSale(
        uint256[] memory _itemTypes,
        uint256[] memory _quantity
    ) external payable itemTypesCheck(_itemTypes) nonReentrant {
        uint256 totalMintCost;
        for (uint i = 0; i < _itemTypes.length; i++) {
            require(
                balanceOf(msg.sender, i) + _quantity[i] <=
                    itemTypes[i].maxMintable,
                "Max Mintable!"
            );
            require(itemTypes[i].requiredMetamon.length == 0, "Claim only!");
            totalMintCost += itemTypes[i].itemPrice * _quantity[i];
        }

        require(msg.value == totalMintCost, "Not enough ETH!");
        _mintBatch(msg.sender, _itemTypes, _quantity, "");
    }

    function mintSpecialItem(
        uint256 _itemType,
        uint256 _quantity,
        bytes32[] calldata _merkleProof
    ) external payable itemTypeCheck(_itemType) nonReentrant {
        require(
            MerkleProof.verify(
                _merkleProof,
                merkleRoot,
                keccak256(abi.encodePacked(msg.sender))
            ),
            "Caller not whitelisted"
        );
        require(
            balanceOf(msg.sender, _itemType) + _quantity <=
                itemTypes[_itemType].maxMintable,
            "Max Mintable"
        );
        require(itemTypes[_itemType].requiredMetamon.length == 0, "Claim only");
        require(
            msg.value == itemTypes[_itemType].itemPrice * _quantity,
            "Not enough ETH"
        );
        _mint(msg.sender, _itemType, _quantity, "");
    }

    function claimCollectionReward(uint256 _itemType, uint256 _quantity)
        external
        itemTypeCheck(_itemType)
        requiredMetamonCheck(_itemType)
        nonReentrant
    {
        require(
            balanceOf(msg.sender, _itemType) + _quantity <=
                itemTypes[_itemType].maxMintable,
            "Max Mintable"
        );
        require(itemTypes[_itemType].itemPrice == 0, "must be a free mint");

        _mint(msg.sender, _itemType, _quantity, "");
    }

    function happyEnding(
        address _user,
        uint256 _itemType,
        uint256 _quantity
    ) external itemTypeCheck(_itemType) nonReentrant {
        require(msg.sender == address(metamonContract), "Caller not valid");
        require(
            balanceOf(msg.sender, _itemType) + _quantity <=
                itemTypes[_itemType].maxMintable,
            "Max Mintable"
        );
        _mint(_user, _itemType, _quantity, "");
    }

    ///////////////////////////////////////////////////////////////////////////
    // Backend URIs
    ///////////////////////////////////////////////////////////////////////////
    function uri(uint256 tokenId) public view override returns (string memory) {
        return (itemTypes[tokenId].uri);
    }

    function setTokenUri(uint256 tokenId, string memory newUri)
        external
        onlyOwner
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