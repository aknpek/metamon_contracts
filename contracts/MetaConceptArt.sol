// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MetaConceptArt is ERC721, Ownable {

    address public constant DEV_ADDRESS = 0xD613c451a22346d1Eaa2Fffb72836B1F24b5B47f;
    address public constant OWNER_CW1_ADDRESS = 0x778341cFfb8C60217958Bd8B2B8a5139c686485a;

    uint256 public currentSupply;
    uint256 public maxSupply = 200;

    //Pre-reveal IPFS link
    string private baseURI = "https://gateway.pinata.cloud/ipfs/QmNxLKTUdTxuzSzrEwpsw2BuVR8Q75r4VSYq7s8PtrcvbX/";

    constructor() ERC721("MiniMetamon Concept Art", "MiniMetamon-CA") {
    }
    
    function totalSupply() external view returns (uint256) {
        return currentSupply;
    }

    function airdrop(address mintAddress, uint256 numberOfMints) external {

      require(msg.sender == DEV_ADDRESS || msg.sender == OWNER_CW1_ADDRESS || msg.sender == owner(), "Invalid Sender");

        uint256 supply = currentSupply;
        require(supply + numberOfMints <= maxSupply,  "This would exceed the max number of allowed mints");
 
        for (uint256 i; i < numberOfMints ; i++) {
            _mint(mintAddress, supply + i);
        }

        currentSupply += numberOfMints;
    }
    
    function withdraw() external  {
        require(msg.sender == DEV_ADDRESS || msg.sender == OWNER_CW1_ADDRESS || msg.sender == owner(), "Invalid Sender");

        (bool owner, ) = OWNER_CW1_ADDRESS.call{value: address(this).balance}("");
        require(owner, "Caller is not an owner of the contract");
    }

    function setBaseURI(string memory _uri) external onlyOwner {
        baseURI = _uri;
    }

    function tokensOfOwner(address _owner, uint startId, uint endId) external view returns(uint256[] memory ) {
      uint256 tokenCount = balanceOf(_owner);
      if (tokenCount == 0) {
        return new uint256[](0);
      } else {
        uint256[] memory result = new uint256[](tokenCount);
        uint256 index = 0;
        for (uint256 tokenId = startId; tokenId < endId; tokenId++) {
            if (index == tokenCount) break;

            if (ownerOf(tokenId) == _owner) {
                result[index] = tokenId;
                index++;
            }
        }

        return result;
      }
    }

    function walletOfOwner(address _owner) external view returns(uint256[] memory ) {
      return this.tokensOfOwner(_owner, 0, currentSupply);
    }
}