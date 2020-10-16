pragma solidity 0.6.12;

import "./Issuer.sol";
import "./minetoken/BtcMineToken.sol";
import "./config/BTCConfig.sol";

interface IMineTokenManager{
    function deployBtcMineToken(string memory name, string memory symbol) external returns(address);
}
contract IssuerBTC is Issuer {
    string public constant NAME = "MineTokenBTC";
    string public constant SYMBOL = "mtBTC";
    BTCConfig public btcConfig;

    constructor(
        string memory hostname,
        BTCConfig _btcConfig,
        address mineTokenManager
    ) public Issuer(hostname, mineTokenManager){
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
        mineTokenAddress = IMineTokenManager(mineTokenManager).deployBtcMineToken(NAME, getUniqueSymbol(SYMBOL));
        BtcMineToken(mineTokenAddress).initialize(btcConfig.index(btc), btcDecimals, currency, btcOracle, buyPrice, buyTotalSupply, buyStartTime, buyEndTime, startTime, endTime);
        BtcMineToken(mineTokenAddress).mint(address(this), preMintNumber);
        addMineToken(mineTokenAddress);
    }
}
