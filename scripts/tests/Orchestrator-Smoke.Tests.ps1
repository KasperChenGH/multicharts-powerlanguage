BeforeDiscovery {
  # The CHM-extracted corpus is gitignored — on a fresh clone it is absent.
  # Skip the whole smoke test gracefully instead of failing in BeforeAll.
  $repoRoot = (Resolve-Path "$PSScriptRoot/../..").Path
  $script:chmAvailable =
    (Test-Path "$repoRoot/references/chm_extracted/files/03_words/Strategy_Orders/buy.htm") -and
    (Test-Path "$repoRoot/references/chm_extracted/files/03_words/Strategy_Orders/sell.htm")
}

Describe 'Orchestrator smoke test (Buy + Sell only)' -Skip:(-not $script:chmAvailable) {
  BeforeAll {
    $repoRoot = (Resolve-Path "$PSScriptRoot/../..").Path
    $script:tmp = "$repoRoot/scripts/.cache/test-orchestrator"
    Remove-Item $script:tmp -Recurse -Force -ErrorAction SilentlyContinue
    New-Item -ItemType Directory -Path "$script:tmp/files/03_words/Strategy_Orders" -Force | Out-Null

    # Copy two real CHM-extracted .htm files into the fake tree
    Copy-Item "$repoRoot/references/chm_extracted/files/03_words/Strategy_Orders/buy.htm" "$script:tmp/files/03_words/Strategy_Orders/"
    Copy-Item "$repoRoot/references/chm_extracted/files/03_words/Strategy_Orders/sell.htm" "$script:tmp/files/03_words/Strategy_Orders/"

    $script:outDetails = "$script:tmp/out/details"
    $script:outTests   = "$script:tmp/out/tests"
    $script:outIndex   = "$script:tmp/out/keywords-index.md"

    & "$repoRoot/scripts/generate-keyword-details.ps1" `
        -ChmExtractedRoot $script:tmp `
        -DetailsRoot $script:outDetails `
        -IndexPath $script:outIndex `
        -TestsDir $script:outTests
  }

  AfterAll {
    Remove-Item $script:tmp -Recurse -Force -ErrorAction SilentlyContinue
  }

  It 'produces Buy.md' {
    Test-Path "$script:tmp/out/details/Strategy_Orders/Buy.md" | Should -BeTrue
  }

  It 'produces Sell.md' {
    Test-Path "$script:tmp/out/details/Strategy_Orders/Sell.md" | Should -BeTrue
  }

  It 'produces keywords-index.md' {
    Test-Path "$script:tmp/out/keywords-index.md" | Should -BeTrue
  }

  It 'produces three .txt files' {
    Test-Path "$script:tmp/out/tests/test_indicator.txt" | Should -BeTrue
    Test-Path "$script:tmp/out/tests/test_signal.txt"    | Should -BeTrue
    Test-Path "$script:tmp/out/tests/test_function.txt"  | Should -BeTrue
  }

  It 'reconciliation deletes orphan detail files on a re-run' {
    # Plant an orphan .md (keyword that no longer exists in the corpus) and
    # re-run the generator: the orphan must be removed, real files kept.
    $orphan = "$script:tmp/out/details/Strategy_Orders/NoSuchKeyword.md"
    Set-Content $orphan -Value '# NoSuchKeyword' -Encoding UTF8
    $repoRoot = (Resolve-Path "$PSScriptRoot/../..").Path
    & "$repoRoot/scripts/generate-keyword-details.ps1" `
        -ChmExtractedRoot $script:tmp `
        -DetailsRoot $script:outDetails `
        -IndexPath $script:outIndex `
        -TestsDir $script:outTests | Out-Null
    Test-Path $orphan | Should -BeFalse
    Test-Path "$script:tmp/out/details/Strategy_Orders/Buy.md" | Should -BeTrue
  }

  It 'Buy.md verbatim-lint passes (no 9-word verbatim run)' {
    $repoRoot = (Resolve-Path "$PSScriptRoot/../..").Path
    Import-Module "$repoRoot/scripts/lib/Test-VerbatimLint.psm1" -Force
    $md  = Get-Content "$script:tmp/out/details/Strategy_Orders/Buy.md" -Raw -Encoding UTF8
    $htm = Get-Content "$script:tmp/files/03_words/Strategy_Orders/buy.htm" -Raw -Encoding UTF8
    Test-VerbatimLint -MarkdownText $md -SourceHtmlText $htm | Should -BeFalse
  }

  It 'Buy.md does not contain the COPYRIGHT-sentinel string' {
    $body = Get-Content "$script:tmp/out/details/Strategy_Orders/Buy.md" -Raw -Encoding UTF8
    $body | Should -Not -Match 'Arrow identifies the time and the Tick identifies'
    # ^^^ a recognizable 9-word run from buy.htm — must not appear verbatim
  }
}
