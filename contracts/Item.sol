// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract Item is ERC721 {
    using Strings for uint256;

    string private passWord = "MADECHANGE";

    uint[7] private itemBurnable = [1, 0, 0, 0, 0, 0, 0];
    uint8[7] private itemTypes = [1, 2, 3, 4, 5, 6, 7];
    uint8[7] private maxOwnable = [1, 5, 5, 5, 5, 5, 5];
    uint32[7] private itemSupplies = [1000, 2000, 3000, 4000, 5000, 2000, 3000];

    uint256 public itemTotalSupply;
    uint256[7] private itemFloor = [0.2 ether, 0.3 ether, 0.4 ether, 0.2 ether, 0.2 ether, 0.3 ether, 0.1 ether];

    address payable public owner;

    string private itemBaseURI;
    string private baseURI;

    mapping(uint256 => uint8) public tokenItemTypes;

    event RecievedEth(address _sender, uint256 _value);
    event ItemMinted(address _reciever, uint256 _tokenId);

    constructor() payable ERC721("Metamon Item Collection", "NFT"){
        owner = payable(msg.sender);
    }

    // Pre-Function Conditions
    modifier onlyOwner(address _sender) {
        require(_sender == owner, "Not a owner call!");
        _;
    }

    modifier itemType(uint256 _itemType){
        require(1 <= _itemType && _itemType <= 7, "Item Type out of scope!");
        _;
    }

    modifier passCheck(string memory _passCode){
        require(keccak256(abi.encodePacked(_passCode)) == keccak256(abi.encodePacked(passWord)), "Token not match!");
        _;
    }

    // State Changes
    function changeFloorPrice(
        uint256 _new_price,
        uint8 _itemType
    ) external onlyOwner(msg.sender) itemType(_itemType) {
        itemFloor[_itemType - 1] = _new_price;
    }

    function getFloorPrice(
        uint256 _itemType
    ) external itemType(_itemType) view returns(uint256){
        return itemFloor[_itemType];
    }

    function burn(uint256 _tokenId) private {
        _burn(_tokenId);
    }

    function mintSale(
        address _recipeint,
        string memory _passCode,
        uint8 _itemType,
        uint256 _quantity
    ) external passCheck(_passCode) payable {

        
    }
}