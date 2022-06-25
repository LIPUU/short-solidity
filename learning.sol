// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.6.4 <0.9.0;
import "hardhat/console.sol";

contract MultiCall {
    function multiCall(address[] calldata targets, bytes[] calldata data)
        external
        view
    {
        require(targets.length == data.length, "target length != data length");

        for (uint i; i < targets.length; i++) {
            (bool success, bytes memory result) = targets[i].staticcall(data[i]);
            require(success, "call failed");
            console.logBytes(result);
        }
    }
}