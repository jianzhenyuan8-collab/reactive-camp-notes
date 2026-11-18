# D1 · Uniswap V2 Stop Order 案例卡

> 目标：当 Uniswap V2 交易对价格跌到阈值时，自动卖出代币，形成一次性止损单。

## 一句话说明

Reactive 监听 Uniswap V2 Pair 每次储备量变化产生的 `Sync` 事件，按储备量计算价格；价格跌破阈值时，自动调用 Sepolia 上的止损合约执行换币。

## 1. 监听哪条链、哪个合约的什么事件？

- **源链：** Ethereum Sepolia（`11155111`）。
- **Uniswap Pair：** 监听 `Sync(uint112 reserve0, uint112 reserve1)`；
- **止损回调合约：** 监听 `Stop`，确认止损已经执行。

`Sync` 会在池子储备变化时出现，因此可以用 reserve0 与 reserve1 的比例估算当前池内价格。

## 2. 满足什么条件时触发？

- 订单尚未触发；
- 根据卖出方向计算的储备价格小于或等于用户设置的阈值；
- 用户已经授权目标回调合约使用要卖出的代币。

这是一次性订单：第一次满足条件后设置 `triggered = true`，避免重复发送回调。

## 3. 在哪条链做什么动作？

在 Ethereum Sepolia 调用 `UniswapDemoStopOrderCallback.stop()`：

1. 再次读取交易对储备并验证价格；
2. 从用户账户拉取已授权代币；
3. 通过 Uniswap V2 Router 执行兑换；
4. 把换得代币发回用户；
5. 发出 `Stop` 事件确认完成。

## 4. 如果不用 Reactive，要怎么做？

用户只能持续盯盘后手动交易，或者运行 24 小时在线的止损机器人。Reactive 让价格变化事件直接启动链上判断和执行，无需维护自己的监听服务器。

代价包括 Reactive 与回调 Gas、Uniswap 手续费、滑点和 MEV；池内瞬时价格可能被操纵，条件满足也不保证最终成交价等于阈值。

## 简图

```text
Uniswap Pair 储备变化 → Sync(reserve0, reserve1)
                           ↓
StopOrderReactive 计算价格 ≤ 阈值？
                           ↓ 是
Sepolia 回调重验价格 → 拉取代币 → Uniswap 换币 → 返回用户
```

## 当前源码注意事项

- 源码使用旧版 Reactive API。
- 源码 TODO 明确指出 `Stop` 完成确认没有充分检查转账方向；完成后也没有真正取消订阅。
- `react()` 在 `done` 后使用 `assert(!done)`，若仍收到已订阅事件可能回退并继续产生费用。
- 只依赖单个池子的即时 reserve 比例容易受到短时价格操纵，生产环境应增加 TWAP、滑点和截止时间保护。

## 参考

- [Demo README](https://github.com/Reactive-Network/reactive-smart-contract-demos/tree/main/src/demos/uniswap-v2-stop-order)
- [Reactive 合约源码](https://github.com/Reactive-Network/reactive-smart-contract-demos/blob/main/src/demos/uniswap-v2-stop-order/UniswapDemoStopOrderReactive.sol)
- [回调合约源码](https://github.com/Reactive-Network/reactive-smart-contract-demos/blob/main/src/demos/uniswap-v2-stop-order/UniswapDemoStopOrderCallback.sol)
