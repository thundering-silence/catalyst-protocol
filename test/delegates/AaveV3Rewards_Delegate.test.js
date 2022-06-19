const { expect } = require("chai");
const { constants, BigNumber, getDefaultProvider } = require("ethers");
const { parseEther } = require("ethers/lib/utils");
const { ethers } = require("hardhat");
const { isCallTrace } = require("hardhat/internal/hardhat-network/stack-traces/message-trace");

require('dotenv').config()

const Provider = getDefaultProvider(process.env.HARDHAT_URL, '0bd316f234e14ba5a28d1dd10f415067')

const abiERC20 = [
    "function balanceOf(address owner) view returns (uint)",
    "function approve(address spender, uint amount) public",
    "function allowance(address owner, address spender) public view returns (uint)",
    "function transfer(address dst, uint wad) public returns (bool)",
    "function transferFrom(address src, address dst, uint wad) public returns (bool)",
]

const ERC20 = new ethers.utils.Interface(abiERC20)

const AAVE_V3 = {
    controller: '0xb47673b7a73D78743AFF1487AF69dBB5763F00cA',
    incentives: '0x58Cd851c28dF05Edc7F018B533C0257DE57673f7'
}

const USDC = '0x3E937B4881CBd500d05EeDAB7BA203f2b7B3f74f'
const aUSDC = '0xA79570641bC9cbc6522aA80E2de03bF9F7fd123a'

describe("AaveV3Rewards:", function () {
    before(async () => {
        this.signers = await ethers.getSigners()
        this.account0 = await this.signers[0].getAddress();

        this.factory = await ethers.getContractFactory('Catalyst_AaveV3Pool_Delegate');
        this.controllerDelegate = await this.factory.deploy();
        await this.controllerDelegate.deployed()

        this.factory = await ethers.getContractFactory('Catalyst_AaveV3Rewards_Delegate');
        this.rewardsDelegate = await this.factory.deploy();
        await this.rewardsDelegate.deployed()

        this.USDC = new ethers.Contract(
            USDC, ERC20, this.signers[0]
        )

        this.DEPOSIT_AMOUNT = BigNumber.from('1000000');

        this.aUSDC = new ethers.Contract(aUSDC, abiERC20, Provider);

        this.controllerDelegate.functions.enter(
            AAVE_V3.controller,
            USDC,
            this.DEPOSIT_AMOUNT
        )
    })

    // TODO
    // it("Should have a `harvestRewards` method that pulls rewards", async () => {
    //     this.rewardsDelegate.functions.harvestRewards(
    //         AAVE_V3.incentives,
    //         USDC
    //     )
    // })

})
