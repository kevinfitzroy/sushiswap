pragma solidity 0.6.12;

interface IIssuer {
    
    function getMineTokenInLiquidityPool(IMineToken mineToken) public view returns(uint256);
}