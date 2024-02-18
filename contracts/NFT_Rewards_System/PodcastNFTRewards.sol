// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract PodFiNFT is ERC721URIStorage, ERC721Burnable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    // Mapping to keep track of listener rewards
    mapping(address => uint256) public listenerRewards;

    constructor() ERC721("PodFiNFT", "PFNFT") {}

    // Function to mint NFTs for exclusive content
    function mintExclusiveContent(address recipient, string memory contentUri) public returns (uint256) {
        _tokenIds.increment();

        uint256 newItemId = _tokenIds.current();
        _mint(recipient, newItemId);
        _setTokenURI(newItemId, contentUri);

        return newItemId;
    }

    function rewardListenerWithNFT(address listener, string memory contentUri) public {
        // Check if the listener meets reward criteria
        if (listenerRewards[listener] >= 10) {
            mintExclusiveContent(listener, contentUri);
            // Reset or update the listener's reward count as needed
            listenerRewards[listener] = 0;
        }
    }

    // Function to track listener engagement and rewards
    function updateListenerEngagement(address listener) public {
        // Increment the listener's engagement
        listenerRewards[listener] += 1;
    }

    function mintBatchExclusiveContent(address[] memory recipients, string[] memory contentUris) public {
        require(recipients.length == contentUris.length, "Recipients and URIs length mismatch");
        for (uint i = 0; i < recipients.length; i++) {
            mintExclusiveContent(recipients[i], contentUris[i]);
        }
    }

    function checkListenerMilestone(address listener) public view returns (bool) {
        if (listenerRewards[listener] >= 50) { 
            return true;
        }
        return false;
    }
}