pragma solidity 0.6.12;


import "@openzeppelin/contracts/math/SafeMath.sol";
import "./IBitcoinOracle.sol";

contract MockBitcoinOracle is IBitcoinOracle {
    using SafeMath for uint256;

    uint256 private _earnPerTPerSecond;

    constructor(uint256 earnPerTPerSecond) public {
        _earnPerTPerSecond = earnPerTPerSecond;
    }

    function calReward(uint256 h, uint startTime, uint endTime) public view override returns (uint256) {
        return _earnPerTPerSecond.mul(h).mul(endTime.sub(startTime));
    }
}
