// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../../interfaces/third-party/Compound/ICompToken.sol";
import "../../interfaces/third-party/Compound/IComptroller.sol";

contract Catalyst_CompPool_Delegate {

    function enter(address pool, address asset, uint amount) external {
        _deposit(pool, amount);
    }

    function exit(address pool, address asset, uint amount) external {
        _withdrawUnderlying(pool, amount);
    }

    // DEPOSIT
    // 1- `approve` spending of underlying by cERC20 contract
    // 2- call `mint` on cERC20 contract
    function _deposit(address vault, uint amount) internal {
        ICompToken cToken = ICompToken(vault);
        IERC20(cToken.underlying()).approve(vault, amount);
        cToken.mint(amount);
    }

    // WITHDRAW
    // 1- `approve` spending of cToken by cERC20 contract
    // 2- call `redeem` on cERC20 contract
    function _withdrawUnderlying(address vault, uint amount) internal returns (uint) {
        // ICompToken already supports passing higher amount than available
        ICompToken cToken = ICompToken(vault);
        return cToken.redeemUnderlying(amount);
    }

    // BORROW
    // 1- call `enterMarkets` with collateral and principal tokens on Comptroller
    // 2- call `borrow` on cERC20 contract
    /**
     * @notice open loan
     * @dev requires to have entered markets for collaterals and principal
     */
    function _borrow(address vault, uint amount) internal {
        ICompToken(vault).borrow(amount);
    }


    // REPAY
    // 1- `approve` spending of underlying by cERC20 contract
    // 2- call `repayBorrow` on cERC20 contract
    function _repay(address vault, uint amount) internal {
        ICompToken cToken = ICompToken(vault);
        IERC20(cToken.underlying()).approve(vault, amount);
        cToken.repayBorrow(amount);
    }
}
