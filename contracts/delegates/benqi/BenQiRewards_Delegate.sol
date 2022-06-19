// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../../interfaces/third-party/Compound/IComptroller.sol";
import "../../interfaces/third-party/INative.sol";

/**
 * @notice Helper contract to interact with BenQi  for rewards.
 * @dev This contract must be called using delegatecall.
 */
contract Catalyst_BenQiRewards_Delegate {

    /**
     * @param controller - the incentives controller
     */
    function harvestRewards(
        address controller
    ) external returns (address[] memory rewards, uint256[] memory amounts) {
        address payable[] memory holders = new address payable[](1);
        holders[0] = payable(address(this));
        // 0 - Qi token
        // 1 - AVAX (that is swapped for WAVAX)
        rewards[0] = 0x8729438EB15e2C8B576fCc6AeCdA6A148776C0F5;
        rewards[1] = 0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7;
        for (uint8 i; i < 2; ++i) {
            IComptroller(controller).claimReward(
                i,
                holders,
                IComptroller(controller).getAssetsIn(address(this)),
                true,
                true
            );
            if (i == uint8(1)) {
                INative(rewards[1]).deposit{value: address(this).balance}();
            }
            amounts[i] = IERC20(rewards[i]).balanceOf(address(this));
        }
    }
}
