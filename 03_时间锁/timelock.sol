// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
// original: https://solidity-by-example.org/app/time-lock
contract TimeLock {
    error NotOwnerError();
    error AlreadyQueuedError(bytes32 txId);
    error TimestampNotInRangeError(uint blockTimestamp, uint timestamp);
    error NotQueuedError(bytes32 txId);
    error TimestampNotPassedError(uint blockTimestmap, uint timestamp);
    error TimestampExpiredError(uint blockTimestamp, uint expiresAt);
    error TxFailedError();

    event Queue(
        bytes32 indexed txId,
        address indexed target,
        uint value,
        string func,
        bytes data,
        uint timestamp
    );

    event Execute(
        bytes32 indexed txId,
        address indexed target,
        uint value,
        string func,
        bytes data,
        uint timestamp
    );
    event Cancel(bytes32 indexed txId);

    uint public constant MIN_DELAY = 10; // seconds
    uint public constant MAX_DELAY = 1000; // seconds
    uint public constant GRACE_PERIOD = 1000; // seconds

    address public owner;
    // tx id => queued
    mapping(bytes32 => bool) public queued;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert NotOwnerError();
        }
        _;
    }

    receive() external payable {}

    function getTxId(
        address _target,
        uint _value,
        string calldata _func,
        bytes calldata _data,
        uint _timestamp
    ) public pure returns (bytes32) {
        return keccak256(abi.encode(_target, _value, _func, _data, _timestamp));
    }

    /**
     * @param _target Address of contract or account to call
     * @param _value Amount of ETH to send
     * @param _func Function signature, for example "foo(address,uint256)"
     * @param _data ABI encoded data send.
     * @param _timestamp Timestamp after which the transaction can be executed.
     */
    function queue(
        address _target,
        uint _value,
        string calldata _func,
        bytes calldata _data,
        uint _timestamp
    ) external onlyOwner returns (bytes32 txId) {
        txId = getTxId(_target, _value, _func, _data, _timestamp);
        if (queued[txId]) {
            revert AlreadyQueuedError(txId);
        }
        // ---|------------|---------------|-------
        //  block    block + min     block + max
        if (
            _timestamp < block.timestamp + MIN_DELAY || // 该操作想要执行的最早时间不得早于入queen交易的时间戳向后推迟MIN_DELAY
            _timestamp > block.timestamp + MAX_DELAY // 想要执行的最晚时间在预定时不得晚于入queen交易的时间戳向后推迟MIN_DELAY
        ) {
            revert TimestampNotInRangeError(block.timestamp, _timestamp);
        }
        // 也就是说该操作预定的执行时间必须处在一个合适的区间里

        queued[txId] = true;

        emit Queue(txId, _target, _value, _func, _data, _timestamp);
    }
    // 为了让用户信任，大权限操作加入queen。必须经过固定的时间间隔之后才有权利调用execute来执行这个交易。
    // 比如，首先给入queen的操作设置成只有owner才能调用。
    // 即使是owner也只能先入queen然后再经过预定的时间才能执行。

    function execute(
        address _target,
        uint _value,
        string calldata _func,
        bytes calldata _data,
        uint _timestamp
    ) external payable onlyOwner returns (bytes memory) {
        // 构造一个和入queen时完全一样的交易，否则queen里面想要执行的交易无法被执行
        bytes32 txId = getTxId(_target, _value, _func, _data, _timestamp); 
        if (!queued[txId]) {
            revert NotQueuedError(txId);
        }
        // ----|-------------------|-------
        //  timestamp    timestamp + grace period
        if (block.timestamp < _timestamp) { // 尝试执行某操作时的时间戳早于预定的执行时间是非法的
            revert TimestampNotPassedError(block.timestamp, _timestamp);
        }
        if (block.timestamp > _timestamp + GRACE_PERIOD) {
            revert TimestampExpiredError(block.timestamp, _timestamp + GRACE_PERIOD);
        }
        // 定义：设某操作入queen时那笔交易时的时间戳为T1，
        // 那么它预定执行的时间戳_timestamp一定有 T1+MIN_DELAY< _timestamp < T1+MAX_DELAY
        // 那么实际请求执行的时间T2一定有T>_timestamp。但是允许 T1+MAX_DELAY < T2 < T1+GRACE_PERIOD (GRACE_PERIOD>MAX_DELAY)
        // MAX_DELAY使得申请入queen时不会误申请一个不合理的数字使得很晚才能执行操作
        // GRACE_PERIOD使得某操作可以比预定的时间再晚一点执行

        queued[txId] = false;

        // prepare data
        bytes memory data;
        if (bytes(_func).length > 0) {
            // data = func selector + _data

            data = abi.encodePacked(bytes4(keccak256(bytes(_func))), _data);
            // 由于_data是外部用encode方式打包好传进来的，因此这里只能用abi.encodePacked进行二次打包，这样就能在前面附上4字节函数选择器。
            // 这样就和一开始用encodeWithSelector打包完全没区别了：4字节选择器+被padding的参数们
            // 如果不用encodePacked，而是encode或者encodeWithSelector等遵从encode方式的编码方式
            // 第一个参数会被从4字节padding成32字节，导致交给call的时候，虽然能够正确解析出前4个字节的函数选择器但多出来28字节的0，从而导致调用失败
        } else {
            // call fallback with data
            data = _data;
        }

        // call target
        (bool ok, bytes memory res) = _target.call{value: _value}(data);
        if (!ok) {
            revert TxFailedError();
        }

        emit Execute(txId, _target, _value, _func, _data, _timestamp);

        return res;
    }

    function cancel(bytes32 _txId) external onlyOwner {
        if (!queued[_txId]) {
            revert NotQueuedError(_txId);
        }

        queued[_txId] = false;

        emit Cancel(_txId);
    }
}