---
name: powerlanguage-syntax
description: Use when reading or writing PowerLanguage code — declarations (Inputs, Variables, Arrays), data types (numeric, string, truefalse), the begin/end semicolon rules, control flow (If/Then/Else, For, While, Switch), bar references (Close, Close[N], Date, Time, BarNumber), operators, comments, the pre-declared Value1..Value10000 and Condition1..Condition10000 built-ins, the built-in trade-state variables (MarketPosition, EntryPrice, BarsSinceEntry, CurrentContracts), and common gotchas — including "syntax error, unexpected X" / "Wrong syntax of X" errors caused by writing keywords like Print/File/Variable/If/Yesterday/#BeginCmtry as RHS values, MarketPosition(N) being position history (NOT bar offset), and bars being labeled by their close time (NOT open time).
---

# PowerLanguage Syntax

## Declarations

Every script starts with declarations. Order matters: `Inputs:` comes before `Variables:` (or its aliases `Vars:`, `Var:`); both come before code.

```pascal
Inputs:
    Length(20),
    Threshold(0.0);

Variables:
    avg(0),
    triggered(False);

Arrays:
    buffer[10](0);
```

- **Inputs** — parameters exposed in the script's Format window. Each gets a default value in parentheses. Read-only inside the script.
- **Variables / Vars / Var** — script state. Each gets an initial value. Persist across bars within the same chart.
- **Arrays** — fixed-size collections. `[size]` is the index of the last element (zero-based by default), `(initial)` initializes every slot.

**Pre-declared default variables.** PowerLanguage ships with numbered built-ins that don't need a `Variables:` declaration:

| Name | Type | Count |
|---|---|---|
| `Value1` … `Value10000` | numeric | 10,000 |
| `Condition1` … `Condition10000` | truefalse | 10,000 |

Use them directly: `Value1 = Average(Close, 14);`, `If Condition1 Then Buy ...;`. No declaration line required (declaring one just shadows the built-in with an identical local). These are handy for quick scratch values when you don't want to bother naming a variable.

## Data types

PowerLanguage is loosely typed but each value is one of:

| Type | What it is | Literal examples |
|---|---|---|
| Numeric | Floating-point number | `0`, `1.5`, `-3.14` |
| String | Text | `"hello"`, `"LE"` |
| TrueFalse (bool) | Boolean | `True`, `False` |

Type is inferred from initial value in `Variables:` / `Inputs:` declarations.

## The `begin … end` rule and semicolons

`begin` opens a block; `end` closes it. **Every `end` gets a semicolon EXCEPT when followed by `else`.**

```pascal
If condition Then Begin
    statement1;
    statement2;
End                     // NO semicolon — else follows
Else Begin
    statement3;
End;                    // semicolon — outer statement boundary
```

Forgetting a semicolon on a terminal `End` is the most common compile error new PowerLanguage users hit. The rule is mechanical: if the next token is `Else`, no semicolon; otherwise yes.

## Control flow

```pascal
If x > 0 Then Begin ... End;

If x > 0 Then ... Else If x = 0 Then ... Else ... ;

For i = 1 To 10 Begin
    sum = sum + i;
End;

While condition Begin ... End;

Switch (n) Begin
    Case 1: ... ;
    Case 2: ... ;
    Default: ... ;
End;
```

## Bar references

`Close` is the close price of the current bar; `Close[1]` is the close one bar ago; `Close[N]` is N bars ago. Same indexing for `Open`, `High`, `Low`, `Volume`, `OpenInterest`.

| Built-in | Meaning |
|---|---|
| `Close`, `Open`, `High`, `Low` | OHLC of current bar |
| `Volume` | Volume of current bar |
| `OpenInterest` | OI of current bar (futures/options) |
| `Date` | Bar date as `YYYMMDD` integer (note: only 7 digits for years up to 2099, format is `(YYYY-1900)*10000 + MM*100 + DD`) |
| `Time` | Bar **close** time as `HHMM` integer — see gotcha below |
| `BarNumber` | Sequential count, same as `CurrentBar` |

## Operators

- Arithmetic: `+`, `-`, `*`, `/`
- Comparison: `=`, `<>`, `>`, `<`, `>=`, `<=`
- Logical: `and`, `or`, `not` (lowercase; `and` is a keyword, not `&&`)

## Comments

- Line comment: `// up to end of line`
- Block comment: `{ braces — can span multiple lines }`

The `{ … }` block-comment form is also how PowerLanguage code authors traditionally write file headers.

## Built-in trade-state variables (Signal scripts)

Inside a Signal script, these are always available — no declaration needed:

| Variable | Meaning |
|---|---|
| `MarketPosition` | `1` if long, `-1` if short, `0` if flat |
| `CurrentContracts` | Absolute size of current position |
| `EntryPrice` | Average fill price of the current position |
| `BarsSinceEntry` | Bars since the current position was entered |
| `BarsSinceExit(N)` | Bars since the Nth-most-recent exit |

## Order syntax (high-level recap)

```pascal
Buy ("LE") 1 Contract Next Bar at Market;
Sell ("LX") 1 Contract Next Bar at Market;
SellShort ("SE") 1 Contract Next Bar at Market;
BuyToCover ("SX") 1 Contract Next Bar at Market;
```

Quantities use `Contract` / `Contracts` (futures, FX) or `Share` / `Shares` (equities). The price-placement keyword (`Market`, `Limit`, `Stop`, `This Bar on Close`) determines when the fill happens. See `powerlanguage-keywords-reference` for each order keyword's full signature.

## Common built-in functions

MultiCharts ships with hundreds of pre-built Functions (`.elf` files) that are NOT in the keyword reference. These are the most commonly used ones — get the signatures right or you'll get compile errors.

### Moving averages and smoothing

| Function | Signature | Returns |
|---|---|---|
| `Average` | `Average(Price, Length)` | numeric |
| `XAverage` | `XAverage(Price, Length)` | numeric (exponential MA) |
| `AverageFC` | `AverageFC(Price, Length)` | numeric (fast calculation) |
| `WAverage` | `WAverage(Price, Length)` | numeric (weighted MA) |
| `AdaptiveMovAvg` | `AdaptiveMovAvg(Price, Length)` | numeric (Kaufman AMA) |

### Oscillators and indicators

| Function | Signature | Returns |
|---|---|---|
| `RSI` | `RSI(Price, Length)` | numeric (0–100) |
| `Stochastic` | `Stochastic(PriceH, PriceL, PriceC, StochLen, SmoothLen1, SmoothLen2, SmoothType, oFastK, oFastD, oSlowK, oSlowD)` | numeric (1=ok, -1=error); populates 4 ref vars |
| `BollingerBand` | `BollingerBand(Price, Length, NumDevs)` | numeric (use +NumDevs for upper, -NumDevs for lower) |
| `MACD` | `MACD(Price, FastLen, SlowLen)` | numeric |
| `CCI` | `CCI(Length)` | numeric |
| `ADX` | `ADX(Length)` | numeric |
| `DMIPlus` | `DMIPlus(Length)` | numeric |
| `DMIMinus` | `DMIMinus(Length)` | numeric |

**`Stochastic` gotcha:** It takes **11 parameters**, not 3. The last 4 are output ref variables — you must declare Variables for them. The return value is just a status code (1 or -1), not the stochastic value itself. Typical usage:

```pascal
Variables: fastK(0), fastD(0), slowK(0), slowD(0);
Value1 = Stochastic(High, Low, Close, 14, 3, 3, 1, fastK, fastD, slowK, slowD);
// Use slowK and slowD for signals
```

### Volatility and range

| Function | Signature | Returns |
|---|---|---|
| `AvgTrueRange` | `AvgTrueRange(Length)` | numeric |
| `TrueRange` | `TrueRange` | numeric (no args) |
| `StandardDev` | `StandardDev(Price, Length, DataType)` | numeric (DataType: 1=population, 2=sample) |
| `TrueHigh` | `TrueHigh` | numeric (no args) |
| `TrueLow` | `TrueLow` | numeric (no args) |

### Price extremes

| Function | Signature | Returns |
|---|---|---|
| `Highest` | `Highest(Price, Length)` | numeric |
| `Lowest` | `Lowest(Price, Length)` | numeric |
| `HighestBar` | `HighestBar(Price, Length)` | numeric (bars ago) |
| `LowestBar` | `LowestBar(Price, Length)` | numeric (bars ago) |

### Aggregation

| Function | Signature | Returns |
|---|---|---|
| `Summation` | `Summation(Price, Length)` | numeric |
| `Cum` | `Cum(Price)` | numeric (cumulative sum from bar 1) |
| `LinearRegValue` | `LinearRegValue(Price, Length, Offset)` | numeric |

## Gotchas

### `MarketPosition(N)` is position history, NOT bar offset

A natural-looking expression like `MarketPosition(1)` reads as "the market position one bar ago" — but it actually returns the position **one trade ago**. So `MarketPosition(1)` on bar 50, when the strategy has been flat for the last 30 bars, returns whatever the previous closed position was (long or short), not `0`.

To detect a position transition between bars (e.g. "did we just enter long?"), store the previous bar's position at the END of each bar:

```pascal
Variables:
    _prevMP(0);

If MarketPosition <> _prevMP Then Begin
    // transition just happened this bar
    ...
End;

_prevMP = MarketPosition;     // end of bar
```

This is the canonical pattern. Don't rely on `MarketPosition(1)` for transition detection.

### Bars are labeled by their CLOSE time, not open time

A 60-minute bar covering 15:00–16:00 has `Time = 1600`, not `Time = 1500`. A filter like `If Time = 1500 Then …` will never match that bar.

To check whether the current bar is the first bar of the night session at 15:00, write:

```pascal
If Time = 1600 Then ...     // for 60-min bars
If Time = 1505 Then ...     // for 5-min bars (first close after 15:00)
If Time = 1501 Then ...     // for 1-min bars
```

Add one bar's worth of minutes to the session-start clock time.

### Inputs are read-only

You cannot assign to an Input inside a script. If you need a mutable copy, declare a Variable and copy from the Input once.

### Variable types are fixed at first assignment

`Variables: x(0);` makes `x` numeric for the life of the script. You can't later assign a string to it. Same for `True`/`False` initial values (bool) and `""` (string).

### Many keywords can't appear as values on the right-hand side of `=`

A common new-user mistake is to write `Value1 = SomeKeyword;` for a keyword that looks identifier-like in the documentation but is actually a syntactic construct. PowerLanguage will throw "syntax error, unexpected '…'" or "Wrong syntax of '…'" when you do this. Empirically, the following classes never work as RHS values:

**Whole keyword classes:**

| Class | Example keywords | Why |
|---|---|---|
| Type / declaration words | `Numeric`, `String`, `TrueFalse`, `Variable`, `Var`, `NumericSeries`, `IntraBarPersist` | Used inside `Inputs:` / `Variables:` / `Arrays:` blocks |
| Control flow / operators | `If`, `Then`, `Else`, `For`, `While`, `Begin`, `End`, `To`, `DownTo`, `Switch`, `Case`, `and`, `or`, `not` | Reserved syntax |
| Script-level attributes | `IntraBarOrderGeneration`, `LegacyColorValue`, `RecoverDrawings`, `AllowSendOrdersOn…`, `PortfolioEntriesPriority` | Used in `[Attr = value];` form at script start |
| Output statements | `Print`, `FileAppend`, `FileClose`, `FileDelete`, `ClearDebug`, `ClearPrintLog`, `File`, `MessageLog`, `PlaySound` | Statement-shaped, no return value |
| DLL-calling directives | `DefineDllFunc`, `external`, `method`, `OnCreate`, `OnDestroy`, `ThreadSafe`, plus C type names (`int`, `lpstr`, `bool`, …) | Statement / declaration syntax |
| Expert Commentary | `#BeginCmtry`, `#EndCmtry`, `CheckCommentary`, `AtCommentaryBar` | Paired-block directives |
| Preprocessor (`#`-prefixed) | `#BeginCmtry`, `#EndCmtry`, `#Return`, `#Events` | Reserved positions; `#BeginCmtry` in particular opens a commentary block that runs to `#EndCmtry` |
| Connector words | `Bar`, `Bars`, `Day`, `Days`, `Point`, `Points`, `Tick`, `Ticks`, `Ago`, `Next`, `This`, `Today`, `Yesterday`, `Market`, `Contract`, `Contracts` | Used in compound phrases ("5 bars ago", "next bar at market") |

**Other rules of thumb:**

- A keyword name that contains a space in the official docs (e.g. `DateTime bar update`, `Cancel Alert`) cannot be used as a single identifier — PowerLanguage parses only the first word and chokes on the rest.
- **Single-letter data-series aliases** (`C`=Close, `D`=Date, `H`=High, `I`=OpenInt, `L`=Low, `O`=Open, `T`=Time, `V`=Volume) are reserved — using them with parentheses like `C(Close)` causes *"A keyword/variable is used as a function"*. Use square brackets for barsback: `C[1]`.
- A handful of names in otherwise-value-rich categories are reserved syntactic tokens: `Data` (used as `Close of Data2`), `Call` / `Put` / `Strike` (option-context syntax), `Length`, `OptionType`, `DeltaType`, `RevSize`, `BoxSize`.
- **Procedure keywords** like `ScrollToBar`, `PlaceMarketOrder`, `ChangeMarketPosition`, and all PMM action keywords (`pmms_strategy_resume`, `pmms_strategy_pause`, `pmms_strategy_close_position`, `pmms_strategy_deny_*`, `pmms_strategy_allow_*`, `pmms_strategies_*_all`) perform an action and do NOT return a value — assigning them to `Value1` causes *"Function must have a return value"*. Call them as standalone statements: `ScrollToBar(1, 0);`.
- **Signal/portfolio-only keywords** like `Portfolio_CurrencyCode`, `StrategyCurrencyCode`, `InitialCapital` cause *"X is not applicable to this type of study"* when used in an Indicator. They only work in Signal studies.
- **Drawing-object accessors** (any `Rectangle*`, `TL_*`, `Arw_*`, `Text_*`, or `MC_TL_*`/`MC_Arw_*`/etc. function ending in `Get`/`Set`/`Delete`/`New`/…) take at least one drawing-object ID argument — never use them as bare values.
- **Setter keywords** (`Set*`, `Portfolio_Set*`, `pmm_set_*`, or any name containing `_set_`) are statement-shaped — they always require at least one value argument and don't return a value.
- **Lowercase-prefix functions** (e.g. `getTPOinfo`, `getplotstyle`) usually take parameters; the unusual lowercase naming is the signal.
- **String-returning keywords** like `Description`, `Symbol`, `GetCurrency`, `BarType_uid`, anything ending in `Name` / `Description` / `Listed` / `ToStr` — can be assigned only to a string variable, not the numeric `Value1`.
- **Boolean-returning keywords** like `Is64BitProcess`, `MouseClickShiftPressed`, `AlertEnabled`, `PosTradeIsOpen`, `PosTradeIsLong`, `pmms_strategy_is_paused` — use them inside an `If` condition (`If Is64BitProcess Then ...`); direct assignment to `Condition1` sometimes fails because PowerLanguage returns numeric 0/1 instead of `TrueFalse` for some "logical" functions. **Exception:** `MarketPosition_at_Broker_for_The_Strategy` looks boolean but returns numeric 1/0/-1 (market position) — use `Value1 = X;`, not `If X Then`.

### Quick error → fix lookup

If MultiCharts gives you one of these errors when using a keyword:

| Compile error | Likely cause | Fix |
|---|---|---|
| `syntax error, unexpected 'X'` | `X` is a reserved syntactic token (declaration / control flow / connector) | Don't use it as a value; it belongs in a different syntactic position |
| `Wrong syntax of 'X'` | `X` is a directive (e.g. `DefineDllFunc`) | Use the documented statement form, not as RHS |
| `Commentary end is expected before end of file` | You used `#BeginCmtry` without `#EndCmtry` | Pair them, or skip the construct |
| `Invalid number of parameters. N parameter(s) expected` | Function needs N args you didn't pass | Look up the signature in `powerlanguage-keywords-reference` and pass the right number |
| `Types are not compatible` | RHS returns a type incompatible with the LHS variable | Assign string→string var, bool→bool var, numeric→`Value1` |
| `A keyword/variable is used as a function` | Using a data-series alias with parentheses, e.g. `C(Close)` | Use square brackets for barsback: `C[1]`, or no brackets: `Value1 = C;` |
| `Function must have a return value` | Assigning a procedure keyword (e.g. `ScrollToBar`) to a variable | Call as a standalone statement: `ScrollToBar(1, 0);` |
| `X is not applicable to this type of study` | Using a signal-only keyword in an Indicator (e.g. `InitialCapital`) | Move to a Signal study, or remove the keyword |

When in doubt, look up the keyword in the `powerlanguage-keywords-reference` skill — the signature line shows whether it's used as `KeywordName(args)` (callable function) or in a larger construct (then it can't be the whole RHS).
