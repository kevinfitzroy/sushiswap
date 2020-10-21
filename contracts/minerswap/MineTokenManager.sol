pragma solidity 0.6.12;

import "./minetoken/BtcMineToken.sol";

contract MineTokenManager{

    function deployBtcMineToken(string memory name,string memory symbol) public returns(address payable mineTokenAddress){
        bytes memory bytecode = type(BtcMineToken).creationCode;
        bytecode = abi.encodePacked(bytecode, abi.encode(name, symbol));
        bytes32 salt = keccak256(abi.encodePacked(symbol, address(this)));
        assembly {
            mineTokenAddress := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        BtcMineToken mineToken = BtcMineToken(mineTokenAddress);
        mineToken.transferOwnership(msg.sender);
    }
}