# D1 · Gasless Cross-Chain Atomic Swap 案例卡

> 目标：让两个用户在 Base Sepolia 与 Ethereum Sepolia 之间交换不同代币，由 Reactive 协调两边状态和放款。

## 一句话说明

用户 1 在 Base Sepolia 发起并存入代币，用户 2 在 Ethereum Sepolia 接受并存入另一种代币；Reactive 监听两条链的状态事件，在条件齐备后分别调用两条链的合约释放资产。

## 1. 监听哪条链、哪个合约的什么事件？

- **发起链示例：** Base Sepolia（`84532`）上的发起方回调合约：
  - `SwapInitiated`
  - `TokensDeposited`
- **接受链示例：** Ethereum Sepolia（`11155111`）上的接受方回调合约：
  - `SwapAcknowledged`
  - `TokensDeposited`

同一个回调合约代码分别部署在两条链上，Reactive 合约负责在两边传递状态。

## 2. 满足什么条件时触发？

这是一个多阶段状态机：

1. 用户 1 发起交换；
2. Reactive 把交换信息复制到另一条链；
3. 用户 2 接受；
4. 用户 1 存入自己的代币；
5. 用户 2 也存入自己的代币；
6. 两边都已存款后，才进入完成阶段。

合约还包含超时保护，用于避免一方长期不继续。

## 3. 在哪条链做什么动作？

Reactive 会多次回调两条链：同步交换信息、同步接受状态、同步存款状态。最后在两条链分别调用 `completeSwap()`：

- Base Sepolia 把用户 1 的代币释放给用户 2；
- Ethereum Sepolia 把用户 2 的代币释放给用户 1。

## 4. 如果不用 Reactive，要怎么做？

需要双方手动观察另一条链，或自己运行协调机器人和中继服务。Reactive 把两条链的事件串成状态机，减少人工协调，并避免由单个托管者暂存双方资产。

代价是流程包含多次跨链回调，费用、延迟和失败点都比单链交易多；两条链的合约都要有回调资金，还要设计超时、退款、幂等和重试。

## 简图

```text
Base Sepolia：发起 + 用户1存款 ─┐
                                ├→ Reactive 状态协调
Ethereum Sepolia：接受 + 用户2存款 ┘          ↓
                         两边分别 completeSwap()
```

## 当前源码注意事项

- 源码使用旧版 Reactive API，部署前必须迁移 Omni。
- README 使用“atomic”描述，但源码最终发出的是多个独立回调，其中三个完成阶段回调也是分别提交的。跨链交易不能天然回滚另一条已经成功的链，因此必须依靠状态机、超时退款、幂等和补偿逻辑，不能把它理解成单笔 EVM 交易那样的绝对原子性。
- “Gasless”不是完全无成本：用户仍支付自己链上的交易 Gas，Reactive 和两个回调合约也需要资金。

## 参考

- [Demo README](https://github.com/Reactive-Network/reactive-smart-contract-demos/tree/main/src/demos/gasless-cross-chain-atomic-swap)
- [Reactive 合约源码](https://github.com/Reactive-Network/reactive-smart-contract-demos/blob/main/src/demos/gasless-cross-chain-atomic-swap/GaslessDemoCrossChainAtomicSwapReactive.sol)
- [双链回调合约源码](https://github.com/Reactive-Network/reactive-smart-contract-demos/blob/main/src/demos/gasless-cross-chain-atomic-swap/GaslessDemoCrossChainAtomicSwapCallback.sol)
