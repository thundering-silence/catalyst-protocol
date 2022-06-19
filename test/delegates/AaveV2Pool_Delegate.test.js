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
    "function deposit() public;",
    "function withdraw() public",
    ...abiERC20,
]
const WRAPPED_NATIVE = new ethers.utils.Interface(abiWrappedNative)

const AAVE_V2 = {
    controller: '0x76cc67FF2CC77821A70ED14321111Ce381C2594D',
    incentives: '0x58Cd851c28dF05Edc7F018B533C0257DE57673f7'
}

const WAVAX = '0xd00ae08403b9bbb9124bb305c09058e32c39a48c'
// const aWAVAX = '0xA79570641bC9cbc6522aA80E2de03bF9F7fd123a'

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
