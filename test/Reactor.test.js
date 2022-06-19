// const { expect } = require("chai");
// const { constants, BigNumber, getDefaultProvider } = require("ethers");
// const { parseEther } = require("ethers/lib/utils");
// const { ethers } = require("hardhat");

// require('dotenv').config()

// const Provider = getDefaultProvider(process.env.HARDHAT_URL, '0bd316f234e14ba5a28d1dd10f415067')

// const abiERC20 = [
//   "function balanceOf(address owner) view returns (uint)",
//   "function approve(address spender, uint amount) public",
//   "function allowance(address owner, address spender) public view returns (uint)",
//   "function transfer(address dst, uint wad) public returns (bool)",
//   "function transferFrom(address src, address dst, uint wad) public returns (bool)",
// ]

// const ERC20 = new ethers.utils.Interface(abiERC20)


// describe("Reactor possibilities tests...", function () {
//   before(async () => {
//     this.signers = await ethers.getSigners()

//     this.account0 = await this.signers[0].getAddress();
//     this.account1 = await this.signers[1].getAddress();

//     // this.FeesCollector = await ethers.getContractFactory("FeesCollector");
//     // this.feesCollector = await this.FeesCollector.deploy(); // basefee / 4 (ETH:21_000 | AVAX:25_000)
//     // await this.feesCollector.deployed();
//     // console.log(`FeesCollector deployed to ${this.feesCollector.address}`)

//     this.Reactor = await ethers.getContractFactory("Reactor");
//     this.reactor = await this.Reactor.deploy();
//     await this.reactor.deployed();
//     console.log(`Reactor deployed to ${this.reactor.address}`)

//     this.SwapHelper = await ethers.getContractFactory("Catalyst_UniswapV2_SwapHelper");
//     this.swapHelper = await this.SwapHelper.deploy();
//     await this.swapHelper.deployed();
//     console.log(`SwapHelper deployed at: `, this.swapHelper.address)

//     this.LPHelper = await ethers.getContractFactory("Catalyst_UniswapV2_LiquidityHelper");
//     this.lpHelper = await this.LPHelper.deploy();
//     await this.lpHelper.deployed();
//     console.log(`LPHelper deployed at: `, this.lpHelper.address)

//     this.ChefHelper = await ethers.getContractFactory("Catalyst_MasterChef_Helper");
//     this.chefHelper = await this.ChefHelper.deploy();
//     await this.chefHelper.deployed();
//     console.log(`ChefHelper deployed at: `, this.chefHelper.address)


//   })

//   it("Should execute Reactions", async () => {

//     const WETH = new ethers.Contract(
//       process.env.WETH,
//       [
//         "function deposit() payable",
//         ...abiERC20
//       ],
//       Provider
//     )

//     // SEND ETH to Reactor
//     let tx = {
//       to: this.reactor.address,
//       // Convert currency unit from ether to wei
//       value: ethers.utils.parseEther('0.1')
//     }
//     tx = await this.signers[0].sendTransaction(tx)
//     await tx.wait()

//     const swapETHforWETH = [
//       WETH.address,
//       WETH.interface.encodeFunctionData("deposit"),
//       true,
//       false,
//       parseEther('0.01')
//     ]

//     // const UniswapV2Router = new ethers.utils.Interface(
//     //   [
//     //     "function swapExactTokensForTokens(uint amountIn,uint amountOutMin,address[] calldata path,address to,uint deadline) external returns (uint[] memory amounts)",
//     //     "function addLiquidity(address tokenA,address tokenB,uint amountADesired,uint amountBDesired,uint amountAMin,uint amountBMin,address to,uint deadline) external returns (uint amountA, uint amountB, uint liquidity)"
//     //   ]
//     // )

//     // const Masterchef = new ethers.utils.Interface([
//     //   "function deposit(uint256 pid, uint256 amount) public",
//     //   "function lpToken(uint256 pid) public returns (address pair)"
//     // ])

//     // const buildTokenSpendingApproval = (token, spender) => ([
//     //   token,
//     //   ERC20.encodeFunctionData("approve", [spender, constants.MaxUint256]),
//     //   true,
//     //   false,
//     //   constants.Zero
//     // ])

//     // const approveWETH = buildTokenSpendingApproval(process.env.WETH, process.env.SUSHI_ROUTER)
//     // const approveDAI = buildTokenSpendingApproval(process.env.DAI, process.env.SUSHI_ROUTER)
//     // const approveUSDC = buildTokenSpendingApproval(process.env.USDC, process.env.SUSHI_ROUTER)
//     // const approveLINK = buildTokenSpendingApproval(process.env.LINK, process.env.SUSHI_ROUTER)


//     // const approveWETH_DAI = buildTokenSpendingApproval(process.env.WETH_DAI, process.env.SUSHI_MASTERCHEF)
//     // const approveWETH_USDC = buildTokenSpendingApproval(process.env.WETH_USDC, process.env.SUSHI_MASTERCHEF)
//     // const approveWETH_LINK = buildTokenSpendingApproval(process.env.WETH_LINK, process.env.SUSHI_MASTERCHEF)

//     const buildSwapData = path => ([
//       this.swapHelper.address,
//       this.swapHelper.interface.encodeFunctionData("swap", [
//         [
//           process.env.SUSHI_ROUTER,
//           parseEther('0.001'),
//           parseEther('0.000000000000000001'),
//           path,
//           this.reactor.address,
//           Math.ceil(Date.now() / 1000)
//         ]
//       ]),
//       true,
//       true,
//       constants.Zero
//     ])

//     const swapWETHforDAI = buildSwapData([process.env.WETH, process.env.DAI])
//     const swapWETHforUSDC = buildSwapData([process.env.WETH, process.env.USDC])
//     const swapWETHforLINK = buildSwapData([process.env.WETH, process.env.LINK])

//     const buildDepositLiquidityData = (altToken, altAmount) => ([
//       this.lpHelper.address,
//       this.lpHelper.interface.encodeFunctionData("deposit", [
//         [
//           process.env.SUSHI_ROUTER,
//           process.env.WETH,
//           altToken,
//           constants.MaxUint256,
//           altAmount,
//           1,
//           1,
//           this.reactor.address,
//           Math.ceil(Date.now() / 1000)
//         ]
//       ]),
//       true,
//       true,
//       constants.Zero
//     ])
//     const addLiquidity_WETH_DAI = buildDepositLiquidityData(process.env.DAI, constants.MaxUint256)
//     const addLiquidity_WETH_USDC = buildDepositLiquidityData(process.env.USDC, constants.MaxUint256)
//     const addLiquidity_WETH_LINK = buildDepositLiquidityData(process.env.LINK, constants.MaxUint256)


//     const buildEnterFarm = (poolId, pairAddress) => ([
//       this.chefHelper.address,
//       this.chefHelper.interface.encodeFunctionData("enter", [
//         [
//           process.env.SUSHI_MASTERCHEF,
//           poolId,
//           pairAddress,
//           constants.MaxUint256
//         ]
//       ]),
//       true,
//       true,
//       constants.Zero
//     ])

//     const farmWETH_DAI = buildEnterFarm(2, process.env.WETH_DAI)
//     const farmWETH_USDC = buildEnterFarm(1, process.env.WETH_USDC)
//     const farmWETH_LINK = buildEnterFarm(8, process.env.WETH_LINK)

//     const ZapInFarm_WETH_DAI = [
//       [
//         swapWETHforDAI,
//         addLiquidity_WETH_DAI,
//         farmWETH_DAI
//       ],
//       false
//     ]

//     const ZapInFarm_WETH_USDC = [
//       [
//         swapWETHforUSDC,
//         addLiquidity_WETH_USDC,
//         farmWETH_USDC
//       ],
//       false
//     ]

//     const ZapInFarm_WETH_LINK = [
//       [
//         swapWETHforLINK,
//         addLiquidity_WETH_LINK,
//         farmWETH_LINK
//       ],
//       false
//     ]

//     // console.log("\n\nREACTOR executing the following operations:\n transfer WETH from wallet to Reactor\n approve spending of WETH by SushiSwap\n swaps for DAI\n swap WETH for USDC\n swap WETH for LINK\n")
//     console.log("\n\nThe below logs are all emitted by the Reactor smart contract:\n")
//     tx = await this.reactor.functions.executeReactions([
//       // Swap ETH for WETH
//       [
//         [
//           swapETHforWETH,
//         ],
//         true
//       ],
//       ZapInFarm_WETH_DAI,
//       ZapInFarm_WETH_USDC,
//       ZapInFarm_WETH_LINK,
//     ])
//     console.log("End of Reactor logs")

//   })
// });
