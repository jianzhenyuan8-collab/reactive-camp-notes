# 第 0 周准备清单 · 提交材料

> 2026-11-17 生成。链上数据均用 `cast` / 浏览器实查，链接可直接点开核对。

## 1. 测试钱包地址

```
0xAFDF23f148BFaA585418F02d1DD120Fd81211C7f
```

- 类型：MetaMask 独立账户（`reactive Camp`），只用于本期，不存任何资产
- Sepolia：0.3775 ETH（pk910 PoW faucet 挖取）
- Lasna：10.5 lREACT

## 2. lREACT 持有证明（Lasna）

浏览器链接：

<https://lasna.reactscan.net/address/0xAFDF23f148BFaA585418F02d1DD120Fd81211C7f>

余额：**10.5 lREACT**

换取记录（Sepolia 侧）：

| 项 | 值 |
|---|---|
| 交易 | [`0xd17405fe…db13`](https://sepolia.etherscan.io/tx/0xd17405fe89d86d579f00df601700bcb7a845746dafd2f0a3d23566343817db13) |
| 发送 | 0.1 ETH → faucet `0x9b9BB25f…f434`（纯转账，无 calldata） |
| 到账 | Lasna +10 lREACT，约 1 分钟 |

> 注：该 faucet 地址在多个 RPC 上 `cast code` 返回 0 字节，但实测转账可正常入账；
> 别用「有没有代码」判断它可用性。详见 [notes/faucet-lreact.md](notes/faucet-lreact.md)。

## 3. GitHub 学习仓库

<https://github.com/jianzhenyuan8-collab/reactive-camp-notes>

公开仓库，含 `README.md`、`notes/`（每日打卡）、`AI-CONTEXT.md`（给 AI 的上下文）、`scripts/`（领币脚本）。

## 4. forge --version

![forge --version 输出](assets/forge-version.png)

附加：starter 模板本地测试 **8/8 通过**（不需要测试币，链下全链路）：

![forge test 输出](assets/forge-test.png)

## 附：环境清单

| 工具 | 版本 | 位置 |
|---|---|---|
| forge / cast / anvil | 1.9.0 | `%USERPROFILE%\.foundry\bin`（已进 PATH） |
| gh CLI | 2.104.0 | `%LOCALAPPDATA%\gh`（已进 PATH） |
| Solc | 0.8.29 | Foundry 自动管理 |

环境搭建踩的坑（TLS、子模块、执行策略、faucet 风控与地址）记录在 [notes/D01-2026-11-17.md](notes/D01-2026-11-17.md)。
