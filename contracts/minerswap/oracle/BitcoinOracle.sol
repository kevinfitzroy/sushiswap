pragma solidity 0.6.12;

import "../interfaces/IBitcoinOracle.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../../uniswapv2/libraries/SafeMath.sol";

contract BitcoinOracle is IBitcoinOracle, Ownable {
    using SafeMathUniswap for uint256;

    // Mine reward per Th per second, decimals is 18
    uint public rewardPerTPerSecond;

    function setRewardPerTPerSecond(uint _rewardPerTPerSecond) external onlyOwner {
        rewardPerTPerSecond = _rewardPerTPerSecond;
    }

    function calReward(uint256 h, uint startTime, uint endTime, uint8 decimals) public view override returns (uint256) {
        require(decimals <= 18, "decimals overflow");
        return rewardPerTPerSecond.mul(h).mul(endTime.sub(startTime)).div(10**(18-decimals));
    }
}
