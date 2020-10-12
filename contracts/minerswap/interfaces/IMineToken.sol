pragma solidity 0.6.12;

interface IMineToken {

    ///所有的算力token 都需要继承
    /// 返回现金储备率，比如 btc token，要
    function cashReserveRatio() external view returns (uint256);

    ///
    function mint(address to,uint256 amount) public;

    function name() public view returns(string);

}