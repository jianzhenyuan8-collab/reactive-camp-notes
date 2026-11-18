# Reactive Builder Camp · 学习仓库

ETHPanda × Reactive Network 两周共学（2026-11-16 → 11-29），对接 [Reactive Omni Buildathon](https://dorahacks.io/hackathon/reactive-omni-buildathon/detail)。

- 报名页：<https://web3career.build/zh/programs/reactive-builder-camp>
- 官方共学仓库：[ethpanda-org/reactive-builder-camp](https://github.com/ethpanda-org/reactive-builder-camp)

## 这个仓库是什么

第 0 周准备清单要求：一个公开仓库，至少有 `README.md` 和 `notes/`，之后每天的打卡和代码都放这里。本仓库就是这件事。

## 当前进度

> 更新于 2026-11-18。

- ✅ 第 0 周环境和测试币准备完成：Foundry、GitHub 仓库、Sepolia ETH、Lasna lREACT。
- ✅ 已跑通首个链上 Reactive 监听：`Sepolia CampToken.transfer()` → `Lasna TransferCounter.react()`。
- ✅ 已整理 Reactive 官方 10 个 Demo 案例卡，以及 Lasna 费用、余额与欠费机制。
- ⏳ 下一步：跑通 `Sepolia 事件 → Lasna react() → Sepolia callback` 完整链路。

> 当前 Xfers 案例的目标是验证事件订阅和 `react()`，没有目标链 callback；因此不把它写成「跨链回调已完成」。

## 目录

| 路径 | 用途 |
|---|---|
| [`notes/`](notes/) | 每日打卡、踩坑记录、提问草稿 |
| [`assets/`](assets/) | 命令输出、链上验证和学习记录截图 |
| [`SUBMISSION.md`](SUBMISSION.md) | 第 0 周准备清单的提交材料（钱包地址 / 链上链接 / 截图） |
| [`AI-CONTEXT.md`](AI-CONTEXT.md) | 让 AI 写 Reactive 代码前的**必读上下文**（旧写法污染严重） |
| [`scripts/faucet-lreact.ps1`](scripts/faucet-lreact.ps1) | 用 Sepolia ETH 领 Lasna 测试币 lREACT 的脚本 |

## 准备清单状态

| 项 | 状态 |
|---|---|
| 测试专用钱包 | ✅ `0xAFDF23f148BFaA585418F02d1DD120Fd81211C7f`（MetaMask 专用账户） |
| Foundry | ✅ 1.9.0（`forge` / `cast` / `anvil`，装在 `%USERPROFILE%\.foundry\bin`） |
| 模板编译 | ✅ `forge build` 通过（33 个文件，Solc 0.8.29） |
| 测试币 lREACT | ✅ Lasna 到账 `10.5 lREACT`；[Sepolia 兑换交易](https://sepolia.etherscan.io/tx/0xd17405fe89d86d579f00df601700bcb7a845746dafd2f0a3d23566343817db13) · [实测记录](notes/faucet-lreact.md) |
| GitHub 学习仓库 | ✅ 就是你正在看的这个 |
| AI 编程工具 | ✅ 上下文已存为 [`AI-CONTEXT.md`](AI-CONTEXT.md) |

## 链上实测

| 项目 | 网络 | 结果 |
|---|---|---|
| `CampToken` | Ethereum Sepolia | [合约 `0xf202...3c77`](https://sepolia.etherscan.io/address/0xf2026c4bD8e9c00e0e3696bd191E02061D953c77) · [部署交易](https://sepolia.etherscan.io/tx/0xb93a51435c1b93840aa290a3aed0892eca881370b769989257c5b79c8ff4c373) |
| 第一次 `Transfer` | Ethereum Sepolia | [交易 `0x1fcc...4f9f`](https://sepolia.etherscan.io/tx/0x1fcc91633cb31c3dfa8519bb745381c93d8655cc674f11a03529ad79502d4f9f) · 转账 `1 CAMP` |
| `TransferCounter` | Reactive Lasna | [合约 `0x9b3e...5579`](https://lasna.reactscan.net/address/0x9b3eaeaBEdE38F7DaC71d9E17BdeA7E1F75F5579) · [部署交易](https://lasna.reactscan.net/tx/0xf4ebca6be32961674b1427ba1e7658864deacf2a8fab6ee70905ed7ca5dd6ad2) |
| 第一次 `react()` | Reactive Lasna | [交易 `0xa190...eb7b`](https://lasna.reactscan.net/tx/0xa1909ff173771a9836fd2564cec49d4d0c71727187a94b08cc2583247e10eb7b) · `processed = 1` · `remaining = 2` · `debt = 0` |

完整过程和验证证据见 [Xfers 实测记录](notes/d1-xfers.md)。

## 关键网络参数

| 网络 | Chain ID | RPC | 原生币 |
|---|---|---|---|
| Reactive Mainnet | 1597 | <https://mainnet-rpc.rnk.dev/> | REACT |
| Reactive Lasna（测试网） | 5318007 | <https://lasna-rpc.rnk.dev/> | lREACT |
| Ethereum Sepolia | 11155111 | 任选公共 RPC | SepETH |

主网与 Lasna 共用同一个系统合约地址：`0x8888888888888888888888888888888888888888`

## 打卡

| 天 | 日期 | 主题 |
|---|---|---|
| D01 | 2026-11-17 | [开营前环境准备](notes/D01-2026-11-17.md) |
| D02 | 2026-11-18 | [跑通 Sepolia Transfer → Lasna react()](notes/D02-2026-11-18.md) |

## 学习与案例索引

- [Reactive 官方 10 个 Demo 案例卡](notes/d1-demo-cards.md)
- [Reactive 费用、余额与欠费机制](notes/d1-economy.md)
- [Xfers：监听 Sepolia ERC-20 Transfer](notes/d1-xfers.md)

## 参考资料

- 文档首页 <https://dev.reactive.network/>
- Reactive Contracts <https://dev.reactive.network/reactive-contracts>
- Callback Contracts <https://dev.reactive.network/callback-contracts>
- Economy & System Interactions <https://dev.reactive.network/economy>
- Mainnet / Lasna / faucet <https://dev.reactive.network/reactive-mainnet>
- Omni 版示例代码 <https://github.com/Reactive-Network/reactive-smart-contract-demos/tree/omni/src/micro-demos>
