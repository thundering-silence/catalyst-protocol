// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "../../../swaps/ICatalystSwapper.sol";
import "../../../swaps/DataTypes.sol";

import "hardhat/console.sol";


abstract contract BaseSinglePoolStrategy is ERC20, Ownable {
    using SafeERC20 for IERC20;

    event Open();
    event Close();
    event Harvest(address[] rewards, uint256[] amounts);
    event FeesCollectorChanged(address indexed collector);
    event SwapperChanged(address indexed swapper);

    address[] public pools;
    mapping(address => bool) public isWhitelisted;
    bool internal _closed; // is joining closed
    address internal _feesCollector;
    ICatalystSwapper internal _swapper;

    mapping(address => bool) internal _canReallocate;
    address internal _currentAllocator;
    mapping(address => uint256) internal _currentlyDeposited; // keep track of allocations

    struct PoolConfig {
        address poolDelegate; // contract to which delegate calls for interacting with the pool.
        address rewardsDelegate; // contract to which delegate calls for harvesting rewards.
        bytes harvestCallData; // bytes calldata for rewardsDelegate.
    }
    mapping(address => PoolConfig) public poolsConfig;

    constructor(
        string memory name_,
        string memory symbol_,
        address feesCollector_,
        address swapper_,
        address[] memory whitelist_,
        PoolConfig[] memory poolConfigs_
    )
    ERC20(name_, symbol_)
    {
        _feesCollector = feesCollector_;
        _swapper = ICatalystSwapper(swapper_);

        _closed = false;

        pools = whitelist_;
        uint l = whitelist_.length;
        for (uint i; i < l; ++i) {
            isWhitelisted[whitelist_[i]] = true;
            poolsConfig[whitelist_[i]] = poolConfigs_[i];
        }
    }

    modifier onlyOpen() {
        require(!_closed, "BaseStrategy: Cannot join");
        _;
    }

    modifier canReallocate() {
        require(
            owner() == _msgSender() || _canReallocate[_msgSender()],
            "BaseStrategy: Not Allowed"
        );
        _;
    }

    function feesCollector() public view returns (address) {
        return _feesCollector;
    }

    function swapper() public view returns (address) {
        return address(_swapper);
    }

    function currentAllocations() public view returns (address[] memory vaults, uint[] memory amounts) {
        uint loops = pools.length;
        for (uint i; i < loops; ++i) {
            vaults[i] = pools[i];
            amounts[i] = _currentlyDeposited[pools[i]];
        }
    }

    function poolConfig(address pool)
    public
    view
    returns (
        address poolDelegate,
        address rewardsDelegate,
        bytes memory harvestCallData
    )
     {
        poolDelegate =  poolsConfig[pool].poolDelegate;
        rewardsDelegate =  poolsConfig[pool].rewardsDelegate;
        harvestCallData =  poolsConfig[pool].harvestCallData;
    }

    /**
     * @notice Enforce dstToken and the dstReceiver of swap
     * @dev This enforces the funds to get sent back to this contract and forces dstToken to be `dst`
     * @param swapCallData - data from the 1inch API
     * @param dst - the toToken of the swap
     * @return overwrittenData - swapCallData with overwritten values
     */
    function enforceBeneficiaryAndDstToken(
        bytes calldata swapCallData,
        address dst
    )
    public
    view
    returns (bytes memory overwrittenData)
    {
        (
            address caller,
            CatalystSwapperDataTypes.SwapDescription memory desc,
            bytes memory calls
        ) = abi.decode(
            swapCallData[4:],
            (
                address,
                CatalystSwapperDataTypes.SwapDescription,
                bytes
            )
        );

        desc.dstToken = IERC20(dst);
        desc.srcReceiver = payable(caller);
        desc.dstReceiver = payable(address(this));

        bytes memory encoded = abi.encode(caller, desc, calls);
        overwrittenData = bytes.concat(swapCallData[:4], encoded);
    }

    function setFeesCollector(address collector) public onlyOwner {
        _feesCollector = collector;
        emit FeesCollectorChanged(collector);
    }

    function setSwapper(ICatalystSwapper newSwapper) public onlyOwner {
        _swapper = newSwapper;
    }

    function setClosed(bool conf) public onlyOwner {
        _closed = conf;
        if (conf) {
            emit Close();
        } else {
            emit Open();
        }
    }


}
