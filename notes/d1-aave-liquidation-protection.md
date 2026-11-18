# D1 · Aave Liquidation Protection 案例卡

> 目标：定期检查 Aave 仓位，在健康度过低时自动补充抵押品、偿还债务，或两者同时执行。本卡是源码分析，不代表已部署或验证资金安全。

## 一句话说明

Reactive 像一个定期巡查仓位的值班员：Cron 到点后叫醒 Sepolia 上的保护合约，保护合约读取 Aave 健康因子，低于用户设定阈值时自动采取保护动作。

## 1. 监听哪条链、哪个合约的什么事件？

- **Reactive Lasna：** 监听选定频率的 Cron 事件。
- **Ethereum Sepolia：** 监听 `AaveProtectionDemoCallback` 发出的配置生命周期事件：
  - `ProtectionConfigured`
  - `ProtectionCancelled`
  - `ProtectionExecuted`
  - `ProtectionPaused`
  - `ProtectionResumed`
  - `ProtectionCycleCompleted`

Cron 负责定时叫醒系统；生命周期事件负责让 Reactive 合约知道哪些保护配置仍然有效，以及一次检查是否已经结束。

## 2. 满足什么条件时触发？

分成两层：

1. 每次 Cron tick 到来，且上一轮检查没有仍在处理中，就请求 Sepolia 回调。
2. Sepolia 回调合约读取 Aave 的真实健康因子。只有健康因子低于用户设置的阈值，才执行补仓或还债。

Reactive 合约本身运行在 Lasna，不能直接读取 Sepolia 的 Aave 状态，所以最终判断必须在 Sepolia 回调合约中重新完成。

## 3. 在哪条链做什么动作？

- **目标链：** Ethereum Sepolia。
- **目标合约：** `AaveProtectionDemoCallback`。
- **动作：** 调用 `checkAndProtectPositions()`，遍历有效配置并查询 Aave；根据用户选择执行：
  - 增加抵押品；
  - 偿还债务；
  - 两者结合。

执行结束后发出 `ProtectionCycleCompleted`，Reactive 合约据此解除“正在处理”标记，等待下一次 Cron。

## 4. 如果不用 Reactive，要怎么做？

需要自己运行服务器机器人：定时查询 Aave、计算健康因子、保存私钥、发送保护交易，并处理断线和失败重试。Reactive 省掉了长期在线的定时服务器，并把触发规则和状态同步放到链上。

代价是每次 Cron 都有 Reactive 执行成本，保护回调还要支付 Sepolia Gas；检查存在时间差，极端行情下可能在保护交易确认前已经被清算。用户还必须提前授权代币并保证账户中有可用于补仓或还债的资产。

## 简图

```text
Reactive Cron → AaveProtectionDemoReactive
                        ↓ 定期请求检查
Ethereum Sepolia → AaveProtectionDemoCallback → 查询健康因子
                                                ↓ 低于阈值
                                         补仓 / 还债 / 两者
```

## 当前源码注意事项

- 源码使用旧版 `service.subscribe`、`vmOnly`、`emit Callback`，不能直接作为当前 Omni 合约部署。
- 当前 Omni 版应改用 `SYSTEM.subscribe`、`onlySystem` 和 `SYSTEM.requestCallbackV_1_0`。
- Cron 频率应选择业务能接受的最长间隔，避免每次空检查仍持续付费。

## 参考

- [Demo README](https://github.com/Reactive-Network/reactive-smart-contract-demos/tree/main/src/demos/aave-liquidation-protection)
- [Reactive 合约源码](https://github.com/Reactive-Network/reactive-smart-contract-demos/blob/main/src/demos/aave-liquidation-protection/AaveProtectionDemoReactive.sol)
- [回调合约源码](https://github.com/Reactive-Network/reactive-smart-contract-demos/blob/main/src/demos/aave-liquidation-protection/AaveProtectionDemoCallback.sol)
