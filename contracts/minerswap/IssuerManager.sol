pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./IssuerBTC.sol";
import "./interfaces/IManagerMigrator.sol";

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

    function removeIssuer(string memory hostname) public onlyOwner {
        issuerInfo[hostname] = address(0);
    }
    
    function addIssuer(string memory hostname, address issuerAddress) public onlyOwner{
        require(issuerInfo[hostname] == address(0) ,"IssuerManager: hostname already exist!");
        issuerInfo[hostname] = issuerAddress;
    }

    function registIssuerBTC(string memory hostname) external returns (address issuerAddress) {
        require(issuerInfo[hostname] == address(0) ,"IssuerManager: hostname already exist!");

        bytes memory bytecode = type(IssuerBTC).creationCode;
        bytecode = abi.encodePacked(bytecode, abi.encode(hostname));
        bytes32 salt = keccak256(abi.encodePacked(hostname, block.timestamp));
        assembly {
            issuerAddress := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        IssuerBTC obj = IssuerBTC(issuerAddress);
        obj.transferOwnership(msg.sender);

        issuerInfo[hostname] = issuerAddress;
        emit DeployedIssuer(hostname, issuerAddress);
    }

    function getIssuerAddress(string memory hostname) public view returns(address issuerAddress){
        issuerAddress = issuerInfo[hostname];
    }

}