// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract MetaTrainer is ERC1155, Ownable {
    using Strings for uint256;

    uint8 public maxMintPerOwner = 1;
    uint256 public mintPrice = 0 ether;
    uint256 public trainerId;
    uint256 public currentTrainerSupply;

    string public baseUri;

    event ReceiveEth(address _sender, uint256 _amount);
    event TrainerCreated(address _minter, uint256 _tokenId);

    constructor() payable ERC1155("Meta Trainer NFT") {}

    ///////////////////////////////////////////////////////////////////////////
    // Mint Functions
    ///////////////////////////////////////////////////////////////////////////
    function mintTrainer(address minter, uint256 amount) public payable {
        require(
            balanceOf(minter, trainerId) + amount <= maxMintPerOwner,
            "Max Trainer Mint 1!"
        );
        require(msg.value >= amount * mintPrice, "Not Enough Funds!");
        require(amount >= currentTrainerSupply, "Not Enough Supply!");

        _mint(minter, trainerId, amount, "");
        emit TrainerCreated(minter, trainerId);
    }

    function withdraw() external onlyOwner {
        (bool owner, ) = address(this).call{value: address(this).balance}("");
        require(owner);
    }

    function setTokenUri(string memory _uri) public onlyOwner {
        baseUri = _uri;
    }

    function uri(uint256 tokenId) public view override returns (string memory) {
        return
            bytes(baseUri).length > 0
                ? string(abi.encodePacked(baseUri, tokenId.toString(), ".json"))
                : "";
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        // TODO: cancel safe transfer
        revert("Secondary sale not possible");
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        revert("Secondary sale not possible");
    }
}
