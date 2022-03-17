// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract Example is Ownable, ERC721 {

    constructor() payable ERC721("NFT", "Example Playground") { 

    }

    function mintPublic(
        address recipient,
        uint256 quantity
    ) public payable {
        _safeMint(recipient, quantity);
    }
}