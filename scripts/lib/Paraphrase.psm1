function Get-ParaphrasedDescription {
  [CmdletBinding()]
  param([Parameter(Mandatory)][string] $SourceText)

  if ([string]::IsNullOrWhiteSpace($SourceText) -or $SourceText.Length -lt 8) {
    throw "Get-ParaphrasedDescription: input too short ('$SourceText')"
  }

  $t = $SourceText.Trim()
  $orig = $t

  # Ordered rule-based rewrites for stock MCT phrasings.
  $rules = @(
    @{ From = '^Enters a long position as specified by the parameters\.?$';       To = 'Opens a long position with the size and timing given by the parameters.' }
    @{ From = '^Enters a short position as specified by the parameters\.?$';      To = 'Opens a short position with the size and timing given by the parameters.' }
    @{ From = '^Closes? (an? )?long position as specified.*$';                    To = 'Exits the current long position per the parameters.' }
    @{ From = '^Closes? (an? )?short position as specified.*$';                   To = 'Exits the current short position per the parameters.' }
    @{ From = '^Completely or partially exits one or all of the long entries as specified by the parameters\.?$'; To = 'Closes part or all of any open long entries per the given parameters.' }
    @{ From = '^Completely or partially exits.*long.*$';                          To = 'Closes part or all of any open long entries per the given parameters.' }
    @{ From = '^Completely or partially exits.*short.*$';                         To = 'Closes part or all of any open short entries per the given parameters.' }
    @{ From = '^Returns the (.+?) of (.+?)\.?$';                                  To = 'Yields the $1 of $2.' }
    @{ From = '^Calculates the (.+?)\.?$';                                        To = 'Computes the $1.' }
    @{ From = '^Used in (.+?)\.?$';                                               To = 'Appears inside $1.' }
    @{ From = '^Used for (.+?)\.?$';                                              To = 'Helps when $1.' }
    @{ From = '^Specifies (.+?)\.?$';                                             To = 'Sets $1.' }
    @{ From = '^Generates? (.+?)\.?$';                                            To = 'Produces $1.' }
    @{ From = '^The (.+?) function returns (.+?)\.?$';                            To = 'Returns $2 (function: $1).' }
  )

  $changed = $false
  foreach ($rule in $rules) {
    if ($t -match $rule.From) {
      $t = [regex]::Replace($t, $rule.From, $rule.To)
      $changed = $true
      break
    }
  }

  if (-not $changed) {
    if ($t.Length -lt 20) {
      throw "Get-ParaphrasedDescription: text too short for safe paraphrase: '$SourceText'"
    }
    $t = $t -replace '\bReturns\b','Provides'
    $t = $t -replace '\bPerforms\b','Invokes'
    $t = $t -replace '\bExecutes\b','Runs'
    $t = $t -replace '\bAllows\b','Enables'
    if ($t -eq $orig) {
      throw "Get-ParaphrasedDescription: could not safely paraphrase: '$SourceText'"
    }
  }

  # Final defense: no 9-consecutive-word verbatim run remains (aligned with
  # Test-VerbatimLint's default MinRunLength of 9).
  # Edge case: source too short for the 9-word window check.
  # Require the paraphrase to not literally contain the whole source.
  # NOTE: use IndexOf, NOT -like — CHM text contains [ ] ? * which are
  # wildcard metacharacters and would throw WildcardPatternException.
  $origWords = $orig -split '\s+'
  if ($origWords.Count -lt 9) {
    $normOrig = ($orig -replace '\s+', ' ').Trim()
    $normNew  = ($t    -replace '\s+', ' ').Trim()
    if ($normNew.IndexOf($normOrig, [StringComparison]::OrdinalIgnoreCase) -ge 0) {
      throw "Get-ParaphrasedDescription: source too short and paraphrase still contains the entire source verbatim: '$SourceText'"
    }
  }

  # 9-word sliding-window check follows ...
  for ($i = 0; $i -le ($origWords.Count - 9); $i++) {
    $window = ($origWords[$i..($i+8)] -join ' ')
    if ($t.IndexOf($window, [StringComparison]::OrdinalIgnoreCase) -ge 0) {
      throw "Get-ParaphrasedDescription: 9-word verbatim run remains: '$window' (from: '$SourceText')"
    }
  }

  return $t
}

function Get-CleanedParamDescription {
  [CmdletBinding()]
  param([string] $RawDesc)

  # Strip CHM boilerplate prefixes that the detail writer already encodes
  # separately via *(optional)*/*(required)*.
  $cleaned = $RawDesc
  $cleaned = $cleaned -replace '^\s*an\s+optional\s+parameter\s*;\s*',''
  $cleaned = $cleaned -replace '^\s*a\s+required\s+parameter\s*;\s*',''
  $cleaned = $cleaned -replace '^\s*an?\s+optional\s+parameter\.\s*',''
  $cleaned = $cleaned -replace '^\s*a\s+required\s+parameter\.\s*',''
  $cleaned = $cleaned.Trim()

  # Try the rule-based paraphraser first.
  try {
    return Get-ParaphrasedDescription $cleaned
  } catch {
    # Paraphraser couldn't safely rewrite this one. Fall back to a short, original
    # placeholder pointing the user at the wiki for full details.
    # Take the first <= 6 words (under the 9-word lint threshold) and append a citation.
    # Em-dash built from its code point: a literal U+2014 here is mangled by
    # PowerShell 5.1's ANSI fallback when this file has no BOM.
    $words = $cleaned -split '\s+'
    $first = ($words | Select-Object -First 6) -join ' '
    return "$first $([char]0x2014) see official docs"
  }
}

Export-ModuleMember -Function Get-ParaphrasedDescription, Get-CleanedParamDescription
