// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.6.4 <0.9.0;
import "hardhat/console.sol";

contract testCall{
    fallback()payable external{
        console.log("i'm fallback function,this is my calldata: %s\n",string(msg.data));
    }

    function abc(uint num)payable public {
        console.logBytes(msg.data);
        console.log("i'm abc function,print a num:%s",num);
    }

    receive() payable external{
        console.log("i'm receive function\n");
    }
}

contract caller{
    // 0xf5059a5D33d5853360D16C683c16e67980206f36是testCall合约的部署地址
    address destination=0x5FC8d32690cc91D4c39d9d3abcBD16989F875707;
    function callTestCall() public {
        (bool ok_0,)=payable(destination).call("");
        require(ok_0);

        (bool ok_1,)=payable(destination).call("when a man love a woman");
        require(ok_1);

        (bool ok_2,)=payable(destination).call(abi.encodeWithSelector(testCall.abc.selector, 5));
        require(ok_2);
    }
}
