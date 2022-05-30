// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
import "hardhat/console.sol";
contract Proxy {
    event Deploy(address);

    fallback() external payable {}

    // 横看竖看，_code都被当成是传进来的参数在memory中的起始位置
    // 在memory中bytes的布局由两部分构成，第一部分是32字节，是bytes的长度，第二部分是bytes的实际数据
    function deploy(bytes memory _code) external payable returns (address addr) {
        assembly {
            // create(v, p, n)
            // v = amount of ETH to send
            // p = pointer in memory to start of code
            // n = size of code
            addr := create(callvalue(), add(_code, 0x20), mload(_code))
            // 比如add这里，_code被当成起始位置，然后加0x20=32字节正好略过bytes的长度，直接得到真实数据的起始位置
            // mload(_code)则是从_code的起始位置拿到32字节的数据，里面装的是_code的长度信息。
            // 它们被完美第提供给create，用以部署合约。
        }
        // return address 0 on error
        require(addr != address(0), "deploy failed");

        emit Deploy(addr);
    }


    receive() payable external {}
}

contract TestContract1 {
    address public owner = msg.sender;

    function setOwner(address _owner) public {
        // require(msg.sender == owner, "not owner"); // owner是Proxy合约的地址。所以执行的时候也要通过它执行
        owner = _owner;
    }
}

contract TestContract2 {
    address public owner = msg.sender;
    uint public value = msg.value;
    uint public x;
    uint public y;

    constructor(uint _x, uint _y) payable {
        x = _x;
        y = _y;
    }
}

contract Helper {
    function getBytecode1() external  returns (bytes memory) {
        bytes memory bytecode = type(TestContract1).creationCode;
        return bytecode;
    }

    function getBytecode2(uint _x, uint _y) external view returns (bytes memory) {
        bytes memory bytecode = type(TestContract2).creationCode;
        console.logUint(bytecode.length); // 717
        console.logUint(abi.encodePacked(bytecode, abi.encode(_x, _y)).length); // 781
        // 781-717=64 说明这两个参数每个参数都占用32字节

        return abi.encodePacked(bytecode, abi.encode(_x, _y));
    }

}

contract test_deploy{
    function run_contract1()public{
        bytes memory test_contract1_code=new Helper().getBytecode1();
        address contract1=new Proxy().deploy(test_contract1_code);
        (bool ok,)=contract1.call(abi.encodeWithSelector(TestContract1.setOwner.selector,address(0x00)));
        require(ok);
    }
}
