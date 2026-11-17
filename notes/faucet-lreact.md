# 领 Lasna 测试币 lREACT

lREACT 是 Reactive Lasna 的**原生币**（付 gas 用）。拿测试网 ETH 换，汇率固定 **1 ETH → 100 lREACT**。

> **2026-11-17 实测更新：官方文档里「Ethereum Sepolia」那一行的 faucet 地址是死的，别往那儿发。** 详见下面第 1 节。

## 1. 先看这个：文档给的 Sepolia 地址是空账户

用 4 个独立 RPC（publicnode / 1rpc / Tenderly / dRPC）交叉验证：

| 地址 | 链 | `cast code` | 余额 | 结论 |
|---|---|---|---|---|
| `0x9b9BB25f1A81078C544C829c5EB7822d947Cf434`<br>（文档标"Ethereum Sepolia"） | Sepolia | **0 字节** | 0 ETH | ❌ 空账户，nonce 0 → 发进去直接丢 |
| `0x9b9BB25f…f434` | Base Sepolia | 0 字节 | 0 | ❌ 同地址也是空的 |
| `0x2afaFD298b23b62760711756088F75B7409f5967`<br>（文档标"Base Sepolia"） | Base Sepolia | **1534 字节** | **8.2 ETH** | ✅ 这个是活的 |
| `0x2afa…5967` | Sepolia | 221 字节 | 0 | ⚠️ 有代码但不像 faucet（bytecode 里没有 `request(address)` 选择器） |

对照组（证明工具本身没问题）：Sepolia 上的 Callback Proxy `0xAa14…23b4` = 218 字节、USDC `0x1c7D…7238` = 1793 字节，都能正常读出来。

**所以：文档的 Sepolia 行是过期的/错的，Base Sepolia 行可用。** 共学群里可以顺手报一下，官方文档估计还没改。

## 2. 三条会亏钱的硬约束

1. **单笔不要超过 5 ETH**，超出部分直接丢失，不会多给 lREACT（上限 500 lREACT）
2. 发之前**一定先 `cast code` 确认那地址有代码**（见上，文档就可能给你个空地址）
3. 用**专用测试钱包**发，别用主钱包

## 3. 推荐路径

### 路径 A：走 Base Sepolia（目前唯一实测可用的 faucet 合约）

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\faucet-lreact.ps1 -Source base-sepolia -Address 0x你的地址
```

需要先有 **Base Sepolia 的 ETH**：<https://www.alchemy.com/faucets/base-sepolia>（一般要求主网有 0.001 ETH）或 <https://portal.cdp.coinbase.com/products/faucet>。

### 路径 B：ReacDEFI 前端兑换

<https://reacdefi.app/markets#testnet-faucet> —— 官方前端，连钱包按想要的 lREACT 数量反推 ETH。地址由前端处理，比自己抄地址安全。

### 路径 C：群里问现地址

文档与实际不符属于正常现象（这个仓库的速查表也写了「官方资料有几处前后矛盾」）。最省事的办法就是在共学群里问一句当前 faucet 地址。

### 路径 D：脚本走 Sepolia（**只有在该地址重新部署可用时才用**）

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\faucet-lreact.ps1 -Address 0x你的地址
```

脚本会先 `cast code` 自检，发现地址没代码会直接停，不会把币发出去。

## 4. 怎么先搞到测试网 ETH

你现在的地址在 Sepolia 和 Base Sepolia 都是 **0**，所以第一步是领测试 ETH：

| 渠道 | 门槛 |
|---|---|
| <https://sepolia-faucet.pk910.de/> | **无门槛**，浏览器里 PoW 挖几分钟就给，0 主网余额也能领 |
| <https://cloud.google.com/application/web3/faucet/ethereum/sepolia> | 需主网 ≥0.001 ETH 或主网有活动 |
| <https://www.alchemy.com/faucets/ethereum-sepolia> | 需主网 ≥0.001 ETH |
| <https://faucet.quicknode.com/ethereum/sepolia> | 需主网 ≥0.001 ETH |

主网没有 ETH 的话，第一个（PoW）是唯一现实路径。

## 5. Lasna 网络参数（加进 MetaMask）

| 字段 | 值 |
|---|---|
| 网络名 | Reactive Lasna |
| RPC | `https://lasna-rpc.rnk.dev/` |
| Chain ID | `5318007` |
| 货币符号 | `lREACT` |
| 浏览器 | <https://lasna.reactscan.net/> |

> MetaMask 的 **Smart Transactions** 建议关掉，否则 faucet / 跨链交易可能"消失"。

## 6. 到账后自检

```powershell
cast balance 0x你的地址 --rpc-url https://lasna-rpc.rnk.dev/ --ether
```

能返回非 0 的数就说明到了。约 1 分钟延迟。

## 参考

- <https://dev.reactive.network/reactive-mainnet>（faucet 地址就是这里有误）
- <https://reacdefi.app/markets#testnet-faucet>
