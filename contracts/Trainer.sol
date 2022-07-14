// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Trainer is ERC721A, Ownable, ReentrancyGuard {
    using Strings for uint256;

    //Flags
    bool public saleActive = false;
    bool private _transferAllowed = false;

    //Constants
    uint8 constant private ADDRESS_MAX_MINTS = 1;

    //Token URI
    string private _baseTokenURI = "";

    //Mappings
    mapping (address => uint256) public numberOfMintsOnAddress;

    //Events
    event ReceivedEth(address sender, uint256 value);
    event ReceiveEth(address _sender, uint256 _amount);
    event TrainerCreated(address _minter, uint256 _tokenId);

    constructor() ERC721A("MiniMetamon Trainer", "Minimetamon-Trainer") {}

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    fallback() external payable {}

    receive() external payable {
        emit ReceivedEth(msg.sender, msg.value);
    }

    ///////////////////////////////////////////////////////////////////////////
    // Mint Functions
    ///////////////////////////////////////////////////////////////////////////
    function mintTrainer(address minter) public payable {
        require(saleActive, "Sale must be active to mint");
        require(numberMinted(msg.sender) + 1 <= ADDRESS_MAX_MINTS, "Sender is trying to mint more than allocated tokens");

        numberOfMintsOnAddress[msg.sender] += 1;
        _safeMint(msg.sender, 1);
        emit TrainerCreated(minter, totalSupply());
    }

    function withdraw() external onlyOwner nonReentrant {
        require(address(this).balance > 0, "No balance to withdraw");
        uint256 contractBalance = address(this).balance;
        _withdraw(payable(msg.sender), contractBalance);
    }

    function _withdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Transfer failed.");
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function setTransferAllowed(bool transferAllows) external onlyOwner {

    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), 'ERC721Metadata: URI query for nonexistent token');

        string memory currentBaseURI = _baseURI();

        return bytes(currentBaseURI).length > 0
            ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), ".json"))
            : '';
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        require(_transferAllowed, "Trainer: transfer is not allowed");
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_transferAllowed, "Trainer: transfer is not allowed");
        super.safeTransferFrom(from, to, tokenId, _data);
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }
}
