#Requires -Version 5.1
<#
.SYNOPSIS
    往 Reactive faucet 打测试网 ETH，换 Lasna 测试币 lREACT（1 ETH -> 100 lREACT）。

.DESCRIPTION
    2026-11-17 实测结论（重要，与官方文档写法不同）：

    - Sepolia 的 0x9b9BB25f...f434 用【纯原生转账】就能换到 lREACT：
      实测 0.1 ETH 打进该地址，Lasna 收到 10.5 lREACT（转账 tx 的 raw_input 是 0x，
      没有调用任何函数）。成功后该地址在 RPC 上仍然读不到 bytecode，
      所以不要用 "有没有代码" 来判断这个 faucet 是否可用。
    - 因此默认模式是 transfer：只发 value，不带 calldata。
      -Mode request 才会调用 request(address)（给有代码的合约式 faucet 用）。

    三条会亏钱的约束：
      - 单笔不要超过 5 ETH，超出部分丢失；
      - 只往本脚本内置的两个官方地址发，别自己抄地址；
      - 用专用测试钱包。

.PARAMETER Address
    接收 lREACT 的钱包地址。

.PARAMETER AmountEth
    发送多少测试 ETH，默认 0.1（-> 10 lREACT，够跑很久）。

.PARAMETER Source
    sepolia（默认，实测可用）或 base-sepolia。

.PARAMETER Mode
    transfer（默认，纯转账）或 request（调 request(address)）。

.PARAMETER RpcUrl
    源链 RPC，不填用默认公共节点。

.PARAMETER PrivateKey
    付款私钥。默认读环境变量 ETHEREUM_SEPOLIA_PRIVATE_KEY。

.EXAMPLE
    $env:ETHEREUM_SEPOLIA_PRIVATE_KEY = '0x...'
    powershell -ExecutionPolicy Bypass -File .\scripts\faucet-lreact.ps1 -Address 0x1234567890abcdef1234567890abcdef12345678 -AmountEth 0.1
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$Address,

    [double]$AmountEth = 0.1,

    [ValidateSet('sepolia', 'base-sepolia')]
    [string]$Source = 'sepolia',

    [ValidateSet('transfer', 'request')]
    [string]$Mode = 'transfer',

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
if ($AmountEth -gt 5) { throw "AmountEth=$AmountEth 超过 5 ETH 上限。超出部分会丢失。" }
if (-not $PrivateKey) {
    throw @"
缺少私钥。用环境变量传，别写进命令行历史：

    `$env:ETHEREUM_SEPOLIA_PRIVATE_KEY = '0x你的私钥'
    .\scripts\faucet-lreact.ps1 -Address $Address
"@
}
$PrivateKey = $PrivateKey.Trim()
if ($PrivateKey -notmatch '^0x[0-9a-fA-F]{64}$') { throw "私钥格式不对（应为 0x + 64 位十六进制）" }

$cast = Get-CastPath

# --- 代码检查：仅作提示，不作为中止条件 -----------------------------------
$code = (& $cast code $faucet.Contract --rpc-url $RpcUrl 2>&1) -join ''
$hasCode = $code -match '^0x[0-9a-fA-F]{2,}$'

# --- 干跑信息 -------------------------------------------------------------
$expected = [math]::Round($AmountEth * 100, 2)
Write-Host ""
Write-Host "源链      : $Source ($RpcUrl)" -ForegroundColor Cyan
Write-Host "Faucet    : $($faucet.Contract)" -ForegroundColor Cyan
if ($hasCode) {
    Write-Host "合约代码  : $([math]::Round(($code.Length - 2) / 2)) 字节" -ForegroundColor Cyan
} else {
    Write-Host "合约代码  : 0 字节（正常，该 faucet 靠原生转账入账，不是合约调用）" -ForegroundColor Yellow
}
Write-Host "发送模式  : $Mode" -ForegroundColor Cyan
Write-Host "收款地址  : $Address" -ForegroundColor Cyan
Write-Host "发送金额  : $AmountEth ETH  ->  预期 $expected lREACT" -ForegroundColor Cyan
Write-Host ""

if (-not $hasCode -and $Mode -eq 'request') {
    throw "该地址没有 bytecode，无法调用 request(address)。改用默认的 -Mode transfer。"
}

$before = Get-BalanceEth -addr $Address -rpc $RpcUrl
Write-Host ("源链余额  : {0} ETH（发送前）" -f $before)
if ($before -lt $AmountEth) {
    throw ("余额不够：需要 {0} ETH，当前只有 {1} ETH。" -f $AmountEth, $before)
}

# --- 发交易 ---------------------------------------------------------------
if ($Mode -eq 'transfer') {
    Write-Host "`n发送 $AmountEth ETH（纯转账）..." -ForegroundColor Yellow
    $out = & $cast send $faucet.Contract `
        --value "${AmountEth}ether" `
        --rpc-url $RpcUrl `
        --private-key $PrivateKey 2>&1
} else {
    Write-Host "`n调用 request(address) 并附带 $AmountEth ETH..." -ForegroundColor Yellow
    $out = & $cast send $faucet.Contract "request(address)" $Address `
        --value "${AmountEth}ether" `
        --rpc-url $RpcUrl `
        --private-key $PrivateKey 2>&1
}
if ($LASTEXITCODE -ne 0) { throw "交易失败：`n$($out -join "`n")" }
Write-Host ($out -join "`n")

# --- 回读 -----------------------------------------------------------------
Write-Host "`n等待 Lasna 铸造（实测约 1 分钟）..." -ForegroundColor Yellow
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
    Write-Host "还没看到到账，稍后自检：" -ForegroundColor Yellow
    Write-Host "    cast balance $Address --rpc-url $LASNA_RPC --ether"
} else {
    Write-Host "到账了。" -ForegroundColor Green
}
Write-Host "浏览器查看：https://lasna.reactscan.net/address/$Address"
