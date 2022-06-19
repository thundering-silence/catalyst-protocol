// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../../interfaces/third-party/AaveV2/ILendingPool.sol";
import "../../interfaces/third-party/AaveV2/IProtocolDataProvider.sol";
import "../../interfaces/third-party/AaveV2/ILendingPoolAddressesProvider.sol";

/**
 * @notice Helper contract to interact with AaveV2' pool.
 * @dev This contract cannot hold any variables in storage as it must be called using delegatecall.
 */
contract Catalyst_AaveV2Pool_Delegate {

    function _getProtocolDataProvider(address lendingPool) public view returns (address provider) {
        ILendingPoolAddressesProvider addressesProvider = ILendingPool(lendingPool).getAddressesProvider();
        provider = addressesProvider.getAddress(bytes32(uint(1)));
    }

    function _getAaveTokensForAsset(
        address provider,
        address asset
    )
    public
    view
    returns (address[] memory tokens)
    {
        (
            address aToken,
            address vDebtToken,
            address sDebtToken
        ) = IProtocolDataProvider(provider).getReserveTokensAddresses(asset);
        tokens[0] = aToken;
        tokens[1] = vDebtToken;
        tokens[3] = sDebtToken;
    }

    function enter(
        address pool,
        address asset,
        uint amount
    ) external {
        IERC20 token = IERC20(asset);
        token.approve(pool, amount);
        ILendingPool(pool).deposit(asset, amount, address(this), 0);
    }

    function exit(
        address pool,
        address asset,
        uint amount
    ) external {
        // AaveV2 accepts type(uint).max as param to withdraw everything
        ILendingPool(pool).withdraw(asset, amount, address(this));
    }

    function borrow(address pool, address asset, uint amount) external {

    }

    function repay(address pool, address asset, uint amount) external {

    }

}
