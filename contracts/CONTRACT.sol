// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NFTArtMarketplace is ERC721URIStorage, Ownable {
    struct NFT {
        uint id;
        string name;
        string metadata;
        address owner;
        uint price;
        bool forSale;
    }

    uint public nextId;
    address public marketplaceOwner;

    mapping(uint => NFT) public nfts;
    mapping(address => uint[]) private ownerToNFTs;

    event NFTCreated(uint indexed id, string name, address indexed owner);
    event NFTSold(uint indexed id, address indexed newOwner, uint price);
    event NFTListed(uint indexed id, uint price);
    event NFTDelisted(uint indexed id);
    event MetadataUpdated(uint indexed id, string newMetadata);
    event Withdrawal(address indexed to, uint amount);

    modifier onlyNFTOwner(uint id) {
        require(nfts[id].owner == msg.sender, "Not the NFT owner");
        _;
    }

    modifier onlyMarketplaceOwner() {
        require(msg.sender == marketplaceOwner, "Not marketplace owner");
        _;
    }

    constructor() ERC721("NFTArtMarketplace", "NAM") Ownable() {
        marketplaceOwner = msg.sender;
    }

    function createNFT(string memory name, string memory metadata) public {
        uint tokenId = nextId;

        _safeMint(msg.sender, tokenId);
        _setTokenURI(tokenId, metadata);

        nfts[tokenId] = NFT(tokenId, name, metadata, msg.sender, 0, false);
        ownerToNFTs[msg.sender].push(tokenId);

        emit NFTCreated(tokenId, name, msg.sender);

        nextId++;
    }

    function listNFT(uint id, uint price) public onlyNFTOwner(id) {
        require(price > 0, "Price must be greater than zero");
        nfts[id].price = price;
        nfts[id].forSale = true;
        emit NFTListed(id, price);
    }

    function delistNFT(uint id) public onlyNFTOwner(id) {
        nfts[id].forSale = false;
        emit NFTDelisted(id);
    }

    function buyNFT(uint id) public payable {
        require(id < nextId, "Invalid NFT id");
        NFT storage nft = nfts[id];
        require(nft.forSale, "NFT not for sale");
        require(msg.value >= nft.price, "Insufficient funds");

        address previousOwner = nft.owner;

        _transfer(previousOwner, msg.sender, id);

        nft.owner = msg.sender;
        nft.forSale = false;

        _removeNFTFromOwner(previousOwner, id);
        ownerToNFTs[msg.sender].push(id);

        payable(previousOwner).transfer(msg.value);

        emit NFTSold(id, msg.sender, msg.value);
    }

    function updateMetadata(uint id, string memory newMetadata) public onlyNFTOwner(id) {
        nfts[id].metadata = newMetadata;
        _setTokenURI(id, newMetadata);
        emit MetadataUpdated(id, newMetadata);
    }

    function withdraw() public onlyMarketplaceOwner {
        uint balance = address(this).balance;
        require(balance > 0, "No funds to withdraw");
        payable(marketplaceOwner).transfer(balance);
        emit Withdrawal(marketplaceOwner, balance);
    }

    // ✅ Return full NFT objects owned by a user
    function getNFTsByOwner(address owner) public view returns (NFT[] memory) {
        uint[] memory ownedIds = ownerToNFTs[owner];
        NFT[] memory result = new NFT[](ownedIds.length);
        for (uint i = 0; i < ownedIds.length; i++) {
            result[i] = nfts[ownedIds[i]];
        }
        return result;
    }

    // ✅ Return all NFTs created (used in marketplace)
    function getAllNFTs() public view returns (NFT[] memory) {
        NFT[] memory result = new NFT[](nextId);
        for (uint i = 0; i < nextId; i++) {
            result[i] = nfts[i];
        }
        return result;
    }

    function getNFT(uint id) public view returns (NFT memory) {
        require(id < nextId, "Invalid NFT id");
        return nfts[id];
    }

    function _removeNFTFromOwner(address owner, uint id) internal {
        uint[] storage nftList = ownerToNFTs[owner];
        for (uint i = 0; i < nftList.length; i++) {
            if (nftList[i] == id) {
                nftList[i] = nftList[nftList.length - 1];
                nftList.pop();
                break;
            }
        }
    }
}
