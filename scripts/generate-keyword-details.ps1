<#
.SYNOPSIS
  Build the multicharts-powerlanguage skill's keywords reference.
.DESCRIPTION
  Walks the CHM-extracted HTML files, parses each, generates an original
  paraphrased markdown summary + a generated example, writes details/<Cat>/<Kw>.md,
  rebuilds keywords-index.md, and emits tests/test_*.txt fixtures.

  Maintainer-only. End users never run this — they get the committed outputs.
.PARAMETER ChmExtractedRoot
  Path to the decompiled CHM root (containing files/03_words/<Category>/<kw>.htm).
  Defaults to references/chm_extracted at repo root.
.PARAMETER DetailsRoot
  Output root for per-keyword markdown. Defaults to
  skills/powerlanguage-keywords-reference/details at repo root.
.PARAMETER IndexPath
  Output path for keywords-index.md.
.PARAMETER TestsDir
  Output dir for test_*.txt fixtures.
.PARAMETER ChmPath
  Path to PowerLanguage.chm. If set and ChmExtractedRoot is empty, the script
  decompiles via hh.exe first.
#>
[CmdletBinding()]
param(
  [string] $ChmExtractedRoot = '',
  [string] $DetailsRoot      = '',
  [string] $IndexPath        = '',
  [string] $TestsDir         = '',
  [string] $ChmPath          = 'C:\Program Files\TS Support\MultiCharts64\PowerLanguage.chm'
)

$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path "$PSScriptRoot/..").Path

if ([string]::IsNullOrWhiteSpace($ChmExtractedRoot)) { $ChmExtractedRoot = "$repoRoot/references/chm_extracted" }
if ([string]::IsNullOrWhiteSpace($DetailsRoot))      { $DetailsRoot      = "$repoRoot/skills/powerlanguage-keywords-reference/details" }
if ([string]::IsNullOrWhiteSpace($IndexPath))        { $IndexPath        = "$repoRoot/skills/powerlanguage-keywords-reference/keywords-index.md" }
if ([string]::IsNullOrWhiteSpace($TestsDir))         { $TestsDir         = "$repoRoot/tests" }

# Decompile CHM if needed
if (-not (Test-Path "$ChmExtractedRoot/files/03_words")) {
  if (Test-Path $ChmPath) {
    Write-Host "Decompiling $ChmPath -> $ChmExtractedRoot"
    New-Item -ItemType Directory -Path $ChmExtractedRoot -Force | Out-Null
    Start-Process -FilePath 'C:\Windows\hh.exe' -ArgumentList '-decompile',$ChmExtractedRoot,$ChmPath -Wait
  } else {
    throw "CHM source not found at $ChmPath and no pre-extracted tree at $ChmExtractedRoot"
  }
}

# Import all modules
$libs = 'Parse-Chm','Paraphrase','Generate-Example','Write-DetailFile','Build-Index','Build-PlaFixtures','Test-VerbatimLint'
foreach ($lib in $libs) {
  Import-Module "$repoRoot/scripts/lib/$lib.psm1" -Force
}

# Get-CleanedParamDescription now lives in lib/Paraphrase.psm1 (imported above)
# so it is unit-testable.

# Find every .htm under the category tree
$htmFiles = Get-ChildItem "$ChmExtractedRoot/files/03_words" -Recurse -Filter '*.htm'
Write-Host "Found $($htmFiles.Count) keyword .htm files"

$parsedKeywords = @()
$failures = @()

$placeholderDescription = 'See the official MultiCharts documentation linked below for the full description and behavior of this keyword.'
$paraphraseSkipped = 0
$verbatimLintFailures = 0

foreach ($f in $htmFiles) {
  try {
    $parsed = Parse-ChmFile $f.FullName

    # Try to paraphrase the main description. If the paraphraser can't safely
    # rewrite it (rule miss or 9-word verbatim run survived), fall back to a
    # generic placeholder + the wiki link in the footer. This keeps coverage
    # at 100% of keywords rather than dropping un-paraphraseable ones.
    try {
      $paraphrased = Get-ParaphrasedDescription $parsed.Description
    } catch {
      $paraphrased = $placeholderDescription
      $paraphraseSkipped++
    }

    $example = New-KeywordExample $parsed

    # Clean and paraphrase each parameter description before writing.
    $cleanParams = @()
    foreach ($p in $parsed.Parameters) {
      $cleanParams += @{
        Name        = $p.Name
        Type        = $p.Type
        Required    = $p.Required
        Description = Get-CleanedParamDescription $p.Description
      }
    }
    $parsed.Parameters = $cleanParams

    $outPath = Write-KeywordDetailFile -Parsed $parsed -Description $paraphrased -Example $example -OutputRoot $DetailsRoot

    # Verbatim lint — last line of defense. If a leak got through, escalate:
    # (1) rewrite description to the placeholder; if still leaking,
    # (2) also blank out the Signature line and the per-parameter list. These
    # come from Parse-Chm's regex extraction and occasionally contain large
    # chunks of the CHM Usage prose verbatim. Replacing them with placeholders
    # preserves the keyword file at the cost of less detail.
    # -Encoding UTF8 everywhere: these files are BOM-less UTF-8; PS 5.1 would
    # otherwise read them as ANSI and corrupt non-ASCII characters.
    $md = Get-Content $outPath -Raw -Encoding UTF8
    $htm = Get-Content $f.FullName -Raw -Encoding UTF8
    $persistentLeak = $false
    if (Test-VerbatimLint -MarkdownText $md -SourceHtmlText $htm) {
      # Step 1: placeholder description.
      Write-KeywordDetailFile -Parsed $parsed -Description $placeholderDescription -Example $example -OutputRoot $DetailsRoot | Out-Null
      $verbatimLintFailures++
      $md2 = Get-Content $outPath -Raw -Encoding UTF8
      if (Test-VerbatimLint -MarkdownText $md2 -SourceHtmlText $htm) {
        # Step 2: also blank out Usage + Parameters.
        $strippedParsed = @{
          Name       = $parsed.Name
          Category   = $parsed.Category
          Usage      = 'See official docs for signature details.'
          Parameters = @()
        }
        Write-KeywordDetailFile -Parsed $strippedParsed -Description $placeholderDescription -Example $example -OutputRoot $DetailsRoot | Out-Null
        $md3 = Get-Content $outPath -Raw -Encoding UTF8
        if (Test-VerbatimLint -MarkdownText $md3 -SourceHtmlText $htm) {
          # Fail closed: a verbatim leak survived every escalation step.
          # Remove the leaking file from disk so it can never be committed,
          # and record a hard failure (the run will exit 1 below).
          Remove-Item $outPath -Force -ErrorAction SilentlyContinue
          Write-Host "REMOVED leaking output: $outPath" -ForegroundColor Red
          $persistentLeak = $true
          $failures += @{ File = $f.FullName; Reason = 'verbatim-lint (persists even with stripped placeholder); output file removed' }
        }
      }
    }
    if (-not $persistentLeak) { $parsedKeywords += $parsed }
  } catch {
    $failures += @{ File = $f.FullName; Reason = $_.Exception.Message }
  }
}

# Fail closed: any hard failure (parse error or persistent verbatim leak)
# aborts the run BEFORE index/fixture building, with a non-zero exit code,
# so stale or leaking content is never indexed or committed.
if ($failures.Count -gt 0) {
  Write-Host ""
  Write-Host "$($failures.Count) keyword(s) hit a hard failure:" -ForegroundColor Red
  $failures | ForEach-Object {
    Write-Host "  $($_.File)  =>  $($_.Reason)" -ForegroundColor Red
  }
  Write-Host "Fail-closed: skipping index + fixture build. Fix the failures and re-run." -ForegroundColor Red
  exit 1
}

# Reconciliation: delete orphan detail files whose keyword is no longer in the
# parsed set (e.g. removed/renamed in a newer CHM). Without this, Build-Index
# would re-index stale files forever.
$expectedRel = @{}
foreach ($kw in $parsedKeywords) { $expectedRel["$($kw.Category)\$($kw.Name).md"] = $true }
$orphansDeleted = 0
if (Test-Path $DetailsRoot) {
  $detailsRootFull = (Resolve-Path $DetailsRoot).Path
  Get-ChildItem $detailsRootFull -Recurse -Filter '*.md' | ForEach-Object {
    $rel = "$($_.Directory.Name)\$($_.Name)"
    if (-not $expectedRel.ContainsKey($rel)) {
      Write-Host "Reconciliation: deleting orphan detail file $($_.FullName)" -ForegroundColor Yellow
      Remove-Item $_.FullName -Force
      $orphansDeleted++
    }
  }
  # Drop category folders left empty by the reconciliation.
  Get-ChildItem $detailsRootFull -Directory | Where-Object {
    @(Get-ChildItem $_.FullName -Recurse -File).Count -eq 0
  } | ForEach-Object {
    Write-Host "Reconciliation: removing empty category folder $($_.FullName)" -ForegroundColor Yellow
    Remove-Item $_.FullName -Recurse -Force
  }
}

# Build the index
New-KeywordsIndex -DetailsRoot $DetailsRoot -OutputPath $IndexPath | Out-Null
Write-Host "Wrote index: $IndexPath"

# Build the .txt compile-test fixtures
if (-not (Test-Path $TestsDir)) { New-Item -ItemType Directory -Path $TestsDir -Force | Out-Null }
New-PlaFixtures -Keywords $parsedKeywords -OutputDir $TestsDir
Write-Host "Wrote .txt compile-test fixtures in: $TestsDir"

# Report stats
Write-Host ""
Write-Host "Generated $($parsedKeywords.Count) of $($htmFiles.Count) keyword files." -ForegroundColor Green
Write-Host "  $paraphraseSkipped keyword(s) used the placeholder description (paraphrase rule miss)." -ForegroundColor Cyan
Write-Host "  $verbatimLintFailures keyword(s) had a verbatim-lint hit and were rewritten with placeholder." -ForegroundColor Cyan
Write-Host "  $orphansDeleted orphan detail file(s) removed by reconciliation." -ForegroundColor Cyan
