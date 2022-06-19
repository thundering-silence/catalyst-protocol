// SPDX-LIcense-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "../../swaps/ICatalystSwapper.sol";
import "../../swaps/DataTypes.sol";

import "hardhat/console.sol";


abstract contract BaseStrategy is ERC20, Ownable {
    using SafeERC20 for IERC20;

    mapping(address => bool) public isWhitelisted;
    bool internal _closed; // is joining closed
    address internal _feesCollector;
    ICatalystSwapper internal _swapper;

    event Join(address indexed src, uint256 amount, uint fee);
    event Leave(address indexed src, uint256 amount, uint fee);
    event Open();
    event Close();
    event Supply(address indexed destination, uint amount);
    event Withdraw(address indexed current, uint amount);
    event Harvest(address[] rewards, uint256[] amounts);
    event FeesCollectorChanged(address indexed collector);
    event SwapperChanged(address indexed swapper);

    constructor(
        string memory name_,
        string memory symbol_,
        address feesCollector_,
        address swapper_,
        address[] memory whitelist_
    )
    ERC20(name_, symbol_)
    {
        _feesCollector = feesCollector_;
        _swapper = ICatalystSwapper(swapper_);

        _closed = false;

        uint l = whitelist_.length;
        for (uint i; i < l; ++i) {
            isWhitelisted[whitelist_[i]] = true;
        }
    }

    modifier onlyOpen() {
        require(!_closed, "BaseStrategy: Cannot join");
        _;
    }

    modifier onlyParticipant() {
        require(balanceOf(_msgSender()) > 0, "BaseStrategy: Not a participant");
        _;
    }

    function feesCollector() public view returns (address) {
        return _feesCollector;
    }

    function swapper() public view returns (address) {
        return address(_swapper);
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
