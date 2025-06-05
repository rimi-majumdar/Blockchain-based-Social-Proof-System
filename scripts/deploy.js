const hre = require("hardhat");

async function main() {
  await hre.run('compile');

  const NFTArtMarketplace = await hre.ethers.getContractFactory("NFTArtMarketplace");

  // Deploy contract - this returns the deployed contract instance after deployment
  const marketplace = await NFTArtMarketplace.deploy();

  // No need to await marketplace.deployed() in ethers v6

  console.log("NFTArtMarketplace deployed to:", marketplace.target || marketplace.address);
  // marketplace.target is the new property for contract address in ethers v6
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});