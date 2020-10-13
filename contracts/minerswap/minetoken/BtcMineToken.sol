pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "../interfaces/IMineToken.sol";

contract BtcMineToken is IMineToken, ERC20, Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    constructor(
        string memory _name,
        string memory _symbol
    ) public ERC20(_name, _symbol) {
    }

     ///所有的算力token 都需要继承
    /// 返回现金储备率，比如 btc token，要
    function cashReserveRatio() external override view returns (uint256){
        return 502;
    }

    ///
    function mint(address to,uint256 amount) public override{
         _mint(to, amount);
    }

}