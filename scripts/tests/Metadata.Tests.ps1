BeforeAll {
  $repoRoot = (Resolve-Path "$PSScriptRoot/../..").Path
}

Describe 'Plugin metadata files' {
  It 'plugin.json parses as valid JSON and has expected fields' {
    $p = Get-Content "$repoRoot/.claude-plugin/plugin.json" -Raw | ConvertFrom-Json
    $p.name        | Should -Be 'multicharts-powerlanguage'
    $p.version     | Should -Be '0.1.0'
    $p.license     | Should -Be 'MIT'
    $p.author.name | Should -Be 'Yu-An Chen'
    $p.homepage    | Should -Match 'github.com/KasperChenGH/multicharts-powerlanguage'
    $p.keywords    | Should -Contain 'multicharts'
  }

  It 'marketplace.json parses as valid JSON and lists our plugin' {
    $m = Get-Content "$repoRoot/.claude-plugin/marketplace.json" -Raw | ConvertFrom-Json
    $m.name                 | Should -Be 'multicharts-powerlanguage-dev'
    $m.plugins.Count        | Should -Be 1
    $m.plugins[0].name      | Should -Be 'multicharts-powerlanguage'
    $m.plugins[0].source    | Should -Be './'
  }

  It 'package.json parses as valid JSON' {
    $j = Get-Content "$repoRoot/package.json" -Raw | ConvertFrom-Json
    $j.name    | Should -Be 'multicharts-powerlanguage'
    $j.version | Should -Be '0.1.0'
  }

  It 'all three files declare the same version' {
    $p = (Get-Content "$repoRoot/.claude-plugin/plugin.json"      -Raw | ConvertFrom-Json).version
    $m = (Get-Content "$repoRoot/.claude-plugin/marketplace.json" -Raw | ConvertFrom-Json).plugins[0].version
    $k = (Get-Content "$repoRoot/package.json"                    -Raw | ConvertFrom-Json).version
    $p | Should -Be $m
    $p | Should -Be $k
  }
}
