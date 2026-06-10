# Decode the HTML entities that actually occur in the CHM corpus.
# Called AFTER tag stripping so decoded < / > cannot be mistaken for tags.
# &amp; is decoded LAST so double-encoded entities aren't over-decoded.
function ConvertFrom-HtmlEntity {
  param([string] $Text)
  $t = $Text
  $t = $t -replace '&nbsp;',  ' '
  $t = $t -replace '&quot;',  '"'
  $t = $t -replace '&lt;',    '<'
  $t = $t -replace '&gt;',    '>'
  $t = $t -replace '&#0*60;', '<'
  $t = $t -replace '&#0*62;', '>'
  $t = $t -replace '&#8211;', ([char]0x2013)   # en dash
  $t = $t -replace '&#8212;', ([char]0x2014)   # em dash
  $t = $t -replace '&amp;',   '&'
  return $t
}

function Parse-ChmFile {
  [CmdletBinding()]
  param([Parameter(Mandatory)][string] $Path)

  if (-not (Test-Path $Path)) { throw "Not found: $Path" }
  # -Encoding UTF8: PS 5.1 otherwise reads BOM-less files as ANSI.
  $raw = Get-Content $Path -Raw -Encoding UTF8

  # Category = parent folder
  $category = Split-Path -Leaf (Split-Path $Path -Parent)

  # Name from <H1>...</H1> — be tolerant of whitespace and case
  $name = if ($raw -match '(?i)<H1>\s*([^<]+?)\s*</H1>') { $Matches[1].Trim() } else { $null }
  if (-not $name) { throw "Could not parse keyword name from $Path" }

  # Description: text inside DIVtdN cell, first sentence
  # The cell opens with <td class="DIVtdN"> and closes with </td>
  $descBlock = if ($raw -match '(?si)<td class="DIVtdN">\s*(.+?)</td>') { $Matches[1] } else { '' }
  $descPlain = ((ConvertFrom-HtmlEntity ($descBlock -replace '<[^>]+>', '')) -replace '\s+', ' ').Trim()
  # First sentence. The terminating [.!?] must not be the trailing period of a
  # common abbreviation (e.g. / i.e. / etc. / vs. / cf.). A decimal point can
  # never terminate the match anyway because (\s|$) requires whitespace/end
  # right after the punctuation, and a decimal's period is followed by a digit.
  $sentenceRe = '(?i)^(.+?(?<!\be\.g)(?<!\bi\.e)(?<!\betc)(?<!\bvs)(?<!\bcf)[.!?])(\s|$)'
  $firstSent = if ($descPlain -match $sentenceRe) { $Matches[1].Trim() } else { $descPlain }

  # Usage: text inside DIVtdU cell, the line(s) after <B>Usage</B><p>
  # Structure: <td class="DIVtdU"><B>Usage</B><p><code>...NESTED code tags...</code>\n<p>optional note
  # We capture everything after <B>Usage</B><p> up to the first plain <p> or </td>
  # then strip all HTML tags to get the signature text.
  $usageRaw = if ($raw -match '(?si)<td class="DIVtdU">.*?<B>Usage</B>\s*<p>\s*(.+?)\s*(?:<p>|</td>)') {
    $Matches[1]
  } else { '' }
  $usage = ((ConvertFrom-HtmlEntity ($usageRaw -replace '<[^>]+>', '')) -replace '\s+', ' ').Trim()

  # Parameters block — inside <div class="param"> within a notepl0 section
  # Each parameter boundary is a <code[...]><i>Name</i></code> - pattern.
  # We split the block at those boundaries so each parameter's description
  # spans from the end of its boundary to the start of the next boundary,
  # capturing multi-paragraph descriptions correctly.
  $params = @()
  if ($raw -match '(?s)<b>Parameters</b>.*?<div class="param">(.+?)</div>') {
    $paramBlock = $Matches[1]

    # A boundary is <code...><i>Name</i></code> - at the start of each parameter entry
    $boundaryRe = [regex]'(?i)<code[^>]*>\s*<i>([A-Za-z_][A-Za-z0-9_]*)</i>\s*</code>\s*-'

    $boundaryMatches = $boundaryRe.Matches($paramBlock)
    for ($i = 0; $i -lt $boundaryMatches.Count; $i++) {
      $pname = $boundaryMatches[$i].Groups[1].Value

      # Description spans from end of this boundary to start of next boundary (or end of block)
      $start = $boundaryMatches[$i].Index + $boundaryMatches[$i].Length
      $end   = if ($i + 1 -lt $boundaryMatches.Count) { $boundaryMatches[$i + 1].Index } else { $paramBlock.Length }
      $rawDesc = $paramBlock.Substring($start, $end - $start)

      # Strip HTML tags, decode entities, collapse whitespace
      $pdesc = ((ConvertFrom-HtmlEntity ($rawDesc -replace '<[^>]+>', ' ')) -replace '\s+', ' ').Trim()

      $required = if ($pdesc -match '(?i)optional') { $false } else { $true }
      $ptype = if ($pdesc -match '(?i)numerical|numeric')      { 'numeric' }
               elseif ($pdesc -match '(?i)string|name')        { 'string' }
               elseif ($pdesc -match '(?i)true.*false')        { 'truefalse' }
               else                                            { 'expression' }
      $params += @{ Name = $pname; Type = $ptype; Required = $required; Description = $pdesc }
    }
  }

  # Source example block (captured to allow non-copy checks; never written to disk)
  # Structure: <td class="DIVtdE"><B>Example</B><p>...content...</td>
  $srcExample = if ($raw -match '(?si)<td class="DIVtdE">.*?<B>Example</B>\s*<p>\s*(.+?)</td>') {
    ((ConvertFrom-HtmlEntity ($Matches[1] -replace '<[^>]+>', '')) -replace '\s+', ' ').Trim()
  } else { '' }

  return @{
    Name               = $name
    Category           = $category
    Description        = $firstSent
    Usage              = $usage
    Parameters         = $params
    SourceExampleBlock = $srcExample
  }
}

Export-ModuleMember -Function Parse-ChmFile
