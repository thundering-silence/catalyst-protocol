// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";


/**
 * @notice Catalyst's staking contract
 * This contract will be receiveing the fees from the FeesCollector once a day
 * veREACT is the receipt for staking REACT and gives access to revenue sharing & governance
 */
contract Staking is ERC20("veREACT", "veREACT") {
    using SafeERC20 for IERC20;

    event Enter(address indexed account, uint256 shares);
    event Leave(address indexed account, uint depositId, bool forced);
    event Claimed(address indexed token, address indexed to, uint256 amount);

    address public immutable REACT = address(1); // TODO - replace with actual REACT address

    struct assetData {
        uint256 totalReleased;
        mapping(address => uint256) released;
    }
    mapping(address => assetData) internal _assets;

    struct DepositData {
        uint amount;
        uint expiry;
        uint multiplier;
        bool withdrawn;
    }

    mapping(address => DepositData[]) internal depositsOf;

    receive() external payable {}

    /**
     * @notice Getter for the total amount of `token` already released. `token` should be the address of an IERC20
     * contract.
     * @return uint256
     */
    function totalReleased(address token) public view returns (uint256) {
        return _assets[token].totalReleased;
    }

    /**
     * @notice Getter for the amount of `asset` already released to `account`
     * @param asset - the asset for which to query data for
     * @param account - the account for which to query data for
     * @return uint
     */
    function amountReleasedTo(address asset, address account) public view returns (uint256) {
        return _assets[asset].released[account];
    }

    /**
     * @notice Triggers a transfer to `account` of the amount of `token` tokens they are owed, according to their
     * percentage of the total shares and their previous withdrawals.
     * @param token - the asset to claim - if Address(0) then ETH will be claimed
     * @param account - the account for which to claim
     */
    function claim(address token, address account) public {
        require(balanceOf(account) > 0, "Staking: account has no shares");

        uint balance;
        if (token == address(0)) {
            balance = address(this).balance;
        } else {
            balance = IERC20(token).balanceOf(address(this));
        }

        uint256 totalReceived = balance + totalReleased(token);
        uint256 claimable = _pendingPayment(account, totalReceived, amountReleasedTo(token, account));

        require(claimable != 0, "Staking: account is not due payment");

        _assets[token].released[account] += claimable;
        _assets[token].totalReleased += claimable;

        if (address(token) == address(0)) {
            Address.sendValue(payable(account), claimable);
        } else {
            SafeERC20.safeTransfer(IERC20(token), account, claimable);
        }
        emit Claimed(token, account, claimable);
    }

    /**
     * @notice Enter staking for a total of `amount` with unlock at `expiry`
     * The expiry can be between 14 days and 1460 days (4 years) inn the future.
     * @param amount - the amount of tokens to stake
     * @param expiry - the unlock timestamp for withdrawing tokens without penalty
     */
    function deposit(uint amount, uint expiry) public {
        require(amount > 0, "Staking: amount is 0");
        require(expiry >= block.timestamp + 14 days, "Staking: expiry too close to now");
        require(expiry <= block.timestamp + 1460 days, "Staking: expiry too far in the future");


        uint multiplier = (block.timestamp - expiry) / 14 days; // shares double for every 14 days of lock;
        uint shares = amount * multiplier;

        depositsOf[_msgSender()].push(DepositData({
            amount: amount,
            expiry: expiry,
            multiplier: multiplier,
            withdrawn: false
        }));

        IERC20(REACT).safeTransferFrom(_msgSender(), address(this), amount);
        _mint(_msgSender(), shares);

        emit Enter(_msgSender(), shares);
    }

    /**
     * @notice withdraw staked amount for a specific deposit
     * It is of imperative importance to first claim all claimable tokens before withdrawing
     * @param ids - the ids of the deposits do withdraw
     */
    function withdraw(uint[] calldata ids, bool force) public {
        require(balanceOf(_msgSender()) > 0, "Staking: account has no shares");

        uint l = ids.length;
        uint burnAmount;
        uint transferAmount;
        uint penaltyAmount;

        DepositData[] memory depositsMem = depositsOf[_msgSender()]; // load in memory to consume less gas when looping through

        for (uint i; i < l; ++i) {
            bool forced = false;
            uint id = ids[i];
            DepositData memory data = depositsMem[id];
            uint shares = data.amount * data.multiplier;
            burnAmount += shares;

            if (block.timestamp < data.expiry) {
                if (force) {
                    transferAmount += data.amount /2;
                    forced = true;
                    penaltyAmount += data.amount / 2;
                } else {
                    continue;
                }
            } else {
                transferAmount += data.amount;
            }

            depositsOf[_msgSender()][id].withdrawn = true;
            emit Leave(_msgSender(), id, forced);
        }
        _burn(_msgSender(), burnAmount);
        IERC20(REACT).safeTransfer(_msgSender(), transferAmount);
        IERC20(REACT).safeTransfer(address(0), penaltyAmount); // burn REACT
    }


    /**
     * @dev internal logic for computing the pending payment of an `account` given the token historical balances and
     * already released amounts.
     */
    function _pendingPayment(
        address account,
        uint256 totalReceived,
        uint256 alreadyReleased
    ) private view returns (uint256) {
        return (totalReceived * balanceOf(account)) / totalSupply() - alreadyReleased;
    }

}
