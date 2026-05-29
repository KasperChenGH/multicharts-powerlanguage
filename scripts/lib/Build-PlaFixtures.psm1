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
  if ($cat -in @('Declaration','Comparison_and_Loops','Attributes','ExpertCommentary','DLL_Calling','Output','Multimedia','Miscellaneous_keywords','Execution_Control','Text_Manipulation')) {
    return "// $name is a language construct ($cat); see official docs for usage."
  }

  # Preprocessor-style directive keywords (e.g. #BeginCmtry, #EndCmtry, #Return,
  # #Events) open paired blocks or special syntactic positions and cannot appear
  # as values. #BeginCmtry in particular starts a multi-line commentary block
  # that runs until #EndCmtry, which would swallow everything to EOF.
  if ($name -like '#*') {
    return "// $name is a preprocessor directive (#-prefixed); see official docs for usage."
  }

  # Specific reserved-word keywords that the parser treats as syntactic tokens
  # rather than identifiers — they appear inside compound constructs like
  # "Close of Data2", "Call Option", "Strike Price". They surface in categories
  # that otherwise contain real values (e.g. Data_Information_General), so we
  # filter by keyword name rather than category.
  $reservedTokens = @(
    'Data','Call','Put','Strike','Length','OptionType','DeltaType','RevSize','BoxSize',
    # Connector words from Data_Information_General that overlap with Miscellaneous_keywords
    'Bar','Bars','Day','Days','Point','Points','Tick','Ticks','Ago','Next','This','Today','Yesterday',
    # Single-letter data-series aliases (C=Close, D=Date, H=High, I=OpenInt, L=Low, O=Open, T=Time, V=Volume)
    'C','D','H','I','L','O','T','V',
    # Statement-shaped keywords that require '(' even when CHM reports zero
    # parameters in our parser (e.g. Alert("text");, AlertEx(...);)
    'Alert','AlertEx',
    # Portfolio attribute directives (used in [Attr = N] form, not as values)
    'PortfolioEntriesPriority'
  )
  if ($reservedTokens -contains $name) {
    return "// $name is a reserved syntactic token; see official docs for usage."
  }

  # Signal/portfolio-only keywords that land in Indicator-mapped categories.
  # Using them in an Indicator causes "X is not applicable to this type of study".
  $signalOnlyKeywords = @(
    'Portfolio_CurrencyCode','StrategyCurrencyCode',
    'InitialCapital'
  )
  if ($signalOnlyKeywords -contains $name) {
    return "// $name is signal/portfolio-only; not applicable to Indicator studies."
  }

  # Multi-word keyword names (e.g. "DateTime bar update") cannot be used as
  # identifiers in expressions. PowerLanguage parses only the first token and
  # then sees the rest as stray syntax. These show up because Parse-Chm
  # captures the H1 text verbatim from the CHM, which sometimes contains spaces.
  if ($name -match '\s') {
    $safeName = $name -replace '\s+', '_'
    return "// $name (multi-word keyword); see official docs for usage."
  }

  # Alias/redirect pages: CHM has stubs like "Same as ElDateToDateTime" with
  # no Usage block. We can't infer signature; skip with a comment.
  if ($Kw.Description -match '^(?i)(Same as|See|Synonym for|Alias for)\b') {
    return "// $name is documented as an alias/redirect; see official docs for the canonical signature."
  }

  # String-returning keywords cannot be assigned to numeric Value1.
  # Match a curated list plus a heuristic on name endings.
  $stringReturningNames = @(
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
  $looksLikeString = $name -match '(?i)(Name|Description|Symbol|Listed|Exchange|Root|ToStr|ToString|ToString_Ms|CodeToStr|DateStr|TimeStr)$' -or
                     $name -match '^(?i)Format(Time|Date|DateTime)'
  if (($stringReturningNames -contains $name) -or $looksLikeString) {
    return "// $name returns a string; see official docs for usage."
  }

  # Boolean-returning keywords assigned to numeric Value1 trip
  # "Types are not compatible". Route them to Condition1 (the built-in
  # boolean variable) so they still exercise the keyword.
  $booleanReturningNames = @(
    'MouseClickShiftPressed','MouseClickCtrlPressed','AlertEnabled',
    'CheckAlert',
    'SessionLastBar','SessionFirstBar','LastBarOnChart',
    'PosTradeIsOpen','PosTradeIsLong',
    'pmms_strategy_is_paused'
  )
  $looksLikeBoolean = ($name -match '(?i)(Pressed|Enabled)$') -or
                      ($name -match '^(?i)(Is|Has|Can)[A-Z0-9]') -or
                      ($name -match '(?i)_(Is|Has|Can)[A-Z0-9]')
  if (($booleanReturningNames -contains $name) -or $looksLikeBoolean) {
    $usageClean = $Kw.Usage -replace '\[\s*Data\s*\(\s*[^)]*\s*\)\s*\]', ''
    $boolArgCount = 0
    if ($usageClean -match '\(([^)]*)\)') {
      $inner = $Matches[1].Trim()
      if (-not [string]::IsNullOrEmpty($inner)) { $boolArgCount = (($inner -split ',').Count) }
    }
    if ($boolArgCount -eq 0) { return "If $name Then Begin End;" }
    $argv = @(); for ($i = 0; $i -lt $boolArgCount; $i++) { $argv += if ($i -eq 0) { '1' } else { '0' } }
    return "If $name( $($argv -join ', ') ) Then Begin End;"
  }

  # Drawing-object accessors (Rectangle/TL/Arw/Text Get*/Set*/Delete*/Active*)
  # all take at least one drawing-object ID arg. Parse-Chm often misses that
  # parameter for these (the CHM uses a non-standard param-list shape), so the
  # default zero-arg branch emits invalid calls. Skip them with a safe comment.
  if ($name -match '^(Rectangle|TL_|Arw_|Text_|MC_TL_|MC_Arw_|MC_Rect_|MC_Text_)(Get|Set|Delete|Active|Anchor|Lock|Color|Style|Size|Width|Begin|End|Fill|First|Next|Prev|Last|New)') {
    return "// $name is a drawing-object accessor (takes a drawing-object ID); see official docs."
  }

  # Setter functions (Set*, Portfolio_Set*, pmm_set_*, pmms_*_set_*) always
  # take at least one argument. Statement-shaped, not value-returning.
  if ($name -match '^Set[A-Z]' -or $name -match '^Portfolio_Set' -or $name -match '^pmm_set_' -or $name -match '_set_') {
    return "// $name is a setter; see official docs."
  }

  # Lowercase-prefix get* (e.g. getTPOinfo, getappinfo) — non-standard
  # naming usually indicates a parameter-taking function where Parse-Chm
  # didn't pick up the params correctly. Skip with a safe comment.
  if ($name -cmatch '^(get|init|raise)[A-Za-z]') {
    return "// $name (lowercase-prefix function, takes at least one argument); see official docs."
  }

  # Procedure keywords: action functions that take arguments but do NOT
  # return a value. Assigning them to Value1 causes "Function must have
  # a return value". Call as standalone statements instead.
  # Procedure keywords: action functions with no return value.
  # Hardcoded calls because arg types are mixed (bool/string/numeric).
  switch ($name) {
    'ScrollToBar'          { return 'ScrollToBar( 1, 0 );' }
    'PlaceMarketOrder'     { return 'PlaceMarketOrder( True, True, 1 );' }
    'ChangeMarketPosition' { return 'ChangeMarketPosition( 1, Close, "x" );' }
    'pmms_strategy_close_position_partial' { return 'pmms_strategy_close_position_partial( 1, True, 1 );' }
    'pmms_strategy_close_position'         { return 'pmms_strategy_close_position( 1 );' }
    'pmms_strategy_resume'                 { return 'pmms_strategy_resume( 1 );' }
    'pmms_strategy_pause'                  { return 'pmms_strategy_pause( 1 );' }
    'pmms_strategy_deny_entries'           { return 'pmms_strategy_deny_entries( 1 );' }
    'pmms_strategy_deny_exits'             { return 'pmms_strategy_deny_exits( 1 );' }
    'pmms_strategy_deny_short_entries'     { return 'pmms_strategy_deny_short_entries( 1 );' }
    'pmms_strategy_deny_long_entries'      { return 'pmms_strategy_deny_long_entries( 1 );' }
    'pmms_strategy_deny_exit_from_short'   { return 'pmms_strategy_deny_exit_from_short( 1 );' }
    'pmms_strategy_deny_exit_from_long'    { return 'pmms_strategy_deny_exit_from_long( 1 );' }
    'pmms_strategy_allow_entries'          { return 'pmms_strategy_allow_entries( 1 );' }
    'pmms_strategy_allow_exits'            { return 'pmms_strategy_allow_exits( 1 );' }
    'pmms_strategy_allow_short_entries'    { return 'pmms_strategy_allow_short_entries( 1 );' }
    'pmms_strategy_allow_long_entries'     { return 'pmms_strategy_allow_long_entries( 1 );' }
    'pmms_strategy_allow_exit_from_short'  { return 'pmms_strategy_allow_exit_from_short( 1 );' }
    'pmms_strategy_allow_exit_from_long'   { return 'pmms_strategy_allow_exit_from_long( 1 );' }
    'pmms_strategies_resume_all'           { return 'pmms_strategies_resume_all;' }
    'pmms_strategies_pause_all'            { return 'pmms_strategies_pause_all;' }
    'pmms_strategies_deny_entries_all'     { return 'pmms_strategies_deny_entries_all;' }
    'pmms_strategies_allow_entries_all'    { return 'pmms_strategies_allow_entries_all;' }
  }

  switch ($cat) {
    'Dynamic_Arrays' {
      # Uses pre-declared arrays from the file header: pl_test_bools, pl_test_floats,
      # pl_test_ints, pl_test_strs.
      switch ($name) {
        'Array_GetBooleanValue' { return 'If Array_GetBooleanValue( pl_test_bools, 0 ) Then Begin End;' }
        'Array_GetFloatValue'   { return 'Value1 = Array_GetFloatValue( pl_test_floats, 0 );' }
        'Array_GetIntegerValue' { return 'Value1 = Array_GetIntegerValue( pl_test_ints, 0 );' }
        'Array_GetStringValue'  { return '// Array_GetStringValue returns a string; see official docs.' }
        'Array_SetBooleanValue' { return 'Array_SetBooleanValue( pl_test_bools, 0, True );' }
        'Array_SetFloatValue'   { return 'Array_SetFloatValue( pl_test_floats, 0, 1.5 );' }
        'Array_SetIntegerValue' { return 'Array_SetIntegerValue( pl_test_ints, 0, 42 );' }
        'Array_SetStringValue'  { return 'Array_SetStringValue( pl_test_strs, 0, "x" );' }
        'Array_GetMaxIndex'     { return 'Value1 = Array_GetMaxIndex( pl_test_ints );' }
        'Array_SetMaxIndex'     { return 'Array_SetMaxIndex( pl_test_ints, 20 );' }
        'Array_GetType'         { return 'Value1 = Array_GetType( pl_test_ints );' }
        'Array_IndexOf'         { return 'Value1 = Array_IndexOf( pl_test_ints, 5 );' }
        'Array_Contains'        { return 'If Array_Contains( pl_test_ints, 5 ) Then Begin End;' }
        'Array_Compare'         { return 'Value1 = Array_Compare( pl_test_ints, 0, pl_test_ints, 0, 5 );' }
        'Array_Copy'            { return 'Array_Copy( pl_test_ints, 0, pl_test_ints, 0, 5 );' }
        'Array_Sort'            { return 'Array_Sort( pl_test_ints, 0, 5, True );' }
        'Array_Sum'             { return 'Value1 = Array_Sum( pl_test_floats, 0, 5 );' }
        'Array_SetValRange'     { return 'Array_SetValRange( pl_test_ints, 0, 5, 0 );' }
        'Fill_Array'            { return 'Fill_Array( pl_test_ints, 0 );' }
        default                 { return "// $name (Dynamic_Arrays); see official docs." }
      }
    }
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
      # Parse-Chm sometimes misses parameter detection (params inline in the
      # Usage signature rather than in a separate block). Use the signature
      # itself: count commas inside the parens to derive arg count.
      if ($name -in @('PI','E','Pi','Euler')) { return "Value1 = $name;" }
      $argCount = 1
      if ($Kw.Usage -match '\(([^)]*)\)') {
        $inner = $Matches[1].Trim()
        if ([string]::IsNullOrEmpty($inner)) { $argCount = 0 }
        else { $argCount = (($inner -split ',').Count) }
      }
      # Build $argCount placeholder args — Close for the first, 14 / 2 / etc. for the rest.
      $args = @()
      for ($i = 0; $i -lt $argCount; $i++) {
        $args += if ($i -eq 0) { 'Close' } else { '2' }
      }
      if ($argCount -eq 0) { return "Value1 = $name;" }
      return "Value1 = $name( $($args -join ', ') );"
    }
    'Plotting' {
      if ($name -match '^Plot\d')           { return "$name( Close );" }
      return "// $name -- see official docs"
    }
    default {
      # Derive arg count from the Usage signature commas (more reliable than
      # Parse-Chm's parameter detection, which misses inline-documented params).
      # Strip decorative '[Data(N)]' specifiers first — those (N) parens are
      # data-series references, not real arg lists.
      $usageClean = $Kw.Usage -replace '\[\s*Data\s*\(\s*[^)]*\s*\)\s*\]', ''
      $argCount = 0
      if ($usageClean -match '\(([^)]*)\)') {
        $inner = $Matches[1].Trim()
        if (-not [string]::IsNullOrEmpty($inner)) { $argCount = (($inner -split ',').Count) }
      } else {
        # No parens in cleaned Usage — treat as zero-arg value reference.
        $argCount = $params.Count
      }

      if ($argCount -eq 0) { return "Value1 = $name;" }

      # PMM strategy getters: first arg is numeric StrategyIndex, rest are strings.
      if ($name -match '^pmms_get_strategy_named_') {
        $argv = @('1'); for ($i = 1; $i -lt $argCount; $i++) { $argv += '"x"' }
        return "Value1 = $name( $($argv -join ', ') );"
      }

      # PMM functions that take an indexesArray argument (dynamic array, not numeric).
      if ($name -match '^pmms_strategies_in_(positions|long|short)_count$') {
        return "Value1 = $name( pl_test_ints );"
      }

      # Heuristic: function-name prefix hints arg types.
      # - StringTo*/StrTo*: all args are strings (input value AND format spec)
      # - GetPosition*/GetRT*Account*: AccountsPositions args are strings
      #   (Symbol, Account both passed as text).
      # - Category AccountsPositions: any function with args takes string args.
      # Default of Close/14 fails with "Incorrect argument type".
      $allArgsString = ($name -match '^(StringTo|StrTo|GetPosition|GetRT)') -or
                       ($cat -eq 'AccountsPositions') -or
                       ($name -match '^pmm_get_\w+_named_')

      $argv = @()
      for ($i = 0; $i -lt $argCount; $i++) {
        $type = if ($i -lt $params.Count) { $params[$i].Type } else { 'numeric' }
        if ($allArgsString) { $type = 'string' }
        $argv += switch ($type) {
          'numeric'   { if ($i -eq 0) { 'Close' } else { '14' } }
          'string'    { '"x"' }
          'truefalse' { 'True' }
          default     { if ($i -eq 0) { 'Close' } else { '1' } }
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
  # The Arrays: block provides typed array refs for Dynamic_Arrays usage examples.
  $arrayDecls = "Arrays: pl_test_bools[10]( false ), pl_test_floats[10]( 0.0 ), pl_test_ints[10]( 0 ), pl_test_strs[10]( ""x"" );`r`n"
  $headerByType = @{
    'Indicator' = "{ test_indicator.txt -- exercises every keyword routed to Indicator script type }`r`n{ Paste this whole file into a new Indicator study in PowerLanguage Editor and Verify (F3). }`r`n${arrayDecls}"
    'Signal'    = "{ test_signal.txt -- exercises every keyword routed to Signal script type }`r`n{ Paste this whole file into a new Signal study in PowerLanguage Editor and Verify (F3). }`r`n${arrayDecls}"
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
