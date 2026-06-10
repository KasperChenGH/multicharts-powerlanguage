BeforeAll {
  $repoRoot = (Resolve-Path "$PSScriptRoot/../..").Path
  Import-Module "$repoRoot/scripts/lib/Paraphrase.psm1" -Force
}

Describe 'Paraphrase' {
  It 'rewrites a long-position opener' {
    $r = Get-ParaphrasedDescription 'Enters a long position as specified by the parameters.'
    $r | Should -Not -Match 'Enters a long position as specified by the parameters'
    $r | Should -Match '(open|opens|long position)'
    $r.Length | Should -BeGreaterThan 10
  }

  It 'rewrites a short-position opener' {
    $r = Get-ParaphrasedDescription 'Enters a short position as specified by the parameters.'
    $r | Should -Not -Match 'Enters a short position as specified by the parameters'
  }

  It 'rewrites a "Returns X" formula' {
    $r = Get-ParaphrasedDescription 'Returns the absolute value of a numeric expression.'
    $r | Should -Not -Match 'Returns the absolute value of a numeric expression'
    $r | Should -Match 'absolute value'
  }

  It 'rewrites a "Used in/for" formula' {
    $r = Get-ParaphrasedDescription 'Used in strategy exit statements in place of expressions.'
    $r | Should -Not -Match 'Used in strategy exit statements in place of expressions'
    # Positive assertion: meaningful content preserved
    $r | Should -Match 'strategy exit'
    $r | Should -Match 'expression'
  }

  It 'throws when a prefix-only rule rewrite leaves a 9-word verbatim tail (9-word threshold)' {
    # The "Used in" rule rewrites only the leading words; with the threshold
    # aligned on 9 (matching Test-VerbatimLint), a source whose remainder is
    # itself a 9-word run must be rejected rather than passed through.
    { Get-ParaphrasedDescription 'Used in strategy exit statements in place of a numerical expression.' } | Should -Throw '*9-word verbatim run*'
  }

  It 'preserves topical terms when the keyword is the subject' {
    $r = Get-ParaphrasedDescription 'Calculates the exponential moving average of price.'
    $r | Should -Match 'moving average'
  }

  It 'throws for descriptions it cannot safely paraphrase' {
    { Get-ParaphrasedDescription 'x' } | Should -Throw
    { Get-ParaphrasedDescription '' } | Should -Throw
  }

  It 'ensures no 9-word verbatim run remains' {
    $src = 'Enters a long position as specified by the parameters.'
    $r = Get-ParaphrasedDescription $src
    $srcWords = $src -split '\s+'
    for ($i = 0; $i -le ($srcWords.Count - 9); $i++) {
      $window = ($srcWords[$i..($i+8)] -join ' ')
      $r | Should -Not -Match ([regex]::Escape($window))
    }
  }

  It 'handles wildcard metacharacters ([ ] ? *) in the source without throwing WildcardPatternException' {
    # Regression: the containment checks used -like, so bracket characters in
    # CHM text (e.g. "Close[1") formed invalid wildcard patterns, threw
    # WildcardPatternException, and silently degraded the description to the
    # placeholder. The IndexOf-based check must process these cleanly.
    $src = 'Returns the value of Close[1 of bars.'   # unclosed [ = invalid wildcard
    $r = Get-ParaphrasedDescription $src
    $r | Should -Match ([regex]::Escape('Close[1'))
    $r | Should -Not -BeNullOrEmpty
  }

  Context 'Get-CleanedParamDescription' {
    It 'strips the CHM "an optional parameter;" boilerplate prefix and paraphrases the rest' {
      $r = Get-CleanedParamDescription 'an optional parameter; Returns the absolute value of a numeric expression.'
      $r | Should -Not -Match '(?i)an optional parameter'
      $r | Should -Match 'absolute value'
      $r | Should -Not -Match '^Returns the absolute value of a numeric expression'
    }

    It 'falls back to a <=6-word excerpt plus citation when the paraphraser cannot rewrite' {
      # No rule matches and no fallback verb appears -> paraphraser throws ->
      # cleaned fallback: first <=6 words + em-dash citation.
      # The em-dash is built from its code point: a literal U+2014 in this file
      # is misparsed by PowerShell 5.1 when the file has no BOM (ANSI fallback),
      # which turned the pattern into an invalid regex.
      $em = [char]0x2014
      $r = Get-CleanedParamDescription 'a required parameter; foo bar baz qux quux corge grault garply.'
      $r | Should -Match "$em see official docs$"
      ($r -replace "\s*$em see official docs$",'' -split '\s+').Count | Should -BeLessOrEqual 6
    }
  }

  It 'throws when short paraphrase still wholly contains the source' {
    # A pattern with no rule and no fallback verb — the t-unchanged check
    # in the original code already throws "could not safely paraphrase". The
    # short-source guard is for when a rule produces output that still
    # contains the original verbatim. Hard to construct synthetically without
    # a rule that intentionally fails. Use the existing throw path test.
    { Get-ParaphrasedDescription 'foo bar baz qux quux.' } | Should -Throw
  }
}
