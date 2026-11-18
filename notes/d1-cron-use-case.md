# D1 · Cron Demo 案例分析

> 这是 Basic Demo 之后的补充案例。它展示的不是“有人做了一件事后触发”，而是“每隔若干区块自动触发”。本卡只分析原理，不代表已经部署或完成链上验证。

## 一句话说明

Cron Demo 像一个运行在 Reactive Network 上的链上闹钟：网络按固定区块间隔发出 Cron 事件，`BasicCronContract` 收到事件后执行 `react()`，记录本次执行的区块，并可继续请求回调完成真正的业务动作。

## 与 Basic Demo 的区别

| 对比 | Basic Demo | Cron Demo |
|---|---|---|
| 触发来源 | 用户向源合约转入 ETH | Reactive Network 定期发出 Cron 事件 |
| 触发方式 | 事件驱动 | 定时（按区块）驱动 |
| 是否需要额外的源合约 | 需要 `BasicDemoL1Contract` | 不需要 |
| 适合场景 | 转账、成交、价格变化后自动响应 | 定期检查、结算、发奖励或维护状态 |

## 1. 监听哪条链、哪个合约的什么事件？

- **触发所在链：** Reactive Lasna（Chain ID：`5318007`）
- **Reactive 合约：** `BasicCronContract`
- **事件来源：** Reactive Network 的 Cron 事件发生器 `0x0000000000000000000000000000000000fffFfF`
- **本卡选择的事件：** `Cron100`
- **Cron100 的 topic0：** `0xb49937fb8970e19fd46d48f7e3fb00d659deac0347f79cd7cb542f0fc1503c70`

这个特殊地址是 Cron 事件的来源，不是当前 Omni 版用来执行普通订阅和回调请求的 `SYSTEM` 地址。

## 2. 满足什么条件时触发？

选择 `Cron100` 后，大约每经过 100 个 Reactive 区块触发一次：

```text
收到 Cron100 事件，并且 topic0 与订阅值相同
                         ↓
                   执行 react()
```

当前官方文档给出的可选频率如下：

| 事件 | 区块间隔 | 当前近似时间 |
|---|---:|---:|
| `Cron1` | 1 个区块 | 约 1 秒 |
| `Cron10` | 10 个区块 | 约 10 秒 |
| `Cron100` | 100 个区块 | 约 2 分钟 |
| `Cron1000` | 1,000 个区块 | 约 17 分钟 |
| `Cron10000` | 10,000 个区块 | 约 3 小时 |

这些时间只是估算。Cron 按区块数触发，不是现实世界里精确到秒的闹钟；区块速度变化时，实际等待时间也会变化。

## 3. 在哪条链做什么动作？

原始 Demo 的目标仍是 **Reactive Lasna 自身**：

1. `react()` 把 `lastCronBlock` 更新为当前 Reactive 区块号；
2. 请求一次发往 `address(this)` 的自身回调；
3. 回调载荷准备调用 `callback()`。

`lastCronBlock` 可以理解成一条运行记录，用来回答“这个定时任务上一次在什么时候执行”。

原始示例源码没有实现对应的 `callback()` 接收函数，因此它更适合用来学习 Cron 订阅、触发和暂停恢复。真正部署时，需要先按当前 Omni API 重写回调部分并实现接收函数。

实际项目也可以把目标改成其他链。例如：

```text
Reactive Cron 定期触发
        ↓
检查 Aave 仓位是否危险
        ↓
如果危险，请求 Sepolia 回调
        ↓
Sepolia 上的保护合约补充抵押品或偿还债务
```

## 4. 如果不用 Reactive，要怎么做？Reactive 简单在哪里，代价是什么？

### 不用 Reactive

通常要自己运行一个长期在线的链下定时机器人：

1. 在服务器上设置 Cron、计划任务或循环计时器；
2. 每次到点连接 RPC 并读取链上状态；
3. 判断是否需要执行；
4. 保存私钥，签名并发送目标链交易；
5. 自己处理服务器宕机、网络断开、重复执行、nonce 冲突和失败重试。

### Reactive 让它简单在哪里

- 不需要自己维护一台 24 小时在线的定时服务器；
- Cron 事件、判断规则和后续回调都可以放在链上；
- 可以把“定期叫醒”和“满足条件才执行”组合起来；
- 支持 `pause()` / `resume()`，不重新部署也能暂停和恢复订阅。

### 需要付出的代价

- 每次 Cron tick 都会产生 Reactive 执行费用，即使检查后什么也没做；
- 频率越高，触发次数和费用越高，因此应选择业务能接受的最长间隔；
- 同时订阅多个重叠频率可能在同一区块触发多次，并分别收费；
- 请求目标链回调时，还需要支付目标链的回调费用；
- Cron 是按区块触发，不能保证在现实时间的某一秒准时执行；
- 仍然需要处理回调失败、余额不足和合约权限等问题。

## 简图

```text
┌──────────── Reactive Lasna：Cron 事件发生器 ────────────┐
│ 每经过 100 个区块发出一次 Cron100 事件                  │
└──────────────────────────┬──────────────────────────────┘
                           │ 订阅 Cron100 topic0
                           ▼
┌──────────── Reactive Lasna：BasicCronContract ──────────┐
│ react() 被调用                                           │
│ 更新 lastCronBlock                                       │
│ 根据业务需要请求自身或其他链回调                          │
└──────────────────────────┬──────────────────────────────┘
                           │ 可选回调
                           ▼
             自身合约或其他链上的业务合约
```

## 当前版本注意事项

官方仓库里的 `CronDemo.sol` 仍使用旧版写法：

```text
service.subscribe(...)
react(...) external vmOnly
emit Callback(...)
```

当前 Omni 版实现应使用：

```text
SYSTEM.subscribe(...)
react(...) external onlySystem
SYSTEM.requestCallbackV_1_0(...)
```

因此，这份旧 Demo 适合帮助理解概念，但不应直接复制后部署。

## 参考

- [Reactive Network Cron Demo](https://github.com/Reactive-Network/reactive-smart-contract-demos/tree/main/src/demos/cron)
- [CronDemo.sol](https://github.com/Reactive-Network/reactive-smart-contract-demos/blob/main/src/demos/cron/CronDemo.sol)
- [Reactive 官方文档：Subscribing To CRON Events](https://dev.reactive.network/reactive-contracts#subscribing-to-cron-events)
