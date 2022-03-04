// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";


interface ItemContract {
    function getFloorPrice(uint8 _itemType) external view returns (uint256);
    function specificItemOwnership(address _owner, uint8 _itemType) external view returns (uint256);
    function burn(address _burner, uint256 _tokenId) external view;
}


// Pick during the meeting 1/10000
// Shiny logic (every mint reset, if you have lucky totem higher chance, if you mintQuantity 10, it increments the probability of minting shiny on each loop of mint

// Before the personalities in 1/10 chance call the chainlink contract 
// Batch actions



contract Metamon is ERC721 {
    using Strings for uint256;

    address payable public owner;
    address _itemContractAddress = 0x1E6059Ec57aE39D2C73E5C3821a26FAFfD68E016; // TODO: we will hardcode it for now
    
    ItemContract _item = ItemContract(_itemContractAddress);  // TODO: move this declaration outside of this function


    string private itemBaseURI;
    string private metamonBaseURI;
    string private baseURI;

    event ReceivedEth(address _reciever, uint256 _value);
    event MetamonMint(uint256 _tokenId, address _reciever);
    event MetamonBurn(uint256 _tokenId, uint8 _dexId, address _burner);

    uint8 public currentMintPhase = 1;
    uint8[5] private withLuckyTotem = [99, 98, 97, 96, 95];  // TODO: total count of 100 probabilities 
    uint32[5] private withoutLuckyTotem = [296, 292, 288, 284, 280];  // TODO: total number of 100 probabilities
    uint256[8] private metamonDex = [1, 2, 3, 4, 7, 10, 11, 13]; // REPR: METAMONT DEX NUMBERS
    uint256[8] private metamonSupply = [1000, 0, 0, 2000, 1000, 3000, 4000, 1000]; // REPR: STARTS FROM TOKEN IDS
    uint256[8] private metamonMinted = [0, 0, 0, 0, 0, 0, 0, 0]; // REPR: STARTS FROM TOKEN IDS
    uint256[8] private metamonMintable = [1, 0, 0, 1, 0, 0, 0, 1]; // REPR: DIRECTLY MINTABLE METAMON DEXIDS
    uint256[8] private metamonFloor = [.05 ether, 0 ether, 0 ether, .025 ether, 0.035 ether, 0.045 ether, 0.055 ether, 0.065 ether];

    uint256 private _tokenIds;

    mapping(uint8 => uint256[]) private metamonMintPhases; // REPR: Metamon mint phases by DAX numbers;
    mapping(uint256 => uint256) private familyMetamon; // REPR: Metamon evalution trees 

    mapping(uint256 => uint256) private itemEvaluation; // REPR: Which item needed for which metamon evalution
    mapping(uint256 => uint256) private burnEvaluation; // REPR: How many metamon balance needed for evalution for next metamon dex

    mapping(address => uint256) private _collectedItems; // MINTING FIRST CHECK IF ADDRESS COLLEDTED ANY ITEMS BEFORE
    mapping(address => uint256) private _collectedDex; // TOTAL COLLECTED DAX ITEMS IMPORTANT TO IDENTIFY SHINY LOGIC

    mapping(uint256 => bool) public metamonInfoShiny; // REPR: Holds the info about If the minted metamon was shiny or not
    mapping(uint256 => uint8) public metamonInfoPersonality; // REPR: Holds the info about the personality of the metamon

    constructor() payable ERC721("Metamon NFT", "NFT") {
        owner = payable(msg.sender);
        // FILLING INFORMATION OF METAMAN AND EVALUATION
        burnEvaluation[1] = 2;
        burnEvaluation[2] = 3;
        itemEvaluation[1] = 1;
        itemEvaluation[2] = 1;
        familyMetamon[1] = 2;
        familyMetamon[2] = 3;
        // ****************
        burnEvaluation[4] = 2;
        burnEvaluation[5] = 3;
        itemEvaluation[4] = 2;
        itemEvaluation[5] = 2;
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
        onlyOwner(msg.sender)
    {
        metamonFloor[_dexId - 1] = _new_price;
    }

    function changeSupplyDexId(
        uint256 _new_supply,
        uint8 _dexId
    )
        external
        onlyOwner(msg.sender)
    {
        metamonSupply[_dexId - 1] = _new_supply;
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
    // Mint / Randomness Mockup TODO: remove this section when Coinbase Implementation
    ///////////////////////////////////////////////////////////////////////////
    function _mockupRandomPersonality() internal pure returns(uint8) {
        uint8[4] memory personality = [1, 2, 3, 4];
        return personality[0];
    }

    function _mockupRandomShiny(uint256 _quantity, bool lucky) internal view returns(bool) {
        // TODO: randomness comes from the loop
        if (lucky){
            uint256 probability = withLuckyTotem[_quantity];
            // TODO: there should be some randomness based on the probability
            return true;
        } else {
            uint256 probability = withoutLuckyTotem[_quantity];
            // TODO: there should be some randomness based on the probability
            return false;
        }
        
    }

    function _checkLuckyOwnership(address _recipient) internal view returns (bool){
        // TODO: lucky item hardcoded as "2" for this 
        uint256 total_ownership = _item.specificItemOwnership(_recipient, 2); // Checks whether Lucky Totem has been owned/or not
        if (total_ownership == 0){
            return false;
        } else {
            return true;
        }
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
            string memory _passCode,
            address _recipient, 
            uint256 _quantity,
            uint8 _dexId // TODO: talk to Nick about the randomness of the dexID
        ) public payable mintableDexPhase(_dexId) mintableSupply(_dexId, _quantity) {
        // TODO: after minting make sure to push token information into mapping
        uint256 floorPrice = getFloorPrice(_dexId);
        if (msg.sender != owner) {
            require(msg.value == floorPrice * _quantity, "Not Enough Balance!");
        }
        
        bool lucky = _checkLuckyOwnership(_recipient);
        uint256 j = _tokenIds;
        for (uint256 i = 0; i < _quantity; i++) {
            j++;
            _mint(_recipient, j);
            metamonInfoPersonality[j] = _mockupRandomPersonality();
            metamonInfoShiny[j]= _mockupRandomShiny(i, lucky);
            metamonMinted[_dexId - 1] = metamonMinted[_dexId - 1] + 1;
            emit MetamonMint(j, _recipient);
        }
        _tokenIds = j;
    }

    function evalutionItemBurn(
        address _recipient,
        uint256 _sendItemTokenId,
        uint256 _sendDexTokenId
    ) public {
        // TODO: burn metamon and item together
        _item.burn(_recipient, _sendItemTokenId);
        burn(_recipient, _sendDexTokenId);
    }

    function evalutionMetaBurn(
        address _recipient, 
        uint256 _sendTokenId, 
        uint256 _sendDexId, 
        uint256 _quantitySend,  
        uint256 _targetDax, 
        uint256 _itemTokenId
        ) public {
        // TODO: only burn metamon
        // check whether owner has item token
        
        // burn(_send, TokenId);
        // uint256 _evaluationToken = burnEvaluation[_sendDaxId];
        // uint256 _tokenIds = _tokenIds + 1;
        // _mint(_recipient, _tokenIds);
    }
}