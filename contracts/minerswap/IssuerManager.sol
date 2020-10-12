pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./Issuer.sol"

interface IManagerMigrator {
  
    function migrate() external returns (); //TODO need add parameters 
}

/// Ownable just for the migration function
/// the version of V1 only include the BTC mine token
contract IssuerManagerV1 is Ownable {

    IManagerMigrator public migrator;

    mapping(string => address) issuerInfo;

    event DeployedIssuer(string hostname, address issuerAddress);

    function setMigrator(IManagerMigrator _migrator) public onlyOwner {
        migrator = _migrator;
    }
    
    function migrate() public {
        require(address(migrator) != address(0), "migrate: no migrator");
        //TODO migrate issuer info to new manager

    }

    function registIssuerBTC(string hostname) external returns (address issuerAddress) {
        require(issuerInfo[hostname] == address(0) ,"IssuerManager: hostname has exist!");//TODO When retrieving item that don't exist in the mapping, whether to return address(0)?

        bytes memory bytecode = type(IssuerBTC).creationCode;
        bytecode = abi.encodePacked(bytecode, abi.encode(hostname))
        bytes32 salt = keccak256(abi.encodePacked(hostname));//TODO Is it just for uniqueness?

        assembly {
            issuerAddress := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        IssuerBTC obj = IssuerBTC(issuerAddress);
        obj.transferOwnership(msg.sender); // TODO check if the syntax is correct

        issuerInfo[hostname] = issuerAddress;
        emit DeployedIssuer(hostname, issuerAddress);
    }

    function getIssuerAddress(string hostname) public view returns(address issuerAddrss){
        issuerAddress = issuerInfo[hostname];
    }



}