// vSPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./DataTypes.sol";

interface ICatalystSwapper {

    function swap(
        CatalystSwapperDataTypes.SwapData memory swapData
    )
    external
    returns (bool, uint, uint);

}
