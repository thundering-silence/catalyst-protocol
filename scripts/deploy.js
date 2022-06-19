// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const hre = require("hardhat");
const { ethers } = require('hardhat')

async function main() {
    this.signers = await ethers.getSigners()

    this.account0 = await this.signers[0].getAddress();

    this.FeesCollector = await ethers.getContractFactory("FeesCollector");
    this.feesCollector = await this.FeesCollector.deploy(); // basefee / 4 (ETH:21_000 | AVAX:25_000)
    await this.feesCollector.deployed();
    console.log(`FeesCollector deployed to ${this.feesCollector.address}`)

    this.Reactor = await ethers.getContractFactory("Reactor");
    this.reactor = await this.Reactor.deploy();
    await this.reactor.deployed();
    console.log(`Reactor deployed to ${this.reactor.address}`)

    this.SwapHelper = await ethers.getContractFactory("Catalyst_UniswapV2_SwapHelper");
    this.swapHelper = await this.SwapHelper.deploy();
    await this.swapHelper.deployed();
    console.log(`SwapHelper deployed at: `, this.swapHelper.address)

    this.LPHelper = await ethers.getContractFactory("Catalyst_UniswapV2_LiquidityHelper");
    this.lpHelper = await this.LPHelper.deploy();
    await this.lpHelper.deployed();
    console.log(`LPHelper deployed at: `, this.lpHelper.address)

    this.ChefHelper = await ethers.getContractFactory("Catalyst_MasterChef_Helper");
    this.chefHelper = await this.ChefHelper.deploy();
    await this.chefHelper.deployed();
    console.log(`ChefHelper deployed at: `, this.chefHelper.address)
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
