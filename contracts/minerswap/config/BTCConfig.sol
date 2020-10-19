pragma solidity 0.6.12;

import "@openzeppelin/contracts/access/Ownable.sol";

contract BTCConfig is Ownable{

    mapping(string => address) public btcAddress;

    constructor() public {
        btcAddress["wBTC"] = address(0x2260fac5e5542a773aa44fbcfedf7c193bc2c599));
        btcAddress["hBTC"] = address(0x0316EB71485b0Ab14103307bf65a021042c6d380);
        btcAddress["sBTC"] = address(0xfe18be6b3bd88a2d2a7f928d00292e7a9963cfc6);
    }

    function update(string memory name, address addr) public onlyOwner{
        btcAddress[name] = addr;
    }

    function index(string memory name) public view returns (address){
        return btcAddress[name];
    }

}