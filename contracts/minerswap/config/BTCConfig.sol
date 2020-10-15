pragma solidity 0.6.12;

import "@openzeppelin/contracts/access/Ownable.sol";

contract BTCConfig is Ownable{

    mapping(string => address) public btcAddress;

    constructor() public {
        btcAddress["wBTC"] = address(0);
        btcAddress["hBTC"] = address(0);
        btcAddress["sBTC"] = address(0);
        btcAddress["renBTC"] = address(0);
    }

    function update(string memory name, address addr) public onlyOwner{
        btcAddress[name] = addr;
    }

    function index(string memory name) public view returns (address){
        return btcAddress[name];
    }

}