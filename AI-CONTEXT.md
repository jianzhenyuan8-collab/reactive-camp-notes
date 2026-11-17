# 给 AI 的上下文

> 用法：开新会话（Claude Code / Codex / Cursor 都行）先把下面「原文」整段贴给 AI，再提需求。
>
> 原因：AI 训练数据里大量是 Reactive 旧写法（RVM 双部署、`vm` 修饰符、`emit Callback`）。不先纠正，它写出来的代码在这套新环境里跑不起来。

## 原文

```text
我在用 Reactive Network 的 Omni 新版本（2026-10-28 主网迁移后）。请只参考 https://dev.reactive.network/reactive-contracts 、https://dev.reactive.network/callback-contracts 、https://dev.reactive.network/economy 和 https://github.com/Reactive-Network/reactive-smart-contract-demos/tree/omni/src/micro-demos 。不要使用 vm 修饰符、ReactVM、emit Callback 或系统合约 0x...fffFfF（只有 Cron 事件来自它）。react() 必须加 onlySystem，回调用 requestCallbackV_1_0。
```

## 补充（已按官方文档核对，可一起贴）

| 项 | 值 / 说明 |
|---|---|
| 系统合约（新文档） | `0x8888888888888888888888888888888888888888`，主网与 Lasna 同址 |
| 旧地址别用 | `0x0000000000000000000000000000000000fffFfF` 是迁移前的写法（旧文档），只在该写 Cron 相关时才出现 |
| Reactive Contract 部署在哪 | 只部署在 Lasna（Chain ID 5318007），没有 RVM 二次部署 |
| `react()` 权限 | 必须 `onlySystem`，否则任何人都能伪造 LogRecord 触发你的业务逻辑 |
| 回调怎么发 | `requestCallbackV_1_0`，不要 `emit Callback` |
| 订阅写法 | `service.subscribe(chainId, contract, topic0, ...)`，不过滤的 topic 用 `REACTIVE_IGNORE` |
| 测试桥接 | `if (!vm) { subscribe... }` 这类 Hardhat 兼容写法在新版里不需要了 |

来源：<https://dev.reactive.network/reactive-mainnet>、<https://dev.reactive.network/reactive-contracts>
