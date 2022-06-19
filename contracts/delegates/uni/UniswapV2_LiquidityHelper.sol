pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../../libraries/LibSpendingApproval.sol";
import "../../interfaces/third-party/UniswapV2/IUniswapV2Router02.sol";

import "hardhat/console.sol";

/**
 * @notice This logic provides liquidity to UniswapV2 forks' Liquidity Pools
 * @dev This contract is built to be called with `delegatecall`
 * @author Catalyst
 */
contract Catalyst_UniswapV2_LiquidityHelper {
    using SafeERC20 for IERC20;
    using LibSpendingApproval for address;

    struct DepositParams {
        IUniswapV2Router02 router;
        IERC20 tokenA;
        IERC20 tokenB;
        uint256 amountADesired;
        uint256 amountBDesired;
        uint256 amountAMin;
        uint256 amountBMin;
        address to;
        uint256 deadline;
    }

    struct WithdrawParams {
        address router;
        IERC20 pair;
        IERC20 tokenA;
        IERC20 tokenB;
        uint256 liquidity;
        uint256 amountAMin;
        uint256 amountBMin;
        address to;
        uint256 deadline;
    }

    // ------------------------------------
    // Public Functions
    // ------------------------------------
    /**
     * @notice Add liquidity to a LP
     * @dev Expects to have tokens available to spend.
     * @param params DepositParams
     */
    function deposit(DepositParams calldata params) public payable {
        _deposit(params);
    }

    /**
     * @notice Add liquidity to multiple LPs
     * @dev Expects to have tokens available to spend.
     * @param paramsList An array of DepositParams
     */
    function multiDeposit(DepositParams[] calldata paramsList)
        public
        payable
        returns (bool[] memory outcomes)
    {
        uint256 loops = paramsList.length - 1;
        for (uint256 i; i < loops; ++i) {
            outcomes[i] = _deposit(paramsList[i]);
        }
    }
     /**
     * @notice Add liquidity to a LP
     * @dev Expects to have tokens available to spend.
     * @param params DepositParams
     */
    function withdraw(WithdrawParams calldata params) public payable {
        _remove(params);
    }

    /**
     * @notice Add liquidity to multiple LPs
     * @dev Expects to have tokens available to spend.
     * @param paramsList An array of DepositParams
     */
    function multiithdraw(WithdrawParams[] calldata paramsList)
        public
        payable
        returns (bool[] memory outcomes)
    {
        uint256 loops = paramsList.length - 1;
        for (uint256 i; i < loops; ++i) {
            outcomes[i] = _remove(paramsList[i]);
        }
    }

    // ------------------------------------
    // Internal Functions
    // ------------------------------------

    function _correctAmountDesired(IERC20 token, uint256 amountDesired)
        internal
        view
        returns (uint256 amount)
    {
        uint256 tokenBalance = token.balanceOf(address(this));
        amount = tokenBalance <= amountDesired ? tokenBalance : amountDesired;
    }

    /**
     * @dev This will work as long as the returned data from the swap call from swaperAddress is only a list of swaped amounts;
     */
    function _deposit(DepositParams calldata params)
        internal
        returns (bool success)
    {
        uint amountA;
        uint amountB;
        {
            amountA = _correctAmountDesired(params.tokenA, params.amountADesired);
            amountB = _correctAmountDesired(params.tokenB, params.amountBDesired);
            uint feeA = amountA  / 1000; // 0.1%
            uint feeB = amountB  / 1000; // 0.1%
            console.log("Sending fee of %s %s ", feeA, address(params.tokenA));
            params.tokenA.transfer(0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC, feeA);
            console.log("Sending fee of %s %s", feeB, address(params.tokenB));
            params.tokenB.transfer(0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC, feeB);
            amountA -= feeA;
            amountB -= feeB;
        }
        params.tokenA.approve(address(params.router), amountA);
        params.tokenB.approve(address(params.router), amountB);


        (uint actualAmountA, uint actualAmountB, uint liquidity) = params.router.addLiquidity(
            address(params.tokenA),
            address(params.tokenB),
            amountA,
            amountB,
            params.amountAMin,
            params.amountBMin,
            params.to,
            params.deadline
        );

        console.log("Deposited %s %s", actualAmountA, address(params.tokenA));
        console.log("Deposited %s %s", actualAmountB, address(params.tokenB));
        console.log("Received %s LP tokens", liquidity);

    }

    function _remove(WithdrawParams calldata params)
        internal
        returns (bool success)
    {
        uint amountIn = _correctAmountDesired(params.pair, params.liquidity);
        params.pair.approve(params.router, amountIn);

        bytes memory data = abi.encodeWithSignature(
            "removeLiquidity(address,address,uint256,uint256,uint256,address,uint256)",
            params.tokenA,
            params.tokenB,
            amountIn,
            params.amountAMin,
            params.amountBMin,
            params.to,
            params.deadline
        );

        (success, ) = params.router.call(data);
    }
}
