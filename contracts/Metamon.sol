// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";


interface ItemContract {
    function getFloorPrice(uint8 _itemType) external returns (uint256);
}


// Pick during the meeting 1/10000
// Shiny logic (every mint reset, if you have lucky totem higher chance, if you mintQuantity 10, it increments the probability of minting shiny on each loop of mint

// Before the personalities in 1/10 chance call the chainlink contract 
// Batch actions



contract Metamon is ERC721 {
    using Strings for uint256;
    address payable public owner;
    ItemContract _item;

    string private itemBaseURI;
    string private metamonBaseURI;
    string private baseURI;

    event ReceivedEth(address _reciever, uint256 _value);
    event MetamonMint(uint256 _tokenId, address _reciever);

    uint8 private currentMintPhase = 1;
    uint256[8] private metamonDax = [1, 2, 3, 4, 7, 10, 11, 13]; // REPR: METAMONT DEX NUMBERS
    uint256[8] private metamonSupply = [1000, 0, 0, 2000, 1000, 3000, 4000, 1000]; // REPR: STARTS FROM TOKEN IDS
    uint256[8] private metamonMinted = [1, 1, 1, 1, 1, 1, 1, 1]; // REPR: STARTS FROM TOKEN IDS
    uint256[8] private metamonFloor = [.05 ether, 0 ether, 0 ether, .025 ether, 0.035 ether, 0.045 ether, 0.055 ether, 0.065 ether];

    uint256 _tokenIds;

    mapping(uint8 => uint256[]) private metamonMintPhases; // REPR: Metamon mint phases by DAX numbers;
    mapping(uint256 => uint256) private familyMetamon; // REPR: Metamon evalution trees 

    mapping(uint256 => uint256) private itemEvaluation; // REPR: Which item needed for which metamon evalution
    mapping(uint256 => uint256) private burnEvaluation; // REPR: How many metamon balance needed for evalution for next metamon dex

    mapping(address => uint256) private _collectedItems; // MINTING FIRST CHECK IF ADDRESS COLLEDTED ANY ITEMS BEFORE
    mapping(address => uint256) private _collectedDex; // TOTAL COLLECTED DAX ITEMS IMPORTANT TO IDENTIFY SHINY LOGIC

    constructor() payable ERC721("Metamon NFT", "NFT") {
        owner = payable(msg.sender);
        // FILLING INFORMATION OF METAMAN AND EVALUATION
        burnEvaluation[1] = 2;
        burnEvaluation[2] = 3;
        familyMetamon[1] = 2;
        familyMetamon[2] = 3;
        // ****************
        burnEvaluation[4] = 2;
        burnEvaluation[5] = 3;
        familyMetamon[4] = 5;
        familyMetamon[5] = 6;
        // ****************
        metamonMintPhases[1] = [1, 4, 7, 20, 86, 133];
        // ****************
        burnEvaluation[129] = 5; // i.e. 5 #DEX129 has to burned for #DEX139
    }

    modifier onlyOwner(address sender) {
        require(sender == owner, "Not a owner call!");
        _;
    }

    ///////////////////////////////////////////////////////////////////////////
    // State Changes
    ///////////////////////////////////////////////////////////////////////////
    function changeFloorPrice(
        uint256 _new_price,
        uint8 _dexId
    )
        external
        // _type 1 represents "ITEMS" _type 2 represents "Metamon"
        // _index tell which "ITEM" or "Metamon" starts from 0, 1, 2, 3, ... 7
        onlyOwner(msg.sender)
    {
        metamonFloor[_dexId - 1] = _new_price;
    }

    ///////////////////////////////////////////////////////////////////////////
    // State Info
    ///////////////////////////////////////////////////////////////////////////
    function getFloorPrice(uint8 _dexId)
        public
        view
        returns (uint256)
    {
        return metamonFloor[_dexId - 1];
    }
 
    function getWalletBalance()
        public
        view
        onlyOwner(msg.sender)
        returns (uint256)
    {
        return address(this).balance;
    }

    function getSupplyDex(uint8 _dexId)
        public
        view 
        returns (uint256)
    {
        return metamonSupply[_dexId - 1] - metamonMinted[_dexId - 1];
    }
    
    ///////////////////////////////////////////////////////////////////////////
    // Contract ETH Deals
    ///////////////////////////////////////////////////////////////////////////
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

    ///////////////////////////////////////////////////////////////////////////
    // Meta Data Related
    ///////////////////////////////////////////////////////////////////////////
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

    ///////////////////////////////////////////////////////////////////////////
    // Mint / Burn Phases
    ///////////////////////////////////////////////////////////////////////////
    function burn(uint256 _value) public {
        _burn(_value);
    }

    function mintableDex(uint8 _dexId) public view returns(bool){
        // Helper functions checks if Dex Id can be mintable for current mint phase
        for (uint i=0; i < metamonMintPhases[currentMintPhase].length; i ++){
            if (_dexId == metamonMintPhases[currentMintPhase][i]){
                return true;
            }
        }
        return false;
    }

    modifier mintableDexPhase(uint8 _dexId) {
        require(mintableDex(_dexId) == true, 'Not Mintable Dex');
        _;
    }

    modifier mintableSupply(uint8 _dexId, uint256 _quantity){
        require(_quantity <= getSupplyDex(_dexId));
        _;
    }

    function mintSale(
            address _recipient, 
            address _itemContractAddress,
            uint256 _quantity,
            uint8 _dexId

        ) public payable mintableDexPhase(_dexId) mintableSupply(_dexId, _quantity) returns(uint256) {
        // TODO: after minting make sure to push token information into mapping
        // TODO: if you have a luck totem, you mint from the second list (*bottom)
        // TODO: 1/4 personality 
        uint256 floorPrice = getFloorPrice(_dexId);

        if (msg.sender != owner) {
            require(msg.value == floorPrice * _quantity, "Not Enough Balance!");
        }
        
        _item = ItemContract(_itemContractAddress);
        uint256 floor = _item.getFloorPrice(1);


        // uint256 j = _tokenIds;
        // for (uint256 i = 0; i < _quantity; i++) {
        //     j++;
        //     _mint(_recipient, j);
        //     emit MetamonMint(j, _recipient);
        // }
        // _tokenIds = j;
    }

    function evalutionItemBurn(
        address _recipient,
        uint256 _sendTokenId,
        uint256 _sendDaxId
    ) public {

    }

    function evalutionMetaBurn(
        address _recipient, 
        uint256 _sendTokenId, 
        uint256 _sendDaxId, 
        uint256 _quantitySend,  
        uint256 _targetDax, 
        uint256 _itemTokenId
        ) public {
        // check whether owner has item token
        
        // burn(_send, TokenId);
        // uint256 _evaluationToken = burnEvaluation[_sendDaxId];
        // uint256 _tokenIds = _tokenIds + 1;
        // _mint(_recipient, _tokenIds);
    }
}