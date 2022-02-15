// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract Item {
    function getFloorPrice(uint8 _itemType) public view returns (uint256) {}
}


contract Metamon is ERC721 {
    using Strings for uint256;
    address payable public owner;
    Item _item;

    string private itemBaseURI;
    string private metamonBaseURI;
    string private baseURI;

    event ReceivedEth(address _reciever, uint256 _value);
    event MetamonMint(uint256 _tokenId, address _reciever);

    uint256[7] private itemtokenTypes = [1, 2, 3, 4, 5, 6, 7]; // REPR: 7 UNIQUE ITEMS
    uint256[7] private itemtokenSupply = [
        1000,
        2500,
        1000,
        2000,
        3000,
        5000,
        2000
    ];
    uint256[7] private itemtokenIds = [1, 1, 1, 1, 1, 1, 1];
    uint256[7] private itemtokenFloor = [
        0.01 ether,
        0.02 ether,
        0.03 ether,
        0.04 ether,
        0.05 ether,
        0.06 ether,
        0.07 ether
    ];

    uint256[6] private metamonDax = [1, 2, 3, 4, 5, 6]; // REPR: METAMONT DEX NUMBERS
    uint256[6] private metamonSupply = [1000, 2000, 1000, 3000, 4000, 1000];
    uint256[6] private metamontIds = [1, 1, 1, 1, 1, 1];
    uint256[7] private metamonFloor = [
        .05 ether,
        .025 ether,
        0.035 ether,
        0.045 ether,
        0.055 ether,
        0.065 ether,
        0.075 ether
    ];
    uint256 _tokenIds;

    mapping(uint256 => uint256) private familyMetamon;

    mapping(uint256 => uint256) private itemEvaluation;
    mapping(uint256 => uint256) private burnEvaluation;

    mapping(address => uint256) private _collectedItems; // MINTING FIRST CHECK IF ADDRESS COLLEDTED ANY ITEMS BEFORE
    mapping(address => uint256) private _collectedDax; // TOTAL COLLECTED DAX ITEMS IMPORTANT TO IDENTIFY SHINY LOGIC

    constructor() payable ERC721("Metamon NFT", "NFT") {

        owner = payable(msg.sender);
        // FILLING INFORMATION OF METAMAN AND EVALUATION
        burnEvaluation[1] = 3;
        burnEvaluation[2] = 3;
        familyMetamon[1] = 2;
        familyMetamon[2] = 3;
        // ****************
        burnEvaluation[4] = 3;
        burnEvaluation[5] = 3;
        familyMetamon[4] = 5;
        familyMetamon[5] = 6;
    }

    modifier onlyOwner(address sender) {
        require(sender == owner, "Not a owner call!");
        _;
    }

    // State Changes
    function changeFloorPrice(
        uint256 _new_price,
        uint256 _type,
        uint8 _index
    )
        external
        // _type 1 represents "ITEMS" _type 2 represents "Metamon"
        // _index tell which "ITEM" or "Metamon" starts from 0, 1, 2, 3, ... 7
        onlyOwner(msg.sender)
    {
        if (_type == 1) {
            itemtokenFloor[_index] = _new_price;
        } else if (_type == 2) {
            metamonFloor[_index] = _new_price;
        }
    }

    function getFloorPrice(uint256 _type, uint8 _index)
        external
        view
        onlyOwner(msg.sender)
        returns (uint256)
    {
        if (_type == 1) {
            return itemtokenFloor[_index];
        } else if (_type == 2) {
            return metamonFloor[_index];
        }
    }

    // Get Information
    function getWalletBalance()
        public
        view
        onlyOwner(msg.sender)
        returns (uint256)
    {
        return address(this).balance;
    }

    // Contract ETH Relationship
    fallback() external payable {}

    receive() external payable {
        emit ReceivedEth(msg.sender, msg.value);
    }

    function transferContractBalance(
        address payable _recipient,
        uint256 _amount
    ) external onlyOwner(msg.sender) returns (bool) {
        require(_amount <= getWalletBalance(), "Not Enough Balance!");
        _recipient.transfer(_amount);
        return true;
    }

    // NFT Minting Related
    function setBaseURI(string memory _baseURILink)
        external
        onlyOwner(msg.sender)
    {
        baseURI = _baseURILink;
    }

    function getBaseURI()
        external
        view
        onlyOwner(msg.sender)
        returns (string memory)
    {
        return baseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        // We will have different baseURIs for Item and Metamon 
        // TODO: move items into different collection
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
        // We can retrieve the information about token id 
        // -> is it Item or Metamon
        // -> what is the dax number
        // -> based on the information that we retrieve we will return base_uri
        // TODO: move items into different collection

        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json"))
                : "";
    }

    function burn(uint256 _value) public {
        _burn(_value);
    }

    function mintSale(
        address _recipient, 
        address _itemCA,
        uint256 _quantity) public payable returns(uint256) {
    //     require(
    //         _quantity > 0 && _quantity <= (totalSupply - _tokenIds),
    //         "Not Enough Reserve!"
    //     );

    //     if (msg.sender != owner) {
    //         require(msg.value == florPrice * _quantity, "Not Enough Balance!");
    //     }

    // TODO: check if the dax number can be mintable based on the phases
    // TODO: after minting make sure to push token information into mapping

        _item = Item(_itemCA);
        uint256 floor = _item.getFloorPrice(1);

        return floor;
        // uint256 j = _tokenIds;
        // for (uint256 i = 0; i < _quantity; i++) {
        //     j++;
        //     _mint(_recipient, j);
        //     emit MetamonMint(j, _recipient);
        // }
        // _tokenIds = j;
    }

    function evalutionMetaItem(address _recipient, uint256 _quantity) public {


    }

    function evalutionMetaBurn(
        address _recipient, 
        uint256 _sendTokenId, 
        uint256 _sendDaxId, 
        // uint256, _quantitySend,  
        uint256 _targetDax, 
        uint256 _itemTokenId
        ) public {
        // check whether owner has item token
        
        burn(_sendTokenId);
        uint256 _evaluationToken = burnEvaluation[_sendDaxId];
        uint256 _tokenIds = _tokenIds + 1;
        _mint(_recipient, _tokenIds);


    }
}