// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IMasterChef {
    /// @notice Deposit LP tokens to MCJV3 for JOE allocation.
    /// @param pid The index of the pool. See `poolInfo`.
    /// @param amount LP token amount to deposit.
    function deposit(uint256 pid, uint256 amount) external;

    /// @notice Withdraw LP tokens from MCJV3.
    /// @param pid The index of the pool. See `poolInfo`.
    /// @param amount LP token amount to withdraw.
    /// @dev set amount to zero in order to only harvest rewards
    function withdraw(uint256 pid, uint256 amount) external;

    /// @notice Returns the number of MCJV3 pools.
    function poolLength() external view returns (uint256 pools);

    /// @notice Update reward variables of the given pool.
    /// @param pid The index of the pool. See `poolInfo`.
    function updatePool(uint256 pid) external;

    /// @notice Withdraw without caring about rewards. EMERGENCY ONLY.
    /// @param pid The index of the pool. See `poolInfo`.
    function emergencyWithdraw(uint256 pid) external;
}
