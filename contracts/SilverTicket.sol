// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract SilverTicket is ERC1155, Ownable {

    uint256 public constant SILVER_TICKET = 0;

    mapping (uint256 => string) private _uris;

    string public name = "Minimetamon-Silver-Ticket";
    string public symbol = "MMST";  

    constructor() ERC1155("") {
        _mint(msg.sender, SILVER_TICKET, 100, "");
    }

    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    function mint(address account, uint256 id, uint256 amount, bytes memory data) public

    {
        _mint(account, id, amount, data);
    }

    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) public
    {
        _mintBatch(to, ids, amounts, data);
    }

    function uri(uint256 tokenId) override public view returns (string memory){
        return(_uris[tokenId]);
    }

    function setTokenUri(uint256 tokenId, string memory uri) public onlyOwner {
        _uris[tokenId] = uri;
    }
}