# D1 · Approval Magic 案例卡

> 目标：让一次 ERC-20 `approve()` 不只是授权，还能自动触发代币换 ETH 或 Uniswap 换币。

## 一句话说明

用户把代币额度授权给某个已订阅的交易合约后，Reactive 看到 `Approval` 事件，自动回调交易服务完成兑换，用户不需要再发送第二笔“执行交易”的交易。

## 1. 监听哪条链、哪个合约的什么事件？

示例目标链通常是 Ethereum Sepolia。`ApprovalListener` 监听三类事件：

- `ApprovalService` 的 `Subscribe`：某个交易合约加入服务；
- `ApprovalService` 的 `Unsubscribe`：某个交易合约退出服务；
- 任意 ERC-20 合约的 `Approval(owner, spender, amount)`，但只匹配已经订阅的 `spender`。

`ApprovalService` 相当于注册表，告诉 Reactive 哪些兑换合约有资格接收自动回调。

## 2. 满足什么条件时触发？

- 用户调用 ERC-20 的 `approve()`；
- `spender` 必须是 `ApprovalService` 中的有效订阅者；
- 授权金额会从事件的 `data` 中解码出来。

普通授权给其他地址不会触发该服务的交易流程。

## 3. 在哪条链做什么动作？

在目标链回调 `ApprovalService.onApproval()`，再转给对应的订阅合约：

- **Magic Exchange：** `ApprovalEthExch` 从用户账户拉取已授权代币，并向用户发送 ETH；
- **Magic Swap：** `ApprovalMagicSwap` 拉取代币，通过 Uniswap V2 Router 换成另一种代币，再把结果发回用户。

订阅、取消订阅事件还会触发 Reactive 自身的动态订阅更新。

## 4. 如果不用 Reactive，要怎么做？

用户通常要先 `approve()`，再手动调用兑换合约；或者由链下机器人监控授权事件并替用户发起第二笔交易。Reactive 把“授权出现 → 自动执行”连接起来，减少一次用户操作。

代价和风险是：`approve()` 在这里等同于发出交易意图，用户必须清楚授权对象、金额和兑换规则；错误或恶意的订阅合约可能立即使用额度。还需要为 Reactive 执行、目标链回调和 Uniswap 交易支付费用，并承担滑点与 MEV 风险。

## 简图

```text
用户 approve(spender, amount)
          ↓ ERC-20 Approval 事件
ApprovalListener → 确认 spender 已订阅
          ↓ 回调
ApprovalService → Exchange 或 Uniswap Swap → 资产返回用户
```

## 当前源码注意事项

- 源码使用旧 Reactive API，并依赖旧版“Reactive 与 RVM 身份对应”的设计。
- README 要求 `ApprovalService` 和 `ApprovalListener` 使用同一私钥部署，这是旧身份校验模型留下的要求，迁移 Omni 时必须重新设计权限。
- 不应把任意 `approve()` 默认为安全交易；生产环境需要价格保护、最小输出、截止时间和严格的订阅者审核。

## 参考

- [Demo README](https://github.com/Reactive-Network/reactive-smart-contract-demos/tree/main/src/demos/approval-magic)
- [ApprovalListener.sol](https://github.com/Reactive-Network/reactive-smart-contract-demos/blob/main/src/demos/approval-magic/ApprovalListener.sol)
- [ApprovalService.sol](https://github.com/Reactive-Network/reactive-smart-contract-demos/blob/main/src/demos/approval-magic/ApprovalService.sol)
