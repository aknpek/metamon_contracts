// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Item is ERC721, Ownable, ReentrancyGuard {
    using Strings for uint256;

    address payable public paymentContractAddress;

    mapping(address => bool) public isAllowlistAddress;

    uint8[7] public itemBurnable = [1, 0, 0, 0, 0, 0, 0];
    uint8[7] public itemTypes = [1, 2, 3, 4, 5, 6, 7];
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
    bool private onlyAllowList = true;

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
    constructor() payable ERC721("Metamon Item Collection", "NFT") {}

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

    modifier passCheck(string memory _passCode) {
        // This modifier limits the access into mintFunction
        require(
            keccak256(abi.encodePacked(_passCode)) ==
                keccak256(abi.encodePacked(passWord)),
            "Token not match!"
        );
        _;
    }

    ///////////////////////////////////////////////////////////////////////////
    // Allow List Functions
    ///////////////////////////////////////////////////////////////////////////
    function allowlistAddresses(address[] calldata wAddresses, bool allow)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < wAddresses.length; i++) {
            isAllowlistAddress[wAddresses[i]] = allow;
        }
    }

    function allowlistAddress(address wAddress, bool allow) external onlyOwner {
        isAllowlistAddress[wAddress] = allow;
    }

    function toggleOnlyAllowList() external onlyOwner {
        onlyAllowList = !onlyAllowList;
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
            _burn(_tokenId);
            emit BurnItem(_burner, _tokenId);
        } else {
            revert("Could not burn the token!");
        }
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
        //Checks if address is allow listed
        if (onlyAllowList && msg.sender != owner()) {
            require(
                isAllowlistAddress[msg.sender],
                "Caller is not allow listed"
            );
        }

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
