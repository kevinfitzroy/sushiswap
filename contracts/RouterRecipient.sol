pragma solidity 0.6.12;


contract  RouterRecipient {
    address public routerAddress;

    function setRouter(address _router) public;

    // Throws if called by any account other than the router
    modifier onlyRouter() {
        require(routerAddress == msg.sender, "RouterRecipient: caller is not the router");
        _;
    }
}