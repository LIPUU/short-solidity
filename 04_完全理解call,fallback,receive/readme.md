调用`caller`之后，打印结果是：  

    i'm receive function
  
    i'm fallback function,this is my calldata: when a man love a woman
  
    0xcc75c4b10000000000000000000000000000000000000000000000000000000000000005
    i'm abc function,print a num:5  

仔细研究一下这个输出结果:  
当abc函数被调时，打印`msg.data`，可以看到该调用的`calldata`就是`abi.encodeWithSelector(testCall.abc.selector, 5)`的结果。也就是说，在`calldata`的前四个字节能够被解析成被调合约地址的某个函数的函数选择器且后续参数也能被正确解析时，`call`就会调用这个函数。

而执行`call("")`时，`calldata`是空的，空的`calldata`使得`receive`被调用。  
至于`call("when a man love a woman")`, `calldata`不是空的，因此不会调用`receive`函数，而前四个字节又无法解析出目标合约地址的任意一个函数，因此会调用`fallback`函数。  

另外，向EOA账户转ether也可以通过call来实现，并且，无论该EOA账户的变量是否是payable的，转账都会成功：
```
// 可以通过call给EOA转ether
(bool ok,)=address(0x659f05D66Ba73b281B97A01aD21918e4475d20fE).call{value:0.5 ether}("");
```



