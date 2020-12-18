// SPDX-License-Identifier: MIT

pragma solidity >=0.5.2;


import '../../node_modules/openzeppelin-solidity/contracts/utils/Address.sol';
import '../../node_modules/openzeppelin-solidity/contracts/drafts/Counters.sol';
import '../../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol';
import '../../node_modules/openzeppelin-solidity/contracts/token/ERC721/IERC721Receiver.sol';
import "./Oraclize.sol";

contract Ownable {
    
    
    address private _owner;
    function getOwner() public view returns(address){
        return _owner;
    }

    
    constructor() internal{
        _owner = msg.sender;
        emit OwnershipTransfered(address(0), _owner);
    }

    
    modifier onlyOwner() {
        require(_owner == msg.sender, "Only Owner");
        _;
    }

    
    
    event OwnershipTransfered(address currentOwner, address newOwner);

    function transferOwnership(address newOwner) public onlyOwner {
        
        
        require(newOwner != address(0), "New owner address is invalid");

        _owner = newOwner;
        emit OwnershipTransfered(msg.sender, newOwner);

    }
}


contract Pausable is Ownable{

    
    bool private _paused;

    
    function setContract() public 
        onlyOwner
    {

    }

    
    constructor() internal {
        _paused = false;
    }

    
    modifier whenNotPaused(){
        require(_paused == false, "Contract is paused");
        emit Unpaused(msg.sender);
        _;
    }

    modifier paused(){
        require(_paused == true, "Contract is not paused");
        emit Paused(msg.sender);
        _;
    }

    
    event Paused(address indexed caller);
    event Unpaused(address indexed caller);

}


contract ERC165 {
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;
   
    mapping(bytes4 => bool) private _supportedInterfaces;
   
    constructor () internal {
        _registerInterface(_INTERFACE_ID_ERC165);
    }

    function supportsInterface(bytes4 interfaceId) external view returns (bool) {
        return _supportedInterfaces[interfaceId];
    }

    function _registerInterface(bytes4 interfaceId) internal {
        require(interfaceId != 0xffffffff);
        _supportedInterfaces[interfaceId] = true;
    }
}

contract ERC721 is Pausable, ERC165 {

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    
    using SafeMath for uint256;
    using Address for address;
    using Counters for Counters.Counter;

    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;

    
    mapping (uint256 => address) private _tokenOwner;

    
    mapping (uint256 => address) private _tokenApprovals;

    mapping (address => Counters.Counter) private _ownedTokensCount;

    
    mapping (address => mapping (address => bool)) private _operatorApprovals;

    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;

    constructor () public {
        
        _registerInterface(_INTERFACE_ID_ERC721);
    }

    function balanceOf(address owner) public view returns (uint256) {
        
        
        return _ownedTokensCount[owner].current();
    }

    function ownerOf(uint256 tokenId) public view returns (address) {
        
        return _tokenOwner[tokenId];
    }


    function approve(address to, uint256 tokenId) public {
        
        
        require(ownerOf(tokenId) != to, "No need to approve owner to transfer your own tokens");

        
        require(isApprovedForAll(msg.sender, to) == true || ownerOf(tokenId) == msg.sender, "Caller is not authorized to modify approvals");

        
        _tokenApprovals[tokenId] = to;

        
        emit Approval(msg.sender, to, tokenId);
    }

    function getApproved(uint256 tokenId) public view returns (address) {
        
        if (_tokenApprovals[tokenId] != address(0)){
          return(_tokenApprovals[tokenId]);
        }
    }

   
    function setApprovalForAll(address to, bool approved) public {
        require(to != msg.sender);
        _operatorApprovals[msg.sender][to] = approved;
        emit ApprovalForAll(msg.sender, to, approved);
    }

    function isApprovedForAll(address owner, address operator) public view returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    function transferFrom(address from, address to, uint256 tokenId) public {
        require(_isApprovedOrOwner(msg.sender, tokenId));

        _transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public {
        transferFrom(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data));
    }

    function _exists(uint256 tokenId) internal view returns (bool) {
        address owner = _tokenOwner[tokenId];
        return owner != address(0);
    }

 
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    function _mint(address to, uint256 tokenId) internal {

        
        require(_exists(tokenId) == false, "Token ID already exists");
        require(to != address(0), "Invalid address");
  
        
        _tokenOwner[tokenId] = to;
        _ownedTokensCount[to].increment();
        
        
        emit Transfer(msg.sender, to, tokenId);
    }

   function _transferFrom(address from, address to, uint256 tokenId) internal {

        
        require(ownerOf(tokenId) == from,"Token ownership mismatch");

        
        require(to != address(0), "Invalid address for token transfer");

        
        _clearApproval(tokenId);

        
        _ownedTokensCount[from].decrement();
        _ownedTokensCount[to].increment();
        _tokenOwner[tokenId] = to; 

        
        emit Transfer(from, to, tokenId);
    }

   
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data)
        internal returns (bool)
    {
        if (!to.isContract()) {
            return true;
        }

        bytes4 retval = IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, _data);
        return (retval == _ERC721_RECEIVED);
    }

    function _clearApproval(uint256 tokenId) private {
        if (_tokenApprovals[tokenId] != address(0)) {
            _tokenApprovals[tokenId] = address(0);
        }
    }
}

contract ERC721Enumerable is ERC165, ERC721 {
    
    mapping(address => uint256[]) private _ownedTokens;

    
    mapping(uint256 => uint256) private _ownedTokensIndex;

    
    uint256[] private _allTokens;

    
    mapping(uint256 => uint256) private _allTokensIndex;

    bytes4 private constant _INTERFACE_ID_ERC721_ENUMERABLE = 0x780e9d63;
   
    constructor () public {
        
        _registerInterface(_INTERFACE_ID_ERC721_ENUMERABLE);
    }

   
    function tokenOfOwnerByIndex(address owner, uint256 index) public view returns (uint256) {
        require(index < balanceOf(owner));
        return _ownedTokens[owner][index];
    }

    
    function totalSupply() public view returns (uint256) {
        return _allTokens.length;
    }


    function tokenByIndex(uint256 index) public view returns (uint256) {
        require(index < totalSupply());
        return _allTokens[index];
    }

    function _transferFrom(address from, address to, uint256 tokenId) internal {
        super._transferFrom(from, to, tokenId);

        _removeTokenFromOwnerEnumeration(from, tokenId);

        _addTokenToOwnerEnumeration(to, tokenId);
    }

    function _mint(address to, uint256 tokenId) internal {
        super._mint(to, tokenId);

        _addTokenToOwnerEnumeration(to, tokenId);

        _addTokenToAllTokensEnumeration(tokenId);
    }

    function _tokensOfOwner(address owner) internal view returns (uint256[] storage) {
        return _ownedTokens[owner];
    }
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        _ownedTokensIndex[tokenId] = _ownedTokens[to].length;
        _ownedTokens[to].push(tokenId);
    }

    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }
  function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        
        

        uint256 lastTokenIndex = _ownedTokens[from].length.sub(1);
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; 
            _ownedTokensIndex[lastTokenId] = tokenIndex; 
        }

        
        _ownedTokens[from].length--;

        
        
    }

    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        
        

        uint256 lastTokenIndex = _allTokens.length.sub(1);
        uint256 tokenIndex = _allTokensIndex[tokenId];

        
        
        
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; 
        _allTokensIndex[lastTokenId] = tokenIndex; 

        
        _allTokens.length--;
        _allTokensIndex[tokenId] = 0;
    }
}

contract ERC721Metadata is ERC721Enumerable, usingOraclize {
    
    
    string private _name;
    string private _symbol;
    string private _baseTokenURI;


    
    mapping (uint256 => string) private _tokenURIs;

    bytes4 private constant _INTERFACE_ID_ERC721_METADATA = 0x5b5e139f;
  

    constructor (string memory name, string memory symbol, string memory baseTokenURI) public {
        
        _name = name;
        _symbol = symbol;
        _baseTokenURI = baseTokenURI; 

        _registerInterface(_INTERFACE_ID_ERC721_METADATA);
    }

    
    function name() external view returns (string memory) {
        return _name;
    }

    function symbol() external view returns (string memory) {
        return _symbol;
    }

    function baseTokenURI() external view returns (string memory) {
        return _baseTokenURI;
    } 

    function tokenURI(uint256 tokenId) external view returns (string memory) {
        require(_exists(tokenId));
        return _tokenURIs[tokenId];
    }


    
    
    
    
        
    
    function setTokenURI(uint256 tokenId) internal {
      require(_exists(tokenId), "Token does not exist");
      _tokenURIs[tokenId] = strConcat(_baseTokenURI, uint2str(tokenId));
    }
}







contract MyERC721PropertyToken is ERC721Metadata{
    
    constructor (string memory name, string memory symbol) public 
        ERC721Metadata(name,symbol,"https://s3-us-west-2.amazonaws.com/udacity-blockchain/capstone/") 
    {
        
    }

    function mint(address to, uint256 tokenId) public onlyOwner() returns(bool){
        super._mint(to, tokenId);
        setTokenURI(tokenId);
        return true;
    }

}

