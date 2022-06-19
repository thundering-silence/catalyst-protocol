const { expect } = require("chai");
const { constants, BigNumber } = require("ethers");
const { ethers } = require("hardhat");

require('dotenv').config()

const abiERC20 = [
    "function balanceOf(address owner) view returns (uint)",
    "function approve(address spender, uint amount) ",
    "function allowance(address owner, address spender) public view returns (uint)",
    "function transfer(address dst, uint wad) public returns (bool)",
    "function transferFrom(address src, address dst, uint wad) public returns (bool)",
]

const abiWrappedNative = [
    "function deposit();",
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

const AAVE_V3 = {
    controller: '0x794a61358D6845594F94dc1DB02A252b5b4814aD',
    incentives: '0x929EC64c34a17401F460460D4B9390518E5B473e',
    aWAVAX: '0x6d80113e533a2C0fe82EaBD35f1875DcEA89Ea97'
}


const delegates = [
    "Catalyst_AaveV2Pool_Delegate",
    "Catalyst_AaveV2Rewards_Delegate",
    "Catalyst_AaveV3Pool_Delegate",
    "Catalyst_AaveV3Rewards_Delegate",
]

describe("SinglePoolSingleAssetStrategy", function () {
    before(async () => {
        this.signers = await ethers.getSigners()
        this.account0 = await this.signers[0].getAddress();

        await Promise.all(delegates.map(
            async contract => {
                this[contract] = await ethers.getContractFactory(contract);
                this[contract.toLowerCase()] = await this[contract].deploy();
                await this[contract.toLowerCase()].deployed()
            }
        ))

        this.Collector = await ethers.getContractFactory("FeesCollector")
        this.collector = await this.Collector.deploy()

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

        this.Sas;
        this.sas;
    })

    it("should be deployable", async () => {
        this.Sas = await ethers.getContractFactory("SinglePoolSingleAssetStrategy");
        this.sas = await this.Sas.deploy(
            WAVAX,
            'WAVAX SinglePoolSingleAssetStrategy',
            'myWAVAX SPSA',
            this.collector.address,
            constants.AddressZero,
            [
                AAVE_V2.controller,
                AAVE_V3.controller,
            ],
            [
                [
                    this.catalyst_aavev2pool_delegate.address,
                    this.catalyst_aavev2rewards_delegate.address,
                    this.catalyst_aavev2rewards_delegate.interface.encodeFunctionData("harvestRewards", [
                        constants.AddressZero,
                        [],
                    ])
                ],
                [
                    this.catalyst_aavev3pool_delegate.address,
                    this.catalyst_aavev3rewards_delegate.address,
                    this.catalyst_aavev3rewards_delegate.interface.encodeFunctionData("harvestRewards", [
                        AAVE_V3.incentives,
                        [AAVE_V3.aWAVAX],
                    ])
                ]
            ]
        )
        console.log(`Strategy deployed to ${this.sas.address}`);
        expect(this.sas.address).to.not.be.undefined;
    })

    it("should mint tokens and charge a fee when joining", async () => {
        const approveSpendingBySas = [
            this.WAVAX.address,
            this.WAVAX.interface.encodeFunctionData("approve", [
                this.sas.address,
                this.DEPOSIT_AMOUNT
            ]),
            constants.Zero,
            false,
            true
        ]
        const joinStrategy = [
            this.sas.address,
            this.sas.interface.encodeFunctionData("join", [
                this.DEPOSIT_AMOUNT
            ]),
            constants.Zero,
            false,
            true,
        ]

        const reaction = [
            [
                approveSpendingBySas,
                joinStrategy
            ],
            true
        ]

        await this.reactor.functions.executeReactions(
            [
                reaction,
            ],
            {
                gasLimit: 3000000
            }
        )

        const WAVAXBalance = await this.WAVAX.functions.balanceOf(this.reactor.address);
        expect(WAVAXBalance[0].eq(constants.Zero)).to.be.true;

        const fees = await this.WAVAX.functions.balanceOf(this.collector.address)
        const fee = this.DEPOSIT_AMOUNT.div(BigNumber.from(1000))
        expect(fees[0].eq(fee)).to.be.true;

        const shares = await this.sas.functions.balanceOf(this.reactor.address);
        expect(shares[0].eq(this.DEPOSIT_AMOUNT.sub(fee))).to.be.true;
    })

    it("should deposit funds into a pool when reallocating", async () => {
        const allocateToAaveV3 = [
            this.sas.address,
            this.sas.interface.encodeFunctionData("reallocate", [AAVE_V3.controller]),
            constants.Zero,
            false,
            true
        ]

        const reaction = [
            [
                allocateToAaveV3,
            ],
            true
        ]

        await this.reactor.functions.executeReactions(
            [
                reaction
            ],
            {
                gasLimit: 30000000
            }
        )

        const WAVAXBalance = await this.WAVAX.functions.balanceOf(this.sas.address);
        expect(WAVAXBalance[0].eq(constants.Zero)).to.be.true;
    })

    it("should allow reallocating to the same pool", async () => {
        const allocateToAaveV3 = [
            this.sas.address,
            this.sas.interface.encodeFunctionData("reallocate", [AAVE_V3.controller]),
            constants.Zero,
            false,
            true
        ]

        const reaction = [
            [
                allocateToAaveV3,
            ],
            true
        ]

        await this.reactor.functions.executeReactions(
            [
                reaction
            ],
            {
                gasLimit: 30000000
            }
        )
        const WAVAXBalance = await this.WAVAX.functions.balanceOf(this.sas.address);
        expect(WAVAXBalance[0].eq(constants.Zero)).to.be.true;
    })

    it("should allow reallocating to a different pool", async () => {
        const allocateToAaveV2 = [
            this.sas.address,
            this.sas.interface.encodeFunctionData("reallocate", [AAVE_V2.controller]),
            constants.Zero,
            false,
            true
        ]

        const reaction = [
            [
                allocateToAaveV2,
            ],
            true
        ]

        await this.reactor.functions.executeReactions(
            [
                reaction
            ],
            {
                gasLimit: 30000000
            }
        )
        const WAVAXBalance = await this.WAVAX.functions.balanceOf(this.sas.address);
        expect(WAVAXBalance[0].eq(constants.Zero)).to.be.true;
    })

    it("should allow reallocating to the same pool", async () => {
        const allocateToAaveV2 = [
            this.sas.address,
            this.sas.interface.encodeFunctionData("reallocate", [AAVE_V2.controller]),
            constants.Zero,
            false,
            true
        ]

        const reaction = [
            [
                allocateToAaveV2,
            ],
            true
        ]

        await this.reactor.functions.executeReactions(
            [
                reaction
            ],
            {
                gasLimit: 30000000
            }
        )
        const WAVAXBalance = await this.WAVAX.functions.balanceOf(this.sas.address);
        expect(WAVAXBalance[0].eq(constants.Zero)).to.be.true;
    })

    it("should remove from strategy the", async () => {
        const shares = await this.sas.balanceOf(this.reactor.address)
        const exitStrategy = [
            this.sas.address,
            this.sas.interface.encodeFunctionData("leave", [
                shares.div(BigNumber.from(10))
            ]),
            constants.Zero,
            false,
            true,
        ]

        const reaction = [
            [
                exitStrategy
            ],
            true
        ]

        await this.reactor.functions.executeReactions(
            [
                reaction,
            ],
            {
                gasLimit: 3000000
            }
        )

        const WAVAXBalance = await this.WAVAX.functions.balanceOf(this.reactor.address);
        expect(WAVAXBalance[0].gt(shares.div(BigNumber.from(10)))).to.be.true;
    })

});
