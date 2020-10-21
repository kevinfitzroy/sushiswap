pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IMineToken is IERC20{

    function mint(address _to, uint256 _amount) external;

    function withdrawToken(address _token, address _to, uint256 _amount) external;

    function withdrawETH(address _to, uint256 _amount) external;

    function buy(uint256 _amount) external;

    function harvest(uint256 _amount) external;

    function harvestTo(address _to, uint256 _numerator, uint256 _denominator) external returns (uint256);

    function getReward(address _account) external view returns (uint, uint);
}
