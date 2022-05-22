// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
import "hardhat/console.sol";

contract MultiDelegatecall {
    error DelegatecallFailed();

    function multiDelegatecall(bytes[] memory data)
        public
        payable
        returns (bytes[] memory results)
    {
        results = new bytes[](data.length);

        for (uint i; i < data.length; i++) {
            (bool ok, bytes memory res) = address(this).delegatecall(data[i]);
            if (!ok) {
                revert DelegatecallFailed();
            }
            results[i] = res;
        }
    }
}

contract TestMultiDelegatecall is MultiDelegatecall {
    event Log(address caller, string func, uint i);

    function func1(uint x, uint y) external {
        emit Log(msg.sender, "func1", x + y);
    }

    function func2() external returns (uint) {
        // msg.sender = alice
        emit Log(msg.sender, "func2", 2);
        return 111;
    }

    mapping(address => uint) public balanceOf;

    // WARNING: unsafe code when used in combination with multi-delegatecall
    // user can mint multiple times for the price of msg.value
    function mint() external payable {
        balanceOf[msg.sender] += msg.value;
    }
}

contract Helper {
    function getFunc1Data(uint x, uint y) external pure returns (bytes memory) {
        return abi.encodeWithSelector(TestMultiDelegatecall.func1.selector, x, y);
    }

    function getFunc2Data() external pure returns (bytes memory) {
        return abi.encodeWithSelector(TestMultiDelegatecall.func2.selector);
    }

    function getMintData() external pure returns (bytes memory) {
        return abi.encodeWithSelector(TestMultiDelegatecall.mint.selector);
    }
}

contract runDelegateCall {
    bytes[] data=new bytes[](3);
    function run() public {
        Helper helper=new Helper();

        bytes memory func1_data=helper.getFunc1Data(1,2);
        bytes memory func2_data=helper.getFunc2Data();
        bytes memory funcMint_data=helper.getMintData();
        data[0]=func1_data;
        data[1]=func2_data;
        data[2]=funcMint_data;

        // 0xCA8c8688914e0F7096c920146cd0Ad85cD7Ae8b9是MultiDelegatecall的部署地址
        TestMultiDelegatecall tmdc=TestMultiDelegatecall(0x96F3Ce39Ad2BfDCf92C0F6E2C2CAbF83874660Fc);
        tmdc.multiDelegatecall(data);
    }
}