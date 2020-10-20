pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "../../uniswapv2/libraries/TransferHelper.sol";
import "../interfaces/IMineToken.sol";
import "../interfaces/IBitcoinOracle.sol";

contract BtcMineToken is IMineToken, ERC20, Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // The bitcoin erc20 token such as wbtc
    IERC20 public btc;
    // The bitcoin erc20 token decimals
    uint8 public btcDecimals;
    // The erc20 token to buy mine token such as usdt
    IERC20 public usdt;
    // The bitcoin info oracle
    IBitcoinOracle public btcOracle;
    // Buy token price
    uint256 public buyPrice;
    // Buy total supply
    uint256 public buyTotalSupply;
    // Buy supply
    uint256 public buySupply;
    // Buy mine token start time
    uint public buyStartTime;
    // Buy mine token end time
    uint public buyEndTime;
    // Btc reward start time
    uint public startTime;
    // Btc reward end time
    uint public endTime;

    struct MinerInfo {
        uint nextRewardTime; // Next cal reward time
        uint256 accReward; // Total reward not withdraw
    }

    // Info of each miner that hold tokens.
    mapping (address => MinerInfo) public minerInfo;

    constructor(
        string memory _name,
        string memory _symbol
    ) public ERC20(_name, _symbol) {
    }

    function initialize(
        address _btc,
        uint8 _btcDecimals,
        address _usdt,
        address _btcOracle,
        uint256 _buyPrice,
        uint256 _buyTotalSupply,
        uint _buyStartTime,
        uint _buyEndTime,
        uint _startTime,
        uint _endTime) external onlyOwner {
        require(_buyStartTime < _buyEndTime && _buyEndTime < _startTime && _startTime < _endTime, "Invalid time");
        btc = IERC20(_btc);
        btcDecimals = _btcDecimals;
        usdt = IERC20(_usdt);
        btcOracle = IBitcoinOracle(_btcOracle);
        buyPrice = _buyPrice;
        buyTotalSupply = _buyTotalSupply;
        buyStartTime = _buyStartTime;
        buyEndTime = _buyEndTime;
        startTime = _startTime;
        endTime = _endTime;
    }

    function setOracle(address _oracle) external override onlyOwner {
        btcOracle = IBitcoinOracle(_oracle);
    }

    function mint(address _to, uint256 _amount) external override onlyOwner {
         _mint(_to, _amount);
    }

    // buy token
    function buy(uint256 _amount) external override {
        require(buySupply.add(_amount) <= buyTotalSupply, "Buy supply capped");
        require(block.timestamp > buyStartTime, "Buy not start");
        require(block.timestamp <= buyEndTime, "Buy ended");
        uint256 _buyValue = _amount.mul(buyPrice);
        TransferHelper.safeTransferFrom(address(usdt), msg.sender, address(this), _buyValue);
        buySupply = buySupply.add(_amount);
        _mint(msg.sender, _amount);
    }

    // withdraw token
    function withdrawToken(address _token, uint256 _amount) external override onlyOwner {
        TransferHelper.safeTransfer(_token, msg.sender, _amount);
    }

    // harvest btc mine reward
    function harvest(uint256 _amount) external override {
        MinerInfo storage accountMinerInfo = minerInfo[msg.sender];
        if (accountMinerInfo.accReward < _amount) {
            accReward(msg.sender);
        }
        accountMinerInfo.accReward = accountMinerInfo.accReward.sub(_amount);
        TransferHelper.safeTransfer(address(btc), msg.sender, _amount);
    }

    // harvest btc mine reward to _to address
    function harvestTo(address _to, uint256 _numerator, uint256 _denominator) external override returns (uint256) {
        accReward(msg.sender);
        MinerInfo storage accountMinerInfo = minerInfo[msg.sender];
        uint256 _amount = _numerator.mul(accountMinerInfo.accReward).div(_denominator);
        if (_amount > 0) {
            accountMinerInfo.accReward = accountMinerInfo.accReward.sub(_amount);
            TransferHelper.safeTransfer(address(btc), _to, _amount);
        }
        return _amount;
    }

    function getReward(address _account) external view override returns (uint, uint) {
        uint accReward = minerInfo[_account].accReward;
        uint waitReward = 0;
        uint amount = balanceOf(_account);
        uint nextRewardTime = 0;
        if (amount == 0) {
            return (accReward, waitReward);
        } else {
            if (minerInfo[_account].nextRewardTime == 0) {
                nextRewardTime = startTime;
            }
        }
        uint rewardEndTime = block.timestamp > endTime ? endTime : block.timestamp;
        if (nextRewardTime >= rewardEndTime) {
            return (accReward, waitReward);
        }
        waitReward = btcOracle.calReward(amount, nextRewardTime, rewardEndTime, btcDecimals);
        return (accReward, waitReward);
    }

    /**
     * @dev See {ERC20-_beforeTokenTransfer}.
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);

        if (from != address(0)) {
            accReward(from);
        }
        if (to != from && to != address(0)) {
            accReward(to);
        }
    }

    function accReward(address account) internal {
        // Only produce btc reward after startTime
        if (block.timestamp < startTime) {
            return;
        }
        MinerInfo storage accountMinerInfo = minerInfo[account];
        uint256 amount = balanceOf(account);
        if (amount == 0) {
            accountMinerInfo.nextRewardTime = block.timestamp;
            return;
        } else {
            if (accountMinerInfo.nextRewardTime == 0) {
                accountMinerInfo.nextRewardTime = startTime;
            }
        }
        uint rewardEndTime = block.timestamp > endTime ? endTime : block.timestamp;
        if (accountMinerInfo.nextRewardTime >= rewardEndTime) {
            return;
        }
        uint256 reward = btcOracle.calReward(amount, accountMinerInfo.nextRewardTime, rewardEndTime, btcDecimals);
        accountMinerInfo.accReward = accountMinerInfo.accReward.add(reward);
        accountMinerInfo.nextRewardTime = block.timestamp;
    }
}
