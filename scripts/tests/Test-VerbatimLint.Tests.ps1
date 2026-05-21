BeforeAll {
  $repoRoot = (Resolve-Path "$PSScriptRoot/../..").Path
  Import-Module "$repoRoot/scripts/lib/Test-VerbatimLint.psm1" -Force
}

Describe 'Test-VerbatimLint' {
  It 'returns $false for clean paraphrased content' {
    $md = @"
# Buy

**Category:** Strategy_Orders
**Signature:** ``Buy ;``

Opens a long position with the size and timing given by the parameters.
"@
    $htm = '<H1>Buy</H1><td class="DIVtdN">Enters a long position as specified by the parameters.</td>'
    Test-VerbatimLint -MarkdownText $md -SourceHtmlText $htm | Should -BeFalse
  }

  It 'returns $true when a 10-word verbatim run leaks through' {
    $md = @"
# Buy

Enters a long position as specified by the parameters today.
"@
    $htm = '<H1>Buy</H1><td>Enters a long position as specified by the parameters.</td>'
    Test-VerbatimLint -MarkdownText $md -SourceHtmlText $htm | Should -BeTrue
  }

  It 'treats short runs (under 10 words) as fine' {
    $md = @"
# Buy

A long position is opened.
"@
    $htm = '<H1>Buy</H1><td>A long position is opened.</td>'
    Test-VerbatimLint -MarkdownText $md -SourceHtmlText $htm | Should -BeFalse
  }

  It 'is case-insensitive' {
    $md = 'Enters a long position as specified by the parameters today.'
    $htm = 'enters a LONG position as specified by the parameters elsewhere.'
    Test-VerbatimLint -MarkdownText $md -SourceHtmlText $htm | Should -BeTrue
  }

  It 'strips HTML tags from the source before comparing' {
    $md = 'Enters a long position as specified by the parameters in your script.'
    $htm = '<P>Enters <code>a</code> long <i>position</i> as specified by the parameters.</P>'
    Test-VerbatimLint -MarkdownText $md -SourceHtmlText $htm | Should -BeTrue
  }

  It 'normalizes whitespace before comparing (collapsed spaces, newlines)' {
    $md = 'Enters a long  position  as  specified by the   parameters today.'
    $htm = '<P>Enters   a   long   position   as   specified   by   the   parameters.</P>'
    # Both normalize to the same 9 consecutive words after normalization
    Test-VerbatimLint -MarkdownText $md -SourceHtmlText $htm | Should -BeTrue
  }

  It 'respects an explicit -MinRunLength override' {
    # 9 shared words; with default threshold 9 → violation; with 10 → clean
    $md = 'Enters a long position as specified by the parameters today.'
    $htm = 'enters a LONG position as specified by the parameters elsewhere.'
    Test-VerbatimLint -MarkdownText $md -SourceHtmlText $htm                       | Should -BeTrue
    Test-VerbatimLint -MarkdownText $md -SourceHtmlText $htm -MinRunLength 10      | Should -BeFalse
  }
}
