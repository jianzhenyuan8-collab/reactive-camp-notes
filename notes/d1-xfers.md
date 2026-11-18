# D1 · Xfers：监听 Sepolia ERC-20 Transfer

> 2026-11-18 实测。基于 Reactive Network Omni 写法，在 Lasna 部署一个 Reactive 合约，监听 Sepolia 上指定测试代币的 `Transfer` 事件。

## 提交结果

1. **Reactive 合约：** [`0x9b3e...5579`](https://lasna.reactscan.net/address/0x9b3eaeaBEdE38F7DaC71d9E17BdeA7E1F75F5579)
2. **成功调用 `react()` 的交易：** [`0xa190...eb7b`](https://lasna.reactscan.net/tx/0xa1909ff173771a9836fd2564cec49d4d0c71727187a94b08cc2583247e10eb7b)
3. **订阅过滤条件：** 监听 Ethereum Sepolia 上我部署的 CampToken 合约发出的所有 ERC-20 `Transfer` 事件，不限制发送者、接收者和金额，最多成功处理 3 次后自动取消订阅。

## 链上地址与交易

| 项目 | 网络 | 链上链接 |
|---|---|---|
| CampToken | Ethereum Sepolia | [`0xf202...3c77`](https://sepolia.etherscan.io/address/0xf2026c4bD8e9c00e0e3696bd191E02061D953c77) |
| CampToken 部署交易 | Ethereum Sepolia | [`0xb93a...c373`](https://sepolia.etherscan.io/tx/0xb93a51435c1b93840aa290a3aed0892eca881370b769989257c5b79c8ff4c373) |
| 第一次 Transfer | Ethereum Sepolia | [`0x1fcc...4f9f`](https://sepolia.etherscan.io/tx/0x1fcc91633cb31c3dfa8519bb745381c93d8655cc674f11a03529ad79502d4f9f) |
| TransferCounter | Reactive Lasna | [`0x9b3e...5579`](https://lasna.reactscan.net/address/0x9b3eaeaBEdE38F7DaC71d9E17BdeA7E1F75F5579) |
| TransferCounter 部署交易 | Reactive Lasna | [`0xf4eb...6ad2`](https://lasna.reactscan.net/tx/0xf4ebca6be32961674b1427ba1e7658864deacf2a8fab6ee70905ed7ca5dd6ad2) |
| 第一次 react() | Reactive Lasna | [`0xa190...eb7b`](https://lasna.reactscan.net/tx/0xa1909ff173771a9836fd2564cec49d4d0c71727187a94b08cc2583247e10eb7b) |

## 它怎样工作？

流程是：

```text
Sepolia CampToken.transfer()
            ↓ 发出 Transfer 事件
Reactive Network 的订阅过滤器
            ↓ 匹配指定链、合约和 topic0
Lasna TransferCounter.react()
            ↓
记录 from、to、amount，并把计数加 1
            ↓
处理满 3 次后自动 unsubscribe
```

### 1. 构造函数完成订阅

```solidity
SYSTEM.subscribe(
    SEPOLIA_CHAIN_ID,
    TOKEN,
    TRANSFER_TOPIC_0,
    REACTIVE_IGNORE,
    REACTIVE_IGNORE,
    REACTIVE_IGNORE
);
```

- `SEPOLIA_CHAIN_ID = 11155111`：只监听 Ethereum Sepolia；
- `TOKEN`：只监听自己部署的 CampToken；
- `TRANSFER_TOPIC_0`：标准 ERC-20 `Transfer(address,address,uint256)`；
- 三个 `REACTIVE_IGNORE`：不限制发送者、接收者和第三个 indexed topic。

### 2. react() 只能由系统调用

```solidity
function react(LogRecord calldata log_) external onlySystem {
    // 解码并记录 Transfer，然后更新次数。
}
```

`onlySystem` 防止普通钱包伪造事件，直接调用 `react()` 修改计数。

### 3. 达到上限后自动退订

```solidity
processed += 1;
remaining -= 1;

if (remaining == 0) {
    _unsubscribe();
}
```

部署时设置 `limit = 3`，避免测试期间无限处理事件并不断消耗 lREACT。

## 第一次触发的验证结果

源链交易发出了标准 Transfer 日志：

| 字段 | 实测结果 |
|---|---|
| 来源链 | Ethereum Sepolia，chain ID `11155111` |
| 来源合约 | `0xf2026c4bD8e9c00e0e3696bd191E02061D953c77` |
| from | `0xAFDF23f148BFaA585418F02d1DD120Fd81211C7f` |
| to | `0xAFDF23f148BFaA585418F02d1DD120Fd81211C7f` |
| amount | `1 CAMP` |
| Sepolia 交易状态 | success |

Reactive 侧追踪结果：

| 字段 | 实测结果 |
|---|---|
| Reactive 区块 | `8662203` |
| react() 交易 | `0xa1909ff173771a9836fd2564cec49d4d0c71727187a94b08cc2583247e10eb7b` |
| react() 结果 | 成功，没有回滚 |
| `processed` | `1` |
| `remaining` | `2` |
| `debt` | `0 lREACT` |
| 订阅状态 | 仍然 active |

本案例不需要目标链回调；`react()` 的动作就是在 Lasna 合约中记录 Transfer 并更新计数，所以没有 callback 是预期结果。

## 资金说明

部署 `TransferCounter` 时通过 payable 构造函数转入 `0.1 lREACT`。第一次执行后合约余额约为 `0.0748435 lREACT`，且 `debt = 0`。合约继承的 `AbstractPayer.pay()` 允许系统从合约 balance 收取反应费用。

## 我学到的关键点

- 构造函数中的 `subscribe()` 必须由 Reactive 合约自己调用；
- 通配 topic 使用 `REACTIVE_IGNORE`，不能用 `0`；
- `react()` 必须使用 `onlySystem`；
- 普通过滤失败应当 `return`，不要 `revert`；
- `unsubscribe()` 的六个参数必须和 `subscribe()` 完全一致；
- Reactive 合约需要提前准备 lREACT，否则产生 debt 后会停止执行。

