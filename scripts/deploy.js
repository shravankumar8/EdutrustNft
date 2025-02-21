require("dotenv").config();
const { ethers } = require("hardhat");

async function main() {
  const [deployer] = await ethers.getSigners(); // Get deployer wallet address

  console.log("Deploying contract with account:", deployer.address);

  // Check deployer balance
  const balance = await ethers.provider.getBalance(deployer.address);
  console.log("Deployer balance:", ethers.formatEther(balance), "MATIC");

  if (balance === 0n) {
    throw new Error("❌ Insufficient funds! Add MATIC to your wallet.");
  }

  const CredentialNFT = await ethers.getContractFactory("CredentialNFT");

  // Deploy the contract (no arguments needed)
  const contract = await CredentialNFT.deploy();

  // Wait for deployment (ethers v6)
  await contract.waitForDeployment();
  console.log("✅ CredentialNFT deployed to:", contract.target); // Ethers v6: use `target`
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
