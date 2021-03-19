pragma solidity ^0.5.0;

import "./IRFTNFT.sol";

/**
 * @title RFT Non-Fungible Token interface, that is supplied with Fungible Token
 * @notice Optional Metadata interface for Non-Fungible Token
 */
contract IRFTNFTMetadata is IRFTNFT {
    /**
     * @dev Returns name of RFT Non-Fungible Token series
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns symbol of RFT Non-Fungible Token series
     */
    function symbol() external view returns (string memory);
      
    /**
     * @dev Returns Unique Resource Identifier of RFT Non-Fungible Token
     * @param _tokenId - Unique Non-Fungible Token identifier
     */
    function tokenURI(uint256 _tokenId) public view returns (string memory);
}