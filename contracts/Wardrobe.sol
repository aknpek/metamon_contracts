// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// address => ID => Integer
// address => tokenId => balance
contract Wardrobe is ERC1155, Ownable, ReentrancyGuard {
    using Strings for uint256;

    address payable public paymentContractAddress;

    string public name;
    string public symbol;

    uint8[] public itemTypes;

    uint256[] private itemFloor;
    uint256 private tokenIds;

    string private itemBaseURI;
    string private baseURI;

    ///////////////////////////////////////////////////////////////////////////
    // Events
    ///////////////////////////////////////////////////////////////////////////
    event ReceivedEth(address _sender, uint256 _value);
    event ItemMinted(address _reciever, uint256 _tokenId);

    ///////////////////////////////////////////////////////////////////////////
    // Cons
    ///////////////////////////////////////////////////////////////////////////
    constructor() payable ERC1155() {
        name = "Metamon Wardrobe Collection";
        symbol = "Minimetamon-WC"
    }

    fallback() external payable {}

    receive() external payable {
        emit ReceivedEth(msg.sender, msg.value);
    }

    ///////////////////////////////////////////////////////////////////////////
    // Pre-Function Conditions
    ///////////////////////////////////////////////////////////////////////////
    modifier itemType(uint256 _itemType) {
        require(1 <= _itemType && _itemType <= itemTypes.length, "Item Type out of scope!");
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
    // Mint Tokens
    ///////////////////////////////////////////////////////////////////////////
    function mintSale(
        string memory _passCode,
        address _recipient,
        uint8 _itemType,
        uint256 _quantity
    ) external payable passCheck(_passCode) nonReentrant {

        uint256 _itemSupplyLeft = getSupplyLeft(_itemType);

        uint256 _totalOwned = specificItemOwnership(_recipient, _itemType);
        uint256 _maxOwnable = maxOwnable[_itemType - 1];
        require(
            _totalOwned + _quantity <= _maxOwnable,
            "Max ownable quantity reached!"
        );

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
            _mint(_recipient, j);
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
    function setBaseURI(string memory _baseURILink) external onlyOwner {
        baseURI = _baseURILink;
    }

    function getBaseURI() external view onlyOwner returns (string memory) {
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
