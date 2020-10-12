pragma solidity 0.6.12;

import "./Issuer.sol";

contract IssuerBTC is Issuer {

    
    function issue (
        string memory _name,
        string memory _symbol, //TODO
        uint256 _supply,
        address _btc,
        address _usdt,
        address _btcOracle,
        uint256 _buyPrice,
        uint _buyEndTime,
        uint _startTime,
        uint _endTime
    ) public onlyOwner returns (address mineTokenAddress){

        bytes memory bytecode = type(BitcoinMinerERC20).creationCode;
        bytes32 salt = keccak256(abi.encodePacked());
        assembly {
            mineTokenAddress := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        BitcoinMinerERC20 mineToken = BitcoinMinerERC20(mineTokenAddress);
        mineToken.initialize(_name,_symbol,_supply);//TODO
        
        addPoolInfo(name,mineTokenAddress);
    }
}