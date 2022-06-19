// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const { BigNumber } = require("ethers");
const { ethers } = require("hardhat");
const hre = require("hardhat");

async function main() {
    // Hardhat always runs the compile task when running scripts with its command
    // line interface.
    //
    // If this script is run directly using `node` you may want to call compile
    // manually to make sure everything is compiled
    // await hre.run('compile');

    const signers = await ethers.getSigners()

    // We get the contract to deploy
    const Masterchef = new ethers.Contract(
        // 0xEF0881eC094552b2e128Cf945EF17a6752B4Ec5d, // V2
        '0xc2EdaD668740f1aA35E4D8f227fB8E17dcA888Cd', // V1
        [
            "function deposit(uint256 pid, uint256 amount) external",
            "function lpToken(uint256 pid) public returns (address pair)",
            "function poolInfo(uint256 id) public returns (address, uint256, uint256, uint256)",
        ],
        signers[0]
    )

    const a = await Promise.all(Array(354).fill('').map(async (e, index) => {
        if (index != 0) return;
        console.log(index)
        const res = await Masterchef.functions.poolInfo(index);
        console.log(res[0])
    }))

}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
