BeforeAll {
  $repoRoot = (Resolve-Path "$PSScriptRoot/../..").Path
  Import-Module "$repoRoot/scripts/lib/Generate-Example.psm1" -Force
}

Describe 'Generate-Example' {
  It 'builds an example for Buy from signature + params' {
    $parsed = @{
      Name = 'Buy'; Category = 'Strategy_Orders'
      Usage = 'Buy [("EntryLabel")] [TradeSize] EntryType ;'
      Parameters = @(
        @{ Name = 'EntryLabel'; Type = 'string';     Required = $false; Description = 'optional name' }
        @{ Name = 'TradeSize';  Type = 'numeric';    Required = $false; Description = 'optional size' }
        @{ Name = 'EntryType';  Type = 'expression'; Required = $true;  Description = 'placement' }
      )
    }
    $ex = New-KeywordExample $parsed
    $ex | Should -Match 'Buy\s*\(\s*"[A-Za-z_]+"\s*\)\s*1\s+Contract\s+Next\s+Bar'
  }

  It 'builds an example for a zero-param keyword (All)' {
    $parsed = @{
      Name = 'All'; Category = 'Strategy_Orders'
      Usage = 'All Contracts'
      Parameters = @()
    }
    $ex = New-KeywordExample $parsed
    $ex | Should -Match 'Sell\s+All\s+(Contracts|Shares)'
  }

  It 'falls back to commented usage line for skip-word keywords' {
    $parsed = @{
      Name = 'On'; Category = 'Skip_Words'
      Usage = 'optional connector keyword'
      Parameters = @()
    }
    $ex = New-KeywordExample $parsed
    $ex | Should -Match '^//\s'
    $ex | Should -Match 'On'
  }

  It 'builds an Average call when params suggest numeric series + length' {
    $parsed = @{
      Name = 'Average'; Category = 'Math_and_Trig'
      Usage = 'Average( Price, Length )'
      Parameters = @(
        @{ Name = 'Price';  Type = 'expression'; Required = $true; Description = 'price series' }
        @{ Name = 'Length'; Type = 'numeric';    Required = $true; Description = 'lookback bars' }
      )
    }
    $ex = New-KeywordExample $parsed
    $ex | Should -Match 'Value1\s*=\s*Average\(\s*Close\s*,\s*14\s*\)'
  }

  It 'builds a Plot1 call for plotting keywords' {
    $parsed = @{
      Name = 'Plot1'; Category = 'Plotting'
      Usage = 'Plot1( Value, "Name" )'
      Parameters = @(
        @{ Name = 'Value'; Type = 'numeric'; Required = $true; Description = 'value to plot' }
      )
    }
    $ex = New-KeywordExample $parsed
    $ex | Should -Match 'Plot1\(\s*Close'
  }

  Context 'category-aware rules (non-RHS keyword classes)' {
    It 'Attributes category -> attribute syntax' {
      $ex = New-KeywordExample @{ Name = 'IntrabarOrderGeneration'; Category = 'Attributes'; Usage = ''; Parameters = @() }
      $ex | Should -Be '[IntrabarOrderGeneration = true];'
    }

    It 'Output: Print -> statement form' {
      $ex = New-KeywordExample @{ Name = 'Print'; Category = 'Output'; Usage = 'Print( expr )'; Parameters = @() }
      $ex | Should -Be 'Print("text");'
    }

    It 'Output: FileAppend -> two-arg statement form' {
      $ex = New-KeywordExample @{ Name = 'FileAppend'; Category = 'Output'; Usage = 'FileAppend( FileName, Str )'; Parameters = @() }
      $ex | Should -Match '^FileAppend\("C:\\out\.txt", "text"\);$'
    }

    It 'Output: parameterless ClearDebug / ClearPrintLog -> bare statement' {
      (New-KeywordExample @{ Name = 'ClearDebug';    Category = 'Output'; Usage = ''; Parameters = @() }) | Should -Be 'ClearDebug;'
      (New-KeywordExample @{ Name = 'ClearPrintLog'; Category = 'Output'; Usage = ''; Parameters = @() }) | Should -Be 'ClearPrintLog;'
    }

    It 'connector words (Ago, Bar, Bars) -> comment-only, never Value1 =' {
      foreach ($kw in 'Ago','Bar','Bars') {
        $ex = New-KeywordExample @{ Name = $kw; Category = 'Data_Information_General'; Usage = ''; Parameters = @() }
        $ex | Should -Match '^//'
        $ex | Should -Match 'not a standalone value'
      }
    }

    It 'DLL_Calling C-type names -> comment-only' {
      foreach ($kw in 'Void','WORD','Long','LPBool','LPByte','VarSize','VarStartAddr') {
        $ex = New-KeywordExample @{ Name = $kw; Category = 'DLL_Calling'; Usage = ''; Parameters = @() }
        $ex | Should -Match '^//'
        $ex | Should -Match 'not a standalone value'
      }
    }

    It 'Alert -> Alert("message");' {
      $ex = New-KeywordExample @{ Name = 'Alert'; Category = 'Alerts'; Usage = 'Alert[( Message )]'; Parameters = @() }
      $ex | Should -Be 'Alert("message");'
    }

    It 'keyword with required signature parameters -> placeholder call, NEVER Value1 =' {
      $ex = New-KeywordExample @{ Name = 'GV_SetNamedInt'; Category = 'Environment_Information'; Usage = 'GV_SetNamedInt( Name, Value )'; Parameters = @() }
      $ex | Should -Match 'GV_SetNamedInt\(\s*Name,\s*Value\s*\)'
      $ex | Should -Match 'placeholder'
      $ex | Should -Not -Match 'Value1\s*='
    }

    It 'keyword with an unparseable complex signature -> comment pointing at Usage' {
      $ex = New-KeywordExample @{ Name = 'WeirdFn'; Category = 'Environment_Information'; Usage = 'WeirdFn( a + b, "lit" )'; Parameters = @() }
      $ex | Should -Match '^//'
      $ex | Should -Match 'Usage'
    }

    It 'optional-only parameters (bracketed) are treated as zero-arg value reference' {
      $ex = New-KeywordExample @{ Name = 'CurrentBar'; Category = 'Data_Information_General'; Usage = 'CurrentBar[( BarsBack )]'; Parameters = @() }
      $ex | Should -Be 'Value1 = CurrentBar;'
    }

    It 'zero-arg value-returning keyword -> Value1 = <Keyword>;' {
      foreach ($kw in 'Date','CurrentBar') {
        $ex = New-KeywordExample @{ Name = $kw; Category = 'Data_Information_General'; Usage = $kw; Parameters = @() }
        $ex | Should -Be "Value1 = $kw;"
      }
    }

    It 'zero-arg string-returning keyword -> string variable, NEVER Value1 =' {
      $ex = New-KeywordExample @{ Name = 'SymbolName'; Category = 'Data_Information_General'; Usage = 'SymbolName'; Parameters = @() }
      $ex | Should -Match 'str_val\s*=\s*SymbolName'
      $ex | Should -Not -Match 'Value1\s*='
    }

    It 'remaining non-RHS categories (e.g. Execution_Control) -> comment-only' {
      $ex = New-KeywordExample @{ Name = 'RaiseRunTimeError'; Category = 'Execution_Control'; Usage = 'RaiseRunTimeError( Message )'; Parameters = @() }
      $ex | Should -Match '^//'
      $ex | Should -Not -Match 'Value1\s*='
    }

    It '#-prefixed directives -> comment-only' {
      $ex = New-KeywordExample @{ Name = '#BeginCmtry'; Category = 'ExpertCommentary'; Usage = ''; Parameters = @() }
      $ex | Should -Match '^//'
    }
  }

  Context 'Get-CategoryAwareExample wrapper (bulk-fix entry point)' {
    It 'produces the same output as New-KeywordExample from flat arguments' {
      $a = Get-CategoryAwareExample -Name 'IntrabarOrderGeneration' -Category 'Attributes'
      $a | Should -Be '[IntrabarOrderGeneration = true];'
      $b = Get-CategoryAwareExample -Name 'AbsValue' -Category 'Math_and_Trig' -Usage 'AbsValue( Num )' -Parameters @(@{ Name='Num'; Type='numeric'; Required=$true; Description='v' })
      $b | Should -Match 'Value1 = AbsValue\( Close \);'
    }
  }

  Context 'Test-StringReturningKeyword (shared taxonomy)' {
    It 'flags curated and heuristic string returners' {
      Test-StringReturningKeyword -Name 'SymbolName'   | Should -BeTrue
      Test-StringReturningKeyword -Name 'GetUserName'  | Should -BeTrue
      Test-StringReturningKeyword -Name 'FormatDate'   | Should -BeTrue
    }
    It 'does not flag numeric keywords' {
      Test-StringReturningKeyword -Name 'Close'      | Should -BeFalse
      Test-StringReturningKeyword -Name 'CurrentBar' | Should -BeFalse
    }
  }

  It 'never references the SourceExampleBlock field' {
    $parsed = @{
      Name = 'TestFn'; Category = 'Math_and_Trig'
      Usage = 'TestFn( x )'
      Parameters = @(
        @{ Name = 'x'; Type = 'numeric'; Required = $true; Description = 'a value' }
      )
      SourceExampleBlock = 'COPYRIGHTED_VERBATIM_TEXT_THAT_MUST_NOT_APPEAR_IN_OUTPUT'
    }
    $ex = New-KeywordExample $parsed
    $ex | Should -Not -Match 'COPYRIGHTED_VERBATIM_TEXT_THAT_MUST_NOT_APPEAR_IN_OUTPUT'
  }
}
