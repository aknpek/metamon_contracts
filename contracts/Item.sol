// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract Item is ERC721 {
    using Strings for uint256;

    address payable public owner;

    uint[7] private itemBurnable = [1, 0, 0, 0, 0, 0, 0];
    uint8[7] private itemTypes = [1, 2, 3, 4, 5, 6, 7];
    uint8[7] private maxOwnable = [10, 1, 1, 1, 1, 1, 1];
    uint32[7] private itemSupplies = [2500, 2500, 1000, 1000, 1000, 1000, 1000];

    uint256[7] private itemFloor = [0.12 ether, 0.25 ether, 0.04 ether, 0.04 ether, 0.04 ether, 0.04 ether, 0.04 ether];
    uint256 private tokenIds;
    uint256 public itemTotalSupply = 10000;

    string private itemBaseURI;
    string private baseURI;
    string private passWord = "MADECHANGE";

    mapping(uint256 => uint8) public tokenItemTypes;
    mapping(address => uint8[]) public tokenOwner;
    mapping(address => mapping(uint8 => uint256[])) public tokenOwners; 
    
    ///////////////////////////////////////////////////////////////////////////
    // Events
    ///////////////////////////////////////////////////////////////////////////
    event RecievedEth(address _sender, uint256 _value);
    event ItemMinted(address _reciever, uint256 _tokenId);
    event burnItem(address _burner, uint256 _tokenId);

    constructor() payable ERC721("Metamon Item Collection", "NFT"){
        owner = payable(msg.sender);
    }

    ///////////////////////////////////////////////////////////////////////////
    // Pre-Function Conditions
    ///////////////////////////////////////////////////////////////////////////
    modifier onlyOwner(address _sender) {
        require(_sender == owner, "Not a owner call!");
        _;
    }

    modifier itemType(uint256 _itemType){
        require(1 <= _itemType && _itemType <= 7, "Item Type out of scope!");
        _;
    }

    modifier passCheck(string memory _passCode){
        // This modifier limits the access into mintFunction
        require(keccak256(abi.encodePacked(_passCode)) == keccak256(abi.encodePacked(passWord)), "Token not match!");
        _;
    }

    ///////////////////////////////////////////////////////////////////////////
    // State Changes
    ///////////////////////////////////////////////////////////////////////////
    function changeFloorPrice(
        uint256 _new_price,
        uint8 _itemType
    ) external onlyOwner(msg.sender) itemType(_itemType) {
        itemFloor[_itemType - 1] = _new_price;
    }

    function getFloorPrice(
        uint8 _itemType
    ) itemType(_itemType) public view returns(uint256){
        return itemFloor[_itemType - 1];
    }

    function getSupplyLeft(
        uint8 _itemType
    ) itemType(_itemType) public view returns(uint256){
        return itemSupplies[_itemType - 1]; 
    }

    function specificItemOwnership(
        address _owner,
        uint8 _itemType
    ) public view returns(uint256){
        // check whether owner owns specific ITEM token
        uint256 total_ownership = tokenOwners[_owner][_itemType].length;
        return total_ownership;
    }

    function mintableLeft(
        uint256 _quantity,
        uint256 _itemSupplyLeft
    ) internal pure returns(uint256){
        if (_quantity <= _itemSupplyLeft){
            return _quantity;
        } else {
            if (_itemSupplyLeft == 0){
                revert('Item supply not enough!');
            } else{
                return _itemSupplyLeft;
            }
        }
    }

    function totalItemTypes() public view returns(uint256){
        return itemTypes.length; 
    }

    function burn(uint256 _tokenId) private {
        _burn(_tokenId);
    }

    function mintSale(
        string memory _passCode,
        address _recipient,
        uint8 _itemType,
        uint256 _quantity
    ) external passCheck(_passCode) payable {       
        uint256 _itemSupplyLeft = getSupplyLeft(_itemType);

        uint256 _totalOwned = specificItemOwnership(_recipient, _itemType);
        uint256 _maxOwnable = maxOwnable[_itemType - 1];
        require(_totalOwned <= _maxOwnable, "Max ownable quantity reached!");

        uint256 _itemFloor = getFloorPrice(_itemType);

        uint256 _maxMintable = mintableLeft(_quantity, _itemSupplyLeft);

        require(_maxMintable * _itemFloor <= msg.value, "Not exact coin send!");

        uint256 j = tokenIds;

        for (uint256 i = 0; i < _quantity; i++) {
            j++;
            _mint(_recipient, j);
            tokenOwners[_recipient][_itemType].push(j);
            tokenOwner[_recipient].push(_itemType);
            tokenItemTypes[j] = _itemType;
            itemSupplies[_itemType - 1] = itemSupplies[_itemType - 1] - 1;
            emit ItemMinted(_recipient, j);
        }
        tokenIds = j;
    } 
}