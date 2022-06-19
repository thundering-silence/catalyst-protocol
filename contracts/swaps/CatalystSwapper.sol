// vSPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import "./DataTypes.sol";


/**
 * @notice This contract is built to execute swaps on OneInchExchange
 */
contract CatalystSwapper is Ownable {

    address internal _aggregator;

    event Swapped(address indexed src, address indexed dst, uint amountIn, uint amountOut);

    constructor(address aggregator_) {
        _aggregator = aggregator_;
    }

    function aggregator() public view returns (address) {
        return _aggregator;
    }

    /**
     * @notice Naively execute swap without checks
     * @dev msg.sender bears the responsibility of executing checks
     * @param swapData - data to be supplied to
     */
    function swap(
        CatalystSwapperDataTypes.SwapData memory swapData
    )
    public
    returns (bool, uint, uint)
    {
        swapData.src.approve(_aggregator, 0);
        swapData.src.approve(_aggregator, swapData.amountIn);
        (
            bool ok,
            bytes memory returnData
            ) = address(_aggregator).call(swapData.swapCallData);
        (
            uint amountOut,
            uint gasLeft
        ) = abi.decode(returnData, (uint, uint));

        emit Swapped(address(swapData.src), address(swapData.dst), swapData.amountIn, amountOut);
        return (ok, amountOut, gasLeft);
    }
}
