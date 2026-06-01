# Pine Script Reference & PowerLanguage-Pine Conversion — Design Spec

**Date:** 2026-06-01
**Status:** Draft
**Scope:** Two new skills for the multicharts-powerlanguage plugin

## Overview

Add two new skills to the plugin:

1. **`pinescript-reference`** — gives Claude expert knowledge of TradingView Pine Script (syntax, type system, built-in functions, gotchas). Mirrors what `powerlanguage-syntax` does for PowerLanguage.
2. **`powerlanguage-pinescript-conversion`** — bidirectional conversion mapping between PowerLanguage and Pine Script, with semantic difference documentation and pre/post-conversion checklists.

Together with the existing three skills, this makes the plugin useful for both MultiCharts and TradingView users, and enables code porting between the two platforms.

## Constraints

- **No TradingView content may be scraped or copied.** TradingView's ToS (Section 3) explicitly prohibits automated access, copying documentation, and creating derivative works from their content.
- **All Pine Script descriptions must be original.** Hand-curated from open-source repos, community resources, and general language knowledge. Same paraphrase-only approach used for the PowerLanguage keywords.
- **Pine Script version target:** Primary focus on `@version=5` and `@version=6`. Older versions are out of scope.

## Skill 1: `pinescript-reference`

### Location

`skills/pinescript-reference/SKILL.md`

### Trigger

Activates when the user asks about Pine Script syntax, TradingView scripting, or needs help writing/understanding Pine Script code.

### Description (YAML frontmatter)

```yaml
name: pinescript-reference
description: >-
  Use when reading or writing TradingView Pine Script code — covers versioning
  (@version=5, @version=6), type system (series, simple, input, const),
  declarations (var, varip, input.*), built-in namespaces (ta.*, math.*, str.*,
  strategy.*, request.*, array.*, map.*), plotting (plot, plotshape, bgcolor),
  strategy functions (strategy.entry, strategy.exit, strategy.close),
  multi-timeframe via request.security(), control flow (if/else, for, while,
  switch, ternary), user-defined functions/types/methods, and common gotchas
  (repainting, na handling, series vs simple context, max_bars_back).
```

### Content Sections

#### 1. Versioning
- `@version=5` vs `@version=6` differences
- How to declare: `//@version=5` as first line
- Key v6 changes (if applicable at time of implementation)

#### 2. Script Types
- `indicator()` — for indicators (oscillators, overlays)
- `strategy()` — for backtestable strategies
- `library()` — for reusable exported functions
- Key differences: `strategy()` requires unique title, allows order functions; `indicator()` allows more plot types

#### 3. Type System
- Fundamental types: `int`, `float`, `bool`, `string`, `color`
- Special types: `series`, `simple`, `input`, `const`
- Type hierarchy: `const` < `input` < `simple` < `series`
- `na` value and `na()` function
- Type casting: `int()`, `float()`, `str.tostring()`, `color.new()`

#### 4. Declarations
- `var` — initialize once, persist across bars (equivalent to PL Variables)
- `varip` — persist across bars AND intrabar ticks (equivalent to PL IntraBarPersist)
- `input.int()`, `input.float()`, `input.bool()`, `input.string()`, `input.color()`, `input.source()`, `input.timeframe()`, `input.symbol()`
- Variable naming: camelCase convention, no reserved word conflicts

#### 5. Built-in Namespaces & Functions

Organized by namespace with signatures:

**`ta.*` (Technical Analysis) — highest priority**
- Moving averages: `ta.sma()`, `ta.ema()`, `ta.wma()`, `ta.vwma()`, `ta.rma()`, `ta.swma()`, `ta.alma()`, `ta.hma()`
- Oscillators: `ta.rsi()`, `ta.stoch()`, `ta.cci()`, `ta.mfi()`, `ta.cmo()`
- Trend: `ta.macd()`, `ta.adx()`, `ta.dmi()`, `ta.supertrend()`
- Volatility: `ta.atr()`, `ta.bb()`, `ta.kc()`
- Volume: `ta.obv()`, `ta.vwap()`
- Misc: `ta.crossover()`, `ta.crossunder()`, `ta.highest()`, `ta.lowest()`, `ta.change()`, `ta.mom()`, `ta.pivothigh()`, `ta.pivotlow()`, `ta.valuewhen()`, `ta.barssince()`

**`strategy.*` (Strategy)**
- `strategy.entry(id, direction, qty, limit, stop, comment)`
- `strategy.exit(id, from_entry, profit, loss, limit, stop, trail_points, trail_offset)`
- `strategy.close(id, comment)`
- `strategy.close_all(comment)`
- `strategy.order(id, direction, qty, limit, stop)`
- `strategy.cancel(id)`, `strategy.cancel_all()`
- Position info: `strategy.position_size`, `strategy.position_avg_price`, `strategy.opentrades`, `strategy.closedtrades`, `strategy.equity`, `strategy.netprofit`

**`request.*` (Data)**
- `request.security(symbol, timeframe, expression)` — multi-timeframe/multi-symbol data
- `request.security_lower_tf()`
- `request.financial()`, `request.quandl()`, `request.dividends()`, `request.earnings()`

**`math.*` (Math)**
- `math.abs()`, `math.ceil()`, `math.floor()`, `math.round()`, `math.log()`, `math.log10()`, `math.pow()`, `math.sqrt()`, `math.max()`, `math.min()`, `math.avg()`, `math.sign()`
- Constants: `math.pi`, `math.e`

**`str.*` (String)**
- `str.tostring()`, `str.format()`, `str.length()`, `str.contains()`, `str.replace()`, `str.split()`, `str.upper()`, `str.lower()`, `str.substring()`

**`array.*` (Arrays)**
- `array.new<type>()`, `array.push()`, `array.pop()`, `array.get()`, `array.set()`, `array.size()`, `array.sort()`, `array.avg()`, `array.sum()`, `array.max()`, `array.min()`

**`color.*` (Color)**
- `color.new()`, `color.rgb()`, `color.r()`, `color.g()`, `color.b()`
- Named colors: `color.red`, `color.green`, `color.blue`, etc.

#### 6. Plotting
- `plot(series, title, color, linewidth, style)` — main plot function
- `plotshape()`, `plotchar()`, `plotarrow()` — marker plots
- `bgcolor()`, `barcolor()` — background/bar coloring
- `fill(plot1, plot2, color)` — fill between plots
- `hline(price)` — horizontal line
- Plot styles: `plot.style_line`, `plot.style_histogram`, `plot.style_circles`, etc.

#### 7. Control Flow
- `if/else` — indentation-based blocks (no begin/end)
- `for ... to ...` and `for ... in ...`
- `while`
- `switch`
- Ternary: `condition ? valueIfTrue : valueIfFalse`

#### 8. User-Defined Functions & Types
- Function syntax: `f(param1, param2) => expression` or multi-line with indentation
- `type` keyword for user-defined types (UDTs)
- `method` keyword for type methods
- `export` / `import` for library functions

#### 9. Bar State & Time
- `bar_index`, `barstate.isfirst`, `barstate.islast`, `barstate.isrealtime`, `barstate.isconfirmed`
- `time`, `time_close`, `year`, `month`, `dayofmonth`, `hour`, `minute`, `second`
- `timeframe.period`, `timeframe.multiplier`
- `syminfo.ticker`, `syminfo.tickerid`, `syminfo.currency`, `syminfo.pointvalue`

#### 10. Common Gotchas
- **Repainting:** `request.security()` can repaint on realtime bars; `barstate.isconfirmed` guard
- **`na` propagation:** Most operations with `na` return `na`; use `nz()` or `na()` checks
- **Series vs simple context:** Some functions require `simple` inputs (e.g., `ta.sma` length must be `simple int`); passing a `series` causes compile error
- **`max_bars_back`:** Pine limits lookback; large `[N]` offsets need explicit `max_bars_back()` call
- **String in switch:** Pine `switch` doesn't support string matching directly
- **Strategy vs indicator:** Strategy scripts can't use `alertcondition()`; indicator scripts can't use `strategy.*` functions
- **Execution model:** Pine executes once per bar close (historical) and on each tick (realtime) — different from PL's configurable execution

### Data Source

All content is hand-curated from:
- Open-source Pine Script repositories on GitHub
- Community blog posts and tutorials
- General knowledge of the Pine Script language

No content is copied or scraped from tradingview.com. All descriptions are original.

---

## Skill 2: `powerlanguage-pinescript-conversion`

### Location

`skills/powerlanguage-pinescript-conversion/SKILL.md`

### Trigger

Activates when the user asks to convert, translate, port, or migrate code between MultiCharts PowerLanguage and TradingView Pine Script, in either direction.

### Description (YAML frontmatter)

```yaml
name: powerlanguage-pinescript-conversion
description: >-
  Use when converting, translating, porting, or migrating code between
  MultiCharts PowerLanguage and TradingView Pine Script, in either direction.
  Contains concept mapping tables, semantic difference documentation, and
  pre/post-conversion checklists. References pinescript-reference and
  powerlanguage-syntax for language-specific details.
```

### Content Sections

#### Part 1: Concept Mapping Table

**Declarations**

| PowerLanguage | Pine Script | Notes |
|---|---|---|
| `Inputs: Length(14);` | `length = input.int(14, "Length")` | Pine inputs are typed; PL infers type |
| `Variables: MyVar(0);` | `var float myVar = 0.0` | Pine needs explicit type + `var` for persistence |
| `Variables: MyStr("");` | `var string myStr = ""` | Pine string variables need `var` + type |
| `Variables: MyBool(False);` | `var bool myBool = false` | Pine `false` is lowercase |
| `Value1..Value99` | No equivalent | Must convert to named variables |
| `Condition1..Condition99` | No equivalent | Must convert to named `bool` variables |
| `Arrays: MyArr[10](0);` | `var myArr = array.new_float(10, 0.0)` | Fundamentally different array API |
| `IntraBarPersist` | `varip` | Same concept, different keyword |

**Data Access**

| PowerLanguage | Pine Script | Notes |
|---|---|---|
| `Open`, `High`, `Low`, `Close`, `Volume` | `open`, `high`, `low`, `close`, `volume` | Lowercase in Pine |
| `Close[1]` | `close[1]` | Same bar-offset syntax |
| `Close of Data2` | `request.security(symbol, timeframe, close)` | Completely different model — Pine uses symbol+timeframe, not data slots |
| `Date`, `Time` | `year`, `month`, `dayofmonth`, `hour`, `minute` | Pine has separate components, no single Date/Time integer |
| `BarNumber` | `bar_index` | PL is 1-based, Pine is 0-based |
| `CurrentBar` | `bar_index + 1` | Off-by-one |

**Indicators / Technical Analysis**

| PowerLanguage | Pine Script | Notes |
|---|---|---|
| `Average(Close, Length)` | `ta.sma(close, length)` | Same function, different name |
| `XAverage(Close, Length)` | `ta.ema(close, length)` | |
| `RSI(Close, Length)` | `ta.rsi(close, length)` | |
| `Stochastic(H, L, C, KLen, KSmooth, DSmooth, ...)` | `ta.stoch(close, high, low, length)` | PL has 11 params; Pine returns only %K, need separate `ta.sma()` for %D |
| `ADX(Length)` | `ta.adx(diLen, adxLen)` | Different parameter model |
| `CCI(Length)` | `ta.cci(source, length)` | Pine takes source param |
| `AvgTrueRange(Length)` | `ta.atr(length)` | |
| `BollingerBand(Close, Length, NumDevs)` | `ta.bb(close, length, mult)` | Pine returns [middle, upper, lower] tuple |
| `Crosses Over` | `ta.crossover(a, b)` | PL is operator syntax; Pine is function |
| `Crosses Under` | `ta.crossunder(a, b)` | |
| `Highest(High, Length)` | `ta.highest(high, length)` | |
| `Lowest(Low, Length)` | `ta.lowest(low, length)` | |
| `MomentumFunc(Close, Length)` | `ta.mom(close, length)` | |

**Strategy Orders**

| PowerLanguage | Pine Script | Notes |
|---|---|---|
| `Buy ("name") Next Bar at Market;` | `strategy.entry("name", strategy.long)` | |
| `SellShort ("name") Next Bar at Market;` | `strategy.entry("name", strategy.short)` | |
| `Sell ("name") Next Bar at Market;` | `strategy.close("name")` | **WARNING:** PL `Sell` = exit long, NOT go short |
| `BuyToCover ("name") Next Bar at Market;` | `strategy.close("name")` | PL `BuyToCover` = exit short |
| `Buy ("name") 2 Contracts Next Bar at Market;` | `strategy.entry("name", strategy.long, qty=2)` | |
| `Buy ("name") Next Bar at 100 Limit;` | `strategy.entry("name", strategy.long, limit=100)` | |
| `Buy ("name") Next Bar at 100 Stop;` | `strategy.entry("name", strategy.long, stop=100)` | |
| `SetStopLoss(dollarAmount);` | `strategy.exit("exit", stop=price)` | PL takes dollar amount; Pine takes price level |
| `SetProfitTarget(dollarAmount);` | `strategy.exit("exit", limit=price)` | Same dollar-vs-price difference |
| `SetStopContract;` / `SetStopPosition;` | No direct equivalent | Must calculate manually in Pine |

**Plotting**

| PowerLanguage | Pine Script | Notes |
|---|---|---|
| `Plot1(value, "name");` | `plot(value, "name")` | Pine returns plot ID for `fill()` |
| `SetPlotColor(1, Red);` | `plot(value, color=color.red)` | Pine sets color inline, not separately |
| `SetPlotWidth(1, 2);` | `plot(value, linewidth=2)` | |
| `NoPlot(1);` | `plot(na)` | Plot `na` to hide |

**Control Flow**

| PowerLanguage | Pine Script | Notes |
|---|---|---|
| `If Cond Then Begin ... End;` | `if cond\n    ...` | Pine uses indentation, no begin/end |
| `If Cond Then ... Else ...;` | `if cond\n    ...\nelse\n    ...` | |
| `For i = 0 To N Begin ... End;` | `for i = 0 to N\n    ...` | |
| `While Cond Begin ... End;` | `while cond\n    ...` | |
| `Switch (X) ... Default: ...;` | `switch X\n    val1 => ...\n    => ...` | Pine uses `=>` syntax |
| `Once ... ;` | `if barstate.isfirst\n    ...` | |

**Other**

| PowerLanguage | Pine Script | Notes |
|---|---|---|
| `MarketPosition` | `strategy.position_size` | PL: 1/0/-1; Pine: positive/0/negative (actual qty) |
| `EntryPrice` | `strategy.position_avg_price` | |
| `CurrentContracts` | `math.abs(strategy.position_size)` | |
| `BarsSinceEntry` | Manual calculation needed | `bar_index - entryBar` |
| `Print(...)` | `label.new(...)` or `log.info(...)` | Pine has no direct Print equivalent |
| `Commentary(...)` | No equivalent | Use labels or tooltips |
| `Alert(...)` | `alert()` or `alertcondition()` | `alertcondition()` only in indicators |

#### Part 2: Semantic Differences & Gotchas

**Critical differences that cause bugs if ignored:**

1. **PL `Sell` ≠ Pine short.** PL `Sell` exits a long position. Pine's equivalent is `strategy.close()`, NOT `strategy.entry("", strategy.short)`. Same for `BuyToCover`.

2. **Multi-data is fundamentally different.** PL uses `Data2`, `Data3` slots configured in the chart. Pine uses `request.security(symbol, timeframe, expression)` — requires explicit symbol and timeframe strings. No direct 1:1 mapping; conversion requires knowing what symbol/timeframe Data2 represents.

3. **Dollar amounts vs price levels.** PL `SetStopLoss(500)` means "$500 risk per contract." Pine `strategy.exit(stop=price)` takes an actual price. Conversion requires: `stopPrice = strategy.position_avg_price - dollarAmount / syminfo.pointvalue`.

4. **Stochastic parameter mismatch.** PL's `Stochastic()` takes 11 parameters and returns multiple outputs via function reference. Pine's `ta.stoch()` returns only %K; %D must be computed separately with `ta.sma()`.

5. **Bar numbering.** PL `BarNumber` is 1-based. Pine `bar_index` is 0-based. Off-by-one errors in lookback calculations.

6. **Position size semantics.** PL `MarketPosition` returns 1/0/-1 (direction only). Pine `strategy.position_size` returns actual quantity (positive for long, negative for short). To get PL-style: `math.sign(strategy.position_size)`.

7. **Execution model.** PL can execute on every tick or on bar close (configurable). Pine executes on bar close (historical) and every tick (realtime) — different defaults may cause logic differences.

8. **PMM (Portfolio Money Management) has no Pine equivalent.** Flag to user that any PMM logic must be reimplemented manually or dropped.

9. **PL Functions (.elf) → Pine user-defined functions.** PL functions are separate compiled files. Pine uses inline function definitions or library imports. Multi-output functions need restructuring.

10. **`Value1..Value99` must be renamed.** Pine has no pre-declared variables. All must be converted to descriptive named variables with explicit types.

#### Part 3: Conversion Checklists

**Pre-conversion checklist (PL → Pine):**
- [ ] Identify Pine Script version target (`@version=5` or `@version=6`)
- [ ] Identify script type (`strategy()` or `indicator()`)
- [ ] List all `Data2`/`Data3` references — ask user for symbol+timeframe
- [ ] List all PL Function calls — determine Pine equivalents or inline replacements
- [ ] List all PMM calls — flag as unsupported

**Post-conversion checklist (PL → Pine):**
- [ ] All `Value1..99` / `Condition1..99` replaced with named, typed variables
- [ ] All `Data2`/`Data3` converted to `request.security()` calls
- [ ] `Sell` mapped to `strategy.close()`, NOT `strategy.entry(short)`
- [ ] `BuyToCover` mapped to `strategy.close()`, NOT `strategy.entry(long)`
- [ ] `SetStopLoss`/`SetProfitTarget` dollar amounts converted to price levels
- [ ] `Begin...End` blocks converted to indentation-based blocks
- [ ] `Once` converted to `if barstate.isfirst`
- [ ] `MarketPosition` checks account for size-vs-direction difference
- [ ] `//@version=N` declared as first line
- [ ] `strategy()` or `indicator()` declaration present with title

**Pre-conversion checklist (Pine → PL):**
- [ ] Identify script type (Signal or Indicator)
- [ ] List all `request.security()` calls — determine Data slot mapping
- [ ] List all library imports — determine PL Function equivalents
- [ ] List all UDTs/methods — restructure for PL's flat model

**Post-conversion checklist (Pine → PL):**
- [ ] All `var`/`varip` converted to `Variables:` / `IntraBarPersist` declarations
- [ ] All `input.*()` converted to `Inputs:` declarations
- [ ] All `strategy.entry()` long → `Buy`, short → `SellShort`
- [ ] All `strategy.close()` → `Sell` (for long exits) or `BuyToCover` (for short exits)
- [ ] All `strategy.exit(stop=price)` → `SetStopLoss(dollarAmount)` with price-to-dollar conversion
- [ ] Indentation blocks wrapped in `Begin...End;`
- [ ] `bar_index` → `BarNumber - 1` or adjusted for 1-based
- [ ] All Pine lowercase built-ins mapped to PL equivalents

---

## Testing Strategy

### For `pinescript-reference`:
- Ask Claude to write Pine Script indicators and strategies; verify output is syntactically correct
- Compare generated code against Pine Script compiler (paste into TradingView editor)
- Test gotcha awareness: ask Claude about repainting, na handling, series vs simple

### For `powerlanguage-pinescript-conversion`:
- Convert the 5 mini-strategies in `test_strategies.txt` from PL to Pine; verify Pine output compiles
- Convert sample Pine scripts to PL; verify PL output compiles in MultiCharts
- Test edge cases: multi-data, PMM, Stochastic, SetStopLoss dollar-to-price conversion

### Compile-verification test files (new):
- `tests/test_pine_from_pl.txt` — Pine Script output from converting PL test strategies (verify in TradingView)
- `tests/test_pl_from_pine.txt` — PL output from converting Pine examples (verify in MultiCharts)

---

## File Changes Summary

**New files:**
- `skills/pinescript-reference/SKILL.md`
- `skills/powerlanguage-pinescript-conversion/SKILL.md`
- `tests/test_pine_from_pl.txt` (Pine compile-test)
- `tests/test_pl_from_pine.txt` (PL compile-test)

**Modified files:**
- `.claude-plugin/plugin.json` — register 2 new skills
- `README.md` — document new skills and conversion capability
- `package.json` — version bump

**No changes to existing skills.** The new skills reference the existing ones but do not modify them.

---

## Future Extensibility

This design supports future language pairs as separate skills:
- `powerlanguage-python-conversion`
- `pinescript-python-conversion`

Each pair gets its own SKILL.md with its own mapping table and checklists. The language reference skills (`powerlanguage-syntax`, `pinescript-reference`) are shared across conversion skills.
