BeforeAll {
  $repoRoot = (Resolve-Path "$PSScriptRoot/../..").Path

  $script:customFunctions = @(
    'StochRSI',
    'supertrend',
    'NVI',
    'PVI',
    'Coppo',
    'LWTI',
    'TVI',
    'SharpeRatio',
    'WRSI',
    'NewMA'
  )
}

Describe 'Custom functions consistency' {

  Context 'powerlanguage-syntax SKILL.md' {
    BeforeAll {
      $script:syntaxContent = Get-Content "$repoRoot/skills/powerlanguage-syntax/SKILL.md" -Raw
    }

    It 'has the Custom functions section header' {
      $script:syntaxContent | Should -Match 'Custom functions \(commonly available\)'
    }

    It 'documents <name> with a signature row' -ForEach @(
      @{ name = 'StochRSI';    sig = 'StochRSI\(Price, RSILen, Length\)' },
      @{ name = 'supertrend';  sig = 'supertrend\(ATRLen, Mult\)' },
      @{ name = 'NVI';         sig = 'NVI\(StartValue\)' },
      @{ name = 'PVI';         sig = 'PVI\(StartValue\)' },
      @{ name = 'Coppo';       sig = 'Coppo\(N1, N2, N3\)' },
      @{ name = 'LWTI';        sig = 'LWTI\(Price, Period, Length\)' },
      @{ name = 'TVI';         sig = 'TVI\(Price, Vol, MinTickValue\)' },
      @{ name = 'SharpeRatio'; sig = 'SharpeRatio\(Period, IntRate, CalculateRatio, InitCapital\)' },
      @{ name = 'WRSI';        sig = 'WRSI\(Length, Price\)' },
      @{ name = 'NewMA';       sig = 'NewMA\(Price, Length\)' }
    ) {
      $script:syntaxContent | Should -Match $sig
    }
  }

  Context 'PL compile test files' {
    BeforeAll {
      $script:newFuncContent   = Get-Content "$repoRoot/tests/test_new_functions.txt" -Raw
      $script:builtinsContent  = Get-Content "$repoRoot/tests/test_builtins.txt" -Raw
    }

    It 'test_new_functions.txt contains a call to <name>' -ForEach @(
      @{ name = 'StochRSI' },
      @{ name = 'supertrend' },
      @{ name = 'NVI' },
      @{ name = 'PVI' },
      @{ name = 'Coppo' },
      @{ name = 'LWTI' },
      @{ name = 'TVI' },
      @{ name = 'SharpeRatio' },
      @{ name = 'WRSI' },
      @{ name = 'NewMA' }
    ) {
      $script:newFuncContent | Should -Match "$name\("
    }

    It 'test_builtins.txt contains a call to <name>' -ForEach @(
      @{ name = 'StochRSI' },
      @{ name = 'supertrend' },
      @{ name = 'NVI' },
      @{ name = 'PVI' },
      @{ name = 'Coppo' },
      @{ name = 'LWTI' },
      @{ name = 'TVI' },
      @{ name = 'SharpeRatio' },
      @{ name = 'WRSI' },
      @{ name = 'NewMA' }
    ) {
      $script:builtinsContent | Should -Match "$name\("
    }
  }

  Context 'conversion skill mapping tables' {
    BeforeAll {
      $script:pineSkill   = Get-Content "$repoRoot/skills/powerlanguage-pinescript-conversion/SKILL.md" -Raw
      $script:pythonSkill = Get-Content "$repoRoot/skills/powerlanguage-python-conversion/SKILL.md" -Raw
      $script:rustSkill   = Get-Content "$repoRoot/skills/powerlanguage-rust-conversion/SKILL.md" -Raw
      $script:cppSkill    = Get-Content "$repoRoot/skills/powerlanguage-cpp-conversion/SKILL.md" -Raw
    }

    It 'Pine Script conversion maps <name>' -ForEach @(
      @{ name = 'StochRSI' },
      @{ name = 'supertrend' },
      @{ name = 'NVI' },
      @{ name = 'PVI' },
      @{ name = 'Coppo' },
      @{ name = 'LWTI' },
      @{ name = 'TVI' },
      @{ name = 'SharpeRatio' },
      @{ name = 'WRSI' },
      @{ name = 'NewMA' }
    ) {
      $script:pineSkill | Should -Match $name
    }

    It 'Python conversion maps <name>' -ForEach @(
      @{ name = 'StochRSI' },
      @{ name = 'supertrend' },
      @{ name = 'NVI' },
      @{ name = 'PVI' },
      @{ name = 'Coppo' },
      @{ name = 'LWTI' },
      @{ name = 'TVI' },
      @{ name = 'SharpeRatio' },
      @{ name = 'WRSI' },
      @{ name = 'NewMA' }
    ) {
      $script:pythonSkill | Should -Match $name
    }

    It 'Rust conversion maps <name>' -ForEach @(
      @{ name = 'StochRSI' },
      @{ name = 'supertrend' },
      @{ name = 'NVI' },
      @{ name = 'PVI' },
      @{ name = 'Coppo' },
      @{ name = 'LWTI' },
      @{ name = 'TVI' },
      @{ name = 'SharpeRatio' },
      @{ name = 'WRSI' },
      @{ name = 'NewMA' }
    ) {
      $script:rustSkill | Should -Match $name
    }

    It 'C++ conversion maps <name>' -ForEach @(
      @{ name = 'StochRSI' },
      @{ name = 'supertrend' },
      @{ name = 'NVI' },
      @{ name = 'PVI' },
      @{ name = 'Coppo' },
      @{ name = 'LWTI' },
      @{ name = 'TVI' },
      @{ name = 'SharpeRatio' },
      @{ name = 'WRSI' },
      @{ name = 'NewMA' }
    ) {
      $script:cppSkill | Should -Match $name
    }
  }

  Context 'conversion test files' {
    BeforeAll {
      $script:pineTest   = Get-Content "$repoRoot/tests/test_pine_new_functions.txt" -Raw
      $script:pythonTest = Get-Content "$repoRoot/tests/test_python_new_functions.txt" -Raw
      $script:rustTest   = Get-Content "$repoRoot/tests/test_rust_new_functions.txt" -Raw
      $script:cppTest    = Get-Content "$repoRoot/tests/test_cpp_new_functions.txt" -Raw
    }

    It 'Pine test references <name>' -ForEach @(
      @{ name = 'StochRSI' },
      @{ name = 'supertrend' },
      @{ name = 'NVI' },
      @{ name = 'PVI' },
      @{ name = 'Coppo' },
      @{ name = 'LWTI' },
      @{ name = 'TVI' },
      @{ name = 'SharpeRatio' },
      @{ name = 'WRSI' },
      @{ name = 'NewMA' }
    ) {
      $script:pineTest | Should -Match $name
    }

    It 'Python test references <name>' -ForEach @(
      @{ name = 'StochRSI';    pattern = 'stochrsi' },
      @{ name = 'supertrend';  pattern = 'supertrend' },
      @{ name = 'NVI';         pattern = 'NVI' },
      @{ name = 'PVI';         pattern = 'PVI' },
      @{ name = 'Coppo';       pattern = 'Coppo' },
      @{ name = 'LWTI';        pattern = 'LWTI' },
      @{ name = 'TVI';         pattern = 'TVI' },
      @{ name = 'SharpeRatio'; pattern = 'SharpeRatio' },
      @{ name = 'WRSI';        pattern = 'WRSI' },
      @{ name = 'NewMA';       pattern = 'NewMA' }
    ) {
      $script:pythonTest | Should -Match $pattern
    }

    It 'Rust test references <name>' -ForEach @(
      @{ name = 'StochRSI' },
      @{ name = 'supertrend' },
      @{ name = 'NVI' },
      @{ name = 'PVI' },
      @{ name = 'Coppo' },
      @{ name = 'LWTI' },
      @{ name = 'TVI' },
      @{ name = 'SharpeRatio' },
      @{ name = 'WRSI' },
      @{ name = 'NewMA' }
    ) {
      $script:rustTest | Should -Match $name
    }

    It 'C++ test references <name>' -ForEach @(
      @{ name = 'StochRSI' },
      @{ name = 'supertrend' },
      @{ name = 'NVI' },
      @{ name = 'PVI' },
      @{ name = 'Coppo' },
      @{ name = 'LWTI' },
      @{ name = 'TVI' },
      @{ name = 'SharpeRatio' },
      @{ name = 'WRSI' },
      @{ name = 'NewMA' }
    ) {
      $script:cppTest | Should -Match $name
    }
  }

  Context 'README documentation' {
    BeforeAll {
      $script:readme = Get-Content "$repoRoot/README.md" -Raw
    }

    It 'README lists <name> in the custom functions table' -ForEach @(
      @{ name = 'StochRSI' },
      @{ name = 'supertrend' },
      @{ name = 'NVI' },
      @{ name = 'PVI' },
      @{ name = 'Coppo' },
      @{ name = 'LWTI' },
      @{ name = 'TVI' },
      @{ name = 'SharpeRatio' },
      @{ name = 'WRSI' },
      @{ name = 'NewMA' }
    ) {
      $script:readme | Should -Match $name
    }

    It 'README reports 160 functions' {
      $script:readme | Should -Match '160 functions'
    }
  }
}
