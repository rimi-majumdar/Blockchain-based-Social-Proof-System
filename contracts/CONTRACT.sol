// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract NFTArtMarketplace {
    struct NFT {
        uint id;
        string name;
        string metadata;
        address owner;
        uint price;
        bool forSale;
    }
    
    uint public nextId;
    uint public totalMinted;
    address public marketplaceOwner;
    
    mapping(uint => NFT) public nfts;
    mapping(address => uint[]) private ownerToNFTs;

    event NFTCreated(uint indexed id, string name, address indexed owner);
    event NFTSold(uint indexed id, address indexed newOwner, uint price);
    event NFTListed(uint indexed id, uint price);
    event NFTDelisted(uint indexed id);
    event MetadataUpdated(uint indexed id, string newMetadata);
    event Withdrawal(address indexed to, uint amount);

    modifier onlyOwner(uint id) {
        require(nfts[id].owner == msg.sender, "Not the NFT owner");
        _;
    }

    modifier onlyMarketplaceOwner() {
        require(msg.sender == marketplaceOwner, "Not marketplace owner");
        _;
    }

    constructor() {
        marketplaceOwner = msg.sender;
    }
    
    function createNFT(string memory name, string memory metadata) public {
        nfts[nextId] = NFT(nextId, name, metadata, msg.sender, 0, false);
        ownerToNFTs[msg.sender].push(nextId);
        emit NFTCreated(nextId, name, msg.sender);
        nextId++;
        totalMinted++;
    }
    
    function listNFT(uint id, uint price) public onlyOwner(id) {
        require(price > 0, "Price must be greater than zero");
        nfts[id].price = price;
        nfts[id].forSale = true;
        emit NFTListed(id, price);
    }
    
    function delistNFT(uint id) public onlyOwner(id) {
        nfts[id].forSale = false;
        emit NFTDelisted(id);
    }
    
    function buyNFT(uint id) public payable {
        require(id < nextId, "Invalid NFT id");
        NFT storage nft = nfts[id];
        require(nft.forSale, "NFT not for sale");
        require(msg.value >= nft.price, "Insufficient funds");

        address previousOwner = nft.owner;

        // Transfer ownership
        nft.owner = msg.sender;
        nft.forSale = false;

        // Remove from previous owner mapping
        _removeNFTFromOwner(previousOwner, id);

        // Add to new owner mapping
        ownerToNFTs[msg.sender].push(id);

        // Pay previous owner
        payable(previousOwner).transfer(msg.value);

        emit NFTSold(id, msg.sender, msg.value);
    }

    function updateMetadata(uint id, string memory newMetadata) public onlyOwner(id) {
        nfts[id].metadata = newMetadata;
        emit MetadataUpdated(id, newMetadata);
    }

    function withdraw() public onlyMarketplaceOwner {
        uint balance = address(this).balance;
        require(balance > 0, "No funds to withdraw");
        payable(marketplaceOwner).transfer(balance);
        emit Withdrawal(marketplaceOwner, balance);
    }

    // View function to get NFTs owned by an address
    function getNFTsByOwner(address owner) public view returns (NFT[] memory) {
        uint[] memory ids = ownerToNFTs[owner];
        NFT[] memory result = new NFT[](ids.length);
        for (uint i = 0; i < ids.length; i++) {
            result[i] = nfts[ids[i]];
        }
        return result;
    }

    // Internal helper to remove NFT from previous owner's list
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