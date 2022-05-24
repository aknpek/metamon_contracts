// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

//Owner => token id => supply
//address => Id => Int
contract Item is ERC1155Supply, Ownable, ReentrancyGuard {
    using Strings for string;

    //Set contract name and symbol
    string public name = "MiniMetamon Item";
    string public symbol = "MiniMetamon-Item";

    address payable public paymentContractAddress;

    uint8 private TEAR_OF_THE_GODDESS = 1;
    uint8 private LUCKY_TOTEM = 2;
    uint8 private SPIRIT_OF_FIRE = 3;
    uint8 private SPIRIT_OF_WATER = 4;
    uint8 private SPIRIT_OF_EARTH = 5;
    uint8 private SPIRIT_OF_ELECTRICTY = 6;
    uint8 private ASTRAL_SPIRIT = 7;

    uint8 private ARTIFACT1 = 8;
    uint8 private ARTIFACT2 = 9;
    uint8 private ARTIFACT3 = 10;
    uint8 private ARTIFACT4 = 11;
    uint8 private ARTIFACT5 = 12;
    uint8 private ARTIFACT6 = 13;
    uint8 private ARTIFACT7 = 14;
    uint8 private ARTIFACT8 = 15;

    uint8 private COMPLITIONIST = 16;

    // uint256 private totalSupply = 8;

    uint8[7] public itemBurnable = [1, 0, 0, 0, 0, 0, 0];
    uint8[7] public itemTypes = [
        TEAR_OF_THE_GODDESS,
        LUCKY_TOTEM,
        SPIRIT_OF_FIRE,
        SPIRIT_OF_WATER,
        SPIRIT_OF_EARTH,
        SPIRIT_OF_ELECTRICTY,
        ASTRAL_SPIRIT
    ];

    uint8[8] public artifactType = [
        ARTIFACT1,
        ARTIFACT2,
        ARTIFACT3,
        ARTIFACT4,
        ARTIFACT5,
        ARTIFACT6,
        ARTIFACT7,
        ARTIFACT8
    ];

    uint8[1] public complicionstNFT = [COMPLITIONIST];

    uint8[7] public maxOwnable = [10, 1, 1, 1, 1, 1, 1];
    uint32[7] public itemSupplies = [2500, 2500, 1000, 1000, 1000, 1000, 1000];

    uint256[7] private itemFloor = [
        0.12 ether,
        0.25 ether,
        0.04 ether,
        0.04 ether,
        0.04 ether,
        0.04 ether,
        0.04 ether
    ];
    uint256 private tokenIds;
    uint256 public itemTotalSupply = 10000;

    string private itemBaseURI;
    string private baseURI;
    string private passWord = "MADECHANGE";

    mapping(uint256 => string) private uris;

    mapping(uint256 => uint8) public tokenItemTypes;
    mapping(address => uint256[]) public tokenOwner; // Represents owner's tokens *tokenIds
    mapping(address => mapping(uint8 => uint256[])) public tokenOwners; // Represents owner's different type of tokens' ids

    ///////////////////////////////////////////////////////////////////////////
    // Events
    ///////////////////////////////////////////////////////////////////////////
    event ReceivedEth(address _sender, uint256 _value);
    event ItemMinted(address _reciever, uint256 _tokenId);
    event BurnItem(address _burner, uint256 _tokenId);

    ///////////////////////////////////////////////////////////////////////////
    // Cons
    ///////////////////////////////////////////////////////////////////////////
    constructor()
        payable
        ERC1155(
            "https://gateway.pinata.cloud/ipfs/INSERT_IPFS_HASH_HERE/{id}.json"
        )
    {}

    fallback() external payable {}

    receive() external payable {
        emit ReceivedEth(msg.sender, msg.value);
    }

    ///////////////////////////////////////////////////////////////////////////
    // Pre-Function Conditions
    ///////////////////////////////////////////////////////////////////////////
    modifier itemType(uint256 _itemType) {
        require(1 <= _itemType && _itemType <= 7, "Item Type out of scope!");
        _;
    }

    ///////////////////////////////////////////////////////////////////////////
    // Get/Set State Changes
    ///////////////////////////////////////////////////////////////////////////
    function changeFloorPrice(uint256 _new_price, uint8 _itemType)
        external
        onlyOwner
        itemType(_itemType)
    {
        itemFloor[_itemType - 1] = _new_price;
    }

    function getFloorPrice(uint8 _itemType)
        public
        view
        itemType(_itemType)
        returns (uint256)
    {
        return itemFloor[_itemType - 1];
    }

    function getSupplyLeft(uint8 _itemType)
        public
        view
        itemType(_itemType)
        returns (uint256)
    {
        return itemSupplies[_itemType - 1];
    }

    function specificItemOwnership(address _owner, uint8 _itemType)
        public
        view
        returns (uint256)
    {
        // check whether owner owns specific ITEM token
        uint256 total_ownership = tokenOwners[_owner][_itemType].length;
        return total_ownership;
    }

    function mintableLeft(uint256 _quantity, uint256 _itemSupplyLeft)
        internal
        pure
        returns (uint256)
    {
        if (_quantity <= _itemSupplyLeft) {
            return _quantity;
        } else {
            if (_itemSupplyLeft == 0) {
                revert("Item supply not enough!");
            } else {
                return _itemSupplyLeft;
            }
        }
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
    // Burn Tokens
    ///////////////////////////////////////////////////////////////////////////
    function _deleteOwnerToken(address _burner, uint256 _tokenId)
        internal
        onlyOwner
        returns (bool)
    {
        // TODO: redundant function, change it with ownerOf() -> when the item will be burned it will be automatically removed
        uint256[] memory tokens = tokenOwner[_burner];
        for (uint256 i = 0; i < tokens.length; i++) {
            if (tokens[i] == _tokenId) {
                delete tokenOwner[_burner][i];
                return true;
            }
        }
        return false;
    }

    // TODO: Only tokens owned by the holder can be burned by the holder
    function burn(address _burner, uint256 _tokenId) public {
        uint8 _tokenType = tokenItemTypes[_tokenId];
        require(itemBurnable[_tokenType - 1] == 1, "Item not burnable!");

        if (_deleteOwnerToken(_burner, _tokenId)) {
            _burn(_burner, _tokenId, 1);
            emit BurnItem(_burner, _tokenId);
        } else {
            revert("Could not burn the token!");
        }
    }

    ///////////////////////////////////////////////////////////////////////////
    // Mint Tokens
    ///////////////////////////////////////////////////////////////////////////
    function mintSale(
        address _recipient,
        uint8 _itemType,
        uint256 _quantity
    ) external payable nonReentrant {
        uint256 _totalOwned = specificItemOwnership(_recipient, _itemType);
        require(
            _totalOwned + _quantity <= maxOwnable[_itemType - 1],
            "Max ownable quantity reached!"
        );

        uint256 _itemSupplyLeft = getSupplyLeft(_itemType);
        uint256 _itemFloor = getFloorPrice(_itemType);

        uint256 _maxMintable = mintableLeft(_quantity, _itemSupplyLeft);
        if (msg.sender != owner()) {
            require(
                _maxMintable * _itemFloor <= msg.value,
                "Not exact coin send!"
            );
        }

        uint256 j = tokenIds;

        for (uint256 i = 0; i < _quantity; i++) {
            j++;
            _mint(_recipient, _itemType, 1, "");
            tokenOwners[_recipient][_itemType].push(j);
            tokenOwner[_recipient].push(j);
            tokenItemTypes[j] = _itemType;
            itemSupplies[_itemType - 1] = itemSupplies[_itemType - 1] - 1;
            emit ItemMinted(_recipient, j);
        }
        tokenIds = j;
    }

    ///////////////////////////////////////////////////////////////////////////
    // Backend URIs
    ///////////////////////////////////////////////////////////////////////////
    function uri(uint256 tokenId) public view override returns (string memory) {
        return (uris[tokenId]);
    }

    function setTokenUri(uint256 tokenId, string memory uri) public onlyOwner {
        uris[tokenId] = uri;
    }

    function setURI(string memory newuri) external onlyOwner {
        _setURI(newuri);
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
