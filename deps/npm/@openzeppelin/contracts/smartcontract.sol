// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./token/ERC721/ERC721.sol";
import "./token/ERC721/extensions/ERC721Burnable.sol";
import "../contracts/access/AccessControl.sol";
import "../contracts/access/Ownable.sol";
import "../contracts/security/Pausable.sol";
import "../contracts/utils/Counters.sol";
import "../contracts/operator-filter-registry/src/DefaultOperatorFilterer.sol";
import "./utils/Strings.sol";
import "./token/ERC20/IERC20.sol";
import "./utils/math/SafeMath.sol";


contract Metagonz is ERC721, ERC721Burnable, Pausable, Ownable, AccessControl, DefaultOperatorFilterer {
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    bytes32 public constant AIRDROP_ROLE = keccak256("AIRDROP_ROLE");

    using Counters for Counters.Counter;
    using SafeMath for uint256;

    string public baseURI;
    string public baseExtension = ".json";
    uint256 public maxSupply;
    mapping (address => bool) private airdrops;

    Counters.Counter private tokenIdCounter;

    constructor(string memory baseURI_, uint256 maxSupply_)
        ERC721("Name", "Symbol")
    {
        baseURI = baseURI_;
        maxSupply = maxSupply_;

        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(MANAGER_ROLE, _msgSender());
        _grantRole(AIRDROP_ROLE, _msgSender());
    }


    function claimAirdrop(address recipient)
        external
        whenNotPaused
        onlyRole (AIRDROP_ROLE)
    {
        require(tokenIdCounter.current() < maxSupply, "exceeds max supply");
        require(airdrops[recipient] == false, "exceeds airdrop limit");

        airdrops[recipient] = true;
        
        uint256 tokenId = tokenIdCounter.current();
        tokenIdCounter.increment();
        _safeMint(recipient, tokenId);
    }
    //
    function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
    {
        require(
            _exists(tokenId)
            
        );

        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0 ? string(abi.encodePacked(currentBaseURI, Strings.toString(tokenId), baseExtension)): "";
    }
    function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
    baseExtension = _newBaseExtension;
    }
//

    function airdrop(address[] calldata recipients)
        external
        whenNotPaused
        onlyRole (MANAGER_ROLE) 
    {
        require(tokenIdCounter.current() + recipients.length <= maxSupply, "exceeds max supply");
    
        for (uint256 i = 0; i < recipients.length; i++)
        {
            uint256 tokenId = tokenIdCounter.current();
            tokenIdCounter.increment();
            _mint(recipients[i], tokenId);
        }
    }

    function pause()
        external
        onlyRole (MANAGER_ROLE)
    {
        _pause();
    }

    function unpause()
        external
        onlyRole (MANAGER_ROLE)
    {
        _unpause();
    }

    function setBaseURI(string calldata baseURI_)
        external
        onlyRole (MANAGER_ROLE)
    {
        baseURI = baseURI_;
    }

    function transferFrom(address from, address to, uint256 tokenId)
        public
        override
        onlyAllowedOperator(from)
    {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId)
        public
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override (ERC721, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _baseURI()
        internal
        view
        override
        returns (string memory)
    {
        return baseURI;
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        whenNotPaused
        override
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    struct TokenInfo {
        IERC20 paytoken;
        uint256 costvalue;
    }

    TokenInfo[] public AllowedCrypto;
    
    function addCurrency(
        IERC20 _paytoken,
        uint256 _costvalue
    ) public onlyOwner {
        AllowedCrypto.push(
            TokenInfo({
                paytoken: _paytoken,
                costvalue: _costvalue
            })
        );
    }

    mapping(address => mapping (address => uint256)) allowed;

     function mintwithERC20(uint256 _count, uint256 _pid) public payable {
        TokenInfo storage tokens = AllowedCrypto[_pid];
        IERC20 paytoken;
        paytoken = tokens.paytoken;
        uint256 cost;
        cost = tokens.costvalue;
        uint totalMinted = tokenIdCounter.current();
        require(totalMinted.add(_count) <= 8888);
        
        
        for (uint256 i = 1; i <= _count; i++) {
            paytoken.transferFrom(msg.sender, address(this), cost);
            uint newTokenID = tokenIdCounter.current();
            _safeMint(msg.sender, newTokenID);
            tokenIdCounter.increment();
        }
    }

    function withdrawERC20(uint256 _pid) public payable onlyOwner() {
        TokenInfo storage tokens = AllowedCrypto[_pid];
        IERC20 paytoken;
        paytoken = tokens.paytoken;
        paytoken.transfer(msg.sender, paytoken.balanceOf(address(this)));
    }
    function getCryptotoken(uint256 _pid) public view virtual returns(IERC20) {
            TokenInfo storage tokens = AllowedCrypto[_pid];
            IERC20 paytoken;
            paytoken = tokens.paytoken;
            return paytoken;
    }
    function getNFTCost(uint256 _pid) public view virtual returns(uint256) {
            TokenInfo storage tokens = AllowedCrypto[_pid];
            uint256 cost;
            cost = tokens.costvalue;
            return cost;
    }
    function mintNFTs(uint _count) public payable {
        uint totalMinted = tokenIdCounter.current();
        uint PRICE = 0.01 ether;
        require(totalMinted.add(_count) <= 8888);
        require(msg.value >= PRICE.mul(_count));

        for (uint i = 0; i < _count; i++) {
            _mintSingleNFT();
        }
    }
     function _mintSingleNFT() private {
        uint newTokenID = tokenIdCounter.current();
        _safeMint(msg.sender, newTokenID);
        tokenIdCounter.increment();
    }
    function withdraw() public payable onlyOwner {
        uint balance = address(this).balance;
        require(balance > 0);

        (bool success, ) = (msg.sender).call{value: balance}("");
        require(success);
    }


}
