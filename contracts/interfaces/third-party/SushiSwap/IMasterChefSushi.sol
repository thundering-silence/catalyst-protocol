// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IMasterChef.sol";

interface IMasterChefSushi is IMasterChef {
    /// @notice View function to see pending SUSHI on frontend.
    /// @param _pid The index of the pool. See `poolInfo`.
    /// @param _user Address of user.
    /// @return uint SUSHI reward for a given user.
    function pendingSushi(uint256 _pid, address _user)
        external
        view
        returns (uint256);

    /// @notice Update reward variables for all pools. Be careful of gas spending!
    function massUpdatePools() external;

    /// @notice Calculates and returns the `amount` of SUSSHI per block.
    function sushiPerSec() external view returns (uint256 amount);
}
