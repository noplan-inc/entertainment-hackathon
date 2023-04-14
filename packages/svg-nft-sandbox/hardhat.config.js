require("@nomicfoundation/hardhat-toolbox");
require("@nomicfoundation/hardhat-chai-matchers")
require("@nomiclabs/hardhat-etherscan");
require('dotenv').config();

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: {
    version: "0.8.18",
    settings: {
      viaIR: true,
      optimizer: {
        enabled: true,
        details: {
          yulDetails: {
            optimizerSteps: "u:",
          },
        },
      },
    },
  },
  defaultNetwork: "hardhat",
  mocha: {
    timeout: 100000000
  },
  networks: {
    hardhat: {},
    mumbai: {
      url: process.env.POLYGON_MUMBAI_URL || "",
      accounts:
        {
          mnemonic: process.env.PRIVATE_KEY !== undefined ? process.env.PRIVATE_KEY : '',
        },
      // etherscan: {
      //   apiKey: process.env.POLYGON_API_KEY,
      // },
    },
    goerli: {
      url: process.env.GOERLI_URL || "",
      accounts:
        {
          mnemonic: process.env.PRIVATE_KEY !== undefined ? process.env.PRIVATE_KEY : '',
        },
    },
  },
  etherscan: {
    apiKey: {
      polygonMumbai: process.env.POLYGON_API_KEY || "",
      goerli: process.env.GOERLI_API_KEY || "",
    },
    url: process.env.POLYGON_MUMBAI_URL || "",
    // apiKey: process.env.POLYGON_API_KEY,
  },
};
