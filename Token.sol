// Solidity files have to start with this pragma.
// It will be used by the Solidity compiler to validate its version.
// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;
import "hardhat/console.sol";

interface _MultiCall{
    function multiCall(address[] calldata targets, bytes[] calldata data)
        external
        view;
}

contract TestMultiCall {
    function add1(uint _i) external pure returns (uint) {
        return _i+1;
    }

    function add10(uint _i) external pure returns (uint){
        return _i+10;
    }

    function getData1(uint _i) external pure  returns (bytes memory) {
        bytes memory fuck=abi.encodeWithSelector(this.add1.selector, _i);
        return fuck;
    }

    function getData10(uint _i) external pure  returns (bytes memory) {
        bytes memory fuck=abi.encodeWithSelector(this.add10.selector, _i);
        return fuck;
    }
}

contract MultiRun{
    address[]  addresses=new address[](2);
    bytes[]  data=new bytes[](2);
    address multicall_address=0x7969c5eD335650692Bc04293B07F5BF2e7A673C0;
    _MultiCall mutilcall=_MultiCall(multicall_address);

    function run() public{
        address[] storage _addresses=addresses;
        bytes[] storage _data=data;

        addresses.push(0x7bc06c482DEAd17c0e297aFbC32f6e63d3846650);
        addresses.push(0x7bc06c482DEAd17c0e297aFbC32f6e63d3846650);

        data.push(new TestMultiCall().getData1(1));
        data.push(new TestMultiCall().getData10(2));

        mutilcall.multiCall(_addresses,_data);
    }
}