BeforeAll {
  $repoRoot = (Resolve-Path "$PSScriptRoot/../..").Path
  Import-Module "$repoRoot/scripts/lib/Test-Frontmatter.psm1" -Force
  $script:tmpDir = "$repoRoot/scripts/.cache/test-frontmatter-fixtures"

  function script:Write-Fixture {
    param([string] $FolderName, [string] $Content)
    $dir = Join-Path $script:tmpDir $FolderName
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
    $path = Join-Path $dir 'SKILL.md'
    Set-Content -Path $path -Value $Content -Encoding UTF8
    return $path
  }
}

AfterAll {
  Remove-Item $script:tmpDir -Recurse -Force -ErrorAction SilentlyContinue
}

Describe 'SKILL.md frontmatter' {

  BeforeEach {
    Remove-Item $script:tmpDir -Recurse -Force -ErrorAction SilentlyContinue
    New-Item -ItemType Directory -Path $script:tmpDir -Force | Out-Null
  }

  Context 'happy path against real skill files' {
    It 'multicharts-fundamentals has valid frontmatter' {
      $r = Test-SkillFrontmatter "$repoRoot/skills/multicharts-fundamentals/SKILL.md"
      $r.Valid | Should -BeTrue -Because $r.Reason
      $r.Name  | Should -Be 'multicharts-fundamentals'
    }
    It 'powerlanguage-syntax has valid frontmatter' {
      $r = Test-SkillFrontmatter "$repoRoot/skills/powerlanguage-syntax/SKILL.md"
      $r.Valid | Should -BeTrue -Because $r.Reason
      $r.Name  | Should -Be 'powerlanguage-syntax'
    }
    It 'powerlanguage-keywords-reference has valid frontmatter' {
      $r = Test-SkillFrontmatter "$repoRoot/skills/powerlanguage-keywords-reference/SKILL.md"
      $r.Valid | Should -BeTrue -Because $r.Reason
      $r.Name  | Should -Be 'powerlanguage-keywords-reference'
    }
    It 'powerlanguage-python-conversion has valid frontmatter' {
      $r = Test-SkillFrontmatter "$repoRoot/skills/powerlanguage-python-conversion/SKILL.md"
      $r.Valid | Should -BeTrue -Because $r.Reason
      $r.Name  | Should -Be 'powerlanguage-python-conversion'
    }
  }

  Context 'negative cases (synthetic fixtures)' {
    It 'fails when frontmatter delimiters are missing' {
      $p = Write-Fixture 'no-delims' @"
# Just a heading

No frontmatter here.
"@
      $r = Test-SkillFrontmatter $p
      $r.Valid | Should -BeFalse
      $r.Reason | Should -Match 'frontmatter'
    }

    It 'fails when name field is missing' {
      $p = Write-Fixture 'no-name' @"
---
description: Use when testing this fixture.
---

Body.
"@
      $r = Test-SkillFrontmatter $p
      $r.Valid | Should -BeFalse
      $r.Reason | Should -Match 'name'
    }

    It 'fails when description field is missing' {
      $p = Write-Fixture 'no-desc' @"
---
name: no-desc
---

Body.
"@
      $r = Test-SkillFrontmatter $p
      $r.Valid | Should -BeFalse
      $r.Reason | Should -Match 'description'
    }

    It 'fails when description does not start with Use when' {
      $p = Write-Fixture 'bad-desc' @"
---
name: bad-desc
description: Triggers when working with the doodad.
---

Body.
"@
      $r = Test-SkillFrontmatter $p
      $r.Valid | Should -BeFalse
      $r.Reason | Should -Match 'Use when'
    }

    It 'fails when name does not match the parent folder' {
      $p = Write-Fixture 'folder-name' @"
---
name: different-name
description: Use when testing folder name mismatch.
---

Body.
"@
      $r = Test-SkillFrontmatter $p
      $r.Valid | Should -BeFalse
      $r.Reason | Should -Match 'folder'
    }

    It 'IGNORES horizontal-rule --- in the body (does not treat as frontmatter close)' {
      $p = Write-Fixture 'body-hr' @"
---
name: body-hr
description: Use when verifying body horizontal rules don't confuse the parser.
---

# Heading

First paragraph.

---

Second paragraph below an HR.
"@
      $r = Test-SkillFrontmatter $p
      $r.Valid | Should -BeTrue -Because $r.Reason
      # The description must be the YAML one, not anything after the body HR
      $r.Description | Should -Match 'verifying body horizontal rules'
    }
  }

  Context 'powerlanguage-keywords-reference scaffolding' {
    It 'has all 40 category folders' {
      $expected = @(
        'AccountsPositions','Alerts','Arrow_Drawing','Attributes','Colors',
        'Comparison_and_Loops','Currency_Codes','Data_Information_General',
        'Date_and_Time_routines','Declaration','DLL_Calling','DOM','Dynamic_Arrays',
        'Environment_Information','Execution_Control','ExpertCommentary',
        'Math_and_Trig','Miscellaneous_keywords','MouseClickEvents','Multimedia',
        'Output','Plotting','Portfolio_Money_Management',
        'Portfolio_Strategy_Performance','Portfolio_Strategy_Position',
        'Portfolio_Strategy_Properties','Quote_Fields','Rectangle_Drawing',
        'Sessions','Skip_Words','Strategy_Events','Strategy_Orders',
        'Strategy_Performance','Strategy_Position',
        'Strategy_Position_Synchronization','Strategy_Position_Trades',
        'Strategy_Properties','Text_Drawing','Text_Manipulation','Trendline_Drawing'
      )
      $detailsRoot = "$repoRoot/skills/powerlanguage-keywords-reference/details"
      $actual = Get-ChildItem $detailsRoot -Directory | Select-Object -Expand Name | Sort-Object
      ($expected | Sort-Object) -join ',' | Should -Be ($actual -join ',')
    }
  }
}
