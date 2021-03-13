pragma solidity >=0.6.0 <0.8.0;

import './IRFTNFT.sol';
import './IRFTNFTMetadata.sol';
import './IRFTNFTEnumerable.sol';

/**
 * @title RFT Non-Fungible Token interface, that is supplied with Fungible Token
 * @notice Non-Fungible Token full interface 
 */
contract IRFTNFTFull is IRFTNFT, IRFTNFTMetadata, IRFTNFTEnumerable {}