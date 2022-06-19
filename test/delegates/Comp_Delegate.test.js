// const { expect } = require("chai");
// const { constants, BigNumber, getDefaultProvider } = require("ethers");
// const { parseEther } = require("ethers/lib/utils");
// const { ethers } = require("hardhat");

// require('dotenv').config()

// const Provider = getDefaultProvider(process.env.HARDHAT_URL, '0bd316f234e14ba5a28d1dd10f415067')

// const abiERC20 = [
//     "function balanceOf(address owner) view returns (uint)",
//     "function approve(address spender, uint amount) public",
//     "function allowance(address owner, address spender) public view returns (uint)",
//     "function transfer(address dst, uint wad) public returns (bool)",
//     "function transferFrom(address src, address dst, uint wad) public returns (bool)",
// ]
// const ERC20 = new ethers.utils.Interface(abiERC20)

// const abiWrappedNative = [
//     "function deposit() public;",
//     "function withdraw() public",
//     ...abiERC20,
// ]
// const WRAPPED_NATIVE = new ethers.utils.Interface(abiWrappedNative)

// const JOE = {
//     controller: '0x6E9603f925FB5A74f7321f51499d9633c1252893',
//     incentives: '0xe6CBCC8589ddDC61083831907b6599ac62EceF5D'
// }

// const WAVAX = '0xd00ae08403b9bbb9124bb305c09058e32c39a48c'
// const jAVAX = '0xE2b2CF0Cc751223C4F2Dc9EF1Cd8d2F27f92a84a'

// describe("CompDelegate:", function () {
//     before(async () => {
//         this.signers = await ethers.getSigners()
//         this.account0 = await this.signers[0].getAddress();
//         console.log(this.account0)

//         this.factory = await ethers.getContractFactory('Catalyst_CompPool_Delegate');
//         this.contract = await this.factory.deploy();
//         await this.contract.deployed()
//         console.log(`Comp Delgate deployed to ${this.contract.address}`)

//         this.Reactor = await ethers.getContractFactory("Reactor");
//         this.reactor = await this.Reactor.deploy();
//         await this.reactor.deployed();
//         console.log(`Reactor deployed to ${this.reactor.address}`)

//         this.WAVAX = new ethers.Contract(
//             WAVAX, WRAPPED_NATIVE, this.signers[0]
//         )
//         // wrap AVAX
//         const wrapAVAX = {
//             from: this.account0,
//             to: WAVAX,
//             value: BigNumber.from(1).mul(constants.WeiPerEther),
//         }
//         await this.signers[0].sendTransaction(wrapAVAX);

//         // transfer WAVAX to reactor
//         await this.WAVAX.transfer(
//             this.reactor.address,
//             BigNumber.from(1).mul(constants.WeiPerEther)
//         )

//         this.DEPOSIT_AMOUNT = BigNumber.from(1).mul(constants.WeiPerEther);

//     })

//     it("Should have a `enter` method that deposits into the pool", async () => {
//         const enterJoe = [
//             this.contract.address,
//             this.contract.interface.encodeFunctionData("enter", [
//                 jAVAX,
//                 WAVAX,
//                 this.DEPOSIT_AMOUNT
//             ]),
//             constants.Zero,
//             true,
//             true,
//         ]
//         const reaction0 = [
//             [
//                 enterJoe
//             ],
//             true
//         ]

//         const tx = await this.reactor.functions.executeReactions(
//             [
//                 reaction0,
//             ],
//             {
//                 gasLimit: 3000000
//             }
//         )

//         const res = await tx.wait()
//         // console.log(res.events)

//         const WAVAXBalance = await this.WAVAX.functions.balanceOf(this.reactor.address)
//         // const aUSDCBalance = await this.aUSDC.functions.balanceOf(this.reactor.address)
//         // console.log(aUSDCBalance)
//         expect(WAVAXBalance[0].eq(BigNumber.from(0))).to.be.true;
//     })


//     it("should have a `exit` method that withdraws from the pool", async () => {
//         const exitJoe = [
//             this.contract.address,
//             this.contract.interface.encodeFunctionData("exit", [
//                 jAVAX,
//                 WAVAX,
//                 constants.MaxUint256
//             ]),
//             constants.Zero,
//             true,
//             true,
//         ]
//         const reaction0 = [
//             [
//                 exitJoe
//             ],
//             true
//         ]

//         const tx = await this.reactor.functions.executeReactions(
//             [
//                 reaction0,
//             ],
//             {
//                 gasLimit: 3000000
//             }
//         )

//         const res = await tx.wait()

//         const WAVAXBalance = await this.WAVAX.functions.balanceOf(this.reactor.address)
//         console.log(WAVAXBalance)
//         // const aUSDCBalance = await this.aUSDC.functions.balanceOf(this.reactor.address)
//         // console.log(aUSDCBalance)
//         expect(WAVAXBalance[0].gt(this.DEPOSIT_AMOUNT)).to.be.true;
//     })
// })
