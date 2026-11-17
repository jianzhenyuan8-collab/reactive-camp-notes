# 领 Lasna 测试币 lREACT

lREACT 是 Reactive Lasna 的**原生币**（付 gas 用）。拿测试网 ETH 换，汇率 **1 ETH → 100 lREACT**。

## 1. 实测可用的做法（2026-11-17 验证）

**往 Sepolia 的 faucet 地址发一笔纯 ETH 转账就行，不要带 calldata、不要调 `request(address)`。**

```powershell
$env:ETHEREUM_SEPOLIA_PRIVATE_KEY = '0x你的私钥'
powershell -ExecutionPolicy Bypass -File .\scripts\faucet-lreact.ps1 -Address 0x你的地址 -AmountEth 0.1
```

等价的手工命令：

```powershell
cast send 0x9b9BB25f1A81078C544C829c5EB7822d947Cf434 `
  --value 0.1ether `
  --rpc-url https://ethereum-sepolia-rpc.publicnode.com `
  --private-key $env:ETHEREUM_SEPOLIA_PRIVATE_KEY
```

实测记录：

| 项 | 值 |
|---|---|
| 交易 | [`0xd17405fe…db13`](https://sepolia.etherscan.io/tx/0xd17405fe89d86d579f00df601700bcb7a845746dafd2f0a3d23566343817db13) |
| 发送 | 0.1 ETH，`raw_input = 0x`（纯转账，没掉函数） |
| 结果 | `status = 0x1`，faucet 发出 1 个事件 |
| 到账 | Lasna 上 **10.5 lREACT**（约 1 分钟） |

## 2. 踩过的坑：不要用「有没有代码」判断这个地址

`cast code 0x9b9BB25f…f434` 在 publicnode / 1rpc / Tenderly 上都返回 `0x`（0 字节），
而这笔交易明明成功、事件也发了。同一个地址 [Blockscout](https://eth-sepolia.blockscout.com/address/0x9b9BB25f1A81078C544C829c5EB7822d947Cf434) 却把它标成合约 `ReactiveFaucetL1`、余额 210 ETH。

结论：**RPC 与浏览器对这个地址的呈现不一致，谁都别全信**。判断能不能用，看实际到账，不看 `cast code`。
（第一版脚本拿 `cast code` 做中止条件，会把这个可用的 faucet 误判成死地址，已改掉。）

## 3. 三条会亏钱的约束

1. **单笔不要超过 5 ETH**，超出部分直接丢失（上限 500 lREACT）
2. 只往脚本内置的官方地址发，别自己从文档/群里抄地址（地址存在多版本）
3. 用**专用测试钱包**

## 4. Faucet 地址

| 来源链 | Faucet 合约 | 备注 |
|---|---|---|
| Ethereum Sepolia | `0x9b9BB25f1A81078C544C829c5EB7822d947Cf434` | ✅ 实测可用（纯转账） |
| Base Sepolia | `0x2afaFD298b23b62760711756088F75B7409f5967` | 有代码（1534 字节）、余额 8.2 ETH，备用 |

共学统一用 **Sepolia ↔ Lasna ↔ Sepolia**，所以用第一个就行，不用桥到 Base。

## 5. 先搞到测试网 ETH

本机已验证可行的渠道：

| 渠道 | 门槛 | 结果 |
|---|---|---|
| <https://sepolia-faucet.pk910.de/> | 无（浏览器 PoW 挖矿） | ✅ 挖到 0.4775 SepETH |
| <https://www.alchemy.com/faucets/ethereum-sepolia> | 需主网 ≥0.001 ETH | 未试 |
| <https://cloud.google.com/application/web3/faucet/ethereum/sepolia> | 需主网余额，且国内直连超时 | 不可用 |

### 如果页面报 IP 被封

```
[IPINFO_RESTRICTION] IP Blocked: You're connecting from a hosting IP range...
```

本机实测：走代理出口是 `67.21.76.77`（AS46844 Sharktech，机房），被 ipinfo 判为 hosting；
直连出口是 `120.245.63.72`（AS56048 中国移动，住宅）——放行。

做法：**整个关掉系统代理**（不要只加单域名规则，否则页面和提交请求出口不一致，captcha 还会报 `invalid token`），
领完再开回来。git 用自己独立的 `http.proxy` 配置，不受影响。

## 6. Lasna 网络参数（加进 MetaMask）

| 字段 | 值 |
|---|---|
| 网络名 | Reactive Lasna |
| RPC | `https://lasna-rpc.rnk.dev/` |
| Chain ID | `5318007` |
| 货币符号 | `lREACT` |
| 浏览器 | <https://lasna.reactscan.net/> |

> MetaMask 的 **Smart Transactions** 建议关掉。

## 7. 到账自检

```powershell
cast balance 0x你的地址 --rpc-url https://lasna-rpc.rnk.dev/ --ether
```

## 参考

- <https://dev.reactive.network/reactive-mainnet>
