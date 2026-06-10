# One-off maintenance script (task: bulk-fix committed detail files).
#
# 1. Strips the scraper junk " Parameters" trailing inside **Signature:** backticks
#    (e.g. `Arw_New_BN (BarNumber, PriceValue, Direction) Parameters` -> no junk).
# 2. Regenerates the **Example (illustrative)** code block of every detail file from
#    the category-aware generator (scripts/lib/Generate-Example.psm1), so the committed
#    artifacts exactly match what a fresh generator run would emit. This removes the
#    `Value1 = <non-RHS keyword>;` compile-error class.
#
# Hand-fixed files (curated examples better than generator output) are excluded from
# step 2 but still get step 1.
#
# Run from anywhere:  powershell -File scripts\fix-detail-examples.ps1
# Idempotent: a second run reports 0 changes.

$ErrorActionPreference = 'Stop'

$scriptsDir = $PSScriptRoot
$repoRoot   = Split-Path $scriptsDir -Parent
Import-Module (Join-Path $scriptsDir 'lib\Generate-Example.psm1') -Force

$detailsDir = Join-Path $repoRoot 'skills\powerlanguage-keywords-reference\details'
if (-not (Test-Path $detailsDir)) { throw "details dir not found: $detailsDir" }

# Curated by hand this session - do NOT regenerate their Example sections.
$handFixed = @(
  'Plotting\Plot.md'
  'Strategy_Orders\Sell.md'
  'Strategy_Orders\Buy.md'
  'Strategy_Orders\SellShort.md'
  'Strategy_Orders\BuyToCover.md'
  'Strategy_Orders\Market.md'
  'Strategy_Orders\Contract.md'
  'Strategy_Orders\Contracts.md'
  'Strategy_Orders\Share.md'
  'Strategy_Orders\Shares.md'
  'Strategy_Orders\All.md'
  'Strategy_Orders\Stop.md'
  'Strategy_Orders\Limit.md'
  'Strategy_Position\MarketPosition.md'
  'Strategy_Position\EntryPrice.md'
  'Strategy_Position\BarsSinceEntry.md'
  'Arrow_Drawing\Arw_New_Self_BN.md'
)

$utf8NoBom = [System.Text.UTF8Encoding]::new($false)
$sigRegex  = [regex]'(?m)^(\*\*Signature:\*\* `[^`\r\n]*?)\s+Parameters(`)'
$usageRgx  = [regex]'(?m)^\*\*Signature:\*\* `([^`\r\n]*)`'
$exRegex   = [regex]'(?s)(\*\*Example \(illustrative\)\*\*\s*\r?\n```[^\r\n]*\r?\n).*?(\r?\n```)'

$scanned = 0; $sigFixed = 0; $exChanged = 0; $noExampleSection = @(); $skippedHandFixed = 0

Get-ChildItem $detailsDir -Recurse -Filter '*.md' | ForEach-Object {
  $scanned++
  $rel  = $_.FullName.Substring($detailsDir.Length + 1)
  $text = [System.IO.File]::ReadAllText($_.FullName)
  $orig = $text

  # --- Step 1: signature junk ---
  $afterSig = $sigRegex.Replace($text, '$1$2')
  if ($afterSig -ne $text) { $sigFixed++ }
  $text = $afterSig

  # --- Step 2: regenerate Example block (skip curated files) ---
  if ($handFixed -contains $rel) {
    $skippedHandFixed++
  }
  else {
    $name  = [System.IO.Path]::GetFileNameWithoutExtension($_.Name)
    $cat   = Split-Path $rel -Parent
    $usage = ''
    $m = $usageRgx.Match($text)
    if ($m.Success) { $usage = $m.Groups[1].Value }

    $example = Get-CategoryAwareExample -Name $name -Category $cat -Usage $usage

    $mEx = $exRegex.Match($text)
    if ($mEx.Success) {
      $newBlock = $mEx.Groups[1].Value + $example + $mEx.Groups[2].Value
      if ($newBlock -ne $mEx.Value) {
        $text = $text.Substring(0, $mEx.Index) + $newBlock + $text.Substring($mEx.Index + $mEx.Length)
        $exChanged++
      }
    }
    else {
      $noExampleSection += $rel
    }
  }

  if ($text -ne $orig) {
    [System.IO.File]::WriteAllText($_.FullName, $text, $utf8NoBom)
  }
}

Write-Output "Scanned:               $scanned"
Write-Output "Signature junk fixed:  $sigFixed"
Write-Output "Examples regenerated:  $exChanged"
Write-Output "Hand-fixed skipped:    $skippedHandFixed"
Write-Output "No Example section:    $($noExampleSection.Count)"
$noExampleSection | ForEach-Object { Write-Output "  (no example) $_" }
