# D1 · Hyperlane 案例卡

> 目标：把 Reactive 的事件触发能力和 Hyperlane 的跨链消息协议组合起来，在 Base Mainnet 与 Reactive Mainnet 之间发送消息。

## 一句话说明

Base 上的 `HyperlaneOrigin` 或 Reactive 上的 `HyperlaneReactive` 发出 `Trigger(bytes)` 后，Reactive 自动调用自身回调，再通过 Hyperlane Mailbox 把消息发送到 Base。

## 1. 监听哪条链、哪个合约的什么事件？

- **Base Mainnet：** `HyperlaneOrigin` 的 `Trigger(bytes)`；
- **Reactive Mainnet：** `HyperlaneReactive` 自己发出的 `Trigger(bytes)`。

示例支持三种入口：直接从 Reactive 发消息、Reactive 自己触发后发送、Base 发事件后由 Reactive 响应。

## 2. 满足什么条件时触发？

收到来自上述两个指定合约之一、且 topic0 匹配 `Trigger(bytes)` 的事件时触发。`trigger()` 和直接 `send()` 都限制为合约所有者调用。

## 3. 在哪条链做什么动作？

Reactive 合约先请求一次指向自己的回调，`callback()` 再调用 Hyperlane Mailbox：

1. 查询发送到 Base 所需费用；
2. 调用 `mailbox.dispatch()`；
3. Base 上的 `HyperlaneOrigin.handle()` 接收消息；
4. 发出 `Received` 事件记录发送者和内容。

## 4. 如果不用 Reactive，要怎么做？

最简单的替代方式是用户直接调用 `send()`，或者运行机器人监听 Base 的 `Trigger` 后再调用 Hyperlane。Reactive 让“链上事件出现 → 自动发送 Hyperlane 消息”无需自建监听机器人。

代价是同时依赖 Reactive 和 Hyperlane 两套基础设施，并同时承担 Reactive 执行、回调和 Hyperlane 消息费用。消息送达时间也受两套网络影响。

## 简图

```text
Base Trigger ─┐
              ├→ HyperlaneReactive.react()
Reactive Trigger ┘          ↓ 自身回调
                    Hyperlane Mailbox → Base handle()
```

## 当前源码注意事项

- 源码使用旧版 Reactive/RVM API，必须迁移 Omni。
- Reactive 负责自动触发，Hyperlane 负责跨链消息传递；使用 Reactive 并不等于去掉 Hyperlane 自己的验证者、relayer 和安全假设。
- Mailbox 费用不足、目标域或接收者配置错误都会导致消息无法发送。

## 参考

- [Demo README](https://github.com/Reactive-Network/reactive-smart-contract-demos/tree/main/src/demos/hyperlane)
- [HyperlaneReactive.sol](https://github.com/Reactive-Network/reactive-smart-contract-demos/blob/main/src/demos/hyperlane/HyperlaneReactive.sol)
- [HyperlaneOrigin.sol](https://github.com/Reactive-Network/reactive-smart-contract-demos/blob/main/src/demos/hyperlane/HyperlaneOrigin.sol)
