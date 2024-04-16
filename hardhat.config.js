
require("dotenv").config();
require("@nomicfoundation/hardhat-toolbox");
require('@openzeppelin/hardhat-upgrades');
module.exports = {
  solidity: {
    compilers: [
      {
        version: "0.8.24",
        settings: {
          "viaIR": true,
          optimizer: {
            enabled: true,
            runs: 100,
            "details": {
              "yulDetails": {
                "optimizerSteps": "u"
              }
            }

          },
        },
      },
      {
        version: "0.8.7",
        settings: {
          "viaIR": true,
          optimizer: {
            enabled: true,
            runs: 200,
            "details": {
              "yulDetails": {
                "optimizerSteps": "u"
              }
            }

          },
        },
      },
      {
        version: "0.8.8",
        settings: {
          // "viaIR": true,
          optimizer: {
            enabled: true,
            runs: 200,
            // "details": {
            //   "yulDetails": {
            //     "optimizerSteps": "u"
            //   }
            // }

          },
        },
      },
    ],
  },
  networks: {
   
    sepolia: {
      url: "",
      accounts: [],
    },
  },
  etherscan: {
    apiKey: "",
  },
};

// npx hardhat ignition deploy ignition / modules / Lock.js--network sepolia

