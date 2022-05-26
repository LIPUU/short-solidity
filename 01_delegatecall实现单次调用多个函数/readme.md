整体的调用流程是：  
`TestMultiDelegatecall.multiDelegatecall -> delegatecall-> func1 / func2 / mint() ..`  
继承`MultiDelegatecall`的contract都会拥有回调自身函数的能力，因为调用子contract的`multiDelegatecall`时，由于是该函数是子合约的实例继承自父合约的，因此`address(this)`得到的是子合约的地址,只要传递了正确的`abi`编码即可在**一次交易**中实现回调自身合约多个函数的能力。  
由于delegatecall的特殊性质，在本例中，当最终执行到func1/func2/funcMint的时候，msg.sender是`runDelegateCall`的合约地址.  
如果这些函数中任意一个执行失败，前面函数的执行结果也会回滚。