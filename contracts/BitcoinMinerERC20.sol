pragma solidity 0.6.12;


import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Capped.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "./IBitcoinOracle.sol";

contract BitcoinMinerERC20 is ERC20Capped, Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // The bitcoin erc20 token such as wbtc
    IERC20 public btc;
    // The bitcoin info oracle
    IBitcoinOracle public btcOracle;
    // Mine earn end block number in ethereum blockchain
    uint256 public earnEndBlockNumber;

    // Info of miner.
    struct MinerInfo {
        uint lastAccTimestamp; // Last acc mine reward timestamp
    }

    // Info of each miner that hold tokens.
    mapping (address => MinerInfo) public minerInfo;

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _supply,
        address _btc,
        address _btcOracle,
        uint256 _earnEndBlockNumber
    ) public ERC20Capped(_supply) ERC20(_name, _symbol) {
        btc = IERC20(_btc);
        btcOracle = IBitcoinOracle(_btcOracle);
        earnEndBlockNumber = _earnEndBlockNumber;
        // Initial mint all token can supply
        _mint(msg.sender, _supply);
    }

    /**
     * @dev See {ERC20-_beforeTokenTransfer}.
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);

        // Only produce btc reward before earnEndBlockNumber
        if (block.number < earnEndBlockNumber) {
            if (from != address(0)) {
                accReward(from);
            }
            if (to != from && to != address(0)) {
                accReward(to);
            }
        }
    }

    function accReward(address account) internal {
        MinerInfo storage accountMinerInfo = minerInfo[account];
        // when account is as `from`, miner info is initialized for sure
        // when account is the first time as `to`, just initial it's miner info
        if (accountMinerInfo.lastAccTimestamp == 0) {
            accountMinerInfo.lastAccTimestamp = block.timestamp;
            return;
        }
        if (block.timestamp <= accountMinerInfo.lastAccTimestamp) {
            return;
        }
        // if account is as `from`, amount wont be zero
        // if account is as `to`, amount maybe zero
        uint256 amount = balanceOf(account);
        if (amount == 0) {
            return;
        }
        uint256 reward = amount.mul(block.timestamp.sub(accountMinerInfo.lastAccTimestamp)).mul(btcOracle.earnPerTPerSecond());
        accountMinerInfo.lastAccTimestamp = block.timestamp;
        btc.transfer(account, reward);
    }
}
