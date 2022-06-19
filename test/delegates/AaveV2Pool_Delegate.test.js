const { expect } = require("chai");
const { constants, BigNumber, getDefaultProvider } = require("ethers");
const { parseEther } = require("ethers/lib/utils");
const { ethers } = require("hardhat");
const { isCallTrace } = require("hardhat/internal/hardhat-network/stack-traces/message-trace");

require('dotenv').config()

const Provider = getDefaultProvider(process.env.HARDHAT_URL, '0bd316f234e14ba5a28d1dd10f415067')

const abiERC20 = [
    "function balanceOf(address owner) returns (uint)",
    "function approve(address spender, uint amount)",
    "function allowance(address owner, address spender) returns (uint)",
    "function transfer(address dst, uint wad) returns (bool)",
    "function transferFrom(address src, address dst, uint wad) returns (bool)",
]

const ERC20 = new ethers.utils.Interface(abiERC20)

const abiWrappedNative = [
    "function deposit()",
    "function withdraw()",
    ...abiERC20,
]
const WRAPPED_NATIVE = new ethers.utils.Interface(abiWrappedNative)

const WAVAX = '0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7'

const AAVE_V2 = {
    controller: '0x4F01AeD16D97E3aB5ab2B501154DC9bb0F1A5A2C',
    incentives: '0x01D83Fe6A10D2f2B7AF17034343746188272cAc9',
    aWAVAX: '0xDFE521292EcE2A4f44242efBcD66Bc594CA9714B',
}

describe("AaveV2Delegate:", function () {
    before(async () => {
        this.signers = await ethers.getSigners()
        this.account0 = await this.signers[0].getAddress();

        this.factory = await ethers.getContractFactory('Catalyst_AaveV2Pool_Delegate');
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
        const enterAaveV2 = [
            this.contract.address,
            this.contract.interface.encodeFunctionData("enter", [
                AAVE_V2.controller,
                WAVAX,
                this.DEPOSIT_AMOUNT
            ]),
            constants.Zero,
            true,
            true,
        ]
        const reaction0 = [
            [
                enterAaveV2
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

        const WAVAXBalance = await this.WAVAX.functions.balanceOf(this.reactor.address)
        expect(WAVAXBalance[0].eq(BigNumber.from(0))).to.be.true;
    })


    it("should have a `exit` method that withdraws from the pool", async () => {
        const exitAaveV2 = [
            this.contract.address,
            this.contract.interface.encodeFunctionData("exit", [
                AAVE_V2.controller,
                WAVAX,
                constants.MaxUint256
            ]),
            constants.Zero,
            true,
            true,
        ]
        const reaction0 = [
            [
                exitAaveV2
            ],
            true
        ]

        const tx = await this.reactor.functions.executeReactions(
            [
                reaction0,
            ],
            {
                gasLimit: 3000000
            }
        )

        const res = await tx.wait()


        const WAVAXBalance = await this.WAVAX.functions.balanceOf(this.reactor.address)
        expect(WAVAXBalance[0].gt(this.DEPOSIT_AMOUNT)).to.be.true;
    })
})
