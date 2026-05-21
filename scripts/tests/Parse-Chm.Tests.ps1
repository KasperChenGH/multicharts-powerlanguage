BeforeAll {
  $repoRoot = (Resolve-Path "$PSScriptRoot/../..").Path
  Import-Module "$repoRoot/scripts/lib/Parse-Chm.psm1" -Force
  $buy = "$repoRoot/references/chm_extracted/files/03_words/Strategy_Orders/buy.htm"
  $all = "$repoRoot/references/chm_extracted/files/03_words/Strategy_Orders/all.htm"
}

Describe 'Parse-Chm' {
  It 'extracts the keyword name from <H1>' {
    $r = Parse-ChmFile $buy
    $r.Name | Should -Be 'Buy'
  }

  It 'derives the category from the folder name' {
    $r = Parse-ChmFile $buy
    $r.Category | Should -Be 'Strategy_Orders'
  }

  It 'extracts the first sentence of the description' {
    $r = Parse-ChmFile $buy
    $r.Description | Should -Match '^Enters a long position'
  }

  It 'extracts the usage signature' {
    $r = Parse-ChmFile $buy
    $r.Usage | Should -Match 'Buy\s*\[\(.*EntryLabel.*\)\]'
  }

  It 'extracts each parameter as a hashtable with Name/Type/Required' {
    $r = Parse-ChmFile $buy
    $r.Parameters.Count | Should -BeGreaterOrEqual 3
    $entryLabel = $r.Parameters | Where-Object Name -eq 'EntryLabel'
    $entryLabel.Required | Should -BeFalse
  }

  It 'captures the source example block (for later avoid-copy check)' {
    $r = Parse-ChmFile $buy
    $r.SourceExampleBlock | Should -Match 'Buy.*Next Bar'
  }

  It 'handles short keywords with no parameter list (All.htm)' {
    $r = Parse-ChmFile $all
    $r.Name | Should -Be 'All'
    $r.Parameters.Count | Should -Be 0
    $r.Description | Should -Match '^Used in strategy exit'
  }

  Context 'error paths' {
    It 'throws when the file does not exist' {
      { Parse-ChmFile "$repoRoot/references/chm_extracted/does-not-exist.htm" } | Should -Throw
    }

    It 'throws when the .htm has no <H1>' {
      $tmpDir = "$repoRoot/scripts/.cache/parse-chm-no-h1"
      New-Item -ItemType Directory -Path $tmpDir -Force | Out-Null
      $path = Join-Path $tmpDir 'no-h1.htm'
      try {
        Set-Content $path '<HTML><BODY>no heading here</BODY></HTML>' -Encoding UTF8
        { Parse-ChmFile $path } | Should -Throw
      } finally {
        Remove-Item $tmpDir -Recurse -Force -ErrorAction SilentlyContinue
      }
    }
  }
}
