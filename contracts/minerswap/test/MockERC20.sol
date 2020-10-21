pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockERC20 is ERC20 {
    constructor(
        string memory _name,
        string memory _symbol
    ) public ERC20(_name, _symbol) {
    }

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}