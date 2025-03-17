// SPDX-License-Identifier: MIT  // or any other open-source license you prefer
pragma solidity ^0.8.9;

contract NFTArtMarketplace {
    
}

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
    mapping(uint => NFT) public nfts;
    
    event NFTCreated(uint id, string name, address owner);
    event NFTSold(uint id, address newOwner, uint price);
    event NFTListed(uint id, uint price);
    event NFTDelisted(uint id);
    
    function createNFT(string memory name, string memory metadata) public {
        nfts[nextId] = NFT(nextId, name, metadata, msg.sender, 0, false);
        emit NFTCreated(nextId, name, msg.sender);
        nextId++;
    }
    
    function listNFT(uint id, uint price) public {
        require(nfts[id].owner == msg.sender, "Not the owner");
        require(price > 0, "Price must be greater than zero");
        nfts[id].price = price;
        nfts[id].forSale = true;
        emit NFTListed(id, price);
    }
    
    function delistNFT(uint id) public {
        require(nfts[id].owner == msg.sender, "Not the owner");
        nfts[id].forSale = false;
        emit NFTDelisted(id);
    }
    
    function buyNFT(uint id) public payable {
        require(nfts[id].forSale, "NFT not for sale");
        require(msg.value >= nfts[id].price, "Insufficient funds");
        
        address previousOwner = nfts[id].owner;
        nfts[id].owner = msg.sender;
        nfts[id].forSale = false;
        
        payable(previousOwner).transfer(msg.value);
        emit NFTSold(id, msg.sender, msg.value);
    }
}
