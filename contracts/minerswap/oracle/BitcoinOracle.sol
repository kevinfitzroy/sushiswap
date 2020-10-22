pragma solidity 0.6.12;

import "../interfaces/IBitcoinOracle.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "../ownership/Multiowned.sol";

contract BitcoinOracle is IBitcoinOracle, Multiowned {
    using SafeMath for uint256;

    // Bitcoin diff adjust for about every 14 days
    uint public constant DIFF_ADJUST_PERIOD = 14 days;

    // Bitcoin block info every 2016 blocks when diff adjust
    BlockInfo[] public blockInfos;

    struct BlockInfo {
        uint timestamp; // Block timestamp
        uint rewardPerTPerSecond; // Mine reward per Th per second, decimals is 18
    }

    constructor (address[] memory _owners, uint _required) public Multiowned(_owners, _required) {
    }

    function addBlockInfo(uint _timestamp, uint _rewardPerTPerSecond, bytes32 _blockHeaderHash) external onlyowner {
        if (blockInfos.length > 0) {
            require(_timestamp > blockInfos[blockInfos.length - 1].timestamp, "invalid timestamp");
        }
        if (!confirmAndCheck(keccak256(msg.data))) {
            return;
        }
        blockInfos.push(BlockInfo({timestamp:_timestamp, rewardPerTPerSecond:_rewardPerTPerSecond}));
    }

    function updateLatestBlockInfo(uint _timestamp, uint _rewardPerTPerSecond, bytes32 _blockHeaderHash) external onlyowner {
        require(blockInfos.length > 0, "invalid state");
        if (blockInfos.length > 1) {
            require(_timestamp > blockInfos[blockInfos.length - 2].timestamp, "invalid timestamp");
        }
        if (!confirmAndCheck(keccak256(msg.data))) {
            return;
        }
        BlockInfo storage info = blockInfos[blockInfos.length - 1];
        info.timestamp = _timestamp;
        info.rewardPerTPerSecond = _rewardPerTPerSecond;
    }

    function calReward(uint256 h, uint startTime, uint endTime, uint8 decimals) external override view returns (uint256) {
        require(startTime < endTime, "invalid time");
        require(decimals <= 18, "decimals overflow");
        (bool success, uint endIndex) = findIndex(endTime);
        if (!success) {
            return 0;
        }
        uint reward = 0;
        while(true) {
            uint _timestamp = blockInfos[endIndex].timestamp;
            uint _rewardPerTPerSecond = blockInfos[endIndex].rewardPerTPerSecond;
            if (startTime >= _timestamp) {
                reward = reward.add(_rewardPerTPerSecond.mul(endTime.sub(startTime)));
                break;
            } else {
                reward = reward.add(_rewardPerTPerSecond.mul(endTime.sub(_timestamp)));
                endTime = _timestamp;
                if (endIndex == 0) {
                    break;
                } else {
                    endIndex--;
                }
            }
        }
        return reward.mul(h)/10**(18-uint(decimals));
    }

    function findIndex(uint time) internal view returns (bool, uint) {
        if (blockInfos.length == 0) {
            return (false, 0);
        }
        uint latestBlockTime = blockInfos[blockInfos.length - 1].timestamp;
        if (time > latestBlockTime) {
            return (true, blockInfos.length - 1);
        } else if (time <= blockInfos[0].timestamp) {
            return (false, 0);
        } else {
            uint indexDiff = (latestBlockTime - time)/DIFF_ADJUST_PERIOD; // overflow will not happen
            uint index = 0;
            if (blockInfos.length > indexDiff.add(2)) {
                index = blockInfos.length - indexDiff - 2;
            }
            uint blockTime = blockInfos[index].timestamp;
            if (time < blockTime) {
                for (uint i = index; i > 0; i--) {
                    if (time > blockInfos[i - 1].timestamp) {
                        return (true, i - 1); // overflow will not happen
                    }
                }
            } else {
                for (uint i = index + 1; i < blockInfos.length - 1; i++) {
                    if (time <= blockInfos[i].timestamp) {
                        return (true, i - 1);
                    }
                }
            }
        }
        return (false, 0);
    }
}
