require("dotenv").config();
require("@nomicfoundation/hardhat-toolbox");

module.exports = {
  solidity: "0.8.28", // ✅ Change to match your contract's Solidity version
  networks: {
    amoy: {
      url: "https://rpc-amoy.polygon.technology",
      accounts: [`0x${process.env.PRIVATE_KEY}`],
      chainId: 80002,
    },
  },
};
