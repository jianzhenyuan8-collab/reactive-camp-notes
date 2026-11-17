# Reactive Builder Camp · 学习仓库

ETHPanda × Reactive Network 两周共学（2026-11-16 → 11-29），对接 [Reactive Omni Buildathon](https://dorahacks.io/hackathon/reactive-omni-buildathon/detail)。

- 报名页：<https://web3career.build/zh/programs/reactive-builder-camp>
- 官方共学仓库：[ethpanda-org/reactive-builder-camp](https://github.com/ethpanda-org/reactive-builder-camp)

## 这个仓库是什么

第 0 周准备清单要求：一个公开仓库，至少有 `README.md` 和 `notes/`，之后每天的打卡和代码都放这里。本仓库就是这件事。

## 目录

| 路径 | 用途 |
|---|---|
| [`notes/`](notes/) | 每日打卡、踩坑记录、提问草稿 |
| [`SUBMISSION.md`](SUBMISSION.md) | 第 0 周准备清单的提交材料（钱包地址 / 链上链接 / 截图） |
| [`AI-CONTEXT.md`](AI-CONTEXT.md) | 让 AI 写 Reactive 代码前的**必读上下文**（旧写法污染严重） |
| [`scripts/faucet-lreact.ps1`](scripts/faucet-lreact.ps1) | 用 Sepolia ETH 领 Lasna 测试币 lREACT 的脚本 |

## 准备清单状态

| 项 | 状态 |
|---|---|
| 测试专用钱包 | ✅ `0xAFDF23f148BFaA585418F02d1DD120Fd81211C7f`（MetaMask 专用账户） |
| Foundry | ✅ 1.9.0（`forge` / `cast` / `anvil`，装在 `%USERPROFILE%\.foundry\bin`） |
| 模板编译 | ✅ `forge build` 通过（33 个文件，Solc 0.8.29） |
| 测试币 lREACT | ⬜ 待领。⚠️ 文档里的 Sepolia faucet 地址实测是空账户，见 [`notes/faucet-lreact.md`](notes/faucet-lreact.md) |
| GitHub 学习仓库 | ✅ 就是你正在看的这个 |
| AI 编程工具 | ✅ 上下文已存为 [`AI-CONTEXT.md`](AI-CONTEXT.md) |

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

## 参考资料

- 文档首页 <https://dev.reactive.network/>
- Reactive Contracts <https://dev.reactive.network/reactive-contracts>
- Callback Contracts <https://dev.reactive.network/callback-contracts>
- Economy & System Interactions <https://dev.reactive.network/economy>
- Mainnet / Lasna / faucet <https://dev.reactive.network/reactive-mainnet>
- Omni 版示例代码 <https://github.com/Reactive-Network/reactive-smart-contract-demos/tree/omni/src/micro-demos>
