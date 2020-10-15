pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../uniswapv2/libraries/TransferHelper.sol";
import "./interfaces/IMineToken.sol";
import "../Console.sol";

abstract contract Issuer is Ownable, Console{
    using SafeMath for uint256;
    using SafeERC20 for IMineToken;

    address public issuerManager;
    uint32 public serialNumber;
    string public hostname;

    event Deployed(string symbol,string name,address tokenAddress);

    mapping(string => IMineToken) public mineTokenMap;

    constructor(
        string memory _hostname
    ) public {
        issuerManager = msg.sender;
        hostname = _hostname;
    }

    function incSerialNumber() internal returns(uint32){
        serialNumber++;
        return serialNumber;
    }
    
    function getUniqueSymbol(string memory _symbol) internal returns (string memory symbol){
        symbol = string(abi.encodePacked(_symbol, uintToString(incSerialNumber())));
    }

    function addMineToken(string memory symbol,address mineTokenAddress) internal {
        mineTokenMap[symbol]= IMineToken(mineTokenAddress);
    }

    function getMineToken(string memory symbol) public view returns(IMineToken mineToken){
        mineToken = mineTokenMap[symbol];
    }

    ///the owner can withdraw any erc20 token and eth
    function withdraw(address token,address to,uint256 amount,string memory symbol) public onlyOwner{
        IMineToken mineToken = mineTokenMap[symbol];
        mineToken.safeTransferFrom(address(mineToken), to, amount);
    }

    // ///withdraw eth
    // function withdrawETH(address to,uint256 amount, string memory symbol) public onlyOwner {
    //     address mineToken = minePoolInfo[symbol];
    //     TransferHelper.safeTransferETH(to, amount);
    // }

    ///the owner can mint any number tokens at any time!
    function mint(string memory symbol,uint256 amount) public onlyOwner {
        IMineToken(mineTokenMap[symbol]).mint(address(this) ,amount);
    }

    function addLiquidity() public onlyOwner {

    }

    function removeLiquidity() public onlyOwner {

    }

    function addLiquidityETH () public onlyOwner {

    }

    function removeLiquidityETH() public onlyOwner {

    }

    function getMineTokenInLiquidityPool(IMineToken mineToken) public view returns(uint256) {
        return 0;
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