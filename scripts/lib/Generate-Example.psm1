# Generate-Example.psm1 — category-aware illustrative example generation.
#
# Public surface:
#   New-KeywordExample       -Parsed <hashtable>           (orchestrator entry point)
#   Get-CategoryAwareExample -Name -Category [-Usage] [-Parameters]
#                                                           (bulk-fix entry point;
#                                                            thin wrapper over New-KeywordExample)
#   Test-StringReturningKeyword -Name                       (shared taxonomy, also used
#                                                            by Build-PlaFixtures.psm1)
#
# Rules (in priority order) — the goal is to NEVER emit `Value1 = <Keyword>;`
# for a keyword that cannot appear as a numeric RHS value:
#   1. Skip_Words / multi-word names / connector words / reserved tokens
#                                                     -> comment-only
#   2. DLL_Calling C-type names                       -> comment-only
#   3. Attributes category                            -> [<Keyword> = true];
#   4. Alert                                          -> Alert("message");
#   5. Output category                                -> statement form (Print/File*/Clear*)
#   6. #-prefixed directives                          -> comment-only
#   7. Known special categories (Strategy_Orders, Plotting, Colors,
#      Math_and_Trig, Date_and_Time_routines, Sessions, Declaration,
#      Comparison_and_Loops)                          -> existing tailored forms
#   8. Other non-RHS categories                       -> comment-only
#   9. Signature shows required parameters            -> placeholder call + comment
#  10. Zero-arg boolean-returning keyword             -> If <Keyword> Then ... example
#  11. Zero-arg string-returning keyword              -> string variable example
#  12. Zero-arg value-returning keyword               -> Value1 = <Keyword>;

# --- Shared taxonomy: string-returning keywords -------------------------------
# Curated list + name heuristic. Build-PlaFixtures.psm1 imports this module and
# reuses Test-StringReturningKeyword so the two stay in sync.
$script:StringReturningNames = @(
  'Description','ExchListed','Symbol','SymbolName','SymbolRoot',
  'RTSymbol','RTSymbolName','GetSymbolName','GetExchangeName',
  'GetRTSymbolName','TradeDate','SymbolCurrencyCode',
  'q_ExchangeListed','q_Description',
  # Environment-info string returners
  'GetCurrency','GetCountry','GetCDRomDrive','GetUserName','GetAppInfo',
  # Other string-returning names
  'BarType_uid','BarType','BarType_ex',
  # Account info string returners
  'GetAccountID','GetAccount','GetPositionBrokerSymbol',
  # PMM named-value string returners
  'pmm_get_global_named_str','pmm_get_my_named_str',
  'pmms_get_strategy_named_str','pmms_strategies_get_by_symbol_name'
)

function Test-StringReturningKeyword {
  [CmdletBinding()]
  param([Parameter(Mandatory)][string] $Name)

  $looksLikeString = $Name -match '(?i)(Name|Description|Symbol|Listed|Exchange|Root|ToStr|ToString|ToString_Ms|CodeToStr|DateStr|TimeStr)$' -or
                     $Name -match '^(?i)Format(Time|Date|DateTime)'
  return (($script:StringReturningNames -contains $Name) -or $looksLikeString)
}

# Boolean (true/false) returning keywords: true/false cannot be assigned to the
# numeric Value1 series. Curated names + name heuristics.
$script:BooleanReturningNames = @('AlertEnabled','CheckAlert')

function Test-BooleanReturningKeyword {
  [CmdletBinding()]
  param([Parameter(Mandatory)][string] $Name)

  return (($script:BooleanReturningNames -contains $Name) -or
          $Name -match '(?i)(Pressed|Enabled)$' -or
          $Name -cmatch '^(Is|Has|Can)[A-Z]')
}

# Connector words: only meaningful inside other statements (e.g. "1 Bar Ago",
# "Buy Next Bar at Market"). Several have CHM pages of their own (mostly under
# Data_Information_General) but still cannot stand alone as RHS values.
$script:ConnectorWords = @(
  'Ago','Bar','Bars','Day','Days','Point','Points','Tick','Ticks',
  'Next','This','Today','Yesterday'
)

# Reserved tokens: only valid inside specific statements (data-series references,
# option-position keywords, chart-resolution settings); never standalone RHS values.
$script:ReservedTokens = @(
  'Data','Call','Put','Strike','Length','OptionType','DeltaType','RevSize','BoxSize'
)

# DLL_Calling C-type names: appear only inside DefineDLLFunc/External declarations.
$script:DllCTypeNames = @('Void','WORD','Long','LPBool','LPByte','VarSize','VarStartAddr')

# Categories whose members are language constructs / statements, never numeric
# RHS values (mirrors the taxonomy in Build-PlaFixtures.psm1).
$script:NonRhsCategories = @(
  'Declaration','Comparison_and_Loops','Attributes','ExpertCommentary',
  'DLL_Calling','Output','Multimedia','Miscellaneous_keywords',
  'Execution_Control','Text_Manipulation'
)

# Extract parameter names from a Usage/Signature string.
# Strips [Data(N)] decorations and optional [...] groups first, so a keyword
# whose every parameter is optional is treated as callable with zero args.
function Get-SignatureParamNames {
  param([string] $Usage)

  if ([string]::IsNullOrWhiteSpace($Usage)) { return @() }
  $clean = $Usage -replace '\[\s*Data\s*\(\s*[^)]*\s*\)\s*\]', ''   # [Data(N)] series refs
  $clean = $clean -replace '\[[^\[\]]*\]', ''                        # optional [...] groups
  if ($clean -notmatch '\(([^()]*)\)') { return @() }
  $inner = $Matches[1].Trim()
  if ([string]::IsNullOrEmpty($inner)) { return @() }
  return @($inner -split ',' | ForEach-Object { $_.Trim() })
}

function New-KeywordExample {
  [CmdletBinding()]
  param([Parameter(Mandatory)][hashtable] $Parsed)

  $name   = $Parsed.Name
  $cat    = $Parsed.Category
  $usage  = if ($Parsed.Usage) { [string]$Parsed.Usage } else { '' }
  # @(...) keeps a single-parameter list an array — a bare `if` expression
  # unrolls one-element arrays to a scalar hashtable, breaking $params.Count.
  $params = @(if ($Parsed.Parameters) { $Parsed.Parameters } else { @() })

  # 1. Skip words, multi-word names, connector words, reserved tokens:
  # used within other constructs only — never standalone RHS values.
  if ($cat -eq 'Skip_Words') {
    return "// $name is used within other statements; not a standalone value. See the Usage line above."
  }
  if ($name -match '\s') {
    # Multi-word names ("Cancel Alert"): the compiler reads the first token only,
    # so the full name can never appear as an RHS value.
    return "// $name is a multi-word statement keyword; see the Usage line above for how it is used."
  }
  if ($script:ConnectorWords -contains $name) {
    return "// $name is a connector word used within other statements (e.g. 1 Bar Ago, Buy Next Bar at Market); not a standalone value."
  }
  if ($script:ReservedTokens -contains $name) {
    return "// $name is a reserved word used only within specific statements; not a standalone value. See the Usage line above."
  }

  # 2. DLL_Calling C-type names: only valid inside DLL declarations.
  if ($cat -eq 'DLL_Calling' -and ($script:DllCTypeNames -contains $name)) {
    return "// $name is a C-type name used within DefineDLLFunc/External declarations; not a standalone value."
  }

  # 3. Attributes: script-level attribute syntax.
  if ($cat -eq 'Attributes') {
    return "[$name = true];"
  }

  # 4. Alert: statement-shaped even though CHM reports zero parameters.
  if ($name -eq 'Alert') {
    return 'Alert("message");'
  }

  # 5. Output category: statement forms, never RHS values.
  if ($cat -eq 'Output') {
    switch ($name) {
      'Print'         { return 'Print("text");' }
      'FileAppend'    { return 'FileAppend("C:\out.txt", "text");' }
      'FileDelete'    { return 'FileDelete("C:\out.txt");' }
      'File'          { return 'Print(File("C:\out.txt"), "text");' }
      'ClearDebug'    { return "$name;" }
      'ClearPrintLog' { return "$name;" }
    }
    $sigNames = Get-SignatureParamNames $usage
    if ($sigNames.Count -eq 0) { return "$name;" }
    return "// $name is an output statement; see the Usage line above for the call form."
  }

  # 6. Preprocessor-style directives cannot appear as values.
  if ($name -like '#*') {
    return "// $name is a compiler directive (#-prefixed); see the Usage line above."
  }

  switch ($cat) {
    'Strategy_Orders' {
      if ($name -in @('Buy','Sell','SellShort','BuyToCover')) {
        return "$name ( ""${name}_Demo"" ) 1 Contract Next Bar at Market;"
      }
      if ($name -eq 'All')      { return 'Sell All Contracts Next Bar at Market;' }
      if ($name -eq 'Market')   { return 'Buy ( "Demo" ) 1 Contract Next Bar at Market;' }
      if ($name -eq 'Limit')    { return 'Buy ( "Demo" ) 1 Contract Next Bar at 100 Limit;' }
      if ($name -eq 'Stop')     { return 'Buy ( "Demo" ) 1 Contract Next Bar at 100 Stop;' }
      if ($name -in @('Contract','Contracts'))  { return 'Buy ( "Demo" ) 2 Contracts Next Bar at Market;' }
      if ($name -in @('Share','Shares'))         { return 'Buy ( "Demo" ) 100 Shares Next Bar at Market;' }
      if ($name -eq 'SetStopLoss') { return 'SetStopLoss( 50 );' }
      return "// $name -- see Usage line above"
    }
    'Math_and_Trig' {
      if ($params.Count -eq 0)                           { return "Value1 = $name;" }
      if ($params.Count -eq 1 -and $params[0].Type -eq 'numeric') { return "Value1 = $name( Close );" }
      return "Value1 = $name( Close, 14 );"
    }
    'Plotting' {
      if ($name -match '^Plot\d') { return "$name( Close, ""$name demo"" );" }
      return "// $name -- see Usage line above"
    }
    'Date_and_Time_routines' {
      if ($params.Count -eq 0) { return "Value1 = $name;" }
      return "Value1 = $name( Date );"
    }
    'Declaration' {
      return "// $name appears in declarations, e.g. Inputs: x( 0 ); Variables: y( 0 );"
    }
    'Comparison_and_Loops' {
      return "// $name is used in expressions, e.g. If Close > Open Then ... ;"
    }
    'Colors' {
      return "Plot1( Close ); SetPlotColor( 1, $name );"
    }
    'Sessions' {
      if ($params.Count -eq 0) { return "Value1 = $name;" }
      return "Value1 = $name( Date );"
    }
    default {
      # Remaining non-RHS categories (ExpertCommentary, Multimedia, Execution_Control,
      # Text_Manipulation, Miscellaneous_keywords, DLL_Calling non-C-types, ...):
      # never emit Value1 = <Keyword>; — point at the Usage line instead.
      if ($script:NonRhsCategories -contains $cat) {
        return "// $name is a language construct ($cat); see the Usage line above for how it is used."
      }

      # 9. Signature shows required parameters: emit a placeholder call annotated
      # as such — never `Value1 = <Keyword>;`. If the signature is too complex to
      # extract clean identifiers from, fall back to a comment pointing at Usage.
      $sigNames = Get-SignatureParamNames $usage
      if ($sigNames.Count -eq 0 -and $params.Count -gt 0) {
        $sigNames = @($params | ForEach-Object { $_.Name })
      }
      if ($sigNames.Count -gt 0) {
        $allClean = $true
        foreach ($pn in $sigNames) {
          if ($pn -notmatch '^[A-Za-z_][A-Za-z0-9_]*$') { $allClean = $false; break }
        }
        if ($allClean) {
          return "$name( $($sigNames -join ', ') );  // parameter names are placeholders -- replace with real values (see the Usage line above)"
        }
        return "// $name takes parameters; see the Usage line above for the call form."
      }

      # 10. Zero-arg boolean-returning keywords: true/false cannot be assigned
      # to the numeric Value1 series — show the keyword inside a condition.
      if (Test-BooleanReturningKeyword -Name $name) {
        return "If $name Then Begin`r`n`tValue1 = 1;`r`nEnd;  // $name returns true/false"
      }

      # 11. Zero-arg string-returning keywords: Value1 is numeric, so assign to
      # a string variable instead (same taxonomy as Build-PlaFixtures).
      if (Test-StringReturningKeyword -Name $name) {
        return "Variables: str_val("""");`r`nstr_val = $name;  // $name returns a string"
      }

      # 12. Zero-arg value-returning keyword.
      return "Value1 = $name;"
    }
  }
}

function Get-CategoryAwareExample {
  <#
  .SYNOPSIS
    Bulk-fix entry point: build a category-aware example from the fields a
    detail .md already carries (name, category, signature), without needing
    the parsed CHM hashtable.
  .PARAMETER Name
    Keyword name (the detail file's H1 / basename).
  .PARAMETER Category
    CHM category (the detail file's **Category:** line / folder name).
  .PARAMETER Usage
    Signature string (the detail file's **Signature:** line). Optional.
  .PARAMETER Parameters
    Optional array of hashtables @{ Name; Type; Required; Description } if the
    caller parsed the **Parameters** bullet list. Used as a fallback source of
    parameter names when the Usage string has no parseable parens.
  #>
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)][string] $Name,
    [Parameter(Mandatory)][string] $Category,
    [string]   $Usage = '',
    [object[]] $Parameters = @()
  )

  return New-KeywordExample -Parsed @{
    Name       = $Name
    Category   = $Category
    Usage      = $Usage
    Parameters = $Parameters
  }
}

Export-ModuleMember -Function New-KeywordExample, Get-CategoryAwareExample, Test-StringReturningKeyword, Test-BooleanReturningKeyword, Get-SignatureParamNames
