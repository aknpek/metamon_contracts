// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MetaTrainer is ERC721, Ownable {
    
    //Pre-reveal IPFS link
    string private baseURI = "";

    constructor() ERC721("MiniMetamon Trainer", "MiniMetamon-TR") {}

    uint256 public currentSupply;

    event TrainerMint(uint256 _tokenId, address _reciever);

    function mintTrainer() public {
        uint256 supply = currentSupply;

        _mint(msg.sender, (supply + 1));

        currentSupply += 1;

        emit TrainerMint(currentSupply, msg.sender);
    }

    function tokensOfOwner(
        address _owner,
        uint256 startId,
        uint256 endId
    ) external view returns (uint256[] memory) {
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

    function walletOfOwner(address _owner) external view returns (uint256[] memory)
    {
        return this.tokensOfOwner(_owner, 0, currentSupply);
    }

    //TODO: Need to discuss this with Nick
    function withdraw() external onlyOwner {
        (bool owner, ) = address(this).call{value: address(this).balance}("");
        require(owner);
    }

    function setBaseURI(string memory _uri) external onlyOwner {
        baseURI = _uri;
    }
}
