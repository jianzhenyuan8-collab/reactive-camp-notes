# 领 Lasna 测试币 lREACT

lREACT 是 Reactive Lasna 的**原生币**（付 gas 用）。拿 Sepolia 上的 SepETH 换，汇率固定 **1 ETH → 100 lREACT**。

## ⚠️ 先说三条会亏钱的

1. **单笔不要超过 5 ETH**，超出部分直接丢失，不会多给 lREACT（上限 500 lREACT）
2. 发出去的是真 Sepolia ETH，转错合约地址不会退回 —— 照抄下面的地址
3. 用**专用测试钱包**发，别用主钱包

## Faucet 合约地址

| 来源链 | Faucet 合约 |
|---|---|
| Ethereum Sepolia（推荐） | `0x9b9BB25f1A81078C544C829c5EB7822d747Cf434` |
| Base Sepolia | `0x2afaFD298b23b62760711756088F75B7409f5967` |

## 方式一：MetaMask 手动发

1. 切到 **Sepolia** 网络，确认有 SepETH（没有先去 <https://cloud.google.com/application/web3/faucet/ethereum/sepolia> 或 <https://sepoliafaucet.com> 领）
2. 发送交易：收款地址填 `0x9b9BB25f1A81078C544C829c5EB7822d747Cf434`，金额 **0.1 ETH**（示例值，够用很久）
3. 等几十秒，把 Lasna 网络加进钱包后就能看到 lREACT：

| 字段 | 值 |
|---|---|
| 网络名 | Reactive Lasna |
| RPC | `https://lasna-rpc.rnk.dev/` |
| Chain ID | `5318007` |
| 货币符号 | `lREACT` |
| 浏览器 | <https://lasna.reactscan.net/> |

> MetaMask 的 **Smart Transactions** 建议关掉，否则 faucet / 跨链交易可能"消失"。

## 方式二：脚本（cast）

```powershell
# 私钥只放环境变量，别写进命令行历史
$env:ETHEREUM_SEPOLIA_PRIVATE_KEY = '0x...'
.\scripts\faucet-lreact.ps1 -Address 0x你的钱包地址
```

脚本会先打印 Sepolia 余额、发交易、再回读 Lasna 的 lREACT 余额。`-AmountEth` 默认 0.1。

> **这台机器默认执行策略是 Restricted**，直接 `.\scripts\faucet-lreact.ps1` 会被拦（`禁止运行脚本`）。改用：
>
> ```powershell
> powershell -ExecutionPolicy Bypass -File .\scripts\faucet-lreact.ps1 -Address 0x你的钱包地址
> ```
>
> 想一劳永逸：`Set-ExecutionPolicy -Scope CurrentUser RemoteSigned`（一次性，之后可以直接 `.\` 跑）。

## 方式三：ReacDEFI

不想手动算金额可以用 <https://reacdefi.app/markets#testnet-faucet>，连钱包后按想要的 lREACT 数量反推需要多少 ETH。

## 到账后自检

```powershell
cast balance 0x你的钱包地址 --rpc-url https://lasna-rpc.rnk.dev/
```

能返回一个 18 位小数的数（单位 wei）就说明到了。

## 参考

<https://dev.reactive.network/reactive-mainnet>
