pragma solidity >=0.6.0 <0.8.0;

import './IRFTFT.sol';
import './IRFTFTMetadata.sol';
import './IRFTFTEnumerable.sol';

/**
 * @title RFT Fungible Token full interface (ERC-20 compatible)
 * @notice Full interface for ERC-20 compatible Token 
 */
contract IRFTFTFull is IRFTFT, IRFTFTMetadata, IRFTFTEnumerable {}