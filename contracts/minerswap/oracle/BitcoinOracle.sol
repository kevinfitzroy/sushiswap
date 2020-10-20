pragma solidity 0.6.12;

import "../interfaces/IBitcoinOracle.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

contract BitcoinOracle is IBitcoinOracle, Ownable {
    using SafeMath for uint256;

    // Bitcoin diff adjust for about every 14 days
    uint public constant DIFF_ADJUST_PERIOD = 14 days;

    // Bitcoin block info every 2016 blocks when diff adjust
    BlockInfo[] public blockInfos;

    struct BlockInfo {
        uint timestamp; // Block timestamp
        uint rewardPerTPerSecond; // Mine reward per Th per second, decimals is 18
    }

    function addBlockInfo(uint _timestamp, uint _rewardPerTPerSecond) external onlyOwner {
        blockInfos.push(BlockInfo({timestamp:_timestamp, rewardPerTPerSecond:_rewardPerTPerSecond}));
    }

    function calReward(uint256 h, uint startTime, uint endTime, uint8 decimals) external view override returns (uint256) {
        require(decimals <= 18, "decimals overflow");
        int endIndex = findIndex(endTime);
        if (endIndex == -1) {
            return 0;
        }
        uint reward = 0;
        while(endIndex >= 0) {
            uint _timestamp = blockInfos[endIndex].timestamp;
            uint _rewardPerTPerSecond = blockInfos[endIndex].rewardPerTPerSecond;
            uint reward;
            if (startTime > _timestamp) {
                reward = reward.add(_rewardPerTPerSecond.mul(endTime.sub(startTime)));
                break;
            } else {
                reward = reward.add(_rewardPerTPerSecond.mul(endTime.sub(_timestamp)));
                endTime = _timestamp;
                endIndex--;
            }
        }
        if (reward == 0) {
            return 0;
        }
        return reward.mul(h).div(10**(18-decimals));
    }

    function findIndex(uint time) internal returns (int) {
        if (blockInfos.length == 0) {
            return -1;
        }
        uint latestBlockTime = blockInfos[blockInfos.length - 1].timestamp;
        if (time > latestBlockTime) {
            return blockInfos.length - 1;
        } else {
            uint indexDiff = (latestBlockTime - time)/DIFF_ADJUST_PERIOD; // overflow will not happen
            int index = blockInfos.length - indexDiff - 2;
            index = index < 0 ? 0 : index;
            uint blockTime = blockInfos[index].timestamp;
            if (time < blockTime) {
                for (int i = index - 1; i >= 0; i--) {
                    if (time > blockInfos[i].timestamp) {
                        return i;
                    }
                }
            } else {
                for (int i = index + 1; i < blockInfos.length - 1; i++) {
                    if (time <= blockInfos[i].timestamp) {
                        return i - 1;
                    }
                }
            }
        }
        return -1;
    }
}
