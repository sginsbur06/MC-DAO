require("@nomiclabs/hardhat-waffle");
require("hardhat-deploy");
require("hardhat-deploy-ethers");
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

/**
 * @type import('hardhat/config').HardhatUserConfig
 */

const RINKEBY_PRIVATE_KEY = "dd107db8a19fff5dd53547f2cddfa508ef6da92d8d7d0043c96ab774d2b17180";

module.exports = {
  solidity: "0.8.10",
  networks: {
    rinkeby: {
      url: `https://rinkeby.infura.io/v3/77e83ffe24944208a1ec8be0af64d2e6`,
      accounts: [`${RINKEBY_PRIVATE_KEY}`]
    }
  }
};