pragma solidity 0.6.12;


import "./IBitcoinOracle.sol";


contract MockBitcoinOracle is IBitcoinOracle {

    uint256 private _earnPerTPerSecond;

    constructor(uint256 earnPerTPerSecond) public {
        _earnPerTPerSecond = earnPerTPerSecond;
    }

    function earnPerTPerSecond() public view override returns (uint256) {
        return _earnPerTPerSecond;
    }
}
