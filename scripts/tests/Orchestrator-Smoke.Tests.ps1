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

Describe 'Orchestrator smoke test (Buy + Sell only)' {
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

  It 'Buy.md verbatim-lint passes (no 9-word verbatim run)' {
    $repoRoot = (Resolve-Path "$PSScriptRoot/../..").Path
    Import-Module "$repoRoot/scripts/lib/Test-VerbatimLint.psm1" -Force
    $md  = Get-Content "$script:tmp/out/details/Strategy_Orders/Buy.md" -Raw
    $htm = Get-Content "$script:tmp/files/03_words/Strategy_Orders/buy.htm" -Raw
    Test-VerbatimLint -MarkdownText $md -SourceHtmlText $htm | Should -BeFalse
  }

  It 'Buy.md does not contain the COPYRIGHT-sentinel string' {
    $body = Get-Content "$script:tmp/out/details/Strategy_Orders/Buy.md" -Raw
    $body | Should -Not -Match 'Arrow identifies the time and the Tick identifies'
    # ^^^ a recognizable 9-word run from buy.htm — must not appear verbatim
  }
}
