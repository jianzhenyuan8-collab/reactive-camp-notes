#Requires -Version 5.1
<#
.SYNOPSIS
    往 Reactive faucet 合约打测试网 ETH，换 Lasna 测试币 lREACT（1 ETH -> 100 lREACT）。

.DESCRIPTION
    在源链上调用 faucet 的 request(address)，Lasna 那边按 100:1 给你原生 lREACT。

    重要：2026-11-17 实测发现文档里 Ethereum Sepolia 那一行的 faucet 地址
    （0x9b9BB25f...f434）在链上是空账户（0 字节代码），发进去就是丢币。
    Base Sepolia 的 0x2afa...5967 是活的。所以脚本默认先做 cast code 自检，
    地址没代码就直接停，一个 wei 都不发。

    其余两条会亏钱的约束：
      - 单笔超过 5 ETH，超出部分直接丢失，不会多给 lREACT；
      - 用专用测试钱包，不要用存有资产的主钱包。

.PARAMETER Address
    接收 lREACT 的钱包地址（也是 faucet 的 request(address) 参数）。

.PARAMETER AmountEth
    发送多少测试 ETH，默认 0.1（0.1 ETH -> 10 lREACT，够跑很久）。

.PARAMETER Source
    sepolia（文档默认）或 base-sepolia。目前只有 base-sepolia 实测可用。

.PARAMETER RpcUrl
    源链 RPC，不填用默认公共节点。

.PARAMETER PrivateKey
    付款私钥。默认读环境变量 ETHEREUM_SEPOLIA_PRIVATE_KEY，别直接写命令行。

.EXAMPLE
    $env:ETHEREUM_SEPOLIA_PRIVATE_KEY = '0x...'
    powershell -ExecutionPolicy Bypass -File .\scripts\faucet-lreact.ps1 -Source base-sepolia -Address 0x1234567890abcdef1234567890abcdef12345678
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$Address,

    [double]$AmountEth = 0.1,

    [ValidateSet('sepolia', 'base-sepolia')]
    [string]$Source = 'sepolia',

    [string]$RpcUrl,

    [string]$PrivateKey = $env:ETHEREUM_SEPOLIA_PRIVATE_KEY
)

$ErrorActionPreference = 'Stop'

$LASNA_RPC = 'https://lasna-rpc.rnk.dev/'
$FAUCETS = @{
    'sepolia'      = @{ Contract = '0x9b9BB25f1A81078C544C829c5EB7822d947Cf434'; Rpc = 'https://ethereum-sepolia-rpc.publicnode.com' }
    'base-sepolia' = @{ Contract = '0x2afaFD298b23b62760711756088F75B7409f5967'; Rpc = 'https://sepolia.base.org' }
}
$faucet = $FAUCETS[$Source]
if (-not $RpcUrl) { $RpcUrl = $faucet.Rpc }

function Get-CastPath {
    $cmd = Get-Command cast -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }
    $fallback = Join-Path $env:USERPROFILE '.foundry\bin\cast.exe'
    if (Test-Path $fallback) { return $fallback }
    throw "找不到 cast。先装 Foundry：https://book.getfoundry.sh/getting-started/installation"
}

function Get-BalanceEth([string]$addr, [string]$rpc) {
    $wei = & (Get-CastPath) balance $addr --rpc-url $rpc 2>&1
    if ($LASTEXITCODE -ne 0) { throw "读余额失败（$rpc）：$wei" }
    return [decimal]$wei / [decimal][math]::Pow(10, 18)
}

# --- 参数校验 -------------------------------------------------------------
if ($Address -notmatch '^0x[0-9a-fA-F]{40}$') {
    throw "地址格式不对：$Address（应为 0x + 40 位十六进制）"
}
if ($AmountEth -le 0) { throw "AmountEth 必须大于 0" }
if ($AmountEth -gt 5) {
    throw "AmountEth=$AmountEth 超过 5 ETH 上限。超出部分会丢失，不会多给 lREACT。"
}
if (-not $PrivateKey) {
    throw @"
缺少私钥。用环境变量传，别写进命令行历史：

    `$env:ETHEREUM_SEPOLIA_PRIVATE_KEY = '0x你的私钥'
    .\scripts\faucet-lreact.ps1 -Address $Address
"@
}
$PrivateKey = $PrivateKey.Trim()
if ($PrivateKey -notmatch '^0x[0-9a-fA-F]{64}$') {
    throw "私钥格式不对（应为 0x + 64 位十六进制）"
}

$cast = Get-CastPath

# --- 关键：先确认 faucet 合约真的有代码 -----------------------------------
$code = (& $cast code $faucet.Contract --rpc-url $RpcUrl 2>&1) -join ''
if ($code -notmatch '^0x[0-9a-fA-F]{2,}$') {
    throw @"
faucet 地址在 $Source 上没有合约代码：$($faucet.Contract)
钱发过去就回不来了，已中止。

2026-11-17 实测：
  - Sepolia 的 0x9b9BB25f...f434 是空账户（文档写错了）
  - Base Sepolia 的 0x2afa...5967 是活的，可用 -Source base-sepolia

其它办法：
  - ReacDEFI 前端：https://reacdefi.app/markets#testnet-faucet
  - 共学群里问官方当前的 faucet 地址
"@
}

# --- 干跑信息 -------------------------------------------------------------
$expected = [math]::Round($AmountEth * 100, 2)
Write-Host ""
Write-Host "源链      : $Source ($RpcUrl)" -ForegroundColor Cyan
Write-Host "Faucet    : $($faucet.Contract)（代码 $([math]::Round(($code.Length - 2) / 2)) 字节）" -ForegroundColor Cyan
Write-Host "收款地址  : $Address" -ForegroundColor Cyan
Write-Host "发送金额  : $AmountEth ETH  ->  预期 $expected lREACT" -ForegroundColor Cyan
Write-Host ""

$before = Get-BalanceEth -addr $Address -rpc $RpcUrl
Write-Host ("源链余额  : {0} ETH（发送前）" -f $before)
if ($before -lt $AmountEth) {
    throw ("余额不够：需要 {0} ETH，当前只有 {1} ETH。先去领测试 ETH（无主网余额就用 https://sepolia-faucet.pk910.de/）。" -f $AmountEth, $before)
}

# --- 发交易 ---------------------------------------------------------------
Write-Host "`n正在发送 request(address)..." -ForegroundColor Yellow
$out = & $cast send $faucet.Contract "request(address)" $Address `
    --value "${AmountEth}ether" `
    --rpc-url $RpcUrl `
    --private-key $PrivateKey 2>&1
if ($LASTEXITCODE -ne 0) {
    throw "交易失败：`n$($out -join "`n")"
}
Write-Host ($out -join "`n")

# --- 回读 -----------------------------------------------------------------
Write-Host "`n等待 Lasna 铸造（通常几十秒）..." -ForegroundColor Yellow
$lreactBefore = 0
try { $lreactBefore = Get-BalanceEth -addr $Address -rpc $LASNA_RPC } catch { Write-Host "读 Lasna 余额失败：$($_.Exception.Message)" }

$deadline = (Get-Date).AddMinutes(5)
$lreact = $lreactBefore
while ((Get-Date) -lt $deadline) {
    Start-Sleep -Seconds 10
    try {
        $lreact = Get-BalanceEth -addr $Address -rpc $LASNA_RPC
        if ($lreact -gt $lreactBefore) { break }
    } catch { }
}

Write-Host ""
Write-Host ("Lasna lREACT : {0}（发送前 {1}）" -f $lreact, $lreactBefore) -ForegroundColor Green
if ($lreact -le $lreactBefore) {
    Write-Host "还没看到到账。faucet 有时要等一两分钟，稍后用下面命令自检：" -ForegroundColor Yellow
    Write-Host "    cast balance $Address --rpc-url $LASNA_RPC --ether"
} else {
    Write-Host "到账了。" -ForegroundColor Green
}
Write-Host "浏览器查看：https://lasna.reactscan.net/address/$Address"
