# Category -> script-type mapping. Keywords in a category emit into that script's .txt.
# Note: the output files are plain-text PowerLanguage source, NOT the .pla archive
# format (which is a binary export bundle). The maintainer PASTES the contents
# into a new Indicator/Signal/Function study in PowerLanguage Editor and verifies.
$script:CategoryScriptType = @{
  'AccountsPositions'                  = 'Indicator'
  'Alerts'                              = 'Indicator'
  'Arrow_Drawing'                       = 'Indicator'
  'Attributes'                          = 'Indicator'
  'Colors'                              = 'Indicator'
  'Comparison_and_Loops'                = 'Indicator'
  'Currency_Codes'                      = 'Indicator'
  'Data_Information_General'            = 'Indicator'
  'Date_and_Time_routines'              = 'Indicator'
  'Declaration'                         = 'Indicator'
  'DLL_Calling'                         = 'Indicator'
  'DOM'                                 = 'Indicator'
  'Dynamic_Arrays'                      = 'Indicator'
  'Environment_Information'             = 'Indicator'
  'Execution_Control'                   = 'Indicator'
  'ExpertCommentary'                    = 'Indicator'
  'Math_and_Trig'                       = 'Indicator'
  'Miscellaneous_keywords'              = 'Indicator'
  'MouseClickEvents'                    = 'Indicator'
  'Multimedia'                          = 'Indicator'
  'Output'                              = 'Indicator'
  'Plotting'                            = 'Indicator'
  'Quote_Fields'                        = 'Indicator'
  'Rectangle_Drawing'                   = 'Indicator'
  'Sessions'                            = 'Indicator'
  'Skip_Words'                          = 'Indicator'
  'Text_Drawing'                        = 'Indicator'
  'Text_Manipulation'                   = 'Indicator'
  'Trendline_Drawing'                   = 'Indicator'
  'Portfolio_Money_Management'          = 'Signal'
  'Portfolio_Strategy_Performance'      = 'Signal'
  'Portfolio_Strategy_Position'         = 'Signal'
  'Portfolio_Strategy_Properties'       = 'Signal'
  'Strategy_Events'                     = 'Signal'
  'Strategy_Orders'                     = 'Signal'
  'Strategy_Performance'                = 'Signal'
  'Strategy_Position'                   = 'Signal'
  'Strategy_Position_Synchronization'   = 'Signal'
  'Strategy_Position_Trades'            = 'Signal'
  'Strategy_Properties'                 = 'Signal'
}

function Get-KeywordStatement {
  param([Parameter(Mandatory)][hashtable] $Kw)

  $name = $Kw.Name
  $cat  = $Kw.Category
  $params = $Kw.Parameters

  # Skip-word category: emit a comment referencing the keyword without invoking it.
  if ($cat -eq 'Skip_Words') { return "// $name appears inside other constructs." }

  # Pure-syntax categories: their entries are language constructs (type names,
  # operators, control-flow keywords, script-level attributes) that cannot
  # appear as values in `Value1 = X;`. Emit a comment so the compile-test still
  # exercises the keyword name without producing a parse error.
  if ($cat -in @('Declaration','Comparison_and_Loops','Attributes','ExpertCommentary','DLL_Calling')) {
    return "// $name is a language construct ($cat); see official docs for usage."
  }

  # Preprocessor-style directive keywords (e.g. #BeginCmtry, #EndCmtry, #Return,
  # #Events) open paired blocks or special syntactic positions and cannot appear
  # as values. #BeginCmtry in particular starts a multi-line commentary block
  # that runs until #EndCmtry, which would swallow everything to EOF.
  if ($name -like '#*') {
    return "// $name is a preprocessor directive (#-prefixed); see official docs for usage."
  }

  switch ($cat) {
    'Strategy_Orders' {
      if ($name -in @('Buy','Sell','SellShort','BuyToCover')) {
        return "$name ( ""${name}_T"" ) 1 Contract Next Bar Market;"
      }
      if ($name -eq 'All')                                  { return 'Sell All Contracts Next Bar Market;' }
      if ($name -in @('Market','Limit','Stop'))             { return 'Buy ( "MLS" ) 1 Contract Next Bar Market;' }
      if ($name -in @('Contract','Contracts'))              { return 'Buy ( "C" ) 1 Contract Next Bar Market;' }
      return "// $name -- see official docs"
    }
    'Math_and_Trig' {
      if ($params.Count -eq 0)              { return "Value1 = $name;" }
      if ($params.Count -eq 1)              { return "Value1 = $name( Close );" }
      return "Value1 = $name( Close, 14 );"
    }
    'Plotting' {
      if ($name -match '^Plot\d')           { return "$name( Close );" }
      return "// $name -- see official docs"
    }
    default {
      if ($params.Count -eq 0)              { return "Value1 = $name;" }
      $argv = @()
      foreach ($p in $params | Select-Object -First 3) {
        $argv += switch ($p.Type) {
          'numeric'   { '14' }
          'string'    { '"x"' }
          'truefalse' { 'True' }
          default     { 'Close' }
        }
      }
      return "Value1 = $name( $($argv -join ', ') );"
    }
  }
}

function New-PlaFixtures {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)][object[]] $Keywords,
    [Parameter(Mandatory)][string]   $OutputDir
  )

  if (-not (Test-Path $OutputDir)) { New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null }

  # Bucket keywords by script type.
  $byType = @{ 'Indicator' = @(); 'Signal' = @(); 'Function' = @() }
  foreach ($kw in $Keywords) {
    $type = $script:CategoryScriptType[$kw.Category]
    if (-not $type) { $type = 'Indicator' }      # default safety net
    $byType[$type] += $kw
  }

  # Note: Value1..Value10000 are pre-declared built-in numeric variables in
  # PowerLanguage — no `Variables: Value1(0);` declaration is needed.
  $headerByType = @{
    'Indicator' = "{ test_indicator.txt -- exercises every keyword routed to Indicator script type }`r`n{ Paste this whole file into a new Indicator study in PowerLanguage Editor and Verify (F3). }`r`n"
    'Signal'    = "{ test_signal.txt -- exercises every keyword routed to Signal script type }`r`n{ Paste this whole file into a new Signal study in PowerLanguage Editor and Verify (F3). }`r`n"
    'Function'  = "{ test_function.txt -- function return idioms }`r`n{ Paste this whole file into a new Function in PowerLanguage Editor and Verify (F3). }`r`n"
  }

  foreach ($type in 'Indicator','Signal','Function') {
    $sb = [System.Text.StringBuilder]::new()
    [void]$sb.AppendLine($headerByType[$type])
    [void]$sb.AppendLine('If False Then Begin    { wrap every statement in an unreachable If/Then to verify syntax only }')
    foreach ($kw in $byType[$type] | Sort-Object Category, Name) {
      [void]$sb.AppendLine("    { $($kw.Category): $($kw.Name) }")
      [void]$sb.AppendLine("    $(Get-KeywordStatement -Kw $kw)")
    }
    [void]$sb.AppendLine('End;')

    $outPath = Join-Path $OutputDir "test_$($type.ToLower()).txt"
    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($outPath, $sb.ToString(), $utf8NoBom)
  }
}

Export-ModuleMember -Function New-PlaFixtures
