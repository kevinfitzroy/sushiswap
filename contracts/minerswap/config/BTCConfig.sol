pragma solidity 0.6.12;

import "@openzeppelin/contracts/access/Ownable.sol";

contract BTCConfig is Ownable{

    mapping(string => address) public btcAddress;

    constructor() public {
        btcAddress["wBTC"] = 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;
        btcAddress["hBTC"] = 0x0316EB71485b0Ab14103307bf65a021042c6d380;
        btcAddress["sBTC"] = 0xfE18be6b3Bd88A2D2A7f928d00292E7a9963CfC6;
    }

    function update(string memory name, address addr) public onlyOwner{
        btcAddress[name] = addr;
    }

    function index(string memory name) public view returns (address){
        return btcAddress[name];
    }

}