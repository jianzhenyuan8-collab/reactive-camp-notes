# D1 · Uniswap V2 Stop-Loss & Take-Profit 案例卡

> 目标：在一个个人合约里管理多张止损单和止盈单，并按订单数量动态订阅 Uniswap Pair。

## 一句话说明

用户创建订单后，Reactive 自动订阅相应 Pair 的 `Sync`；价格下跌到止损线或上涨到止盈线时触发换币，最后在该 Pair 没有活动订单时取消订阅。

## 1. 监听哪条链、哪个合约的什么事件？

首先监听个人回调合约的五类生命周期事件：

- `StopOrderCreated`
- `StopOrderCancelled`
- `StopOrderExecuted`
- `StopOrderPaused`
- `StopOrderResumed`

收到第一张新订单后，再动态订阅对应 Uniswap V2 Pair 的 `Sync` 事件；该 Pair 的活动订单清零后取消订阅。

## 2. 满足什么条件时触发？

- 订单状态为 Active；
- 止损单：当前价格小于或等于阈值；
- 止盈单：当前价格大于或等于阈值；
- 距离上次尝试至少经过 5 分钟；
- 尝试次数少于 5 次。

## 3. 在哪条链做什么动作？

目标链回调 `executeStopOrder(orderId)`：重新检查价格，从用户账户拉取授权代币，通过 Uniswap V2 Router 换币，并把结果返回用户。成功后发出 `StopOrderExecuted`，Reactive 更新状态并在必要时取消 Pair 订阅。

相比单张 Stop Order，这个版本增加了多订单、暂停、恢复、取消、失败冷却和动态订阅。

## 4. 如果不用 Reactive，要怎么做？

需要由中心化交易所托管订单，或者运行自己的价格机器人。Reactive 让订单配置、价格事件、执行与订单生命周期都在链上衔接。

代价仍包括 Gas、滑点、MEV、额度授权和价格操纵风险；订单触发不等于一定按阈值成交，失败重试还会继续产生费用。

## 简图

```text
创建订单 → Reactive 订阅 Pair Sync
                       ↓
             计算价格与订单阈值
             ↙                 ↘
      止损：价格下降       止盈：价格上涨
             ↘                 ↙
              回调执行 Uniswap 换币
                       ↓
             完成订单 / 无订单则退订
```

## 当前源码注意事项

- 源码使用旧版 Reactive API 和旧式自身回调来动态订阅。
- 源码把名为 `SEPOLIA_CHAIN_ID` 的常量写成 `1`，但 `1` 实际是 Ethereum Mainnet；又把注释为 Lasna 的 `REACTIVE_CHAIN_ID` 写成主网 `1597`。README 却按 Sepolia 测试流程说明，部署前必须统一成正确网络参数。
- 即时储备价格容易被操纵，生产环境应考虑 TWAP、最小输出、截止时间和更严格的重试策略。

## 参考

- [Demo README](https://github.com/Reactive-Network/reactive-smart-contract-demos/tree/main/src/demos/uniswap-v2-stop-take-profit-order)
- [Reactive 合约源码](https://github.com/Reactive-Network/reactive-smart-contract-demos/blob/main/src/demos/uniswap-v2-stop-take-profit-order/UniswapDemoStopTakeProfitReactive.sol)
- [回调合约源码](https://github.com/Reactive-Network/reactive-smart-contract-demos/blob/main/src/demos/uniswap-v2-stop-take-profit-order/UniswapDemoStopTakeProfitCallback.sol)
