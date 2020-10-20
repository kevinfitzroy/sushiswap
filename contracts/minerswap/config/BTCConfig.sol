pragma solidity 0.6.12;

import "@openzeppelin/contracts/access/Ownable.sol";

contract BTCConfig is Ownable{

    struct Config {
        address addr;
        uint8 decimal;
    }

    mapping(string => Config) public btcAddress;

    constructor() public {
        btcAddress["wBTC"] = Config({addr: 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599, decimal:18});
        btcAddress["hBTC"] = Config({addr: 0x0316EB71485b0Ab14103307bf65a021042c6d380, decimal:18});
        btcAddress["sBTC"] = Config({addr: 0xfE18be6b3Bd88A2D2A7f928d00292E7a9963CfC6, decimal:18});
    }

    function update(string memory name, address _addr, uint8 _decimal) public onlyOwner{
        btcAddress[name] = Config({addr: _addr, decimal: _decimal});
    }

    function indexAddr(string memory name) public view returns (address){
        return btcAddress[name].addr;
    }

    function indexDecimal(string memory name) public view returns (uint8){
        return btcAddress[name].decimal;
    }

    function index(string memory name) public view returns (address, uint8){
        Config memory conf = btcAddress[name];
        return (conf.addr, conf.decimal);
    }

}