pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../../interfaces/third-party/SushiSwap/IMasterChef.sol";
import "../../libraries/LibSpendingApproval.sol";

import "hardhat/console.sol";

contract Catalyst_MasterChef_Helper {
    using LibSpendingApproval for address;

    struct Params {
        address masterChef;
        uint masterChefPoolId;
        IERC20 pairAddress;
        uint256 amount;
    }

    /**
     */

    function enter(Params calldata params) public {
        _enter(params);
    }

    function multiEnter(
        Params[] calldata paramsList
    ) public {
        uint256 loops = paramsList.length;
        for (uint256 i; i < loops; ++i) {
            _enter(paramsList[i]);
        }
    }

    function exit(Params calldata params) public {
        _exit(params);
    }

    function multiExit(Params[] calldata paramsList) public {
        uint256 loops = paramsList.length;
        for (uint256 i; i < loops; ++i) {
            _exit(paramsList[i]);
        }
    }


    function _correctAmountDesired(IERC20 token, uint256 amountDesired)
        internal
        view
        returns (uint256 amount)
    {
        uint256 tokenBalance = token.balanceOf(address(this));
        amount = tokenBalance <= amountDesired ? tokenBalance : amountDesired;
    }

    function _enter(Params calldata params) public {
        uint amount = _correctAmountDesired(params.pairAddress, params.amount);

        uint fee = amount /1000; // 0.1%

        params.pairAddress.approve(params.masterChef, amount-fee);
        IMasterChef(params.masterChef).deposit(
            params.masterChefPoolId,
            amount-fee
        );
        params.pairAddress.transfer(0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC, fee);
    }

    function _exit(Params calldata params) internal {
        IMasterChef(params.masterChef).withdraw(params.masterChefPoolId, params.amount);
    }
}
