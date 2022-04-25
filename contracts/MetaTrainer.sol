// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

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
    function mintTrainer(
        address minter,
        uint256 amount,
        bytes memory data
    ) public payable {
        require(
            balanceOf(minter, trainerId) + amount <= maxMintPerOwner,
            "Max Trainer Mint 1!"
        );
        require(msg.value >= amount * mintPrice, "Not Enough Funds!");
        require(amount >= currentTrainerSupply, "Not Enough Supply!");

        _mint(minter, trainerId, amount, data);
        emit TrainerCreated(minter, trainerId);
    }

    function withdraw() external onlyOwner {
        (bool owner, ) = address(this).call{value: address(this).balance}("");
        require(owner);
    }

    function setTokenUri(string memory uri) public virtual override onlyOwner {
        baseUri = uri;
    }

    // function uri(uint256 tokenId) public view override returns (string memory) {
    //     return
    //         bytes(baseUri).length > 0
    //             ? string(abi.encodePacked(baseUri, tokenId.toString(), ".json"))
    //             : "";
    // }

    function uri(uint256 _tokenid)
        public
        pure
        override
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    "https://ipfs.io/ipfs/bafybeihjjkwdrxxjnuwevlqtqmh3iegcadc32sio4wmo7bv2gbf34qs34a/",
                    Strings.toString(_tokenid),
                    ".json"
                )
            );
    }
}
