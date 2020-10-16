pragma solidity 0.6.12;

import "./Issuer.sol";
import "./minetoken/BtcMineToken.sol";
import "./config/BTCConfig.sol";

contract IssuerBTC is Issuer {
    string public constant NAME = "MineTokenBTC";
    string public constant SYMBOL = "mtBTC";
    BTCConfig public btcConfig;

    constructor(
        string memory hostname,
        BTCConfig _btcConfig
    ) public Issuer(hostname){
        btcConfig = _btcConfig;
    }

    function issue(
        string memory btc, 
        uint8 btcDecimals, 
        address currency,
        address btcOracle,
        uint256 buyPrice,
        uint256 buyTotalSupply,
        uint256 preMintNumber,
        uint256 buyStartTime,
        uint256 buyEndTime,
        uint256 startTime,
        uint256 endTime
    ) public onlyOwner returns (address mineTokenAddress){
        require(btcConfig.index(btc) != address(0), "BTCConfig: wrapper btc name does not exist!");
        mineTokenAddress = deployMineToken();
        BtcMineToken mineToken = BtcMineToken(mineTokenAddress);
        address btcConfigAddress = btcConfig.index(btc);
        mineToken.initialize(btcConfigAddress, btcDecimals, currency, btcOracle, buyPrice, buyTotalSupply, buyStartTime, buyEndTime, startTime, endTime);
        mineToken.mint(address(this), preMintNumber);
    }

    function deployMineToken() internal returns(address mineTokenAddress){
        string memory symbol = getUniqueSymbol(SYMBOL);
        bytes memory bytecode = type(BtcMineToken).creationCode;
        bytecode = abi.encodePacked(bytecode, abi.encode(NAME, symbol));
        bytes32 salt = keccak256(abi.encodePacked(symbol, address(this)));
        assembly {
            mineTokenAddress := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        addMineToken(symbol, mineTokenAddress);
        emit Deployed(symbol, NAME, mineTokenAddress);
    }
}