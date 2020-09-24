pragma solidity 0.6.12;


import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Capped.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "./IBitcoinOracle.sol";

contract BitcoinMinerERC20 is ERC20Capped, Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Issuer of this mine token
    address public issuer;
    // The bitcoin erc20 token such as wbtc
    IERC20 public btc;
    // The erc20 token to buy mine token such as usdt
    IERC20 public usdt;
    // The bitcoin info oracle
    IBitcoinOracle public btcOracle;
    // Buy mine token price
    uint256 public buyPrice;
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
        string memory _symbol,
        uint256 _supply,
        address _btc,
        address _usdt,
        address _btcOracle,
        uint256 _buyPrice,
        uint _buyEndTime,
        uint _startTime,
        uint _endTime
    ) public ERC20Capped(_supply) ERC20(_name, _symbol) {
        require(_buyEndTime < _startTime, "Buy end time must less than reward start time");
        require(_startTime < _endTime, "Reward start time must less than reward end time");
        btc = IERC20(_btc);
        usdt = IERC20(_usdt);
        btcOracle = IBitcoinOracle(_btcOracle);
        buyPrice = _buyPrice;
        buyEndTime = _buyEndTime;
        startTime = _startTime;
        endTime = _endTime;
    }

    function mint(address _to, uint256 _amount) public onlyOwner {
        require(block.timestamp <= buyEndTime, "Buy token has already end");
        _mint(_to, _amount);
    }


    function harvest(uint256 amount) public {
        MinerInfo storage accountMinerInfo = minerInfo[msg.sender];
        accountMinerInfo.accReward = accountMinerInfo.accReward.sub(amount);
        btc.transfer(msg.sender, amount);
    }

    /**
     * @dev See {ERC20-_beforeTokenTransfer}.
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);

        // Only produce btc reward after startTime
        if (block.timestamp < startTime) {
            return;
        }
        if (from != address(0)) {
            accReward(from);
        }
        if (to != from && to != address(0)) {
            accReward(to);
        }
    }

    function accReward(address account) internal {
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
        uint256 reward = btcOracle.calReward(amount, accountMinerInfo.nextRewardTime, rewardEndTime);
        accountMinerInfo.accReward = accountMinerInfo.nextRewardTime.add(reward);
        accountMinerInfo.nextRewardTime = block.timestamp;
    }
}
