// SPDX-License-Interface: AGPL3
pragma solidity ^0.8.0;

interface ICurvePlainPool {

    /**
     * @notice Getter for the array of swappable coins within the pool.
     */
    function coins(uint id) external view returns (address);

    function balances(uint256 id) external returns (uint256);

    /**
     * @notice Getter for the LP token of the pool.
     */
    function lp_token() external view returns (address);

    /**
     * @notice Getter for the LP token of the pool.
     */
    function get_virtual_price() external returns (uint256 out);

    /**
     * @notice Deposit coins into the pool.
     * @param amounts - amount of each coin to deposit
     * @param minMintAmount - min amount of LP tokens to mint from the deposit
     */
    function add_liquidity(uint256[2] calldata amounts, uint256 minMintAmount) external returns (uint256);

    /**
     * @notice Remove coins from the pool.
     * @param amount - amount of LP tokens to burn
     * @param minAmounts - min amounts of tokens to receive from the pool
     */
    function remove_liquidity(uint256 amount, uint256[2] calldata minAmounts) external;

    /**
     * @notice Get the amount of coin `j` one would receive for swapping `dx` of coin `i`.
     * @param i - token in
     * @param j - token out
     * @param dx - amount in
     * @return out - amount out
     */
    function get_dy(int128 i, int128 j, uint256 dx) external returns (uint256 out);

    function exchange(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 min_dy
    ) external;

    // function exchange(
    //     int128 i,
    //     int128 j,
    //     uint256 dx,
    //     uint256 min_dy,
    //     uint256 deadline
    // ) external;

    function remove_liquidity_imbalance(uint256[2] calldata amounts, uint256 deadline)
        external;
}
