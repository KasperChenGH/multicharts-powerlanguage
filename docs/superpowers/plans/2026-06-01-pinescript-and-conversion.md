# Pine Script Reference & PL-Pine Conversion — Implementation Plan

> **SUPERSEDED (historical document):** the `pinescript-reference` skill described here was implemented, then split into `pinescript-core`, `pinescript-builtins`, and `pinescript-visual` in commit e96a64f (v0.4.0). Skill names and counts below reflect the state as of 2026-06-01.

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add two new skills — `pinescript-reference` and `powerlanguage-pinescript-conversion` — so Claude can write Pine Script and convert code bidirectionally between PowerLanguage and Pine Script.

**Architecture:** Two new SKILL.md files under `skills/`, following the same single-file pattern as `powerlanguage-syntax`. No scripts, no generation pipeline — all content is hand-written. Plugin metadata updated to register both skills.

**Tech Stack:** Markdown with YAML frontmatter (Claude Code plugin skill format)

---

## File Map

| Action | File | Purpose |
|---|---|---|
| Create | `skills/pinescript-reference/SKILL.md` | Pine Script language reference |
| Create | `skills/powerlanguage-pinescript-conversion/SKILL.md` | Bidirectional PL ↔ Pine mapping |
| Create | `tests/test_pine_from_pl.txt` | Pine Script conversion test (5 strategies from PL) |
| Create | `tests/test_pl_from_pine.txt` | PL conversion test (Pine examples back to PL) |
| Modify | `.claude-plugin/plugin.json` | Add keywords for new skills |
| Modify | `README.md` | Document new skills, add conversion example |
| Modify | `package.json` | Version bump to 0.2.0 |
| Modify | `.claude-plugin/marketplace.json` | Version bump to 0.2.0 |

---

### Task 1: Create `pinescript-reference` SKILL.md — Versioning, Script Types, Type System, Declarations

**Files:**
- Create: `skills/pinescript-reference/SKILL.md`

- [ ] **Step 1: Create the skill file with frontmatter and sections 1-4**

Create `skills/pinescript-reference/SKILL.md` with the following content:

```markdown
---
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
---

# Pine Script Reference

## Versioning

Every Pine Script starts with a version annotation as the first line. This plugin targets v5 and v6.

```pine
//@version=5
indicator("My Indicator", overlay=true)
```

- `//@version=5` — most widely used version. Introduced namespaced functions (`ta.sma` instead of `sma`), `input.*()` typed inputs, and `var`/`varip` keywords.
- `//@version=6` — latest version. Adds `force_overlay` parameter, `enum` types, `map.new()` typed maps, and changes to `request.security()` behavior. Scripts on v5 continue to work; v6 is opt-in.

Always specify the version. Omitting it defaults to an old version and causes confusing errors.

## Script Types

Pine has three script types, declared immediately after the version annotation:

- **`indicator(title, overlay, ...)`** — computes and plots values. Cannot place orders. Can use `alertcondition()`. Use for oscillators, overlays, and visual tools.
- **`strategy(title, overlay, default_qty_type, default_qty_value, ...)`** — can place simulated orders via `strategy.*` functions. Cannot use `alertcondition()`. Use for backtestable trading systems.
- **`library(title, overlay)`** — exports functions for use by other scripts via `import`. Cannot use `input.*()` or `strategy.*`. Use for shared utilities.

```pine
//@version=5
strategy("RSI Strategy", overlay=true, default_qty_type=strategy.percent_of_equity, default_qty_value=100)
```

Key properties for `strategy()`:
- `default_qty_type` — `strategy.fixed`, `strategy.cash`, `strategy.percent_of_equity`
- `default_qty_value` — default order size
- `initial_capital` — starting capital for backtesting
- `commission_type`, `commission_value` — trading costs
- `pyramiding` — max number of entries in the same direction (default 0 = no pyramiding)

## Type System

### Fundamental types

| Type | Example | Notes |
|---|---|---|
| `int` | `14` | Integer |
| `float` | `1.5` | Decimal |
| `bool` | `true`, `false` | Lowercase |
| `string` | `"hello"` | Double-quoted |
| `color` | `color.red`, `#FF0000` | Named or hex |

### Type qualifiers

Pine has a type qualifier system that controls when a value is known:

| Qualifier | Meaning | Example |
|---|---|---|
| `const` | Known at compile time | `14`, `"hello"` |
| `input` | Known at input time (user sets once) | `input.int(14)` |
| `simple` | Known at bar zero, same for all bars | `syminfo.pointvalue` |
| `series` | Can change on every bar | `close`, `ta.sma(close, 14)` |

Hierarchy: `const` < `input` < `simple` < `series`. A function that accepts `simple int` will reject a `series int`. This is the most common source of Pine Script compile errors.

Example: `ta.sma(close, length)` requires `length` to be `simple int`. If you compute length dynamically (`length = close > open ? 14 : 20`), it becomes `series int` and the call fails.

### na

`na` represents "not available" — Pine's null. Most operations with `na` return `na`.

```pine
x = na              // x is na (type inferred from context)
y = na(x)           // true if x is na
z = nz(x, 0.0)     // returns x if not na, else 0.0
w = fixnan(x)       // replaces na with last non-na value
```

## Declarations

### Variables

```pine
//@version=5
indicator("Example")

// Recalculated every bar (no persistence)
myVal = close - open

// Initialized once, persists across bars (like PL Variables)
var float runningTotal = 0.0
runningTotal += close - open

// Persists across bars AND intrabar ticks (like PL IntraBarPersist)
varip float tickCount = 0.0
tickCount += 1
```

- No keyword → recalculated every bar. This is the default.
- `var` → initialized on the first bar only, value persists. Equivalent to PowerLanguage `Variables:`.
- `varip` → like `var` but also persists between ticks within the same bar. Equivalent to PowerLanguage `IntraBarPersist`.

### Inputs

Pine inputs are typed functions, not declarations:

```pine
length = input.int(14, "RSI Length", minval=1, maxval=100)
threshold = input.float(1.5, "Threshold", step=0.1)
useFilter = input.bool(true, "Use Volume Filter")
src = input.source(close, "Source")
sym = input.symbol("AAPL", "Symbol")
tf = input.timeframe("D", "Timeframe")
```

Each `input.*()` function returns a `input`-qualified value (between `const` and `simple` in the type hierarchy).
```

- [ ] **Step 2: Verify the file was created and has valid YAML frontmatter**

Open the file and confirm:
1. YAML frontmatter between `---` delimiters parses correctly
2. `name:` is `pinescript-reference`
3. `description:` is present and non-empty
4. Content begins with `# Pine Script Reference`

- [ ] **Step 3: Commit**

```bash
git add skills/pinescript-reference/SKILL.md
git commit -m "feat: add pinescript-reference skill — versioning, types, declarations"
```

---

### Task 2: Extend `pinescript-reference` — Built-in Namespaces & Functions

**Files:**
- Modify: `skills/pinescript-reference/SKILL.md`

- [ ] **Step 1: Append the built-in namespaces section**

Append the following to the end of `skills/pinescript-reference/SKILL.md`:

```markdown
## Built-in Namespaces & Functions

### ta.* — Technical Analysis

**Moving Averages**

| Function | Signature | Returns |
|---|---|---|
| `ta.sma` | `ta.sma(source, length)` | Simple moving average |
| `ta.ema` | `ta.ema(source, length)` | Exponential moving average |
| `ta.wma` | `ta.wma(source, length)` | Weighted moving average |
| `ta.vwma` | `ta.vwma(source, length)` | Volume-weighted moving average |
| `ta.rma` | `ta.rma(source, length)` | Running moving average (Wilder's smoothing) |
| `ta.swma` | `ta.swma(source)` | Symmetrically weighted moving average (fixed 4-bar) |
| `ta.alma` | `ta.alma(source, length, offset, sigma)` | Arnaud Legoux moving average |
| `ta.hma` | `ta.hma(source, length)` | Hull moving average |

**Oscillators**

| Function | Signature | Returns |
|---|---|---|
| `ta.rsi` | `ta.rsi(source, length)` | Relative strength index (0-100) |
| `ta.stoch` | `ta.stoch(source, high, low, length)` | Raw %K of stochastic. Does NOT return %D — compute %D separately with `ta.sma()` |
| `ta.cci` | `ta.cci(source, length)` | Commodity channel index |
| `ta.mfi` | `ta.mfi(series, length)` | Money flow index |
| `ta.cmo` | `ta.cmo(series, length)` | Chande momentum oscillator |

**Trend**

| Function | Signature | Returns |
|---|---|---|
| `ta.macd` | `ta.macd(source, fastlen, slowlen, siglen)` | Returns `[macdLine, signalLine, histogram]` tuple |
| `ta.supertrend` | `ta.supertrend(factor, atrPeriod)` | Returns `[supertrend, direction]` tuple |

Note: Pine has no single `ta.adx()` that matches PL's `ADX(Length)`. Use `ta.dmi()`:

```pine
[diplus, diminus, adxValue] = ta.dmi(diLen, adxSmoothing)
```

**Volatility**

| Function | Signature | Returns |
|---|---|---|
| `ta.atr` | `ta.atr(length)` | Average true range |
| `ta.bb` | `ta.bb(source, length, mult)` | Returns `[middle, upper, lower]` tuple |
| `ta.kc` | `ta.kc(source, length, mult)` | Returns `[middle, upper, lower]` Keltner Channel |

**Volume**

| Function | Signature | Returns |
|---|---|---|
| `ta.obv` | `ta.obv` | On-balance volume (no parentheses — it's a variable) |
| `ta.vwap` | `ta.vwap(source)` | Volume-weighted average price |

**Crossovers & Lookbacks**

| Function | Signature | Returns |
|---|---|---|
| `ta.crossover` | `ta.crossover(a, b)` | `true` when `a` crosses above `b` |
| `ta.crossunder` | `ta.crossunder(a, b)` | `true` when `a` crosses below `b` |
| `ta.highest` | `ta.highest(source, length)` | Highest value over `length` bars |
| `ta.lowest` | `ta.lowest(source, length)` | Lowest value over `length` bars |
| `ta.change` | `ta.change(source, length)` | Difference: `source - source[length]` |
| `ta.mom` | `ta.mom(source, length)` | Momentum (same as `ta.change`) |
| `ta.pivothigh` | `ta.pivothigh(source, leftbars, rightbars)` | Pivot high price or `na` |
| `ta.pivotlow` | `ta.pivotlow(source, leftbars, rightbars)` | Pivot low price or `na` |
| `ta.valuewhen` | `ta.valuewhen(condition, source, occurrence)` | Value of `source` when `condition` was true |
| `ta.barssince` | `ta.barssince(condition)` | Bars since `condition` was last true |

### strategy.* — Strategy Orders & Position Info

**Order functions (strategy scripts only)**

```pine
// Enter long
strategy.entry("Long", strategy.long, qty=1, limit=100.0, stop=95.0, comment="entry")

// Enter short
strategy.entry("Short", strategy.short)

// Exit a specific entry with stop/profit
strategy.exit("Exit Long", from_entry="Long", stop=stopPrice, limit=targetPrice,
              trail_points=50, trail_offset=10)

// Close a specific entry at market
strategy.close("Long", comment="close")

// Close all positions at market
strategy.close_all(comment="close all")

// Standalone order (does not affect position tracking like entry/exit)
strategy.order("Order1", strategy.long, qty=1, limit=100.0)

// Cancel pending orders
strategy.cancel("Order1")
strategy.cancel_all()
```

**Position info variables**

| Variable | Type | Description |
|---|---|---|
| `strategy.position_size` | `float` | Current position size. Positive = long, negative = short, 0 = flat |
| `strategy.position_avg_price` | `float` | Average entry price of current position |
| `strategy.opentrades` | `int` | Number of open trades |
| `strategy.closedtrades` | `int` | Number of closed trades |
| `strategy.equity` | `float` | Current equity (initial capital + net profit + open P&L) |
| `strategy.netprofit` | `float` | Net profit from closed trades |
| `strategy.openprofit` | `float` | Unrealized P&L of open positions |
| `strategy.wintrades` | `int` | Number of winning trades |
| `strategy.losstrades` | `int` | Number of losing trades |

### request.* — External Data

```pine
// Multi-timeframe: get daily close while on a 1H chart
dailyClose = request.security(syminfo.tickerid, "D", close)

// Multi-symbol: get another symbol's data
spyClose = request.security("SPY", timeframe.period, close)

// Lower timeframe data (v5+)
ltfData = request.security_lower_tf(syminfo.tickerid, "1", close)

// Fundamental data
pe = request.financial(syminfo.tickerid, "EARNINGS_PER_SHARE_BASIC_TTM", "FQ")
```

`request.security()` is Pine's equivalent of PowerLanguage's multi-data series (`Data2`, `Close of Data2`), but the model is fundamentally different — Pine specifies symbol + timeframe explicitly, PL uses preconfigured data slots.

### math.* — Math Functions

| Function | Signature | Description |
|---|---|---|
| `math.abs` | `math.abs(x)` | Absolute value |
| `math.ceil` | `math.ceil(x)` | Round up |
| `math.floor` | `math.floor(x)` | Round down |
| `math.round` | `math.round(x, precision)` | Round to N decimals |
| `math.log` | `math.log(x)` | Natural logarithm |
| `math.log10` | `math.log10(x)` | Base-10 logarithm |
| `math.pow` | `math.pow(base, exp)` | Power |
| `math.sqrt` | `math.sqrt(x)` | Square root |
| `math.max` | `math.max(a, b)` | Maximum |
| `math.min` | `math.min(a, b)` | Minimum |
| `math.avg` | `math.avg(a, b, ...)` | Average of arguments |
| `math.sign` | `math.sign(x)` | Sign: -1, 0, or 1 |

Constants: `math.pi`, `math.e`

### str.* — String Functions

| Function | Signature | Description |
|---|---|---|
| `str.tostring` | `str.tostring(value, format)` | Convert to string |
| `str.format` | `str.format(formatString, args...)` | Format string (like printf) |
| `str.length` | `str.length(s)` | String length |
| `str.contains` | `str.contains(s, substr)` | Check if contains substring |
| `str.replace` | `str.replace(s, old, new, count)` | Replace occurrences |
| `str.split` | `str.split(s, separator)` | Split into string array |
| `str.upper` | `str.upper(s)` | Uppercase |
| `str.lower` | `str.lower(s)` | Lowercase |
| `str.substring` | `str.substring(s, begin, end)` | Extract substring |

### array.* — Arrays

```pine
// Create
var myArr = array.new_float(0)

// Add/remove
array.push(myArr, close)
lastVal = array.pop(myArr)

// Access
val = array.get(myArr, 0)
array.set(myArr, 0, 99.0)

// Info
sz = array.size(myArr)

// Aggregates
avg = array.avg(myArr)
total = array.sum(myArr)
hi = array.max(myArr)
lo = array.min(myArr)

// Sort
array.sort(myArr, order.ascending)
```

Type-specific constructors: `array.new_float()`, `array.new_int()`, `array.new_bool()`, `array.new_string()`, `array.new_color()`

### color.* — Colors

```pine
// Named colors
color.red, color.green, color.blue, color.white, color.black,
color.orange, color.yellow, color.purple, color.aqua, color.gray

// Custom colors
myColor = color.new(color.red, 50)        // 50% transparent red
myRgb = color.rgb(255, 128, 0, 0)         // orange, fully opaque

// Extract components
r = color.r(myColor)
g = color.g(myColor)
b = color.b(myColor)
```
```

- [ ] **Step 2: Verify the appended content is well-formed**

Read the file and confirm all markdown tables render correctly and no syntax is broken.

- [ ] **Step 3: Commit**

```bash
git add skills/pinescript-reference/SKILL.md
git commit -m "feat: add built-in namespaces and functions to pinescript-reference"
```

---

### Task 3: Extend `pinescript-reference` — Plotting, Control Flow, UDFs, Bar State, Gotchas

**Files:**
- Modify: `skills/pinescript-reference/SKILL.md`

- [ ] **Step 1: Append the remaining sections**

Append the following to the end of `skills/pinescript-reference/SKILL.md`:

```markdown
## Plotting

```pine
//@version=5
indicator("Plot Example", overlay=true)

// Basic line plot
plot(ta.sma(close, 20), "SMA 20", color=color.blue, linewidth=2)

// Histogram
plot(close - open, "Body", style=plot.style_histogram, color=close > open ? color.green : color.red)

// Shape markers
plotshape(ta.crossover(ta.sma(close, 10), ta.sma(close, 20)), "Buy Signal",
          shape.triangleup, location.belowbar, color.green, size=size.small)

// Character markers
plotchar(ta.crossunder(ta.sma(close, 10), ta.sma(close, 20)), "Sell Signal",
         "X", location.abovebar, color.red)

// Arrow markers
plotarrow(close - open, "Direction", colorup=color.green, colordown=color.red)

// Background color
bgcolor(ta.rsi(close, 14) > 70 ? color.new(color.red, 90) : na)

// Bar color
barcolor(close > open ? color.green : color.red)

// Horizontal line
hline(70, "Overbought", color=color.red, linestyle=hline.style_dashed)
hline(30, "Oversold", color=color.green, linestyle=hline.style_dashed)

// Fill between plots
p1 = plot(ta.sma(close, 10), "Fast MA")
p2 = plot(ta.sma(close, 20), "Slow MA")
fill(p1, p2, color=color.new(color.blue, 90))
```

Plot styles: `plot.style_line`, `plot.style_stepline`, `plot.style_histogram`, `plot.style_cross`, `plot.style_area`, `plot.style_circles`, `plot.style_columns`

## Control Flow

```pine
// If/else
if close > open
    label.new(bar_index, high, "Bull")
else if close < open
    label.new(bar_index, low, "Bear")
else
    label.new(bar_index, close, "Doji")

// For loop (to)
sum = 0.0
for i = 0 to 9
    sum += close[i]

// For loop (in) — iterate over array
for val in myArray
    sum += val

// While loop
i = 0
while i < 10 and close[i] > open[i]
    i += 1

// Switch
action = switch
    close > ta.sma(close, 20) => "above"
    close < ta.sma(close, 20) => "below"
    => "at"

// Ternary
direction = close > open ? 1 : -1
```

Pine uses indentation for blocks — there is no `begin/end` or `{/}`. Each indented line belongs to the parent `if`/`for`/`while`/`switch` block.

## User-Defined Functions & Types

### Functions

```pine
// Single-line function
smaCustom(src, len) =>
    ta.sma(src, len)

// Multi-line function
myStrategy(src, fastLen, slowLen) =>
    fast = ta.sma(src, fastLen)
    slow = ta.sma(src, slowLen)
    longSignal = ta.crossover(fast, slow)
    shortSignal = ta.crossunder(fast, slow)
    [longSignal, shortSignal]   // return tuple

// Call with tuple destructuring
[goLong, goShort] = myStrategy(close, 10, 20)
```

### User-Defined Types (UDTs)

```pine
type OrderInfo
    string id
    float price
    int qty

var OrderInfo lastOrder = OrderInfo.new("", 0.0, 0)
lastOrder := OrderInfo.new("buy1", close, 1)
```

### Methods

```pine
method toStr(OrderInfo this) =>
    str.format("Order {0} @ {1} x {2}", this.id, this.price, this.qty)

label.new(bar_index, high, lastOrder.toStr())
```

### Libraries

```pine
//@version=5
library("MyLib")

export smaCustom(float src, simple int len) =>
    ta.sma(src, len)
```

Usage in another script:
```pine
import username/MyLib/1 as ml
plot(ml.smaCustom(close, 20))
```

## Bar State & Time

### Bar state

| Variable | Type | Description |
|---|---|---|
| `bar_index` | `int` | Current bar index (0-based, starts from leftmost bar) |
| `barstate.isfirst` | `bool` | True on the very first bar |
| `barstate.islast` | `bool` | True on the last bar |
| `barstate.isrealtime` | `bool` | True on realtime bars (live data) |
| `barstate.isconfirmed` | `bool` | True when the bar has closed (confirmed) |
| `barstate.isnew` | `bool` | True on the first tick of a new bar |
| `last_bar_index` | `int` | Index of the last bar in the dataset |

### Time

| Variable | Type | Description |
|---|---|---|
| `time` | `int` | Bar open time in UNIX ms |
| `time_close` | `int` | Bar close time in UNIX ms |
| `year` | `int` | Year |
| `month` | `int` | Month (1-12) |
| `dayofmonth` | `int` | Day of month (1-31) |
| `dayofweek` | `int` | Day of week (1=Sun, 7=Sat) |
| `hour` | `int` | Hour (0-23) |
| `minute` | `int` | Minute (0-59) |
| `second` | `int` | Second (0-59) |

### Symbol info

| Variable | Type | Description |
|---|---|---|
| `syminfo.ticker` | `string` | Ticker without exchange prefix |
| `syminfo.tickerid` | `string` | Full ticker with exchange prefix |
| `syminfo.currency` | `string` | Currency of the symbol |
| `syminfo.pointvalue` | `float` | Point value (for futures contracts) |
| `syminfo.mintick` | `float` | Minimum tick size |
| `syminfo.type` | `string` | Symbol type ("stock", "futures", "forex", etc.) |
| `timeframe.period` | `string` | Current chart timeframe ("D", "60", "W", etc.) |
| `timeframe.multiplier` | `int` | Timeframe multiplier |

## Common Gotchas

### 1. Repainting

`request.security()` can return the current (unconfirmed) bar's value on realtime bars, which changes as new ticks arrive. On historical bars it uses the confirmed close. This mismatch is called repainting.

**Fix:** Use `barstate.isconfirmed` guard or request the previous bar:
```pine
// Safe: always uses confirmed data
safeClose = request.security(syminfo.tickerid, "D", close[1], barmerge.gaps_off, barmerge.lookahead_on)
```

### 2. na propagation

Most operations with `na` return `na`. This silently breaks calculations.

```pine
x = na
y = x + 1      // y is na, not 1
z = nz(x, 0)   // z is 0 — use nz() to provide default
```

Always guard with `nz()`, `na()` checks, or `fixnan()` when working with values that might be `na` (like `ta.pivothigh()` which returns `na` on most bars).

### 3. Series vs simple context

Some built-in functions require `simple` parameters. Passing a `series` value causes a compile error.

```pine
// FAILS: len is series int (changes per bar)
len = close > open ? 14 : 20
sma = ta.sma(close, len)  // Error: cannot use series int as simple int

// FIX: use a fixed input
len = input.int(14, "Length")
sma = ta.sma(close, len)  // OK: input int qualifies as simple
```

Functions that require `simple int` for length: `ta.sma`, `ta.ema`, `ta.rsi`, `ta.atr`, `ta.bb`, `ta.stoch`, `ta.cci`, and most other `ta.*` functions.

### 4. max_bars_back

Pine limits how far back you can look with `[N]`. For large lookbacks, set `max_bars_back()` explicitly:

```pine
max_bars_back(close, 5000)
val = close[4999]  // OK with the above declaration
```

Without it, large `[N]` offsets cause a runtime error.

### 5. Strategy vs indicator restrictions

| Feature | `indicator()` | `strategy()` |
|---|---|---|
| `strategy.entry/exit/close` | No | Yes |
| `alertcondition()` | Yes | No |
| `plot()` | Yes | Yes |
| Max plots | 64 | 64 |
| `request.security()` | Yes | Yes |

Do not use `alertcondition()` in a strategy script or `strategy.*` in an indicator script — both cause compile errors.

### 6. Execution model

- **Historical bars:** Script runs once per bar, after the bar closes. `close` is the final closing price.
- **Realtime bars:** Script runs on every tick. `close` is the current (last) price, which changes.
- `barstate.isconfirmed` is `true` only after a bar closes. Use it to avoid recalculating on every tick.
- `barstate.isrealtime` distinguishes live bars from historical playback.

This differs from PowerLanguage where the execution mode (bar close vs every tick) is configurable per script.
```

- [ ] **Step 2: Verify the complete file**

Read the full `skills/pinescript-reference/SKILL.md` and confirm:
1. All 10 sections from the spec are present (Versioning, Script Types, Type System, Declarations, Built-in Namespaces, Plotting, Control Flow, UDFs, Bar State, Gotchas)
2. No broken markdown tables or unclosed code blocks
3. All Pine Script code examples use correct syntax

- [ ] **Step 3: Commit**

```bash
git add skills/pinescript-reference/SKILL.md
git commit -m "feat: add plotting, control flow, UDFs, bar state, and gotchas to pinescript-reference"
```

---

### Task 4: Create `powerlanguage-pinescript-conversion` SKILL.md

**Files:**
- Create: `skills/powerlanguage-pinescript-conversion/SKILL.md`

- [ ] **Step 1: Create the conversion skill file**

Create `skills/powerlanguage-pinescript-conversion/SKILL.md` with the full content from the spec: YAML frontmatter, Part 1 (concept mapping tables for Declarations, Data Access, Indicators, Strategy Orders, Plotting, Control Flow, Other), Part 2 (10 semantic differences & gotchas), and Part 3 (pre/post-conversion checklists for both directions).

The file should contain exactly what is specified in the design spec at `docs/superpowers/specs/2026-06-01-pinescript-and-conversion-design.md`, sections "Part 1: Concept Mapping Table", "Part 2: Semantic Differences & Gotchas", and "Part 3: Conversion Checklists".

Structure:

```markdown
---
name: powerlanguage-pinescript-conversion
description: >-
  Use when converting, translating, porting, or migrating code between
  MultiCharts PowerLanguage and TradingView Pine Script, in either direction.
  Contains concept mapping tables, semantic difference documentation, and
  pre/post-conversion checklists. References pinescript-reference and
  powerlanguage-syntax for language-specific details.
---

# PowerLanguage ↔ Pine Script Conversion

## How to use this skill

This skill provides mapping tables and checklists for converting code between
MultiCharts PowerLanguage and TradingView Pine Script. For language-specific
syntax details, see also:
- `powerlanguage-syntax` — PowerLanguage declarations, control flow, built-in functions
- `pinescript-reference` — Pine Script type system, namespaces, built-in functions

## Concept Mapping

### Declarations
[... table from spec ...]

### Data Access
[... table from spec ...]

### Technical Indicators
[... table from spec ...]

### Strategy Orders
[... table from spec ...]

### Plotting
[... table from spec ...]

### Control Flow
[... table from spec ...]

### Other
[... table from spec ...]

## Semantic Differences & Gotchas
[... numbered list of 10 gotchas from spec ...]

## Conversion Checklists

### PowerLanguage → Pine Script

#### Pre-conversion
[... checklist from spec ...]

#### Post-conversion
[... checklist from spec ...]

### Pine Script → PowerLanguage

#### Pre-conversion
[... checklist from spec ...]

#### Post-conversion
[... checklist from spec ...]
```

Copy all tables and content from the spec verbatim — they have been validated during the design phase.

- [ ] **Step 2: Verify the file**

Read the file and confirm:
1. YAML frontmatter is valid with correct `name` and `description`
2. All 7 mapping table categories are present
3. All 10 semantic gotchas are present
4. All 4 checklists (PL→Pine pre/post, Pine→PL pre/post) are present

- [ ] **Step 3: Commit**

```bash
git add skills/powerlanguage-pinescript-conversion/SKILL.md
git commit -m "feat: add powerlanguage-pinescript-conversion skill"
```

---

### Task 5: Create Pine Script conversion test file

**Files:**
- Create: `tests/test_pine_from_pl.txt`

- [ ] **Step 1: Create the test file**

Convert the 5 mini-strategies from `tests/test_strategies.txt` into Pine Script. Each strategy should be a complete, compilable Pine Script strategy.

Create `tests/test_pine_from_pl.txt` with:

```pine
// test_pine_from_pl.txt — Pine Script conversions of the 5 PL test strategies
// Paste each strategy block into TradingView's Pine Editor and verify it compiles.
// Expected: no errors on any strategy.

// ================================================================
// Strategy 1: MA Crossover (from PL test_strategies.txt)
// ================================================================
//@version=5
strategy("S1 MA Crossover", overlay=true)

fastMA = ta.sma(close, 10)
slowMA = ta.sma(close, 20)

if ta.crossover(fastMA, slowMA)
    strategy.entry("S1_LE", strategy.long)

if ta.crossunder(fastMA, slowMA)
    strategy.close("S1_LE")

// ================================================================
// Strategy 2: RSI + ATR Stop + Position Detection
// ================================================================
//@version=5
strategy("S2 RSI ATR", overlay=true)

rsiVal = ta.rsi(close, 14)
atrVal = ta.atr(14)

if strategy.position_size == 0 and rsiVal < 30
    strategy.entry("S2_LE", strategy.long)

if strategy.position_size > 0
    stopPx = strategy.position_avg_price - 2 * atrVal
    strategy.exit("S2_STP", from_entry="S2_LE", stop=stopPx)
    if rsiVal > 70
        strategy.close("S2_LE", comment="S2_TGT")

// ================================================================
// Strategy 3: Bollinger Band Breakout + Volume Filter
// ================================================================
//@version=5
strategy("S3 BB Breakout", overlay=true)

[bbMiddle, bbUpper, bbLower] = ta.bb(close, 20, 2)
volAvg = ta.sma(volume, 20)

if close > bbUpper and volume > volAvg * 1.5
    strategy.entry("S3_LE", strategy.long)

if close < bbLower and volume > volAvg * 1.5
    strategy.entry("S3_SE", strategy.short)

if strategy.position_size > 0
    strategy.exit("S3_LX", from_entry="S3_LE", stop=bbLower)

if strategy.position_size < 0
    strategy.exit("S3_SX", from_entry="S3_SE", stop=bbUpper)

// ================================================================
// Strategy 4: Multi-Indicator + Risk Management
// ================================================================
//@version=5
strategy("S4 Multi-Indicator", overlay=true)

[diplus, diminus, adxVal] = ta.dmi(14, 14)
cciVal = ta.cci(close, 20)

if adxVal > 25 and ta.crossover(cciVal, -100)
    strategy.entry("S4_LE", strategy.long)

if adxVal > 25 and ta.crossunder(cciVal, 100)
    strategy.entry("S4_SE", strategy.short)

// Dollar-based stops converted to point-based
stopPoints = 500.0 / syminfo.pointvalue
profitPoints = 1000.0 / syminfo.pointvalue
strategy.exit("S4_LX", from_entry="S4_LE", loss=stopPoints, profit=profitPoints)
strategy.exit("S4_SX", from_entry="S4_SE", loss=stopPoints, profit=profitPoints)

// ================================================================
// Strategy 5: Multi-Timeframe Regime Filter
// (PL used Data2 — converted to request.security with daily timeframe)
// ================================================================
//@version=5
strategy("S5 Regime Filter", overlay=true)

regimeClose = request.security(syminfo.tickerid, "D", close)
regimeSMA = request.security(syminfo.tickerid, "D", ta.sma(close, 50))

if regimeClose > regimeSMA
    if ta.rsi(close, 14) < 30
        strategy.entry("S5_LE", strategy.long)

if strategy.position_size > 0 and ta.rsi(close, 14) > 70
    strategy.close("S5_LE", comment="S5_LX")
```

- [ ] **Step 2: Review the conversions**

Check each converted strategy against the mapping table:
1. `Average()` → `ta.sma()` — correct
2. `RSI()` → `ta.rsi()` — correct
3. `AvgTrueRange()` → `ta.atr()` — correct
4. `BollingerBand()` → `ta.bb()` with tuple destructuring — correct
5. `ADX()` → `ta.dmi()` with tuple destructuring — correct
6. `CCI()` → `ta.cci()` with source param — correct
7. `Sell` → `strategy.close()` (NOT `strategy.short`) — correct
8. `BuyToCover` → `strategy.exit()` with stop — correct
9. `SetStopLoss(dollars)` → `strategy.exit(loss=points)` with conversion — correct
10. `Close of Data2` → `request.security()` — correct

- [ ] **Step 3: Commit**

```bash
git add tests/test_pine_from_pl.txt
git commit -m "test: add Pine Script conversion test for 5 PL strategies"
```

---

### Task 6: Create PL conversion test file

**Files:**
- Create: `tests/test_pl_from_pine.txt`

- [ ] **Step 1: Create the test file**

Write 3 Pine Script strategies, convert them to PowerLanguage, and save as a compile-test file. Uses the same `If False Then Begin ... End;` guard pattern as existing PL test files.

Create `tests/test_pl_from_pine.txt` with:

```
{ test_pl_from_pine.txt -- PL conversions of Pine Script strategies }
{ Paste this whole file into a new Signal study in PowerLanguage Editor and Verify (F3). }
{ Expected: 0 errors, 0 warnings. }

Variables:
    emaFast(0), emaSlow(0),
    rsiVal(0), atrVal(0), stopPx(0),
    bbMid(0), bbUp(0), bbLow(0),
    posDir(0);

If False Then Begin

    { ================================================================ }
    { === Pine Conversion 1: EMA Crossover (from Pine ta.ema) === }
    { ================================================================ }
    emaFast = XAverage(Close, 9);
    emaSlow = XAverage(Close, 21);

    If emaFast crosses over emaSlow Then
        Buy ("P1_LE") 1 Contract Next Bar at Market;

    If emaFast crosses under emaSlow Then
        Sell ("P1_LX") 1 Contract Next Bar at Market;

    { ================================================================ }
    { === Pine Conversion 2: RSI Mean Reversion === }
    { ================================================================ }
    rsiVal = RSI(Close, 14);

    If MarketPosition = 0 and rsiVal < 25 Then
        Buy ("P2_LE") 1 Contract Next Bar at Market;

    If MarketPosition = 0 and rsiVal > 75 Then
        SellShort ("P2_SE") 1 Contract Next Bar at Market;

    If MarketPosition = 1 and rsiVal > 50 Then
        Sell ("P2_LX") 1 Contract Next Bar at Market;

    If MarketPosition = -1 and rsiVal < 50 Then
        BuyToCover ("P2_SX") 1 Contract Next Bar at Market;

    { ================================================================ }
    { === Pine Conversion 3: BB + ATR Trailing Stop === }
    { ================================================================ }
    bbUp = BollingerBand(Close, 20, 2);
    bbLow = BollingerBand(Close, 20, -2);
    atrVal = AvgTrueRange(14);

    If Close > bbUp Then
        Buy ("P3_LE") 1 Contract Next Bar at Market;

    If MarketPosition = 1 Then Begin
        stopPx = EntryPrice - 2 * atrVal;
        Sell ("P3_STP") 1 Contract Next Bar at stopPx Stop;
    End;

End;
```

- [ ] **Step 2: Verify the PL code follows all syntax rules**

Check against `powerlanguage-syntax` gotchas:
1. All variables declared before use — yes
2. No single-letter variable names (C, H, L, O, V, T) — yes
3. No variable names shadowing built-in functions — yes
4. Order labels are unique strings — yes
5. `Sell` used to exit longs, `BuyToCover` to exit shorts — yes
6. `Begin...End;` for multi-statement blocks — yes

- [ ] **Step 3: Commit**

```bash
git add tests/test_pl_from_pine.txt
git commit -m "test: add PL conversion test from Pine Script examples"
```

---

### Task 7: Update plugin metadata and README

**Files:**
- Modify: `.claude-plugin/plugin.json`
- Modify: `.claude-plugin/marketplace.json`
- Modify: `package.json`
- Modify: `README.md`

- [ ] **Step 1: Update plugin.json**

Add `"pinescript"`, `"pine-script"`, `"tradingview"`, and `"conversion"` to the `keywords` array in `.claude-plugin/plugin.json`. Update the `description` to mention Pine Script. Bump `version` to `0.2.0`.

New content:
```json
{
  "name": "multicharts-powerlanguage",
  "description": "MultiCharts PowerLanguage and TradingView Pine Script skills for Claude: platform fundamentals, language syntax, keyword reference, Pine Script reference, and bidirectional code conversion.",
  "version": "0.2.0",
  "author": { "name": "Yu-An Chen" },
  "homepage": "https://github.com/KasperChenGH/multicharts-powerlanguage",
  "repository": "https://github.com/KasperChenGH/multicharts-powerlanguage",
  "license": "MIT",
  "keywords": ["multicharts", "powerlanguage", "trading", "skills", "easylanguage", "keywords-reference", "pinescript", "pine-script", "tradingview", "conversion"]
}
```

- [ ] **Step 2: Update marketplace.json**

Bump version to `0.2.0` and update description in `.claude-plugin/marketplace.json`:

```json
{
  "name": "multicharts-powerlanguage-dev",
  "description": "MultiCharts PowerLanguage and TradingView Pine Script skills marketplace",
  "owner": { "name": "Yu-An Chen" },
  "plugins": [
    {
      "name": "multicharts-powerlanguage",
      "description": "MultiCharts PowerLanguage and TradingView Pine Script skills for Claude: fundamentals, syntax, keywords reference, Pine Script reference, and bidirectional code conversion.",
      "version": "0.2.0",
      "source": "./"
    }
  ]
}
```

- [ ] **Step 3: Update package.json**

```json
{
  "name": "multicharts-powerlanguage",
  "version": "0.2.0"
}
```

- [ ] **Step 4: Update README.md**

Add the two new skills to the "What's inside" section, update the stats tagline, add a conversion example, update the test file table, and bump the version badge.

Changes:
1. Version badge: `0.1.3` → `0.2.0`
2. Stats tagline: add `+ Pine Script reference + bidirectional conversion`
3. Add to "What's inside" list:
   - **`pinescript-reference`** — TradingView Pine Script syntax, type system, built-in namespaces (`ta.*`, `strategy.*`, `request.*`, `math.*`, `str.*`, `array.*`), plotting, control flow, user-defined functions/types, and common gotchas (repainting, `na` handling, series vs simple context).
   - **`powerlanguage-pinescript-conversion`** — bidirectional code conversion between PowerLanguage and Pine Script with concept mapping tables, semantic difference documentation (Sell ≠ short, dollar vs price stops, multi-data vs request.security), and pre/post-conversion checklists.
4. Add conversion example after the existing example:
   ```
   ## Conversion Example

   **PowerLanguage input:**
   > Convert this to Pine Script: `Buy ("Entry") 1 Contract Next Bar at Market;`

   **Converted Pine Script:**
   ```pine
   strategy.entry("Entry", strategy.long, qty=1)
   ```
   ```
5. Add to test table:
   - `test_pine_from_pl.txt` | Pine Script | 5 strategies converted from PL
   - `test_pl_from_pine.txt` | Signal | 3 strategies converted from Pine Script

- [ ] **Step 5: Commit**

```bash
git add .claude-plugin/plugin.json .claude-plugin/marketplace.json package.json README.md
git commit -m "docs: update metadata and README for Pine Script skills (v0.2.0)"
```

---

### Task 8: Final verification

**Files:** (none modified — read-only checks)

- [ ] **Step 1: Verify all 5 skills are present**

```bash
ls skills/*/SKILL.md
```

Expected output lists 5 files:
- `skills/multicharts-fundamentals/SKILL.md`
- `skills/pinescript-reference/SKILL.md`
- `skills/powerlanguage-keywords-reference/SKILL.md`
- `skills/powerlanguage-pinescript-conversion/SKILL.md`
- `skills/powerlanguage-syntax/SKILL.md`

- [ ] **Step 2: Verify all 11 test files are present**

```bash
ls tests/test_*.txt
```

Expected: 11 files (9 existing + 2 new).

- [ ] **Step 3: Verify YAML frontmatter on new skills**

Read the first 10 lines of each new SKILL.md and confirm `name:` and `description:` are present and match the spec.

- [ ] **Step 4: Verify version consistency**

Check that `plugin.json`, `marketplace.json`, `package.json`, and `README.md` badge all show `0.2.0`.

- [ ] **Step 5: Run git log to verify clean history**

```bash
git log --oneline -10
```

Expected: 7 new commits on top of the existing history, each with a clear message.

- [ ] **Step 6: Push**

```bash
git push
```
