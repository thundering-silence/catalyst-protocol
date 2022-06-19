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

const abiWrappedNative = [
    "function deposit();",
    "function withdraw()",
    ...abiERC20,
]
const WRAPPED_NATIVE = new ethers.utils.Interface(abiWrappedNative)

const AAVE_V3 = {
    controller: '0x794a61358D6845594F94dc1DB02A252b5b4814aD',
    incentives: '0x929EC64c34a17401F460460D4B9390518E5B473e'
}

const WAVAX = '0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7'
const aWAVAX = '0x6d80113e533a2C0fe82EaBD35f1875DcEA89Ea97'

describe("AaveV3Delegate:", function () {
    before(async () => {
        this.signers = await ethers.getSigners()
        this.account0 = await this.signers[0].getAddress();

        this.factory = await ethers.getContractFactory('Catalyst_AaveV3Pool_Delegate');
        this.contract = await this.factory.deploy();
        await this.contract.deployed()

        this.Reactor = await ethers.getContractFactory("Reactor");
        this.reactor = await this.Reactor.deploy();
        await this.reactor.deployed();

        this.DEPOSIT_AMOUNT = constants.WeiPerEther;

        this.WAVAX = new ethers.Contract(
            WAVAX, WRAPPED_NATIVE, this.signers[0]
        )
        // wrap AVAX
        const wrapAVAX = {
            from: this.account0,
            to: WAVAX,
            value: this.DEPOSIT_AMOUNT
        }
        await this.signers[0].sendTransaction(wrapAVAX);

        // transfer WAVAX to reactor
        await this.WAVAX.transfer(
            this.reactor.address,
            this.DEPOSIT_AMOUNT
        )

    })

    it("Should have a `enter` method that deposits into the pool", async () => {
        const enterAaveV3 = [
            this.contract.address,
            this.contract.interface.encodeFunctionData("enter", [
                AAVE_V3.controller,
                WAVAX,
                this.DEPOSIT_AMOUNT
            ]),
            constants.Zero,
            true,
            true,
        ]
        const reaction0 = [
            [
                enterAaveV3
            ],
            true
        ]

        await this.reactor.functions.executeReactions(
            [
                reaction0,
            ],
            {
                gasLimit: 3000000
            }
        )

        const balance = await this.WAVAX.functions.balanceOf(this.reactor.address)
        expect(balance[0].eq(BigNumber.from(0))).to.be.true;
    })


    it("should have a `exit` method that withdraws from the pool", async () => {
        const exitAaveV3 = [
            this.contract.address,
            this.contract.interface.encodeFunctionData("exit", [
                AAVE_V3.controller,
                WAVAX,
                constants.MaxUint256
            ]),
            constants.Zero,
            true,
            true,
        ]
        const reaction0 = [
            [
                exitAaveV3
            ],
            true
        ]

        await this.reactor.functions.executeReactions(
            [
                reaction0,
            ],
            {
                gasLimit: 3000000
            }
        )

        const balance = await this.WAVAX.functions.balanceOf(this.reactor.address)
        expect(balance[0].gte(this.DEPOSIT_AMOUNT)).to.be.true;
    })
})
