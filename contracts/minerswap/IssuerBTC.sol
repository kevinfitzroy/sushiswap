pragma solidity 0.6.12;

import "./Issuer.sol";
import "./minetoken/BtcMineToken.sol";
import "./config/BTCConfig.sol";

interface IMineTokenManager{
    function deployBtcMineToken(string memory name, string memory symbol) external returns(address payable);
}
interface IIssuerManager{
    function getBitcoinOracle() external view returns(address);
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
        address currency,
        uint256 buyPrice,
        uint256 buyTotalSupply,
        uint256 preMintNumber,
        uint256 buyStartTime,
        uint256 buyEndTime,
        uint256 startTime,
        uint256 endTime,
        string memory comment
    ) public onlyOwner returns (address payable mineTokenAddress){
        require(btcConfig.indexAddr(btc) != address(0), "BTCConfig: wrapper btc name does not exist!");
        mineTokenAddress = IMineTokenManager(mineTokenManager).deployBtcMineToken(NAME, getUniqueSymbol(SYMBOL));
        BtcMineToken(mineTokenAddress).initialize(btcConfig.indexAddr(btc), btcConfig.indexDecimal(btc), currency, IIssuerManager(issuerManager).getBitcoinOracle(), buyPrice, buyTotalSupply, buyStartTime, buyEndTime, startTime, endTime,comment);
        BtcMineToken(mineTokenAddress).mint(address(this), preMintNumber);
        addMineToken(mineTokenAddress);
    }
}
