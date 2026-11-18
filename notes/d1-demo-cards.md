# D1 · Reactive 官方 Demo 案例卡索引

> 核对范围：[`reactive-smart-contract-demos/src/demos`](https://github.com/Reactive-Network/reactive-smart-contract-demos/tree/main/src/demos)，本次分析基于 `main` 分支提交 `6fd02ce56d110762b9cecbacbf4374aa5951d491`。共 10 个 Demo，均已制作卡片。

## 建议学习顺序

| 顺序 | Demo | 核心触发 | 最终动作 | 卡片 |
|---:|---|---|---|---|
| 1 | Basic | 收到 ETH 后的 `Received` | 留下回调成功记录 | [打开](d1-use-case.md) |
| 2 | Cron | 固定区块间隔 | 定期执行任务 | [打开](d1-cron-use-case.md) |
| 3 | Approval Magic | ERC-20 `Approval` | 自动兑换或换币 | [打开](d1-approval-magic.md) |
| 4 | Automated Prediction Market | `PredictionResolved` | 自动发放奖金 | [打开](d1-automated-prediction-market.md) |
| 5 | Uniswap V2 Stop Order | Pair `Sync` 后价格跌破阈值 | 执行一次性止损 | [打开](d1-uniswap-v2-stop-order.md) |
| 6 | Stop-Loss & Take-Profit | `Sync` + 多订单生命周期 | 止损或止盈换币 | [打开](d1-uniswap-v2-stop-take-profit-order.md) |
| 7 | Aave Liquidation Protection | Cron 定期检查 | 补仓、还债或两者 | [打开](d1-aave-liquidation-protection.md) |
| 8 | Leverage Loop | `Deposited` / `LoopStepExecuted` | 借款、换币、再抵押循环 | [打开](d1-leverage-loop.md) |
| 9 | Gasless Cross-Chain Atomic Swap | 两条链的交换状态事件 | 两边分别释放代币 | [打开](d1-gasless-cross-chain-atomic-swap.md) |
| 10 | Hyperlane | Base 或 Reactive 的 `Trigger` | 通过 Hyperlane 发消息 | [打开](d1-hyperlane.md) |

## 共同框架

每张卡都回答四个问题：

1. 监听哪条链、哪个合约、什么事件？
2. 满足什么条件时触发？
3. 在哪条链执行什么动作？
4. 不用 Reactive 时如何实现；Reactive 简化了什么、代价是什么？

```text
源链事件或 Cron
      ↓
Reactive 订阅 + 判断
      ↓
目标链回调执行
      ↓
目标合约事件可再次成为下一轮输入
```

## 全仓库版本警告

当前这 10 个 Demo 的 Reactive 源码都仍能看到旧版模式，例如：

```text
service.subscribe(...)
react(...) external vmOnly
emit Callback(...)
```

学习案例思想没有问题，但不能直接当成当前 Omni 部署模板。迁移时至少要改为：

```text
SYSTEM.subscribe(...)
react(...) external onlySystem
SYSTEM.requestCallbackV_1_0(...)
```

还必须重新核对链 ID、Callback Proxy、权限、费用、事件参数位置及回调接收函数。卡片中的“动作”描述的是案例目标，不代表当前仓库代码已经在最新网络完整验证。

## 学习重点分类

- **基础机制：** Basic、Cron
- **事件即意图：** Approval Magic、Prediction Market
- **自动交易：** Stop Order、Stop-Loss & Take-Profit
- **DeFi 风险管理：** Aave Protection、Leverage Loop
- **跨链状态机：** Atomic Swap、Hyperlane
