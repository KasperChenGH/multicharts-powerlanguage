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

  It 'returns $true when a 9-word verbatim run leaks through' {
    $md = @"
# Buy

Enters a long position as specified by the parameters today.
"@
    $htm = '<H1>Buy</H1><td>Enters a long position as specified by the parameters.</td>'
    Test-VerbatimLint -MarkdownText $md -SourceHtmlText $htm | Should -BeTrue
  }

  It 'treats short runs (under 9 words) as fine' {
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

  It 'decodes HTML entities so they cannot break a verbatim run (false-negative guard)' {
    # Without entity decoding, "&#8211;" in the source becomes the spurious
    # word "8211" and the 9-word run would be split (lint would miss the copy).
    $md  = 'Enters a long position as specified by the parameters today.'
    $htm = '<P>Enters a long &#8211; position as specified by the parameters.</P>'
    Test-VerbatimLint -MarkdownText $md -SourceHtmlText $htm | Should -BeTrue
  }

  It 'returns $false for a sub-9-word source even when copied wholesale (KNOWN LIMITATION)' {
    # Known limitation: sources shorter than MinRunLength words can never form
    # a 9-word run, so a verbatim copy of a very short description is NOT
    # flagged by this lint. The upstream guard for that case lives in
    # Get-ParaphrasedDescription (whole-source containment check for short
    # inputs). This test documents the current behavior.
    $md  = 'Returns the high of the bar.'
    $htm = '<td>Returns the high of the bar.</td>'
    Test-VerbatimLint -MarkdownText $md -SourceHtmlText $htm | Should -BeFalse
  }
}
