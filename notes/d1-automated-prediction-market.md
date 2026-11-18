# D1 · Automated Prediction Market 案例卡

> 目标：预测市场结果确定后，自动启动获胜者奖金发放，不再等待管理员手动点击“结算”。

## 一句话说明

预测市场完成多签裁决并发出 `PredictionResolved` 后，Reactive 自动回调市场合约，按批次向押中结果的参与者发放奖金。

## 1. 监听哪条链、哪个合约的什么事件？

- **源链：** Ethereum Sepolia（源码固定 Chain ID `11155111`）。
- **源合约：** `AutomatedPredictionMarketCallback`。
- **事件：** `PredictionResolved(uint256 predictionId, uint256 outcome)`。

事件表示市场结果已经由多签流程确定，并不是 Reactive 自己判断现实世界的答案。

## 2. 满足什么条件时触发？

- 市场已经结束并完成多签投票；
- 达到合约要求的签名数量；
- 市场合约最终发出 `PredictionResolved`；
- 事件必须来自部署时指定的市场合约。

## 3. 在哪条链做什么动作？

Reactive 回调 Sepolia 上同一个市场合约的：

```text
distributeWinnings(sender, predictionId)
```

合约遍历本批参与者，计算押中结果者的份额并发送 ETH，同时把已领取份额清零，防止重复领取。

## 4. 如果不用 Reactive，要怎么做？

管理员、用户或链下机器人需要在结果确定后主动调用 `distributeWinnings()`。Reactive 省掉了这个“谁来按结算按钮”的问题，使结果事件能够直接启动奖金发放。

代价是 Reactive 和回调都需要费用；批量转账可能因单个收款方回退而使整批失败；市场仍然依赖多签裁决，Reactive 只自动执行结果，并不能证明结果真实。

## 简图

```text
Sepolia 预测市场完成多签裁决
              ↓ PredictionResolved
AutomatedPredictionReactive
              ↓ 回调 distributeWinnings
Sepolia 市场合约 → 计算并发送获胜奖金
```

## 当前源码注意事项

- Reactive 源码使用旧版 `service.subscribe`、`vmOnly`、`emit Callback`。
- `distributeWinnings()` 每次最多处理 `100` 名参与者，但 `PredictionResolved` 只触发一次回调；超过 100 人时，当前代码不会自动继续下一批，需要额外触发或重新设计连续批处理。
- 奖金发送使用外部 ETH 调用，生产环境应仔细处理失败接收者和重入风险。

## 参考

- [Demo README](https://github.com/Reactive-Network/reactive-smart-contract-demos/tree/main/src/demos/automated-prediction-market)
- [Reactive 合约源码](https://github.com/Reactive-Network/reactive-smart-contract-demos/blob/main/src/demos/automated-prediction-market/AutomatedPredictionReactive.sol)
- [市场与回调合约源码](https://github.com/Reactive-Network/reactive-smart-contract-demos/blob/main/src/demos/automated-prediction-market/AutomatedPredictionMarketCallback.sol)
