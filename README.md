NFT Art Marketplace
A decentralized NFT marketplace where users can mint, list, and buy NFTs securely on the blockchain.

Table of Contents
About the Project

Features

Tech Stack

Getting Started

Usage

Folder Structure

Contributing

License

About the Project
NFT Art Marketplace is a React-based web application integrated with an Ethereum-compatible blockchain smart contract to allow users to mint their own NFTs, list them for sale, and purchase NFTs from other users. The metadata for NFTs is stored on IPFS using Pinata for decentralized storage.

Features
Connect your Ethereum wallet (MetaMask)

Mint new NFTs with custom metadata

View owned NFTs with detailed info

List owned NFTs for sale at desired prices

Browse marketplace listings of NFTs for sale

Purchase NFTs directly from the marketplace

Tech Stack
Frontend: React, ethers.js, Axios

Smart Contract: Solidity (NFTArtMarketplace contract)

Storage: IPFS via Pinata API

Blockchain Network: TCORE2 Testnet (chainId: 1114)

Getting Started
Prerequisites
Node.js (v16+) and npm installed

MetaMask wallet extension installed in your browser

Access to TCORE2 testnet configured in MetaMask

Installation
Clone the repository:

bash
Copy
Edit
git clone https://github.com/your-username/nft-art-marketplace.git
cd nft-art-marketplace
Install dependencies:

bash
Copy
Edit
npm install
Create a .env file and add your Pinata API credentials:

env
Copy
Edit
REACT_APP_PINATA_API_KEY=your_pinata_api_key
REACT_APP_PINATA_API_SECRET=your_pinata_api_secret
Start the development server:

bash
Copy
Edit
npm start
Open http://localhost:3000 in your browser and connect your wallet.

Usage
Mint NFT: Enter a name and click "Mint NFT" to create a new NFT.

My NFTs: View all NFTs you own. For NFTs not for sale, enter a price and click "List for Sale".

Marketplace: Browse and buy NFTs currently listed for sale.

