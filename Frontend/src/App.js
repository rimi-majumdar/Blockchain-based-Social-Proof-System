import React, { useState, useEffect } from "react";
import { ethers } from "ethers";
import axios from "axios";
import NFTArtMarketplaceArtifact from "./NFTArtMarketplace.json";
import './App.css';

const CONTRACT_ADDRESS = "0xfC5127f0709531D3A83bee5d6820d6aCEB5b09AC";

// Pinata API credentials (replace with your own or load from env securely)
const PINATA_API_KEY = "65e86cf4e4f45b3afcc5";
const PINATA_API_SECRET = "a821043cec0e7e04ca486608141730baf67f352a61008a686d6c1ac7c9c2e5eb";

function App() {
  const [provider, setProvider] = useState(null);
  const [signer, setSigner] = useState(null);
  const [contract, setContract] = useState(null);
  const [account, setAccount] = useState(null);
  const [nfts, setNfts] = useState([]);
  const [minting, setMinting] = useState(false);
  const [mintName, setMintName] = useState("");

  useEffect(() => {
    const init = async () => {
      if (!window.ethereum) {
        alert("Please install MetaMask to use this app");
        return;
      }

      const prov = new ethers.BrowserProvider(window.ethereum);
      setProvider(prov);

      // Check network
      const network = await prov.getNetwork();

      if (network.chainId !== 1114) {
        try {
          await window.ethereum.request({
            method: "wallet_switchEthereumChain",
            params: [{ chainId: "0x45a" }], // 1114 decimal = 0x45a hex
          });
          // Do NOT reload here — wait for chainChanged event instead
        } catch (switchError) {
          if (switchError.code === 4902) {
            alert("TCORE2 network is not added to your MetaMask. Please add it manually.");
          } else {
            alert("Network switch rejected or failed. Please switch to TCORE2 manually.");
          }
          console.error("Network switch error:", switchError);
          return;
        }
      }

      const accounts = await window.ethereum.request({ method: "eth_requestAccounts" });
      setAccount(accounts[0]);

      const sign = await prov.getSigner();
      setSigner(sign);

      const cont = new ethers.Contract(CONTRACT_ADDRESS, NFTArtMarketplaceArtifact.abi, sign);
      setContract(cont);
    };

    init();

    // Listen for network changes and reinitialize connection
    const handleChainChanged = (chainIdHex) => {
      console.log("Chain changed to", chainIdHex);
      // Re-run init to update connection info after network switch
      init();
    };

    window.ethereum?.on("chainChanged", handleChainChanged);

    // Cleanup event listener on component unmount
    return () => {
      window.ethereum?.removeListener("chainChanged", handleChainChanged);
    };
  }, []);

  useEffect(() => {
    if (contract && account) {
      fetchMyNFTs();
    }
  }, [contract, account]);

  async function fetchMyNFTs() {
    try {
      const rawNFTs = await contract.getNFTsByOwner(account);
      const mapped = rawNFTs.map((nft) => ({
        id: nft.id.toNumber ? nft.id.toNumber() : Number(nft.id),
        name: nft.name,
        metadata: nft.metadata,
        owner: nft.owner,
        price: ethers.formatEther(nft.price),
        forSale: nft.forSale,
      }));
      setNfts(mapped);
    } catch (error) {
      console.error("Failed to fetch NFTs:", error);
      setNfts([]);
    }
  }

  async function uploadToPinata(name) {
    const metadata = {
      name: name,
      description: `This is an NFT named ${name} created on NFTArtMarketplace.`,
      image: "https://via.placeholder.com/300.png?text=NFT",
      attributes: [
        { trait_type: "Artist", value: account },
        { trait_type: "Created At", value: new Date().toISOString() },
      ],
    };

    try {
      const res = await axios.post("https://api.pinata.cloud/pinning/pinJSONToIPFS", metadata, {
        headers: {
          pinata_api_key: PINATA_API_KEY,
          pinata_secret_api_key: PINATA_API_SECRET,
        },
      });
      return `ipfs://${res.data.IpfsHash}`;
    } catch (error) {
      console.error("Pinata upload failed:", error);
      throw error;
    }
  }

  async function mintNFT() {
    if (!mintName) {
      alert("Please enter a name for the NFT");
      return;
    }
    if (!contract) {
      alert("Contract not loaded");
      return;
    }

    setMinting(true);
    try {
      const metadataURI = await uploadToPinata(mintName);
      const tx = await contract.createNFT(mintName, metadataURI);
      await tx.wait();
      alert("NFT minted successfully!");
      setMintName("");
      fetchMyNFTs();
    } catch (error) {
      alert("Minting failed: " + (error?.message || error));
      console.error(error);
    }
    setMinting(false);
  }

  return (
    <div className="app-container" style={{ maxWidth: 700, margin: "auto", padding: 20 }}>
      <h1>NFT Art Marketplace</h1>
      <p>
        Connected account: <b>{account || "Not connected"}</b>
      </p>

      <section>
        <h2>Mint New NFT</h2>
        <input
          type="text"
          placeholder="Enter NFT name"
          value={mintName}
          onChange={(e) => setMintName(e.target.value)}
          disabled={minting}
          style={{ padding: 8, width: "100%", marginBottom: 12 }}
        />
        <button onClick={mintNFT} disabled={minting || !mintName}>
          {minting ? "Minting..." : "Mint NFT"}
        </button>
      </section>

      <section style={{ marginTop: 40 }}>
        <h2>My NFTs</h2>
        {nfts.length === 0 && <p>You don't own any NFTs yet.</p>}
        <ul>
          {nfts.map((nft) => (
            <li
              key={nft.id}
              style={{ marginBottom: 20, border: "1px solid #ccc", padding: 10 }}
            >
              <p>
                <b>ID:</b> {nft.id}
              </p>
              <p>
                <b>Name:</b> {nft.name}
              </p>
              <p>
                <b>Metadata URI:</b>{" "}
                <a
                  href={`https://ipfs.io/ipfs/${nft.metadata.replace("ipfs://", "")}`}
                  target="_blank"
                  rel="noreferrer"
                >
                  {nft.metadata}
                </a>
              </p>
              <p>
                <b>Owner:</b> {nft.owner}
              </p>
              <p>
                <b>Price:</b> {nft.price} ETH
              </p>
              <p>
                <b>For Sale:</b> {nft.forSale ? "Yes" : "No"}
              </p>
            </li>
          ))}
        </ul>
      </section>
    </div>
  );
}

export default App;
