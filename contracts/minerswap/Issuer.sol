pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "../uniswapv2/libraries/TransferHelper.sol";
import "./interfaces/IMineToken.sol";

abstract contract Issuer is Ownable, ReentrancyGuard{
    using SafeMath for uint256;
    using SafeERC20 for IMineToken;

    address public issuerManager;
    uint32 public serialNumber;
    string public hostname;
    address public mineTokenManager;

    mapping(string => IMineToken) public mineTokenMap;
    event Deployed(string symbol,string name,address tokenAddress);

    constructor(
        string memory _hostname,
        address _mineTokenManager
    ) public {
        issuerManager = msg.sender;
        hostname = _hostname;
        mineTokenManager = _mineTokenManager;
    }

    receive() external payable {}

    function incSerialNumber() internal returns(uint32){
        serialNumber++;
        return serialNumber;
    }

    function getUniqueSymbol(string memory _symbol) internal returns (string memory symbol){
        symbol = string(abi.encodePacked(_symbol, uintToString(incSerialNumber())));
    }

    function addMineToken(address mineTokenAddress) internal {
        ERC20 mineTokenErc = ERC20(mineTokenAddress);
        mineTokenMap[mineTokenErc.symbol()]= IMineToken(mineTokenAddress);
        emit Deployed(mineTokenErc.symbol(), mineTokenErc.name(), mineTokenAddress);
    }

    function getMineToken(string memory symbol) public view returns(IMineToken mineToken){
        mineToken = mineTokenMap[symbol];
    }

    ///the owner can withdraw any erc20 token from himself
    function withdraw(address token, address to, uint256 amount) external onlyOwner nonReentrant{
        TransferHelper.safeTransfer(token, to, amount);
    }

    ///withdraw eth from this contract 
    function withdrawETH(address to, uint256 amount) external onlyOwner nonReentrant{
        TransferHelper.safeTransferETH(to, amount);
    }

    ///withdraw token from minetoken through symbol
    function withdrawFromMineToken(address token, string memory symbol, address to, uint256 amount) external onlyOwner nonReentrant{
        IMineToken mineToken = mineTokenMap[symbol];
        mineToken.withdrawToken(token, to, amount);
    }

    ///withdraw eth from minetoken through symbol
    function withdrawETHFromMineToken(string memory symbol, address to, uint256 amount) external onlyOwner nonReentrant{
        IMineToken mineToken = mineTokenMap[symbol];
        mineToken.withdrawETH(to, amount);
    }

    ///the owner can mint any amount tokens at any time!
    function mint(string memory symbol,uint256 amount) public onlyOwner {
        mineTokenMap[symbol].mint(address(this), amount);
    }
    
    string[] private sarr = ["0","1","2","3","4","5","6","7","8","9"];
    function uintToString(uint32 v) public view returns (string memory) {
        string memory strBuilder = "";
        while (v != 0) {
            uint8 remainder = uint8(v % 10);
            v = v / 10;
            strBuilder = string(abi.encodePacked(sarr[remainder], strBuilder));
        }
        return strBuilder;
    }

}
