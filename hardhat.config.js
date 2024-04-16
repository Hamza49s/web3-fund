
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
      url: "https://eth-sepolia.g.alchemy.com/v2/Jj_luMlU_qU-AE5UHvF9pngQFbw6s8wm",
      accounts: ["c359eec1563db748a9681cfbd2ba2408b28188f52d2cab9f23b688ebf688e47a"],
    },
  },
  etherscan: {
    apiKey: "NV774QI9Q8UYWC2URUCGNXC86ENAG2HXSA",
  },
};

// npx hardhat ignition deploy ignition / modules / Lock.js--network sepolia

