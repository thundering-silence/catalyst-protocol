const { BigNumber, constants } = require("ethers");

require("dotenv").config();

require("@nomiclabs/hardhat-etherscan");
require("@nomiclabs/hardhat-waffle");
require("hardhat-gas-reporter");
require("solidity-coverage");

// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html
task("accounts", "Prints the list of accounts", async (taskArgs, hre) => {
  const accounts = await hre.ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
  }
});

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

const hardhat = {
  forking: {
    url: process.env.HARDHAT_URL || "",
    block: 16196784,
  },
  // accounts: [{
  //   privateKey: process.env.PRIVATE_KEY_TEST,
  //   balance: BigNumber.from(6).mul(constants.WeiPerEther).toString()
  // }],
  chainId: 43113
}

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  solidity: "0.8.13",
  defaultNetwork: "hardhat",
  networks: {
    hardhat: hardhat,
    // kovan: {
    //   url: process.env.HARDHAT_URL,
    //   accounts:
    //     process.env.PRIVATE_KEY_TEST !== undefined ? [process.env.PRIVATE_KEY_TEST] : [],
    // },
    // ropsten: {
    //   url: process.env.ROPSTEN_URL || "",
    //   accounts:
    //     process.env.PRIVATE_KEY0 !== undefined ? [process.env.PRIVATE_KEY0] : [],
    // },
  },
  gasReporter: {
    enabled: process.env.REPORT_GAS !== undefined,
    currency: "USD",
  },
  etherscan: {
    apiKey: process.env.ETHERSCAN_API_KEY,
  },
};
