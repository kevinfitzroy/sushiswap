pragma solidity 0.6.12;

/**
 * @dev Interface of the Bitcoin info
 */
interface IBitcoinOracle {
    /**
     * @dev Returns the miner earn
     */
    function calReward(uint256 h, uint startTime, uint endTime) external view returns (uint256);
}
