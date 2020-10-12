pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../uniswapv2/libraries/TransferHelper.sol";
import "./interfaces/IMineToken.sol"

contract Issuer is Ownable{
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    address public ownerPool;

    string public immutable hostname;//hostname

    event Deployed(string symbol,string name,address tokenAddress);

    struct MinePoolInfo {
        IMineToken mineToken; // mine contract address
    }

    MinePoolInfo[] public minePoolInfo;

    constructor(
        string _hostname
    ) public {
        ownerPool = msg.sender;
        hostname = _hostname;
    }
    
    //TODO can subclass be called a function that with internal type?
    function addPoolInfo(string name,address mineTokenAddress) internal {
        minePoolInfo.push(MinePoolInfo({
            mineToken: IMineToken(mineTokenAddress),
            //TODO need more info
        }))
    }

    ///the owner can withdraw any erc20 token and eth
    function withdraw(IERC20 token,address to,uint256 amount,uint256 tid) public onlyOwner{
        address mineToken = minePoolInfo[tid];
        TransferHelper.safeTransferFrom(token, mineToken, to, amount);
    }

    ///withdraw eth
    function withdrawETH(address to,uint256 amount, uint256 tid) public onlyOwner {
        address mineToken = minePoolInfo[tid];
        TransferHelper.safeTransferETH(to, amount);
    }

    ///the owner can mint any number tokens at any time!
    function mint(uint256 tid,uint256 amount) public onlyOwner {
        IMineToken(minePoolInfo[tid]).mint(msg.sender ,amount)
    }

    function addLiquidity() public onlyOwner {

    }

    function removeLiquidity() public onlyOwner {

    }

    function addLiquidityETH () public onlyOwner {

    }

    function removeLiquidityETH() public onlyOwner {

    }
}