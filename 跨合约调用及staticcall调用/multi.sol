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
            // 通过提供给的合约地址及calldata调用相应合约的函数
            (bool success, bytes memory result) = targets[i].staticcall(data[i]);
            require(success, "call failed");
            console.logBytes(result);
        }
    }
}
