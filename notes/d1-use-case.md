# D1 · Basic Demo 案例分析

> 本卡选择 Reactive Network 的 **Basic Demo**。为了把“哪条链”说清楚，采用最简单的测试配置：**Ethereum Sepolia 同时作为源链和目标链，Reactive Lasna 负责监听和判断**。同一条链可以同时承担源链和目标链两个角色。

## 一句话说明

当 Sepolia 上的 `BasicDemoL1Contract` 收到至少 `0.001 ETH` 时，Reactive 自动发现它发出的事件，并调用 Sepolia 上的 `BasicDemoL1Callback`，留下回调成功的记录。

## 1. 监听哪条链、哪个合约的什么事件？

- **源链：** Ethereum Sepolia（Chain ID：`11155111`）
- **源合约：** `BasicDemoL1Contract`（实际地址在部署后记为 `ORIGIN_ADDR`）
- **监听事件：** `Received`

`BasicDemoL1Contract` 收到 ETH 后会把 ETH 退还给发送者，同时发出 `Received` 事件。事件中记录交易发起者、直接调用者和转入金额，Reactive 订阅的正是这张“链上小票”。

## 2. 满足什么条件时触发？

`BasicDemoReactiveContract` 收到 `Received` 事件后，检查事件中的金额：

```text
value >= 0.001 ETH
```

- 达到或超过 `0.001 ETH`：请求目标链回调。
- 小于 `0.001 ETH`：不执行回调。

因此，`Received` 事件出现只代表 Reactive 看到了它；金额达到门槛，才代表真正满足了触发条件。

## 3. 在哪条链做什么动作？

- **目标链：** Ethereum Sepolia（Chain ID：`11155111`）
- **目标合约：** `BasicDemoL1Callback`（实际地址在部署后记为 `CALLBACK_ADDR`）
- **动作：** Reactive 通过 Sepolia 的 Callback Proxy 调用目标合约。目标合约先验证调用者是获授权的 Callback Proxy，然后发出 `CallbackReceived` 事件，记录这次回调已经送达。

这个 Basic Demo 的目标合约没有转账、交易等真实业务逻辑；它只负责证明“源链事件 → Reactive 判断 → 目标链回调”整条链路成功跑通。

## 4. 如果不用 Reactive，要怎么做？Reactive 简单在哪里，代价是什么？

### 不用 Reactive

通常要自己运行一个 24 小时在线的链下机器人：

1. 连接 Sepolia RPC，持续轮询新区块或订阅日志；
2. 找出 `BasicDemoL1Contract` 的 `Received` 事件；
3. 解码金额并判断是否达到 `0.001 ETH`；
4. 保存目标链私钥，自己签名并发送回调交易；
5. 处理断线、重复事件、区块回滚、nonce 冲突和交易失败后的重试。

也可以人工查看区块浏览器后手动调用目标合约，但这不及时，也不是真正的自动化。

### Reactive 让它简单在哪里

- 监听、条件判断和请求回调都可以写进智能合约，不必自己维护一台长期在线的机器人服务器；
- 规则公开地保存在链上，别人可以检查“监听什么、何时触发、触发后做什么”；
- Reactive Network 负责把源链事件送到 Reactive 合约，并把回调请求送往目标链。

### 需要付出的代价

- 要部署并维护源合约、Reactive 合约和回调合约，结构比单链合约更复杂；
- Reactive 合约执行需要 lREACT/REACT，目标链回调还要用目标链原生币支付费用；
- 即使目标回调执行失败，尝试回调所消耗的 Gas 仍可能产生费用；
- 只能使用 Reactive 当前支持的链，并依赖它的事件监听和回调基础设施；
- 跨链回调不是瞬间完成，仍要等待源链确认、Reactive 处理和目标链交易确认。

## 简图

```text
┌──────────────────────── 源链：Ethereum Sepolia ────────────────────────┐
│ BasicDemoL1Contract 收到 ETH，并发出 Received(origin, sender, value)   │
└────────────────────────────────┬────────────────────────────────────────┘
                                 │ 监听 Received 事件
                                 ▼
┌──────────────────────── Reactive Lasna ────────────────────────────────┐
│ BasicDemoReactiveContract                                             │
│ 判断：value >= 0.001 ETH？                                             │
│ 是 → 请求回调；否 → 不执行                                             │
└────────────────────────────────┬────────────────────────────────────────┘
                                 │ Callback Proxy 投递回调
                                 ▼
┌──────────────────────── 目标链：Ethereum Sepolia ──────────────────────┐
│ BasicDemoL1Callback 验证来电者，并发出 CallbackReceived 事件           │
└─────────────────────────────────────────────────────────────────────────┘
```

## 当前版本注意事项

官方仓库当前的 Basic Demo 源码仍使用旧版 `service.subscribe`、`vmOnly` 和 `emit Callback`。本卡保留其案例逻辑，但如果真正部署到当前 Omni 网络，应改用 `SYSTEM.subscribe`、`react() external onlySystem` 和 `SYSTEM.requestCallbackV_1_0`，并重新核对 Callback Proxy 与权限。

## 参考

- [Reactive Network Basic Demo（本次课程材料）](https://github.com/Reactive-Network/reactive-smart-contract-demos/tree/main/src/demos/basic)
- [Reactive Network：Origins & Destinations](https://dev.reactive.network/origins-and-destinations)
- [Reactive Network：Callback Contracts](https://dev.reactive.network/callback-contracts)
