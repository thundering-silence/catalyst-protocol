pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

library LibSpendingApproval {
    using SafeERC20 for IERC20;

    function approve(
        address token,
        address spender,
        uint256 amount
    ) internal {
        _approve(IERC20(token), spender, amount);
    }

    function approveMax(address token, address spender) internal {
        _approve(IERC20(token), spender, type(uint256).max);
    }

    function approve(
        IERC20 token,
        address spender,
        uint256 amount
    ) internal {
        _approve(token, spender, amount);
    }

    function approveMax(IERC20 token, address spender) internal {
        _approve(token, spender, type(uint256).max);
    }

    function _approve(
        IERC20 token,
        address spender,
        uint256 amount
    ) internal {
        if (token.allowance(msg.sender, spender) <= amount) {
            token.safeIncreaseAllowance(spender, amount);
        }
    }
}
