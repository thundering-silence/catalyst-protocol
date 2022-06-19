// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../../interfaces/third-party/AaveV3/IPool.sol";
import "../../interfaces/third-party/AaveV3/IRewardsController.sol";

import "hardhat/console.sol";

/**
 * @notice Helper contract to interact with AaveV3's pool.
 * @dev This contract cannot hold any variables in storage as it must be called using delegatecall.
 */
contract Catalyst_AaveV3Pool_Delegate {

    function enter(address pool, address asset, uint amount) public {
        IERC20 token = IERC20(asset);
        token.approve(pool, amount);
        IPool(pool).supply(asset, amount, address(this), 0);
    }

    function exit(address pool, address asset, uint amount) public {
        // AaveV3 supports sending type(uint).max to withdraw everything
        IPool(pool).withdraw(asset, amount, address(this));
    }

}
