// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

library MetadataURI {
    function constructURI(
        string memory baseURI,
        uint256 tokenId
    ) internal pure returns (string memory) {
        return string(abi.encodePacked(baseURI, tokenIdToString(tokenId)));
    }

    function tokenIdToString(
        uint256 tokenId
    ) internal pure returns (string memory) {
        if (tokenId == 0) {
            return "0";
        }
        uint256 length = 0;
        for (uint256 i = tokenId; i > 0; i /= 10) {
            length++;
        }
        bytes memory buffer = new bytes(length);
        for (uint256 i = length; i > 0; i--) {
            buffer[i - 1] = bytes1(uint8(48 + (tokenId % 10)));
            tokenId /= 10;
        }
        return string(buffer);
    }
}
