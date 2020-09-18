pragma solidity 0.6.12;

/**
 * @dev Interface of the Bitcoin info
 */
interface IBitcoinOracle {
    /**
     * @dev Returns the miner earn of 1TH per second.
     */
    function earnPerTPerSecond() external view returns (uint256);
}
