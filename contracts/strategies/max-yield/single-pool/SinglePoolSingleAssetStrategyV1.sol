// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../../../swaps/DataTypes.sol";
import "./BaseSinglePoolStrategy.sol";

import "hardhat/console.sol";

/**
 * @notice Single asset strategy - only capable of supplying to a single pool at a time
 */
contract SinglePoolSingleAssetStrategy is BaseSinglePoolStrategy {
    using Address for address;
    using SafeERC20 for IERC20;

    event Join(address indexed src, uint256 amount, uint fee);
    event Leave(address indexed src, uint256 amount, uint fee);
    event Supply(address indexed destination, uint amount);
    event Withdraw(address indexed current, uint amount);

    IERC20 public immutable asset;
    uint internal _index = 1e18;
    uint256 internal _depositedInCurrent;


    constructor(
        address asset_,
        string memory name_,
        string memory symbol_,
        address feesCollector_,
        address swapper_,
        address[] memory whitelist_,
        PoolConfig[] memory poolConfigs_
    )
    BaseSinglePoolStrategy(name_, symbol_, feesCollector_, swapper_, whitelist_, poolConfigs_)
    {
        asset = IERC20(asset_);
    }

    /*** PUBLIC FUNCTIONS ***/

    function granularity() public pure returns (uint) {
        return 1e18;
    }

    function index() public view returns (uint) {
        return _index;
    }



    /**
     * @notice Deposit `amount` into the strategy.
     * Deposit the asset and receive tokens as receipt.
     * The amount of tokens received is inversly correlated to the index.
     * @param amount - the amount of underlying to deposit
     */
    function join(uint amount) public onlyOpen {
        address account = _msgSender();
        asset.safeTransferFrom(account, address(this), amount);

        uint fee = amount >= 1000 ? amount / 1000 : 0; // 0.1% or 0
        asset.safeTransfer(_feesCollector, fee);

        uint256 mintAmount = (amount-fee) * granularity() / _index;
        _mint(account, mintAmount);
        updateCanReallocate(account);

        emit Join(account, amount-fee, fee);

        if (_currentPool != address(0)) {
            _supplyToPool(_currentPool, amount, true);
        }
    }

    /**
     * @notice Withdraw `amount` from the strategy
     */
    function leave(uint amount) public {
        uint cachedIndex = _index;
        address account = _msgSender();
        uint256 grossAmountOut = amount * cachedIndex / granularity();
        console.log(grossAmountOut);
        _withdrawFromPool(grossAmountOut);

        uint256 yield = grossAmountOut - amount;
        console.log(yield);
        uint fee = yield >= 20 ? yield / 20 : 0; // 5% or 0

        _burn(account, amount);
        updateCanReallocate(account);


        asset.safeTransfer(account, grossAmountOut - fee);
        asset.safeTransfer(_feesCollector, fee);

        emit Leave(account, grossAmountOut - fee, fee);
    }

    /**
     * @notice Swap currently held assets that are not the main asset and deposit the results into the current pool.
     * A small incentive - 0.5% of the swaps output - is rewarded to the esecutioner of such function.
     * @dev Only accounts that have a stake can execute this action.
     * Enforces the destination token being the main asset & the receiver of the swap output to be this contract.
     * The assets should be transferred to _swapper before calling swap() on it.
     * Ideally this should be called just after harvesting rewards by listening to the Harvest event.
     * @param swapsData - array of swaps to execute
     */
    function swapToAssetAndCompound(
        CatalystSwapperDataTypes.SwapData[] calldata swapsData
    )
    public
    canReallocate
    {
        uint max = swapsData.length;
        uint amountFromSwaps;
        for (uint i; i < max; ++i) {

            CatalystSwapperDataTypes.SwapData memory memSwapData = swapsData[i];
            memSwapData.dst = asset;
            memSwapData.swapCallData = enforceBeneficiaryAndDstToken(
                swapsData[i].swapCallData,
                address(asset)
            );

            // transfer assets to swapper contract instead of approving & then pulling
            swapsData[i].src.transfer(address(_swapper), swapsData[i].amountIn);
            (,uint amountOut, ) = _swapper.swap(memSwapData);
            amountFromSwaps += amountOut;
        }

        // Incentivise compounding, the more you do so the more you earn
        uint harvestReward = amountFromSwaps >= 200 ? amountFromSwaps / 200 : 0; // 0.5% or 0
        asset.transfer(_msgSender(), harvestReward);

        _supplyToPool(_currentPool, amountFromSwaps - harvestReward, false);
    }

    /**
     * @notice Move funds to a new pool.
     * Removes funds from the current pool and drops everything it has in the new one, while updating the index appropriately
     * @dev Only accounts that have a stake can decide where to allocate the funds
     * @param destination - the pool to which supply funds
     */
    function reallocate(address destination) public canReallocate {
        require(isWhitelisted[destination], "SingleAssetStrategy: Forbidden address");

        uint amountToDeposit = asset.balanceOf(address(this));
        if (_currentPool != address(0)) {
            _harvestRewards();
            _withdrawFromPool(type(uint256).max);

            uint balanceAfter = asset.balanceOf(address(this));
            uint yield = balanceAfter - _depositedInCurrent;
            require(yield >= 0, "SingleAssetStrategy: Reallocating not available");

            // Incentivise allocator to deposit in pool w/ best yield
            uint rewardToAllocator = yield >= 400 ? yield / 400 : 0; // 0.25% or 0
            asset.safeTransfer(_currentAllocator, rewardToAllocator);

            uint increase = yield - rewardToAllocator;
            _updateIndex(increase);
            amountToDeposit = _depositedInCurrent + increase;
        }

        _depositedInCurrent = 0;
        _supplyToPool(
            destination,
            amountToDeposit,
            true
        );
        _currentAllocator = _msgSender();
    }

    function emergencyWithdraw() public onlyOwner {
        _withdrawFromPool(type(uint).max);
    }

    /*** INTERNAL FUNCTIONS ***/

    function updateCanReallocate(address account) internal {
        // must have more than 1% of the pool
        _canReallocate[account] = balanceOf(account) >= (totalSupply() / 100);
    }

    /**
     * @notice Supply `amount` of funds to `destination`.
     * @dev
     * @param destination - the pool to supply funds to
     * @param amount - the quantity of tokens to supply
     * @param addToDeposited - whether to consider the supplied funds should be considered for index calculations or not
     */
    function _supplyToPool(address destination, uint256 amount, bool addToDeposited) internal {

        _currentPool = destination;
        bytes memory data = abi.encodeWithSignature(
            "enter(address,address,uint256)",
            destination,
            address(asset),
            amount
        );
        (
            address poolDelegate,,
        ) = poolConfig(destination);

        Address.functionDelegateCall(
            poolDelegate,
            data,
            "SingleAssetStrategy: Failed to enter new"
        );

        if (addToDeposited) {
            _depositedInCurrent += amount;
        }

        emit Supply(destination, amount);
    }

    /**
     * @notice Withdraw funds from current pool.
     * @dev poolDelegate must be called with delegatecall.
     * @param amount - qauntity of tokens to withdraw
     */
    function _withdrawFromPool(uint256 amount) internal {
        bytes memory exitData = abi.encodeWithSignature(
            "exit(address,address,uint256)",
            _currentPool,
            address(asset),
            amount
        );

        (
            address poolDelegate,,
        ) = poolConfig(_currentPool);

        Address.functionDelegateCall(
            address(poolDelegate),
            exitData,
            "SingleAssetStrategy: Failed to exit"
        );
        emit Withdraw(_currentPool, amount);
    }

    /**
     * @notice Harvest rewards generated by supplying to current pool
     * @dev rewardsDelegate is called with delegatecall
     * @return rewards - the assets received
     * @return amounts - the amount for each reward
     */
    function _harvestRewards() internal returns (address[] memory, uint256[] memory) {
        (
            ,
            address rewardsDelegate,
            bytes memory harvestCallData
        ) = poolConfig(_currentPool);

        bytes memory data = Address.functionDelegateCall(
            rewardsDelegate,
            harvestCallData,
            "SingleAssetStrategy: Failed to harvest"
        );
        (
            address[] memory rewards,
            uint256[] memory amounts
        ) = abi.decode(data, (address[], uint256[]));

        emit Harvest(rewards, amounts);
        return (rewards, amounts);
    }

    /**
     * @notice Update the index in order to keep track of yield generated
     * @param balanceIncrease - the amount of new tokens yielded by the current pool
     */
    function _updateIndex(uint256 balanceIncrease) internal {
        uint256 cachedIndex = _index;
        uint256 shares = totalSupply();
        uint prevBalance = cachedIndex*shares;
        uint scaledIncrease = balanceIncrease*granularity();
        _index = (prevBalance + scaledIncrease) / shares;
        require(_index >= cachedIndex, "SingleAssetStrategy: Index has decreased");
    }
}
