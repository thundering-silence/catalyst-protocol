// SPDX-License-Interface: AGPL3
pragma solidity ^0.8.0;

import "./ICurvePlainPool.sol";

interface ICurveLendingPool is ICurvePlainPool {
    /**
     * @notice Getter for the array of underlying coins within the pool.
     */
    function underlying_coins(uint id) external view returns (address);

    /**
     * @notice Perform an exchange between two underlying tokens.
     * Index values can be found via the underlying_coins public getter method.
     * @param i - index of token in
     * @param j - index of token out
     * @param dx - amount in
     * @param min_dy - min amount out
     */
    function exchange_underlying(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 min_dy
    ) external;
}
