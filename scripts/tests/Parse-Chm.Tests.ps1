BeforeDiscovery {
  # The CHM-extracted corpus is gitignored — on a fresh clone it is absent.
  # Compute availability at discovery time so corpus-dependent tests can be
  # skipped gracefully instead of failing.
  $repoRoot = (Resolve-Path "$PSScriptRoot/../..").Path
  $script:chmAvailable =
    (Test-Path "$repoRoot/references/chm_extracted/files/03_words/Strategy_Orders/buy.htm") -and
    (Test-Path "$repoRoot/references/chm_extracted/files/03_words/Strategy_Orders/all.htm")
}

Describe 'Parse-Chm (CHM corpus)' -Skip:(-not $script:chmAvailable) {
  BeforeAll {
    $repoRoot = (Resolve-Path "$PSScriptRoot/../..").Path
    Import-Module "$repoRoot/scripts/lib/Parse-Chm.psm1" -Force
    $buy = "$repoRoot/references/chm_extracted/files/03_words/Strategy_Orders/buy.htm"
    $all = "$repoRoot/references/chm_extracted/files/03_words/Strategy_Orders/all.htm"
  }

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
}

Describe 'Parse-Chm (synthetic, no corpus needed)' {
  BeforeAll {
    $repoRoot = (Resolve-Path "$PSScriptRoot/../..").Path
    Import-Module "$repoRoot/scripts/lib/Parse-Chm.psm1" -Force

    $script:tmpDir = "$repoRoot/scripts/.cache/parse-chm-synthetic"
    New-Item -ItemType Directory -Path $script:tmpDir -Force | Out-Null

    function script:New-SyntheticHtm {
      param([string] $FileName, [string] $Description)
      $path = Join-Path $script:tmpDir $FileName
      $html = "<HTML><BODY><H1>TestKw</H1><table><tr><td class=""DIVtdN"">$Description</td></tr></table></BODY></HTML>"
      $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
      [System.IO.File]::WriteAllText($path, $html, $utf8NoBom)
      return $path
    }
  }

  AfterAll {
    $repoRoot = (Resolve-Path "$PSScriptRoot/../..").Path
    Remove-Item "$repoRoot/scripts/.cache/parse-chm-synthetic" -Recurse -Force -ErrorAction SilentlyContinue
  }

  Context 'first-sentence extraction hardening' {
    It 'does not truncate at "e.g." inside the first sentence' {
      $p = New-SyntheticHtm 'eg.htm' 'Use this keyword, e.g. when plotting values. Second sentence here.'
      $r = Parse-ChmFile $p
      $r.Description | Should -Be 'Use this keyword, e.g. when plotting values.'
    }

    It 'does not truncate at "i.e." or "vs." inside the first sentence' {
      $p = New-SyntheticHtm 'ie.htm' 'Compares bars, i.e. current vs. prior values of the series. More text.'
      $r = Parse-ChmFile $p
      $r.Description | Should -Be 'Compares bars, i.e. current vs. prior values of the series.'
    }

    It 'does not truncate at a decimal point' {
      $p = New-SyntheticHtm 'decimal.htm' 'Returns 1.5 when the condition holds. Second sentence.'
      $r = Parse-ChmFile $p
      $r.Description | Should -Be 'Returns 1.5 when the condition holds.'
    }

    It 'still stops at a genuine sentence boundary' {
      $p = New-SyntheticHtm 'plain.htm' 'First sentence here. Second sentence there.'
      $r = Parse-ChmFile $p
      $r.Description | Should -Be 'First sentence here.'
    }
  }

  Context 'HTML entity decoding' {
    It 'decodes &amp; &quot; &lt; &gt; and numeric dash entities in the description' {
      $p = New-SyntheticHtm 'entities.htm' 'Bars &amp; ticks &#8211; values &lt;= limit, &quot;quoted&quot;.'
      $r = Parse-ChmFile $p
      $r.Description | Should -Match '&(?!amp)'      # a literal & survives
      $r.Description | Should -Not -Match '&amp;'
      $r.Description | Should -Not -Match '&#8211;'
      $r.Description | Should -Not -Match '&quot;'
      $r.Description | Should -Match '<='
      $r.Description | Should -Match '"quoted"'
    }
  }

  Context 'error paths' {
    It 'throws when the file does not exist' {
      $repoRoot = (Resolve-Path "$PSScriptRoot/../..").Path
      { Parse-ChmFile "$repoRoot/references/chm_extracted/does-not-exist.htm" } | Should -Throw
    }

    It 'throws when the .htm has no <H1>' {
      $repoRoot = (Resolve-Path "$PSScriptRoot/../..").Path
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
