BeforeAll {
  $repoRoot = (Resolve-Path "$PSScriptRoot/../..").Path
  Import-Module "$repoRoot/scripts/lib/Build-PlaFixtures.psm1" -Force

  $script:tmp = "$repoRoot/scripts/.cache/test-pla-fixtures"
  Remove-Item $script:tmp -Recurse -Force -ErrorAction SilentlyContinue
  New-Item -ItemType Directory -Path $script:tmp -Force | Out-Null

  # Synthetic keyword set spanning Indicator + Signal + skip-word categories.
  # Market/Limit/Stop and Contract/Contracts share demo order statements and
  # exercise the unique-order-name behavior.
  $script:keywords = @(
    @{ Name = 'Buy';       Category = 'Strategy_Orders';  Parameters = @(); Usage = 'Buy ;' }
    @{ Name = 'Sell';      Category = 'Strategy_Orders';  Parameters = @(); Usage = 'Sell ;' }
    @{ Name = 'Market';    Category = 'Strategy_Orders';  Parameters = @(); Usage = 'Market' }
    @{ Name = 'Limit';     Category = 'Strategy_Orders';  Parameters = @(); Usage = 'Limit' }
    @{ Name = 'Stop';      Category = 'Strategy_Orders';  Parameters = @(); Usage = 'Stop' }
    @{ Name = 'Contract';  Category = 'Strategy_Orders';  Parameters = @(); Usage = 'Contract' }
    @{ Name = 'Contracts'; Category = 'Strategy_Orders';  Parameters = @(); Usage = 'Contracts' }
    @{ Name = 'AbsValue'; Category = 'Math_and_Trig';    Parameters = @(@{Name='x';Type='numeric';Required=$true;Description='val'}); Usage = 'AbsValue( x )' }
    @{ Name = 'Average';  Category = 'Math_and_Trig';    Parameters = @(@{Name='Price';Type='expression';Required=$true;Description='val'}; @{Name='Length';Type='numeric';Required=$true;Description='length'}); Usage = 'Average( Price, Length )' }
    @{ Name = 'Plot1';    Category = 'Plotting';         Parameters = @(@{Name='Value';Type='numeric';Required=$true;Description='val'}); Usage = 'Plot1( Value )' }
    @{ Name = 'On';       Category = 'Skip_Words';       Parameters = @(); Usage = 'optional connector' }
  )
}

AfterAll {
  Remove-Item $script:tmp -Recurse -Force -ErrorAction SilentlyContinue
}

Describe 'Build-PlaFixtures' {
  It 'creates exactly three .txt files' {
    New-PlaFixtures -Keywords $script:keywords -OutputDir $script:tmp
    Test-Path "$script:tmp/test_indicator.txt" | Should -BeTrue
    Test-Path "$script:tmp/test_signal.txt"    | Should -BeTrue
    Test-Path "$script:tmp/test_function.txt"  | Should -BeTrue
  }

  It 'signal file uses Strategy_Orders keywords' {
    $body = Get-Content "$script:tmp/test_signal.txt" -Raw
    $body | Should -Match '\bBuy\b'
    $body | Should -Match '\bSell\b'
  }

  It 'indicator file uses Math and Plotting keywords' {
    $body = Get-Content "$script:tmp/test_indicator.txt" -Raw
    $body | Should -Match '\bAbsValue\b'
    $body | Should -Match '\bAverage\b'
    $body | Should -Match '\bPlot1\b'
  }

  It 'signal file does NOT contain Plot1 (it would fail to compile in Signal scripts)' {
    $body = Get-Content "$script:tmp/test_signal.txt" -Raw
    $body | Should -Not -Match '\bPlot1\b'
  }

  It 'indicator file does NOT contain Buy/Sell (would fail to compile in Indicator scripts)' {
    $body = Get-Content "$script:tmp/test_indicator.txt" -Raw
    $body | Should -Not -Match '\bBuy\s*\(' # the keyword usage, not "Buy" as a word
    $body | Should -Not -Match '\bSell\s*\('
  }

  It 'each file ends with a syntactically valid statement (semicolon)' {
    foreach ($p in 'test_indicator.txt','test_signal.txt','test_function.txt') {
      $body = (Get-Content "$script:tmp/$p" -Raw).TrimEnd()
      $body | Should -Match ';\s*$'
    }
  }

  It 'wraps keyword statements in an unreachable If False Then Begin ... End so the compiler verifies syntax only' {
    $body = Get-Content "$script:tmp/test_indicator.txt" -Raw
    $body | Should -Match '(?i)If\s+False\s+Then\s+Begin'
    $body | Should -Match '(?i)End\s*;'
  }

  It 'includes per-keyword comment markers naming the category and keyword' {
    $body = Get-Content "$script:tmp/test_indicator.txt" -Raw
    $body | Should -Match '\{\s*Math_and_Trig:\s*AbsValue\s*\}'
    $body | Should -Match '\{\s*Plotting:\s*Plot1\s*\}'
  }

  It 'emits no duplicate quoted order names in the signal fixture (MultiCharts requires unique order names)' {
    $body = Get-Content "$script:tmp/test_signal.txt" -Raw
    $names = [regex]::Matches($body, '(?i)\b(?:Buy|Sell|SellShort|BuyToCover)\s*\(\s*"([^"]+)"') |
      ForEach-Object { $_.Groups[1].Value }
    $names.Count | Should -BeGreaterThan 1
    $dupes = $names | Group-Object | Where-Object Count -gt 1
    $dupes | Should -BeNullOrEmpty
  }

  It 'order-name counters reset between builds (re-run is deterministic)' {
    $body1 = Get-Content "$script:tmp/test_signal.txt" -Raw
    New-PlaFixtures -Keywords $script:keywords -OutputDir $script:tmp
    $body2 = Get-Content "$script:tmp/test_signal.txt" -Raw
    $body2 | Should -Be $body1
  }

  It 'function fixture is an explicit minimal function template with a return assignment' {
    $body = Get-Content "$script:tmp/test_function.txt" -Raw
    $body | Should -Match '(?i)RangeRatio\s*=\s*Range\s*/\s*avgRng'   # return-by-assignment
    $body | Should -Match '(?i)If\s+avgRng\s*<>\s*0\s+Then'           # divide-by-zero guard
    $body | Should -Not -Match '(?i)If\s+False\s+Then'   # not the empty keyword shell
  }
}
