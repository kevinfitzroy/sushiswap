pragma solidity 0.6.12;

interface IMultiowned {
    function confirmAndCheck(bytes32 _operation) external returns (bool);
}