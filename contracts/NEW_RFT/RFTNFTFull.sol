pragma solidity ^0.5.0;

import './RFTNFT.sol';
import './RFTNFTMetadata.sol';
import './RFTNFTEnumerable.sol';

contract RFTNFTFull is RFTNFT, RFTNFTMetadata, RFTNFTEnumerable {
    /**
     * @dev Constructor for full RFT NFT contract
     * @param _name - Name for a set of NFTs
     * @param _symbol - Symbol (abbreviated from name) for a set of NFTs
     */
    constructor (
        string memory _name,
        string memory _symbol
    ) 
        public 
        RFTNFTMetadata(
            _name,
            _symbol
        ) 
    {
        
    }
}