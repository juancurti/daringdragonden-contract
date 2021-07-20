//SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.3;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract DaringDragonDen is ERC721, ERC721Enumerable,ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    
    uint16 public constant maxSupply = 6000;
    bool public isSaleStarted = false;
    string private _baseTokenURI;
    uint16 public sold = 0;

    constructor() ERC721("DaringDragonDen", "DDD") {}

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }
    
    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    // Set sale (mintability) status
    function setSale(bool _setSaleBool) public onlyOwner {
        isSaleStarted = _setSaleBool;
    }


    function setBaseURI(string memory _newbaseTokenURI) public onlyOwner {
        _baseTokenURI = _newbaseTokenURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    // Get minting limit (for a single transaction) based on current token supply
    function getCurrentMintLimit() public pure returns (uint8) {
        return 20;
    }

    // Get ether price based on current token supply
    function getCurrentPrice() public pure returns (uint64) {
        return 30_000_000_000_000_000;
    }

    // Mint new token(s)
    function mint(string[] memory _tokenURIs, uint8 _quantityToMint) public payable {
        require(isSaleStarted == true, "Sale is not open");
        require(_quantityToMint >= 1, "Must mint at least 1");
        require(
            _quantityToMint <= getCurrentMintLimit(),
            "Maximum current buy limit for individual transaction exceeded"
        );
        require(
            (_quantityToMint + totalSupply()) <= maxSupply,
            "Exceeds maximum supply"
        );
        require(
            msg.value == (getCurrentPrice() * _quantityToMint),
            "Ether submitted does not match current price"
        );

        for (uint8 i = 0; i < _quantityToMint; i++) {
            _tokenIds.increment();

            uint256 newItemId = _tokenIds.current();
            _mint(msg.sender, newItemId);
            _setTokenURI(newItemId, _tokenURIs[i]);
            approve(address(this), newItemId);
            transferFrom(msg.sender, address(this), newItemId);
        }
            sold = sold + _quantityToMint;
    }
    
    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    // Withdraw ether from contract
    function withdraw() public onlyOwner {
        require(address(this).balance > 0, "Balance must be positive");
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success == true, "Failed to withdraw ether");
    }
}