pragma solidity >=0.6.0 <0.8.0;

import '../@openzeppelin/contracts/math/SafeMath.sol';
import '../@openzeppelin/contracts/utils/Address.sol';
import '../@openzeppelin/contracts/introspection/ERC165.sol';
import '../@openzeppelin/contracts/utils/EnumerableMap.sol';
import '../@openzeppelin/contracts/utils/EnumerableSet.sol';
import './IRNFT.sol';
import './IRNFTReceiver.sol';
import './IRNFTEnumerable.sol';
import './IRNFTMetadata.sol';



contract RNFT is ERC165, IRNFT,IRNFTMetadata,IRNFTEnumerable {
    
    using SafeMath for uint256;
    using Address for address;
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableMap for EnumerableMap.UintToAddressMap;
    

    // Equals to `bytes4(keccak256("onRFTReceived(address,address,uint256,bytes)"))`
    // which can be also obtained as `IRFTNFTReceiver(0).onRFTReceived.selector`
    bytes4 private constant _RFTNFT_RECEIVED = 0x150b7a02;

    // Mapping from Non-Fungible Token unique identifier (id) to owner address
    EnumerableMap.UintToAddressMap private _tokenOwners;
    
    // Mapping holder address to their enumerable set of tokens
    mapping (address => EnumerableSet.UintSet) private _holderTokens;

    // Mapping from Non-Fungible Token unique identifier (id) to approved address
    mapping (uint256 => address) internal _tokenApprovals;

    // Mapping from Non-Fungible Token owner to amount of his tokens
    mapping (address => uint256) internal _ownedTokensCount;

    // Mapping from owner address to approved operator address
    mapping (address => mapping (address => bool)) private _operatorApprovals;

    bytes4 private constant _InterfaceId_RFTNFT = 0x80ac58cd;
    /*
     * 0x80ac58cd ===
     *   bytes4(keccak256('balanceOf(address)')) ^
     *   bytes4(keccak256('ownerOf(uint256)')) ^
     *   bytes4(keccak256('approve(address,uint256)')) ^
     *   bytes4(keccak256('getApproved(uint256)')) ^
     *   bytes4(keccak256('setApprovalForAll(address,bool)')) ^
     *   bytes4(keccak256('isApprovedForAll(address,address)')) ^
     *   bytes4(keccak256('transferFrom(address,address,uint256)')) ^
     *   bytes4(keccak256('safeTransferFrom(address,address,uint256,bytes)'))
     */

    /**
     * @dev Constructor for RFT contract
     */
    constructor() public {
        _registerInterface(_InterfaceId_RFTNFT);
        
    }


    /**
     * @dev See {IRNFTEnumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        return _holderTokens[owner].at(index);
    }

    /**
     * @dev See {IRNFTEnumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        // _tokenOwners are indexed by tokenIds, so .length() returns the number of tokenIds
        return _tokenOwners.length();
    }

    /**
     * @dev See {IRNFTEnumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        (uint256 tokenId, ) = _tokenOwners.at(index);
        return tokenId;
    }


    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "RNFTMetadata: URI query for nonexistent token");

        string memory tokenURI = tokenURIs[tokenId];
        string memory base = baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(tokenURI).length > 0) {
            return string(abi.encodePacked(base, tokenURI));
        }
        // If there is a baseURI but no tokenURI, concatenate the tokenID to the baseURI.
        return string(abi.encodePacked(base, tokenId.toString()));
    }



    /**
     * @dev Returns NFT Token balance of selected address (_owner),
     * which means, how many NFT tokens owner of address has on his balance.
     * @param _owner - Address of NFT holder
     */
    function balanceOf(address _owner)
        public 
        view 
        override
        returns (uint256) 
    {
        require(_owner != address(0));
        return _ownedTokensCount[_owner];
    }

    /** 
     * @dev Returns owner address of selected NFT token (_tokenId).
     * @param _tokenId - Unique identifier of NFT
     */
    function ownerOf(uint256 _tokenId)
        public
        view 
        override
        returns (address) 
    {
        address _owner = _tokenOwner[_tokenId];
        require(_owner != address(0));
        return _owner;
    }

    /** 
     * @dev Approves to transfer selected NFT (_tokenId) by specific address (_to).
     * @notice Approving is needed when you want to give rights
     * for some identified party to transfer your token.
     * Approval event will be generated once approved.
     * @param _to - Receiver address of transfer approve for selected NFT
     * @param _tokenId - Unique identifier of NFT
     */
    function approve(
        address _to,
        uint256 _tokenId
    ) public override {
        address _owner = ownerOf(_tokenId);
        require(_to != _owner);
        require(msg.sender == _owner || isApprovedForAll(_owner, msg.sender));

        _tokenApprovals[_tokenId] = _to;
        emit Approval(_owner, _to, _tokenId);
    }

    /**
     * @dev Returns address of approved for transfer address for selected NFT(_tokenId). 
     * @notice Return approved address for NFT, if there is none 
     * approved address for this NFT, it will return zero address
     * @param _tokenId - Unique identifier of NFT
     */
    function getApproved(uint256 _tokenId) 
        public 
        view 
        override
        returns (address) 
    {
        require(_exists(_tokenId));
        return _tokenApprovals[_tokenId];
    }

    /** 
     * @dev Approve/Disapprove(depends on _approved value) transfering of all 
     * caller's NFTs by specific address (_to).
     * @notice Needed in case you want to give rights to transfer
     * of all your NFT's to some address
     * @param _to - Receiver of approvals for all NFT's owned by caller address
     * @param _approved - Approval status
     */
    function setApprovalForAll(
        address _to,
        bool _approved
    ) public override{
        require(_to != msg.sender);
        _operatorApprovals[msg.sender][_to] = _approved;
        emit ApprovalForAll(msg.sender, _to, _approved);
    }

    /**
     * @dev Checks if all NFT's of certain address(_owner) is approved to transfer
     * by another address(_operator)
     * @notice Returns true in case it was called 
     * setApprovalForAll(_operator, true), otherwise - false
     * @param _owner - Address of NFT's owner
     * @param _operator - Receipient address of transfer rights
     */
    function isApprovedForAll(
        address _owner,
        address _operator
    ) public view override returns (bool) {
        return _operatorApprovals[_owner][_operator];
    }

    /** 
     * @dev Transfer selected NFT (_tokenId) from owner (_from) to new owner(_to)
     * @notice Transaction sender(msg.sender) should be owner or approved address by 
     * approve or setApprovalForAll
     * @param _from - Address of NFT's owner 
     * @param _to - Address of NFT receiver
     * @param _tokenId - Unique identifier of NFT
     */
    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) public override{
        require(_isApprovedOrOwner(msg.sender, _tokenId));
        require(_to != address(0));

        _clearApproval(_from, _tokenId);
        _removeTokenFrom(_from, _tokenId);
        _addTokenTo(_to, _tokenId);

        emit Transfer(_from, _to, _tokenId);
    }

    /**
     * @dev Safe implementation of transferFrom function, which additionally checks
     * that NFT receiver address is NFT compatible by calling method of Receipient
     * contract address and supplying sender address, previous owner of NFT, NFT id
     * @notice Safe transfer is being used instead of transferFrom, in case we need 
     * to check that recipient address is compatible with NFT (only in case if 
     * receipient address is contract) 
     * @param _from - Address of NFT owner
     * @param _to - Address of NFT receiver
     * @param _tokenId - Unique identifier of NFT
     */
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) public override {
        safeTransferFrom(_from, _to, _tokenId, "");
    }

    /**
     * @dev Extended safeTransferFrom function with bytes parameter
     * @param _from - Address of NFT sender
     * @param _to - Address of NFT receiver
     * @param _tokenId - Unique identifier of NFT
     * @param _data - Bytes additional transaction data
     */
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes memory _data
    ) public override {
        transferFrom(_from, _to, _tokenId);
        require(_checkAndCallSafeTransfer(_from, _to, _tokenId, _data));
    }

    /** 
     * @dev Checks existing of specified NFT by its tokenId (unique identifier)
     * @param _tokenId - Unique identifier of NFT
     */
    function _exists(uint256 _tokenId) 
        internal 
        view
        returns (bool) 
    {
        address _owner = _tokenOwner[_tokenId];
        return _owner != address(0);
    }

    /** 
     * @dev Checks if transaction sender address if NFT owner or approved operator
     * @param _operator - Address of transaction sender
     * @param _tokenId - Unique identifier of NFT
     */
    function _isApprovedOrOwner(
        address _operator,
        uint256 _tokenId
    )
        internal 
        view 
        returns (bool) 
    {
        address _owner = ownerOf(_tokenId);

        return(
            _operator == _owner ||
            getApproved(_tokenId) == _operator ||
            isApprovedForAll(_owner, _operator)
        );
    }

    /**
     * @dev Internal mint function
     * @param _to - Address of NFT receiver
     * @param _tokenId - Unique identifier for new NFT
     */
    function _mint(
        address _to, 
        uint256 _tokenId
    ) 
        internal virtual
        returns (bool)
    {
        require(_to != address(0));
        _addTokenTo(_to, _tokenId);
        emit Transfer(address(0), _to, _tokenId);
        return true;
    } 

    /** 
     * @dev Internal burn function
     * @param _owner - Address of NFT holder
     * @param _tokenId - Unique identifier of NFT to burn
     */
    function _burn(
        address _owner,
        uint256 _tokenId
    ) 
        internal virtual
        returns (bool)
    {
        _clearApproval(_owner, _tokenId);
        _removeTokenFrom(_owner, _tokenId);
        emit Transfer(_owner, address(0), _tokenId);
        return true;
    }

    /** 
     * @dev Remove approved operator for selected NFT
     * @param _owner - Address of NFT owner
     * @param _tokenId - Unique identifier of NFT
     */
    function _clearApproval(
        address _owner,
        uint256 _tokenId
    ) internal {
        require(ownerOf(_tokenId) == _owner);
        if (_tokenApprovals[_tokenId] != address(0)) {
            _tokenApprovals[_tokenId] = address(0);
        }
    }

    /**
     * @dev Assigns ownership of selected NFT to specified address
     * @param _to - Address of NFT new owner
     * @param _tokenId - Unique identifier of NFT
     */
    function _addTokenTo(
        address _to,
        uint256 _tokenId
    ) internal virtual{
        require(_tokenOwner[_tokenId] == address(0));
        _tokenOwner[_tokenId] = _to;
        _ownedTokensCount[_to] = _ownedTokensCount[_to].add(1);
    }

    /** 
     * @dev Removes ownership of selected NFT from specified address
     * @param _from - Address of NFT old owner 
     * @param _tokenId - Unique identifier of NFT
     */
    function _removeTokenFrom(
        address _from,
        uint256 _tokenId
    ) internal virtual{
        require(ownerOf(_tokenId) == _from);
        _ownedTokensCount[_from] = _ownedTokensCount[_from].sub(1);
        _tokenOwner[_tokenId] = address(0);
    }

    /** 
     * @dev Checks that transfer call is safe
     * @param _from - Address of NFT sender
     * @param _to - Address of NFT receiver
     * @param _tokenId - Unique identifier of NFT
     * @param _data - Bytes transaction additional data
     */
    function _checkAndCallSafeTransfer(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes memory _data
    )
        internal
        returns (bool) 
    {
        if (!_to.isContract()) {
            return true;
        }
        bytes4 retval = IRFTNFTReceiver(_to).onRFTReceived(
            msg.sender, _from, _tokenId, _data
        );
        return (retval == _RFTNFT_RECEIVED);
    }
}