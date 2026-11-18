# D1 · Leverage Loop 案例卡

> 目标：把“存抵押品 → 借款 → 换成更多抵押品 → 再存入”的循环杠杆策略自动化。

## 一句话说明

用户向 Sepolia 上的个人 `LeverageAccount` 存入抵押品后，Reactive 自动反复执行借款、换币和追加抵押，直到健康因子达到目标、风险过高或循环次数达到上限。

## 1. 监听哪条链、哪个合约的什么事件？

- **源链：** Ethereum Sepolia（`11155111`）。
- **源合约：** 用户的 `LeverageAccount`。
- **事件：**
  - `Deposited`：用户首次存入抵押品；
  - `LoopStepExecuted`：一轮借款、换币、追加抵押已经完成。

## 2. 满足什么条件时触发？

首次存款后：

- 健康因子至少为目标值 `1.5`，才开始第一轮；
- 第一轮借款额约为抵押品美元价值的 40%，并限制在约 `$0.1` 到 `$500`。

后续每一轮：

- 最多执行 5 轮；
- 健康因子低于或等于 `1.2` 时立即停止；
- 健康因子已经降到目标 `1.5` 时完成；
- 否则按新增抵押价值的 55% 计算下一轮借款。

## 3. 在哪条链做什么动作？

在 Ethereum Sepolia 回调 `LeverageAccount.executeLeverageStep()`：

1. 从 Aave 借出指定资产；
2. 通过 DEX Router 换成 WETH 等抵押资产；
3. 把换得的资产再次存入 Aave；
4. 发出 `LoopStepExecuted`，让 Reactive 决定是否继续下一轮。

回调合约使用 Aave Oracle 估算最小换出量，降低无保护换币的风险。

## 4. 如果不用 Reactive，要怎么做？

用户需要连续执行多笔交易，每轮都重新查询抵押价值和健康因子；机器人方案则要保存私钥、监控事件并管理多轮状态。Reactive 把每轮完成事件自动连接到下一轮。

代价是每轮都有借款利息、兑换手续费、滑点、目标链 Gas 和 Reactive 回调费用。杠杆会放大收益，也会放大亏损和清算风险；任何一轮失败都可能留下部分完成的仓位。

## 简图

```text
用户存入抵押品 → Deposited
                    ↓
LoopingRC 判断健康因子
                    ↓ 回调
借款 → 换成抵押品 → 再存入 → LoopStepExecuted
                    └──────────────→ 判断是否继续
```

## 当前源码注意事项

- 源码使用旧版 Reactive API，部署前必须迁移 Omni。
- 这是高风险 DeFi 策略，不应把测试网参数直接用于主网。
- 需要额外验证预言机、DEX 池深度、代币小数位、授权、滑点和回调幂等性。

## 参考

- [Demo README](https://github.com/Reactive-Network/reactive-smart-contract-demos/tree/main/src/demos/leverage-loop)
- [LoopingRC.sol](https://github.com/Reactive-Network/reactive-smart-contract-demos/blob/main/src/demos/leverage-loop/LoopingRC.sol)
- [LeverageAccount.sol](https://github.com/Reactive-Network/reactive-smart-contract-demos/blob/main/src/demos/leverage-loop/LeverageAccount.sol)
