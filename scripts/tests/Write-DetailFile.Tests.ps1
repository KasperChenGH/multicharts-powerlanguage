BeforeAll {
  $repoRoot = (Resolve-Path "$PSScriptRoot/../..").Path
  Import-Module "$repoRoot/scripts/lib/Write-DetailFile.psm1" -Force

  $script:tmp = "$repoRoot/scripts/.cache/test-write-detail"
  Remove-Item $script:tmp -Recurse -Force -ErrorAction SilentlyContinue
  New-Item -ItemType Directory -Path $script:tmp -Force | Out-Null
}

AfterAll {
  Remove-Item $script:tmp -Recurse -Force -ErrorAction SilentlyContinue
}

Describe 'Write-DetailFile' {
  It 'writes a markdown file with the expected template' {
    $parsed = @{
      Name = 'Buy'; Category = 'Strategy_Orders'
      Description = 'Opens a long position with the size and timing given by the parameters.'
      Usage = 'Buy [("EntryLabel")] [TradeSize] EntryType ;'
      Parameters = @(
        @{ Name = 'EntryLabel'; Type = 'string';     Required = $false; Description = 'name for the entry' }
        @{ Name = 'TradeSize';  Type = 'numeric';    Required = $false; Description = 'contract or share count' }
        @{ Name = 'EntryType';  Type = 'expression'; Required = $true;  Description = 'placement keyword' }
      )
    }
    $example = 'Buy ( "Buy_Demo" ) 1 Contract Next Bar Market;'

    $outPath = Write-KeywordDetailFile -Parsed $parsed -Description $parsed.Description -Example $example -OutputRoot $script:tmp

    $outPath | Should -Be "$script:tmp/Strategy_Orders/Buy.md"
    Test-Path $outPath | Should -BeTrue

    $body = Get-Content $outPath -Raw
    $body | Should -Match '^# Buy'
    $body | Should -Match '\*\*Category:\*\* Strategy_Orders'
    $body | Should -Match '\*\*Signature:\*\* `Buy \[\("EntryLabel"\)\] \[TradeSize\] EntryType ;`'
    $body | Should -Match 'Opens a long position'
    $body | Should -Match '`EntryLabel` \*\(string, optional\)\*'
    $body | Should -Match '`EntryType` \*\(expression, required\)\*'
    $body | Should -Match 'Buy \( "Buy_Demo" \) 1 Contract Next Bar Market;'
    $body | Should -Match '\*Official docs:\* https://www\.multicharts\.com/trading-software/index\.php\?title=Buy'
  }

  It 'creates the category folder if it does not exist' {
    $parsed = @{
      Name = 'TestKeyword'; Category = 'NewCategory'
      Description = 'A test description.'; Usage = 'TestKeyword;'; Parameters = @()
    }
    Write-KeywordDetailFile -Parsed $parsed -Description $parsed.Description -Example 'TestKeyword;' -OutputRoot $script:tmp
    Test-Path "$script:tmp/NewCategory/TestKeyword.md" | Should -BeTrue
  }

  It 'omits the Parameters section when there are zero parameters' {
    $parsed = @{
      Name = 'All'; Category = 'Strategy_Orders'
      Description = 'Quantity placeholder.'; Usage = 'All Contracts'; Parameters = @()
    }
    $outPath = Write-KeywordDetailFile -Parsed $parsed -Description $parsed.Description -Example 'Sell All Contracts Next Bar Market;' -OutputRoot $script:tmp
    $body = Get-Content $outPath -Raw
    $body | Should -Not -Match '\*\*Parameters\*\*'
  }

  It 'writes UTF-8 without BOM' {
    $parsed = @{
      Name = 'Foo'; Category = 'TestCat'
      Description = 'Bar baz quux.'; Usage = 'Foo;'; Parameters = @()
    }
    $outPath = Write-KeywordDetailFile -Parsed $parsed -Description $parsed.Description -Example 'Foo;' -OutputRoot $script:tmp
    $bytes = [System.IO.File]::ReadAllBytes($outPath)
    # First three bytes should NOT be UTF-8 BOM (0xEF, 0xBB, 0xBF)
    -not ($bytes.Count -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) | Should -BeTrue
  }
}
