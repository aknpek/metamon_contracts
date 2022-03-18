// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";


interface ItemContract {
    function getFloorPrice(uint8 _itemType) external view returns (uint256);
    function specificItemOwnership(address _owner, uint8 _itemType) external view returns (uint256);
    function burn(address _burner, uint256 _tokenId) external payable;
    function balanceOf(address _owner) external view returns(uint256);
}


// Pick during the meeting 1/10000
// Shiny logic (every mint reset, if you have lucky totem higher chance, if you mintQuantity 10, it increments the probability of minting shiny on each loop of mint

// Before the personalities in 1/10 chance call the chainlink contract 
// Batch actions



contract Metamon is ERC721 {
    using Strings for uint256;

    address payable public owner;
    address _itemContractAddress = 0xd2a5bC10698FD955D1Fe6cb468a17809A08fd005; // TODO: we will hardcode it for now

    ItemContract _item = ItemContract(_itemContractAddress);  // TODO: move this declaration outside of this function


    string private itemBaseURI;
    string private metamonBaseURI;
    string private baseURI;

    bool public collectArtifact = false;

    event ReceivedEth(address _reciever, uint256 _value);
    event MetamonMint(uint256 _tokenId, address _reciever);
    event MetamonBurn(uint256 _tokenId, uint8 _dexId, address _burner);

    uint8 public currentMintPhase = 1;
    uint8[5] private withLuckyTotem = [99, 98, 97, 96, 95];  // TODO: total count of 100 probabilities
    uint32[5] private withoutLuckyTotem = [296, 292, 288, 284, 280];  // TODO: total number of 100 probabilities
    uint256[8] private metamonDex = [1, 2, 3, 4, 5, 6, 7, 10]; // REPR: METAMONT DEX NUMBERS
    uint256[13] private evalutionMintDex = [2, 3, 5, 6, 8, 9, 11, 12, 14, 15, 17, 18, 20];
    uint256[8] private metamonSupply = [1000, 0, 0, 2000, 0, 0, 1000, 3000]; // REPR: STARTS FROM TOKEN IDS
    uint256[8] private metamonMinted = [0, 0, 0, 0, 0, 0, 0, 0]; // REPR: STARTS FROM TOKEN IDS
    uint256[8] private metamonMintable = [1, 0, 0, 1, 0, 0, 0, 1]; // REPR: DIRECTLY MINTABLE METAMON DEXIDS
    uint256[8] private metamonFloor = [.05 ether, 0 ether, 0 ether, .025 ether, 0.035 ether, 0.045 ether, 0.055 ether, 0.065 ether];

    uint256 private _tokenIds;

    mapping(uint8 => uint256[]) private metamonMintPhases; // REPR: Metamon mint phases by DAX numbers;
    mapping(uint256 => uint8) private familyMetamon; // REPR: Metamon evalution trees

    mapping(uint256 => uint256) private itemEvaluation; // REPR: Which item needed for which metamon evalution
    mapping(uint256 => uint256) private burnEvaluation; // REPR: How many metamon balance needed for evalution for next metamon dex

    mapping(address => uint256[]) private ownerCollectedMetamons; // REPR: Collected tokenIDs Metamons per address // TODO: remove when there is a burn or transfer
    mapping(uint256 => uint8) public mintedMetamonDexId; // REPR: Minted metamon dex id

    mapping(uint256 => bool) public metamonInfoShiny; // REPR: Holds the info about If the minted metamon was shiny or not
    mapping(uint256 => uint8) public metamonInfoPersonality; // REPR: Holds the info about the personality of the metamon

    mapping(uint8 => uint256[]) public artifactBatches; // REPR: Metamons need to be collected to mint Artifacts

    constructor() payable ERC721("Metamon NFT", "NFT") {
        owner = payable(msg.sender);

        artifactBatches[1] = [1, 4, 7, 20, 86, 133];  // TODO: we can use metmaon Mint phases, it can be removed

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
    // Mint  Phases
    ///////////////////////////////////////////////////////////////////////////
    function mintableDex(uint8 _dexId) public view returns(bool){
        // Helper function checks if Dex Id can be mintable for current mint phase
        for (uint i=0; i < metamonMintPhases[currentMintPhase].length; i ++){
            if (_dexId == metamonMintPhases[currentMintPhase][i]){
                return true;
            }
        }
        return false;
    }

    function mintableSpecial(uint8 _dexId) public view returns(bool){
        // Helper function checks if Dex Id can be specially mintable for evalution
        for (uint8 i=0; i < evalutionMintDex.length; i ++ ){
            if (_dexId == evalutionMintDex[i]){
                return true;
            }
        }
        return false;
    }

    modifier mintableDexPhase(uint8 _dexId) {
        require(mintableDex(_dexId) == true, 'Not Mintable Dex');
        _;
    }

    modifier mintalbeSpecialDex(uint8 _dexId) {
        require(mintableSpecial(_dexId) == true, 'Not Mintable Special Dex');
        _;
    }

    modifier mintableSupply(uint8 _dexId, uint256 _quantity){
        require(_quantity <= getSupplyDex(_dexId));
        _;
    }

    function mintSpecial(
        address _recipient,
        uint8 _dexId,
        uint256 _quantity
    ) internal {
        bool lucky = _checkLuckyOwnership(_recipient);
        uint256 j = _tokenIds;
        for (uint256 i = 0; i < _quantity; i ++){
            j ++;
            _mint(_recipient, j);
            metamonInfoPersonality[j] = _mockupRandomPersonality();
            metamonInfoShiny[j] = _mockupRandomShiny(i, lucky);

            mintedMetamonDexId[j] = _dexId;
            ownerCollectedMetamons[_recipient].push(j);
            emit MetamonMint(j, _recipient);
        }
         metamonMinted[_dexId - 1] = metamonMinted[_dexId - 1] + _quantity;
        _tokenIds = j;
    }

    function mintSale(
            string memory _passCode,
            address _recipient,
            uint256 _quantity,
            uint8 _dexId // TODO: talk to Nick about the RNG of the dexID
        ) external payable mintableDexPhase(_dexId) mintableSupply(_dexId, _quantity) {

        uint256 floorPrice = getFloorPrice(_dexId);
        if (msg.sender != owner) {
            require(msg.value == floorPrice * _quantity, "Not Enough Balance!");
        }

        bool lucky = false;  // TODO: _checkLuckyOwnership(_recipient);

        uint256 j = _tokenIds;
        for (uint256 i = 0; i < _quantity; i++) {
            j++;
            _mint(_recipient, j);
            // metamonInfoPersonality[j] = _mockupRandomPersonality();  // TODO: change with VRF
            // metamonInfoShiny[j]= _mockupRandomShiny(i, lucky);  // TODO: change with VRF
            mintedMetamonDexId[j] = _dexId;
            ownerCollectedMetamons[_recipient].push(j);
            emit MetamonMint(j, _recipient);
        }
       metamonMinted[_dexId - 1] = metamonMinted[_dexId - 1] + _quantity;
        _tokenIds = j;
    }

    ///////////////////////////////////////////////////////////////////////////
    // Mint / Burn Phases
    ///////////////////////////////////////////////////////////////////////////
    function artifactCollectTime(bool _collect) public onlyOwner(msg.sender){
        collectArtifact = _collect;
    }

    modifier artifactCollectibe(){
        require(collectArtifact == true, 'Artifacts not collectible');
        _;
    }

    function mintArtifact(address _recipient, uint8 _targetArtifact) external artifactCollectibe() {


    }

    function specificDexIdOwned(address _recipient, uint8 _dexId) internal returns(uint256[] memory) {
        // Return owned dexId's tokenIds
        uint256 counter = 0;
        uint256[] memory collectedMetamons = ownerCollectedMetamons[_recipient];
        uint256[] memory specificDexTokenIds;
        for (uint256 i=0; i < collectedMetamons.length; i++) {
            if (_dexId == mintedMetamonDexId[collectedMetamons[i]]){
                specificDexTokenIds[i] = collectedMetamons[i];
            }
        }
        return(specificDexTokenIds);
    }

    modifier ownerOfMetamon(address _recipient, uint256 _sendDexTokenId) {
        require(_recipient == ownerOf(_sendDexTokenId), "Not the owner call");
        _;
    }

    function evalutionItemBurn(
        address _recipient,
        uint256 _sendItemTokenId,
        uint256 _sendDexTokenId
    ) public payable ownerOfMetamon(_recipient, _sendDexTokenId) {
        // TODO: burn metamon and item together for evalution
        _item.burn(_recipient, _sendItemTokenId); // item token will handle burnable logic
        _burn(_sendDexTokenId); // normally you need to burn 1 metamon to evolve
        uint8 _dexId = familyMetamon[mintedMetamonDexId[_sendDexTokenId]];
        mintSpecial(_recipient, _dexId, 1);
    }

    function checkTokensDexId(uint256 _dexId, uint256[] memory _sendDexTokensId) internal {
        for (uint256 i; i < _sendDexTokensId.length; i++){
            require(_dexId == mintedMetamonDexId[i], "Not all same dex id");
        }
    }

    modifier checkTokensDex(uint256 _dexId, uint256[] memory  _sendDexTokensId){
        checkTokensDexId(_dexId, _sendDexTokensId);
        _;
    }

    function evalutionMetaBurn(
        address _recipient,
        uint8 _dexId,
        uint256[] memory _sendDexTokenId,
        uint256 _quantitySend
        ) public payable checkTokensDex(_dexId, _sendDexTokenId) {
        // TODO: only burn metamon for evalution # ownerOfMetamon(_recipient, _sendDexTokenId)

        uint256 _quantityCondition = burnEvaluation[_dexId];
        uint256[] memory _collectedMetamons = ownerCollectedMetamons[_recipient];
        // check number of metamon ownership to check _quantityCondition
        for (uint i; i < _sendDexTokenId.length; i ++){
            _burn(_sendDexTokenId[i]);
        }
        uint8 dexId = familyMetamon[_dexId];
        mintSpecial(_recipient, dexId, 1);
    }


    ///////////////////////////////////////////////////////////////////////////
    // Item Contract Calls
    ///////////////////////////////////////////////////////////////////////////
    function checkItemOwnership(
        address _owner
    ) public view returns(uint256){
        uint256 balance = _item.balanceOf(_owner);
        return balance;
    }

    function burnItem(
        address _reciever,
        uint256 _sendItemTokenId
    ) public payable {
        _item.burn(_reciever, _sendItemTokenId);
    }
}