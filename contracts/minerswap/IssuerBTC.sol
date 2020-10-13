pragma solidity 0.6.12;

import "./Issuer.sol";
import "./minetoken/BtcMineToken.sol";

contract IssuerBTC is Issuer {
    string public constant NAME = "MineTokenBTC";
    string public constant SYMBOL = "mtBTC";

     constructor(
        string memory _hostname
    ) public Issuer(_hostname){
    }

    function issue() public onlyOwner returns (address mineTokenAddress){
        string memory symbol = getUniqueSymbol(SYMBOL);
        bytes memory bytecode = type(BtcMineToken).creationCode;
        bytecode = abi.encodePacked(bytecode, abi.encode(NAME, symbol));
        bytes32 salt = keccak256(abi.encodePacked(symbol, address(this)));
        assembly {
            mineTokenAddress := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        BtcMineToken mineToken = BtcMineToken(mineTokenAddress);
        
        addPoolInfo(symbol, mineTokenAddress);
    }
}