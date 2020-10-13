pragma solidity 0.6.12;

import "./IMineToken.sol";

interface IIssuer {
    
    function getMineTokenInLiquidityPool(IMineToken mineToken) external view returns(uint256);
}