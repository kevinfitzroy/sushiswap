pragma solidity 0.6.12;

/**
 * @dev Interface of the Bitcoin info
 */
interface IBitcoinOracle {
    /**
     * @dev Returns the miner earn
     * h - how many hash rate(Th/s)
     * startTime - mine start time
     * endTime - mine end time
     * decimals - btc token decimals
     */
    function calReward(uint256 h, uint startTime, uint endTime, uint8 decimals) external view returns (uint256);
}
