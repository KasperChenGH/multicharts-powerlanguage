---
name: pinescript-reference
description: >-
  Use when reading or writing TradingView Pine Script code — covers versioning
  (@version=5, @version=6), type system (series, simple, input, const),
  declarations (var, varip, input.*), built-in namespaces (ta.*, math.*, str.*,
  strategy.*, request.*, array.*, color.*, label.*, line.*, box.*, table.*,
  map.*, matrix.*, log.*), alerts (alert, alertcondition), plotting (plot,
  plotshape, bgcolor), strategy functions (strategy.entry, strategy.exit,
  strategy.close), multi-timeframe via request.security(), control flow
  (if/else, for, while, switch, ternary), user-defined functions/types/methods,
  and common gotchas (repainting, na handling, series vs simple context,
  max_bars_back, global-scope function calls, drawing object limits).
---

# Pine Script Reference

## 1. Versioning

Every Pine Script file must declare its version on the very first line using a compiler annotation:

```pine
//@version=5
indicator("My Indicator")
```

Or for version 6:

```pine
//@version=6
indicator("My Indicator")
```

**Always specify the version.** Omitting it defaults to version 1 behavior, which is almost never what you want. TradingView will warn you about version-less scripts, and many modern features simply won't compile.

### v5 vs v6 key differences

| Area | v5 | v6 |
|---|---|---|
| Type system | Implicit casting in many places | Stricter — explicit casts required more often |
| `request.security()` | Returns series directly | Returns `[value, barstate]` tuple in some overloads; cleaner multi-value syntax |
| `matrix.*` namespace | Available | Extended with more methods |
| `polyline.*` drawing | Not available | Added in v6 |
| `chart.point` type | Not available | Added in v6 for coordinate-aware drawings |
| `UDT` (user-defined types) | Available | Extended — methods can be attached directly to types |
| `import` libraries | Available | Available; v6 libraries can export methods |

**Version target:** All examples in this skill use `//@version=5`. TradingView may show a deprecation warning recommending v6 — this is non-blocking and the code compiles and runs correctly. v6 introduces syntax changes that may require adjustments; test on v6 separately if needed.

---

## 2. Script Types

Every Pine Script file must declare exactly one script type on the line immediately after the version annotation. There are three types:

### `indicator()`

Used for overlays and studies that display data but place no trades.

```pine
//@version=5
indicator(
    title           = "My Study",
    shorttitle      = "MS",
    overlay         = true,    // draw on price chart; false = separate pane
    precision       = 2,
    max_bars_back   = 500,
    max_lines_count = 50
)
```

- Supports `alertcondition()`.
- Cannot call `strategy.*` order functions — they are not available in indicator context.
- `overlay = true` renders on the main price chart; `overlay = false` opens a sub-pane.

### `strategy()`

Used when you want to backtest or forward-test trading logic. Enables the full `strategy.*` order API.

```pine
//@version=5
strategy(
    title                = "My Strategy",
    shorttitle           = "MS",
    overlay              = true,
    initial_capital      = 10000,
    default_qty_type     = strategy.percent_of_equity,
    default_qty_value    = 10,
    commission_type      = strategy.commission.percent,
    commission_value     = 0.1,
    slippage             = 1,
    pyramiding           = 0,
    calc_on_every_tick   = false
)
```

- Cannot use `alertcondition()` — use `alert()` instead.
- Order functions: `strategy.entry()`, `strategy.exit()`, `strategy.close()`, `strategy.order()`.
- `pyramiding` controls how many open entries in the same direction are allowed simultaneously.
- `calc_on_every_tick = true` recalculates intra-bar on live data, which can affect backtest realism.

### `library()`

Used to create reusable packages of functions and types that other scripts can `import`.

```pine
//@version=5
library("MyLib", overlay = false)

// exported function — callers reference it as MyLib.double()
export double(float x) =>
    x * 2.0
```

- Cannot plot or place orders on its own.
- Functions and types marked `export` are visible to importers.
- Import in another script: `import username/MyLib/1 as MyLib`.

### Key differences at a glance

| Feature | indicator | strategy | library |
|---|---|---|---|
| `strategy.*` orders | No | Yes | No |
| `alertcondition()` | Yes | No | No |
| Backtest tab | No | Yes | No |
| `export` keyword | No | No | Yes |
| Can be imported | No | No | Yes |

---

## 3. Type System

### Fundamental types

Pine Script has six fundamental data types:

| Type | Description | Literal examples |
|---|---|---|
| `int` | Integer number | `1`, `-5`, `0` |
| `float` | Floating-point number | `1.5`, `-0.01`, `3.14` |
| `bool` | Boolean | `true`, `false` |
| `string` | Text | `"hello"`, `"BUY"` |
| `color` | RGBA color | `color.red`, `color.new(color.blue, 50)` |
| `label` / `line` / `box` / `table` | Drawing objects | Created via `label.new()`, etc. |

### Type qualifiers (the "form" system)

Every value in Pine Script has both a type (e.g. `float`) and a qualifier that describes when the value is known. From most-restricted to most-flexible:

| Qualifier | When the value is known | Can be used as |
|---|---|---|
| `const` | Compile time — never changes | Anything |
| `input` | Script load time — set by the user via Inputs dialog | `const`, `input`, `simple`, `series` |
| `simple` | Bar 0 (first bar) — fixed for the script's lifetime | `simple`, `series` |
| `series` | Every bar — the most general form | `series` only |

**The hierarchy is one-way.** A `const` value can be passed anywhere a less-restrictive qualifier is expected, but a `series` value cannot be passed where `simple` is required.

```pine
//@version=5
indicator("Qualifier demo")

// This works — literal 14 is const int, which satisfies simple int
length = input.int(14, "Length")
sma_val = ta.sma(close, length)  // length is input int → accepted as simple int

// This FAILS — bar index changes every bar, so it is series int
// ta.sma(close, bar_index)  // ERROR: "simple int" argument required, got "series int"

plot(sma_val)
```

Common functions that require `simple` (not `series`) arguments include `ta.sma()`, `ta.ema()`, and most `request.*` functions for their `timeframe` parameter.

### `na`, `nz`, and `fixnan`

`na` is Pine's "not a value" sentinel — similar to `NaN` in other languages. Every series starts as `na` on bars before it has been assigned.

```pine
//@version=5
indicator("na demo")

var float running_sum = na  // explicitly uninitialized

if not na(running_sum)
    running_sum := running_sum + close
else
    running_sum := close

// nz(x, replacement) — returns replacement if x is na, otherwise x
safe_val = nz(running_sum, 0.0)

// fixnan(x) — replaces na with the last non-na value (forward-fills)
filled = fixnan(running_sum)

plot(safe_val)
```

- `na(x)` — returns `true` if `x` is `na`.
- `nz(x)` — returns `0` (or `0.0` or `""`) if `x` is `na`.
- `nz(x, y)` — returns `y` if `x` is `na`.
- `fixnan(x)` — carries the last known value forward, eliminating gaps.

---

## 4. Declarations

### Variable declaration keywords

Pine Script has three ways a variable can persist — controlled by an optional keyword before the type or name:

#### No keyword — recalculated every bar

```pine
//@version=5
indicator("No keyword")

float my_val = close * 1.05  // recomputed from scratch on every bar
plot(my_val)
```

The variable exists only for the current bar's execution. There is no memory of previous assignments.

#### `var` — persist across bars (analogous to PL `Variables:`)

```pine
//@version=5
indicator("var example")

var float highest_close = na  // initialized once on bar 0, then persists

if na(highest_close) or close > highest_close
    highest_close := close  // := is the reassignment operator

plot(highest_close)
```

- Initialized **once** at the first bar (or when `na` on first eval).
- Retains its value across all subsequent bars.
- Use `:=` (not `=`) to reassign after declaration.
- Equivalent to PL's `Variables:` block — the variable remembers its last value.

#### `varip` — persist across ticks (analogous to PL `IntraBarPersist`)

```pine
//@version=5
indicator("varip example", calc_on_every_tick = true)

varip int tick_count = 0  // increments every real-time tick, not just every closed bar

tick_count += 1
plot(tick_count)
```

- Like `var`, but updates survive intra-bar recalculations in real-time.
- On historical bars `varip` behaves identically to `var`.
- Rarely needed — only useful when `calc_on_every_tick = true` and you need intra-bar state.

### Input functions

Inputs appear in the Script Settings dialog and let users configure the script without editing code.

```pine
//@version=5
indicator("Input demo")

// Integer input
length    = input.int(14,    title = "Length",     minval = 1, maxval = 500)

// Float input
threshold = input.float(1.5, title = "Threshold",  step = 0.1)

// Boolean toggle
show_ma   = input.bool(true, title = "Show MA")

// String dropdown
mode      = input.string("EMA", title = "Mode", options = ["SMA", "EMA", "WMA"])

// Source — lets the user pick which series to use (close, open, hl2, etc.)
src       = input.source(close, title = "Source")

// Symbol — lets the user type a ticker symbol
sym       = input.symbol("NASDAQ:AAPL", title = "Symbol")

// Timeframe — lets the user pick a resolution
tf        = input.timeframe("D", title = "Timeframe")

// Color picker
line_col  = input.color(color.blue, title = "Line Color")

ma = show_ma ? ta.ema(src, length) : na
plot(ma, color = line_col)
```

| Function | Returns | Notes |
|---|---|---|
| `input.int()` | `input int` | Supports `minval`, `maxval`, `step` |
| `input.float()` | `input float` | Supports `minval`, `maxval`, `step` |
| `input.bool()` | `input bool` | Renders as a checkbox |
| `input.string()` | `input string` | Pass `options = [...]` for a dropdown |
| `input.source()` | `series float` | Returns the selected price series |
| `input.symbol()` | `input string` | Symbol string for use with `request.security()` |
| `input.timeframe()` | `input string` | Timeframe string for use with `request.security()` |
| `input.color()` | `input color` | Renders a color picker |

**Important:** `input.source()` returns a `series float`, not `input float`. This means it cannot be passed to functions that require `simple` or `const` arguments — it carries the full per-bar series.

---

## 5. Built-in Namespaces & Functions

Pine Script organizes its built-in functionality into namespaces — prefixed groups of related functions and variables. Understanding which namespace owns which capability is the fastest way to write correct code.

---

### ta.* — Technical Analysis

The `ta` namespace contains all indicator calculations. Every function operates on series data and returns series data.

#### Moving Averages

| Function | Signature | Returns |
|---|---|---|
| `ta.sma` | `ta.sma(source, length)` | `series float` — simple moving average |
| `ta.ema` | `ta.ema(source, length)` | `series float` — exponential moving average |
| `ta.wma` | `ta.wma(source, length)` | `series float` — linearly weighted moving average |
| `ta.vwma` | `ta.vwma(source, length)` | `series float` — volume-weighted moving average |
| `ta.rma` | `ta.rma(source, length)` | `series float` — Wilder/RMA smoothing (used internally by RSI) |
| `ta.swma` | `ta.swma(source)` | `series float` — symmetrically weighted 4-bar MA (fixed length) |
| `ta.alma` | `ta.alma(source, length, offset, sigma)` | `series float` — Arnaud Legoux moving average |
| `ta.hma` | `ta.hma(source, length)` | `series float` — Hull moving average |

```pine
//@version=5
indicator("Moving average examples", overlay = true)

length = input.int(20, "Length")
src    = input.source(close, "Source")

sma_line  = ta.sma(src, length)
ema_line  = ta.ema(src, length)
hull_line = ta.hma(src, length)

plot(sma_line,  "SMA",  color = color.blue)
plot(ema_line,  "EMA",  color = color.orange)
plot(hull_line, "HMA",  color = color.green)
```

#### Oscillators

| Function | Signature | Returns |
|---|---|---|
| `ta.rsi` | `ta.rsi(source, length)` | `series float` — RSI value (0–100) |
| `ta.stoch` | `ta.stoch(source, high, low, length)` | `series float` — stochastic %K only |
| `ta.cci` | `ta.cci(source, length)` | `series float` — commodity channel index |
| `ta.mfi` | `ta.mfi(source, length)` | `series float` — money flow index (0–100) |
| `ta.cmo` | `ta.cmo(source, length)` | `series float` — Chande momentum oscillator |

> **Gotcha — `ta.stoch` returns %K only.** To get a smoothed %D signal line, call `ta.sma()` on the %K result:
> ```pine
> k = ta.stoch(close, high, low, 14)
> d = ta.sma(k, 3)   // %D is just a 3-period SMA of %K
> ```

#### Trend

`ta.macd` returns a **tuple** of three series — you must destructure with `[macdLine, signalLine, histogram]`:

```pine
//@version=5
indicator("MACD example")

[macd_line, signal_line, hist] = ta.macd(close, 12, 26, 9)

plot(macd_line,   "MACD",      color = color.blue)
plot(signal_line, "Signal",    color = color.orange)
plot(hist,        "Histogram", color = color.gray, style = plot.style_histogram)
```

`ta.supertrend` also returns a **tuple** — the trend value and a direction integer (+1 or -1):

```pine
[st_value, st_direction] = ta.supertrend(3.0, 10)
// st_direction: -1 means uptrend (price above), +1 means downtrend (price below)
plot(st_value, "Supertrend", color = st_direction < 0 ? color.green : color.red)
```

| Function | Signature | Returns |
|---|---|---|
| `ta.dmi` | `ta.dmi(diLength, adxSmoothing)` | `[diPlus, diMinus, adxValue]` tuple |

> **Gotcha — no `ta.adx()`.** Pine has no standalone ADX function. Use `ta.dmi()` which returns a three-value tuple:
> ```pine
> [di_plus, di_minus, adx_val] = ta.dmi(14, 14)
> plot(adx_val, "ADX")
> ```

#### Volatility

| Function | Signature | Returns |
|---|---|---|
| `ta.atr` | `ta.atr(length)` | `series float` — average true range |
| `ta.bb` | `ta.bb(source, length, mult)` | `[middle, upper, lower]` tuple |
| `ta.kc` | `ta.kc(source, length, mult)` | `[middle, upper, lower]` tuple (Keltner channels) |

```pine
//@version=5
indicator("Bollinger Bands", overlay = true)

[bb_mid, bb_upper, bb_lower] = ta.bb(close, 20, 2.0)

plot(bb_mid,   "BB Mid",   color = color.gray)
plot(bb_upper, "BB Upper", color = color.blue)
plot(bb_lower, "BB Lower", color = color.blue)
fill(plot(bb_upper, display = display.none), plot(bb_lower, display = display.none),
     color = color.new(color.blue, 90))
```

#### Volume

| Function / Variable | Notes |
|---|---|
| `ta.obv` | Built-in variable (no parentheses) — on-balance volume running total |
| `ta.vwap` | Built-in variable (no parentheses) — volume-weighted average price, resets each session |

```pine
//@version=5
indicator("OBV and VWAP", overlay = false)

plot(ta.obv,  "OBV",  color = color.purple)
// ta.vwap is an overlay value — better plotted on price chart
```

#### Crossovers & Lookbacks

| Function | Signature | Returns |
|---|---|---|
| `ta.crossover` | `ta.crossover(a, b)` | `bool` — true on the bar where `a` crosses above `b` |
| `ta.crossunder` | `ta.crossunder(a, b)` | `bool` — true on the bar where `a` crosses below `b` |
| `ta.highest` | `ta.highest(source, length)` | `series float` — highest value in window |
| `ta.lowest` | `ta.lowest(source, length)` | `series float` — lowest value in window |
| `ta.change` | `ta.change(source, length?)` | `series float` — difference vs. N bars ago (default 1) |
| `ta.mom` | `ta.mom(source, length)` | `series float` — momentum (same as `ta.change` but explicit length) |
| `ta.pivothigh` | `ta.pivothigh(source, leftbars, rightbars)` | `series float` — pivot high price or `na` |
| `ta.pivotlow` | `ta.pivotlow(source, leftbars, rightbars)` | `series float` — pivot low price or `na` |
| `ta.valuewhen` | `ta.valuewhen(condition, source, occurrence)` | `series float` — source value the Nth time condition was true |
| `ta.barssince` | `ta.barssince(condition)` | `series int` — bars elapsed since condition was last true |

```pine
//@version=5
indicator("Crossover demo")

fast = ta.ema(close, 9)
slow = ta.ema(close, 21)

buy_signal  = ta.crossover(fast, slow)
sell_signal = ta.crossunder(fast, slow)

plotshape(buy_signal,  "Buy",  shape.triangleup,   location.belowbar, color.green)
plotshape(sell_signal, "Sell", shape.triangledown,  location.abovebar, color.red)

// How many bars since last buy?
bars_since_buy = ta.barssince(buy_signal)
```

---

### strategy.* — Strategy Orders & Position Info

The `strategy` namespace is only available in scripts declared with `strategy()`. Attempting to call order functions in an `indicator()` or `library()` context causes a compile error.

#### Order Functions

```pine
//@version=5
strategy("Order examples", overlay = true, initial_capital = 10000,
         default_qty_type = strategy.percent_of_equity, default_qty_value = 10)

fast = ta.ema(close, 9)
slow = ta.ema(close, 21)

// --- strategy.entry(id, direction, qty?, ...)
// Opens a new position (or adds to it if pyramiding > 0)
if ta.crossover(fast, slow)
    strategy.entry("Long", strategy.long)

if ta.crossunder(fast, slow)
    strategy.entry("Short", strategy.short)

// --- strategy.close(id)
// Closes the named open entry at market
// strategy.close("Long")

// --- strategy.close_all()
// Closes every open position immediately
// strategy.close_all()

// --- strategy.exit(id, from_entry, qty, qty_percent, profit, loss, limit, stop, trail_price, trail_points, trail_offset, comment)
// Attach a bracket order to an open entry
strategy.exit("Long Exit", from_entry = "Long",
              stop   = close * 0.98,   // stop-loss 2% below entry bar close
              limit  = close * 1.04,   // take-profit 4% above
              trail_offset = 10 * syminfo.mintick)  // trailing stop in ticks

// --- strategy.order(id, direction, qty, ...)
// Lower-level: places a qty-specified order without the entry/exit pairing semantics
// strategy.order("Raw Buy", strategy.long, qty = 1)

// --- strategy.cancel(id)
// Cancels a pending limit/stop order that has not yet filled
// strategy.cancel("Long Exit")

// --- strategy.cancel_all()
// Cancels all pending orders
// strategy.cancel_all()
```

#### Position Info Variables

These read-only variables reflect the current state of the strategy's position. They update after each order execution.

| Variable | Type | Description |
|---|---|---|
| `strategy.position_size` | `series float` | Current open position size (positive = long, negative = short, 0 = flat) |
| `strategy.position_avg_price` | `series float` | Average fill price of the current open position |
| `strategy.opentrades` | `series int` | Number of currently open trades |
| `strategy.closedtrades` | `series int` | Total number of closed trades |
| `strategy.equity` | `series float` | Current account equity (initial capital + net profit) |
| `strategy.netprofit` | `series float` | Cumulative realized profit/loss |
| `strategy.openprofit` | `series float` | Unrealized P&L of open position(s) |
| `strategy.wintrades` | `series int` | Count of profitable closed trades |
| `strategy.losstrades` | `series int` | Count of losing closed trades |

```pine
// Accessing position info
is_long  = strategy.position_size > 0
is_short = strategy.position_size < 0
is_flat  = strategy.position_size == 0

win_rate = strategy.closedtrades > 0
         ? strategy.wintrades / strategy.closedtrades * 100
         : 0.0
```

---

### request.* — External Data

`request.security()` is Pine's equivalent of MultiCharts's multi-data series (Data2, Data3, etc.) — it fetches data from a different symbol or timeframe and aligns it to the current chart's bar timeline.

#### `request.security()`

```pine
//@version=5
indicator("Multi-timeframe RSI", overlay = false)

// Fetch the daily close on any intraday chart
daily_close = request.security("", "D", close)
//   symbol ""     → same symbol as chart
//   timeframe "D" → daily
//   expression    → what to evaluate in that context

// Fetch RSI calculated on the daily timeframe
daily_rsi = request.security(syminfo.tickerid, "D", ta.rsi(close, 14))

plot(daily_rsi, "Daily RSI", color = color.blue)
hline(70), hline(30)
```

**Common pitfalls with `request.security()`:**

- The `timeframe` argument must be `simple string` — you cannot pass a `series` variable. Use `input.timeframe()` to let users pick it.
- Requesting a **lower** timeframe than the chart (e.g., 1-minute data on a 5-minute chart) returns only the last intra-bar value unless you use `request.security_lower_tf()`.
- **Repainting risk:** On the current unfinished bar, higher-timeframe data reflects the bar-in-progress, not a confirmed close. To avoid repainting, request the previous bar's value: `request.security("", "D", close[1])`.

#### `request.security_lower_tf()`

Returns all intra-bar values as an array rather than a single scalar:

```pine
//@version=5
indicator("Lower TF example")

// Returns array of all 1-minute closes within each 5-minute bar (when chart is 5m)
one_min_closes = request.security_lower_tf(syminfo.tickerid, "1", close)

// Process the array — e.g. count bullish 1-minute bars within each 5-minute bar
bullish_count = 0
if array.size(one_min_closes) > 1
    for i = 0 to array.size(one_min_closes) - 1
        if array.get(one_min_closes, i) > array.get(one_min_closes, math.max(0, i - 1))
            bullish_count += 1

plot(bullish_count)
```

#### `request.financial()`

Fetches fundamental financial data (earnings, revenue, etc.) from financial statements:

```pine
//@version=5
indicator("Earnings per share")

eps = request.financial(syminfo.tickerid, "EARNINGS_PER_SHARE", "FQ")
// Second argument: financial metric ID (string)
// Third argument: period — "FQ" quarterly, "FY" annual, "TTM" trailing 12 months

plot(eps, "EPS (quarterly)")
```

---

### math.* — Math Functions

The `math` namespace provides mathematical operations that work on both `simple` and `series` values.

| Function / Constant | Signature | Description |
|---|---|---|
| `math.abs` | `math.abs(x)` | Absolute value |
| `math.ceil` | `math.ceil(x)` | Round up to nearest integer |
| `math.floor` | `math.floor(x)` | Round down to nearest integer |
| `math.round` | `math.round(x, precision?)` | Round to nearest integer or N decimal places |
| `math.log` | `math.log(x)` | Natural logarithm (base e) |
| `math.log10` | `math.log10(x)` | Base-10 logarithm |
| `math.pow` | `math.pow(base, exp)` | Raise base to exponent |
| `math.sqrt` | `math.sqrt(x)` | Square root |
| `math.max` | `math.max(a, b, ...)` | Maximum of two or more values |
| `math.min` | `math.min(a, b, ...)` | Minimum of two or more values |
| `math.avg` | `math.avg(a, b, ...)` | Arithmetic mean of two or more values |
| `math.sign` | `math.sign(x)` | Returns -1, 0, or 1 based on sign of x |
| `math.pi` | constant `float` | 3.14159265358979… |
| `math.e` | constant `float` | 2.71828182845905… |

```pine
//@version=5
indicator("Math examples")

// Normalized price distance from 20-bar high
hi_20    = ta.highest(close, 20)
lo_20    = ta.lowest(close, 20)
range_20 = math.max(hi_20 - lo_20, syminfo.mintick)  // guard against zero range
position = (close - lo_20) / range_20 * 100           // 0–100

// Log returns
log_return = math.log(close / close[1]) * 100

// Round to 2 decimal places for display
rounded = math.round(log_return, 2)

plot(position, "Position in range (0-100)")
```

---

### str.* — String Functions

The `str` namespace handles string construction, inspection, and manipulation. Strings are most commonly used with `label.new()`, `table.cell()`, and `alert()`.

| Function | Signature | Description |
|---|---|---|
| `str.tostring` | `str.tostring(value, format?)` | Convert a number or bool to string |
| `str.format` | `str.format(formatStr, ...)` | Format string with positional `{0}`, `{1}` placeholders |
| `str.length` | `str.length(str)` | Number of characters |
| `str.contains` | `str.contains(str, substr)` | Returns `true` if substring found |
| `str.replace` | `str.replace(str, target, replacement, occurrence?)` | Replace occurrence(s) of target |
| `str.split` | `str.split(str, separator)` | Split into array of strings |
| `str.upper` | `str.upper(str)` | Convert to uppercase |
| `str.lower` | `str.lower(str)` | Convert to lowercase |
| `str.substring` | `str.substring(str, beginIndex, endIndex?)` | Extract a slice (0-based index) |

```pine
//@version=5
indicator("String demo", overlay = true)

rsi_val  = ta.rsi(close, 14)
rsi_str  = str.tostring(rsi_val, "#.##")          // "63.47"
msg      = str.format("RSI({0}): {1}", 14, rsi_str)  // "RSI(14): 63.47"

// Show a label on the most recent bar
if barstate.islast
    label.new(bar_index, high, msg,
              color      = color.new(color.gray, 70),
              textcolor  = color.white,
              style      = label.style_label_down)
```

---

### array.* — Arrays

Pine arrays are dynamically-sized, index-based collections. All elements must share the same type. Arrays are a reference type — assigning an array variable copies the reference, not the data.

#### Creating and populating arrays

```pine
//@version=5
indicator("Array example")

// Type-specific constructors (preferred in v5/v6)
var float[] prices = array.new_float(0)       // empty float array
var int[]   counts = array.new_int(5, 0)      // 5 elements, all initialized to 0
var bool[]  flags  = array.new_bool(3, false)

// Add / remove elements
array.push(prices, close)            // append to end
array.unshift(prices, open)          // prepend to front
last_val  = array.pop(prices)        // remove and return last element
first_val = array.shift(prices)      // remove and return first element

// Read / write by index (0-based)
array.set(prices, 0, close * 1.01)
val = array.get(prices, 0)
sz  = array.size(prices)             // current element count
```

#### Statistical helpers

```pine
// Sort (modifies in place)
array.sort(prices, order.ascending)   // or order.descending

// Aggregates — operate on the whole array
avg_price = array.avg(prices)
total     = array.sum(prices)
hi        = array.max(prices)
lo        = array.min(prices)
```

#### Rolling window pattern (common idiom)

```pine
//@version=5
indicator("Rolling window via array", overlay = false)

var float[] window = array.new_float(0)
window_size = 20

array.push(window, close)
if array.size(window) > window_size
    array.shift(window)   // drop the oldest value

rolling_avg = array.size(window) == window_size ? array.avg(window) : na
plot(rolling_avg, "20-bar avg")
```

> **Type-specific constructors:** use `array.new_int()`, `array.new_float()`, `array.new_bool()`, `array.new_string()`, `array.new_color()` — not a generic `array.new()`.

---

### color.* — Colors

Pine's `color` type stores RGBA values. Colors are used in `plot()`, `plotshape()`, `bgcolor()`, `label.new()`, `table.cell()`, and drawing functions.

#### Named color constants

```pine
// Built-in named colors
color.red     color.green    color.blue     color.orange
color.yellow  color.purple   color.fuchsia  color.teal
color.navy    color.maroon   color.lime     color.olive
color.aqua    color.white    color.black    color.gray
color.silver
```

#### `color.new()` — apply transparency

```pine
// color.new(baseColor, transparency)
// transparency: 0 = fully opaque, 100 = fully transparent
semi_blue = color.new(color.blue, 60)   // 60% transparent blue
```

#### `color.rgb()` — build from components

```pine
// color.rgb(r, g, b, transparency?)
// r, g, b: 0–255 integers
my_teal = color.rgb(0, 128, 128)                  // fully opaque
my_teal_fade = color.rgb(0, 128, 128, 50)         // 50% transparent
```

#### `color.r()`, `color.g()`, `color.b()`, `color.t()` — extract components

```pine
base   = color.rgb(200, 100, 50, 30)
red_ch = color.r(base)   // → 200
grn_ch = color.g(base)   // → 100
blu_ch = color.b(base)   // → 50
transp = color.t(base)   // → 30
```

#### Dynamic color based on condition

```pine
//@version=5
indicator("Dynamic color", overlay = true)

rsi      = ta.rsi(close, 14)
bar_col  = rsi > 70 ? color.new(color.red, 20)
         : rsi < 30 ? color.new(color.green, 20)
         :             color.new(color.gray, 60)

bgcolor(bar_col, title = "RSI zone background")
```

---

### label.* — Labels

Labels attach text annotations to specific chart coordinates. Each label is an object created by `label.new()` and modified via setter functions.

#### Constructor

```pine
label.new(
    x,                   // bar index (int) or timestamp if xloc = xloc.bar_time
    y,                   // price level (float)
    text         = "",
    xloc         = xloc.bar_index,
    yloc         = yloc.price,
    color        = color.blue,
    style        = label.style_label_down,
    textcolor    = color.white,
    size         = size.normal,
    textalign    = text.align_center,
    tooltip      = "",
    text_font_family = font.family_default
)
```

#### Setter functions

| Function | What it changes |
|---|---|
| `label.set_x(id, x)` | Bar index or timestamp |
| `label.set_y(id, y)` | Price level |
| `label.set_xy(id, x, y)` | Position in one call |
| `label.set_text(id, text)` | Label text string |
| `label.set_color(id, color)` | Label background/border color |
| `label.set_textcolor(id, color)` | Text color |
| `label.set_style(id, style)` | Label style constant |
| `label.set_size(id, size)` | Text/marker size |
| `label.set_textalign(id, align)` | Text alignment within label |
| `label.set_tooltip(id, tooltip)` | Tooltip text on hover |
| `label.set_text_font_family(id, family)` | Font family |
| `label.set_xloc(id, x, xloc)` | X coordinate and its type |
| `label.set_yloc(id, yloc)` | Y positioning mode |

#### Getter functions

| Function | Returns |
|---|---|
| `label.get_x(id)` | `series int` — current x (bar index or timestamp) |
| `label.get_y(id)` | `series float` — current y (price) |
| `label.get_text(id)` | `series string` — current text |

#### Other functions

| Function | Description |
|---|---|
| `label.copy(id)` | Creates a copy of a label and returns the new id |
| `label.delete(id)` | Removes the label from the chart |
| `label.all` | `array<label>` — every label currently on the chart |

#### `label.style_*` constants

| Constant | Appearance |
|---|---|
| `label.style_label_down` | Callout box pointing downward (default) |
| `label.style_label_up` | Callout box pointing upward |
| `label.style_label_left` | Callout box pointing left |
| `label.style_label_right` | Callout box pointing right |
| `label.style_label_lower_left` | Callout pointing to lower-left |
| `label.style_label_lower_right` | Callout pointing to lower-right |
| `label.style_label_upper_left` | Callout pointing to upper-left |
| `label.style_label_upper_right` | Callout pointing to upper-right |
| `label.style_label_center` | Centered box with no pointer |
| `label.style_circle` | Filled circle |
| `label.style_cross` | Plus sign |
| `label.style_xcross` | X mark |
| `label.style_diamond` | Diamond shape |
| `label.style_flag` | Flag marker |
| `label.style_square` | Filled square |
| `label.style_triangleup` | Upward-pointing triangle |
| `label.style_triangledown` | Downward-pointing triangle |
| `label.style_arrowup` | Arrow pointing up |
| `label.style_arrowdown` | Arrow pointing down |
| `label.style_none` | Invisible — text only, no marker |
| `label.style_text_outline` | Text with an outline border, no background box |

#### Supporting constants

| Group | Values |
|---|---|
| `size.*` | `size.auto`, `size.tiny`, `size.small`, `size.normal`, `size.large`, `size.huge` |
| `xloc.*` | `xloc.bar_index` (default), `xloc.bar_time` |
| `yloc.*` | `yloc.price` (default), `yloc.abovebar`, `yloc.belowbar` |
| `text.align_*` | `text.align_left`, `text.align_center`, `text.align_right` |

> **Gotcha — label count limit:** By default a script can display at most **50 labels** simultaneously. Older labels are automatically deleted as new ones are created past the limit. To raise the cap, pass `max_labels_count = 500` in the `indicator()` or `strategy()` declaration (maximum 500).

#### Example

```pine
//@version=5
indicator("Label example", overlay = true, max_labels_count = 500)

rsi = ta.rsi(close, 14)

// Create a label whenever RSI crosses above 70
if ta.crossover(rsi, 70)
    label.new(
        x         = bar_index,
        y         = high,
        text      = "OB " + str.tostring(math.round(rsi, 1)),
        style     = label.style_label_down,
        color     = color.new(color.red, 20),
        textcolor = color.white,
        size      = size.small
    )

// Update a persistent label on the most recent bar
var label info_lbl = na
if barstate.islast
    if na(info_lbl)
        info_lbl := label.new(bar_index, high, "", style = label.style_label_left)
    label.set_xy(info_lbl, bar_index, high)
    label.set_text(info_lbl, "RSI: " + str.tostring(math.round(rsi, 1)))
```

---

### line.* — Lines

Lines draw a segment (or ray) between two chart coordinates. They are independent drawing objects managed via the `line.*` namespace.

#### Constructor

```pine
line.new(
    x1,                       // start bar index (int) or timestamp
    y1,                       // start price (float)
    x2,                       // end bar index (int) or timestamp
    y2,                       // end price (float)
    xloc   = xloc.bar_index,
    extend = extend.none,
    color  = color.blue,
    style  = line.style_solid,
    width  = 1
)
```

#### Setter and getter functions

| Function | Description |
|---|---|
| `line.set_x1(id, x)` | Move the start x coordinate |
| `line.set_y1(id, y)` | Move the start y coordinate |
| `line.set_x2(id, x)` | Move the end x coordinate |
| `line.set_y2(id, y)` | Move the end y coordinate |
| `line.set_xy1(id, x, y)` | Set start point in one call |
| `line.set_xy2(id, x, y)` | Set end point in one call |
| `line.set_color(id, color)` | Change line color |
| `line.set_style(id, style)` | Change line style |
| `line.set_width(id, width)` | Change line width in pixels |
| `line.set_extend(id, extend)` | Change extend mode |
| `line.set_xloc(id, x1, x2, xloc)` | Change both x values and xloc type |
| `line.get_x1(id)` | Returns start x |
| `line.get_y1(id)` | Returns start y |
| `line.get_x2(id)` | Returns end x |
| `line.get_y2(id)` | Returns end y |
| `line.get_price(id, x)` | Price on the line at bar index `x` (interpolated) |
| `line.copy(id)` | Duplicate the line |
| `line.delete(id)` | Remove the line |
| `line.all` | `array<line>` — all currently visible lines |

#### `line.style_*` constants

| Constant | Appearance |
|---|---|
| `line.style_solid` | Continuous solid line |
| `line.style_dashed` | Dashed line |
| `line.style_dotted` | Dotted line |
| `line.style_arrow_left` | Arrow head at the left (start) end |
| `line.style_arrow_right` | Arrow head at the right (end) end |
| `line.style_arrow_both` | Arrow heads at both ends |

#### `extend.*` constants

| Constant | Description |
|---|---|
| `extend.none` | Line drawn only between x1 and x2 |
| `extend.left` | Ray extending infinitely to the left of x1 |
| `extend.right` | Ray extending infinitely to the right of x2 |
| `extend.both` | Full infinite line through both points |

> **Gotcha — line count limit:** Default maximum is **50 lines**. Raise to up to 500 with `max_lines_count = 500` in the script declaration.

#### Example

```pine
//@version=5
indicator("Trendline example", overlay = true, max_lines_count = 500)

// Draw a horizontal line at the 20-bar high, updated each bar
pivot_high = ta.highest(high, 20)

var line resistance = na
if barstate.islast
    if not na(resistance)
        line.delete(resistance)
    resistance := line.new(
        x1     = bar_index - 20,
        y1     = pivot_high,
        x2     = bar_index,
        y2     = pivot_high,
        extend = extend.right,
        color  = color.new(color.red, 30),
        style  = line.style_dashed,
        width  = 2
    )

// line.get_price() — read the line's price value at a specific bar
// useful when the line is sloped (different y1 and y2)
if not na(resistance)
    price_at_current = line.get_price(resistance, bar_index)
    bgcolor(close > price_at_current ? color.new(color.green, 90) : na)
```

---

### box.* — Boxes

Boxes draw filled rectangles between two price levels over a range of bars. They combine a border and a background fill into one object.

#### Constructor

```pine
box.new(
    left,                         // left bar index (int) or timestamp
    top,                          // top price (float)
    right,                        // right bar index (int) or timestamp
    bottom,                       // bottom price (float)
    border_color     = color.blue,
    border_width     = 1,
    border_style     = line.style_solid,
    extend           = extend.none,
    xloc             = xloc.bar_index,
    bgcolor          = color.new(color.blue, 90),
    text             = "",
    text_size        = size.auto,
    text_color       = color.black,
    text_halign      = text.align_center,
    text_valign      = text.align_center,
    text_wrap        = text.wrap_none,
    text_font_family = font.family_default
)
```

#### Setter functions

| Function | What it changes |
|---|---|
| `box.set_left(id, left)` | Left x boundary |
| `box.set_top(id, top)` | Top price boundary |
| `box.set_right(id, right)` | Right x boundary |
| `box.set_bottom(id, bottom)` | Bottom price boundary |
| `box.set_lefttop(id, left, top)` | Left and top in one call |
| `box.set_rightbottom(id, right, bottom)` | Right and bottom in one call |
| `box.set_border_color(id, color)` | Border color |
| `box.set_border_width(id, width)` | Border width |
| `box.set_border_style(id, style)` | Border style (reuses `line.style_*`) |
| `box.set_bgcolor(id, color)` | Fill color |
| `box.set_extend(id, extend)` | Extend mode |
| `box.set_text(id, text)` | Box text |
| `box.set_text_color(id, color)` | Text color |
| `box.set_text_size(id, size)` | Text size |
| `box.set_text_halign(id, align)` | Horizontal text alignment |
| `box.set_text_valign(id, align)` | Vertical text alignment |
| `box.set_text_wrap(id, wrap)` | Whether text wraps |
| `box.set_text_font_family(id, family)` | Font family |

#### Getter functions

| Function | Returns |
|---|---|
| `box.get_left(id)` | `series int` — left x |
| `box.get_top(id)` | `series float` — top price |
| `box.get_right(id)` | `series int` — right x |
| `box.get_bottom(id)` | `series float` — bottom price |

#### Other functions

| Function | Description |
|---|---|
| `box.copy(id)` | Duplicate the box |
| `box.delete(id)` | Remove the box |
| `box.all` | `array<box>` — all visible boxes |

#### Text wrap constants

| Constant | Behavior |
|---|---|
| `text.wrap_none` | Text displayed on a single line (may overflow) |
| `text.wrap_auto` | Text wraps to fit inside the box width |

> **Gotcha — box count limit:** Default maximum is **50 boxes**. Raise to up to 500 with `max_boxes_count = 500` in the script declaration.

#### Example

```pine
//@version=5
indicator("Supply/Demand zones", overlay = true, max_boxes_count = 500)

// Draw a box highlighting the prior session's range
var box session_box = na

is_new_session = ta.change(time("D")) != 0

if is_new_session
    // Close previous box at the session end bar
    if not na(session_box)
        box.set_right(session_box, bar_index - 1)

    // Open a new box starting at this bar
    session_box := box.new(
        left         = bar_index,
        top          = high,
        right        = bar_index,        // will be extended as the session progresses
        bottom       = low,
        border_color = color.new(color.gray, 50),
        bgcolor      = color.new(color.yellow, 85),
        text         = "Session",
        text_size    = size.small,
        text_color   = color.gray
    )
else if not na(session_box)
    // Expand box boundaries to encompass the full session's range
    box.set_top(session_box,    math.max(box.get_top(session_box),    high))
    box.set_bottom(session_box, math.min(box.get_bottom(session_box), low))
    box.set_right(session_box, bar_index)
```

---

### table.* — Tables

Tables display text in a fixed grid layout anchored to a corner of the chart pane. Unlike labels, tables do not have price or bar-index coordinates — they are always positioned relative to the visible pane.

#### Constructor

```pine
table.new(
    position     = position.top_right,
    columns      = 2,
    rows         = 3,
    bgcolor      = color.new(color.gray, 80),
    frame_color  = color.gray,
    frame_width  = 1,
    border_color = color.gray,
    border_width = 1
)
```

#### Populating and updating cells

```pine
// table.cell() — define or redefine a single cell (0-based row and column)
table.cell(
    table_id,
    column,
    row,
    text          = "",
    width         = 0,        // 0 = auto-size
    height        = 0,
    text_color    = color.black,
    text_halign   = text.align_center,
    text_valign   = text.align_center,
    text_size     = size.normal,
    bgcolor       = na,
    tooltip       = "",
    text_font_family = font.family_default
)
```

#### Cell setter functions (partial updates)

| Function | Description |
|---|---|
| `table.cell_set_text(id, col, row, text)` | Change the cell text |
| `table.cell_set_bgcolor(id, col, row, color)` | Change cell background color |
| `table.cell_set_text_color(id, col, row, color)` | Change cell text color |
| `table.cell_set_text_size(id, col, row, size)` | Change font size |
| `table.cell_set_text_halign(id, col, row, align)` | Horizontal text alignment |
| `table.cell_set_text_valign(id, col, row, align)` | Vertical text alignment |
| `table.cell_set_width(id, col, row, width)` | Set column width in chars |
| `table.cell_set_height(id, col, row, height)` | Set row height |
| `table.cell_set_tooltip(id, col, row, tooltip)` | Hover tooltip |

#### Other table functions

| Function | Description |
|---|---|
| `table.merge_cells(id, c1, r1, c2, r2)` | Merge a rectangular range of cells |
| `table.clear(id, c1, r1, c2, r2)` | Clear content in a cell range |
| `table.delete(id)` | Remove the table entirely |

#### `position.*` constants

| Constant | Location on pane |
|---|---|
| `position.top_left` | Upper-left corner |
| `position.top_center` | Upper-center |
| `position.top_right` | Upper-right corner |
| `position.middle_left` | Mid-left edge |
| `position.middle_center` | Center of pane |
| `position.middle_right` | Mid-right edge |
| `position.bottom_left` | Lower-left corner |
| `position.bottom_center` | Lower-center |
| `position.bottom_right` | Lower-right corner |

> **Gotcha — create in `barstate.islast` or with `var`:** Creating a new table with `table.new()` on every bar wastes resources and flickers. Either declare the table with `var` so it is created once and reused, or create it inside `if barstate.islast`. Use `table.cell()` to update content on each bar — calling `table.cell()` on an existing cell redefines all of that cell's properties from scratch.

#### Example

```pine
//@version=5
indicator("Stats table", overlay = true)

rsi  = ta.rsi(close, 14)
fast = ta.ema(close, 9)
slow = ta.ema(close, 21)

// Create the table once (var ensures it survives across bars)
var table stats = table.new(
    position     = position.top_right,
    columns      = 2,
    rows         = 4,
    bgcolor      = color.new(color.black, 60),
    frame_color  = color.gray,
    frame_width  = 1,
    border_color = color.new(color.gray, 50),
    border_width = 1
)

// Populate header row once
if barstate.isfirst
    table.cell(stats, 0, 0, "Metric",  text_color = color.silver, text_size = size.small)
    table.cell(stats, 1, 0, "Value",   text_color = color.silver, text_size = size.small)

// Update data rows on every bar
table.cell(stats, 0, 1, "RSI",       text_color = color.white, text_size = size.small)
table.cell(stats, 1, 1, str.tostring(math.round(rsi, 2)),
           text_color = rsi > 70 ? color.red : rsi < 30 ? color.lime : color.white,
           text_size  = size.small)

table.cell(stats, 0, 2, "EMA 9",     text_color = color.white,  text_size = size.small)
table.cell(stats, 1, 2, str.tostring(math.round(fast, 2)),
           text_color = color.orange, text_size = size.small)

table.cell(stats, 0, 3, "Trend",     text_color = color.white,  text_size = size.small)
table.cell(stats, 1, 3, fast > slow ? "Bullish" : "Bearish",
           text_color = fast > slow ? color.lime : color.red, text_size = size.small)
```

---

### map.* — Maps

Maps store key-value pairs with O(1) lookup. They are the Pine equivalent of a dictionary or hash map.

#### Constructor

```pine
// Generic syntax — specify key and value types explicitly
map.new<string, float>()   // string keys → float values
map.new<int, bool>()       // int keys → bool values
```

Valid key types: `int`, `float`, `bool`, `string`, `color`. Value types can be any Pine type including UDTs.

#### Core functions

| Function | Description |
|---|---|
| `map.put(id, key, value)` | Insert or overwrite a key-value pair |
| `map.put_all(id, other_map)` | Copy all pairs from another map into this one |
| `map.get(id, key)` | Return the value for a key (`na` if not found) |
| `map.contains(id, key)` | `bool` — true if the key exists |
| `map.remove(id, key)` | Delete the entry for a key; returns the removed value |
| `map.keys(id)` | `array` of all keys in insertion order |
| `map.values(id)` | `array` of all values in insertion order |
| `map.size(id)` | `int` — number of key-value pairs |
| `map.clear(id)` | Remove all entries |
| `map.copy(id)` | Return a shallow copy of the map |

> **Gotchas:**
> - Keys are **unique** — inserting an existing key overwrites its value silently.
> - Maps are **unordered** in terms of retrieval semantics; `map.keys()` returns keys in insertion order but this is an implementation detail.
> - Maximum **50,000 key-value pairs** per map.

#### Example

```pine
//@version=5
indicator("Map example", overlay = false)

// Track the last-seen close price for multiple timeframes
var map<string, float> tf_closes = map.new<string, float>()

daily  = request.security(syminfo.tickerid, "D",  close)
weekly = request.security(syminfo.tickerid, "W",  close)
monthly= request.security(syminfo.tickerid, "M",  close)

map.put(tf_closes, "Daily",   daily)
map.put(tf_closes, "Weekly",  weekly)
map.put(tf_closes, "Monthly", monthly)

// Check presence before reading
if map.contains(tf_closes, "Daily")
    d = map.get(tf_closes, "Daily")
    plot(close / d * 100 - 100, "% from daily close")

// Iterate all entries
if barstate.islast
    keys = map.keys(tf_closes)
    for k in keys
        v = map.get(tf_closes, k)
        label.new(bar_index, close,
                  k + ": " + str.tostring(math.round(v, 2)),
                  style = label.style_label_left, size = size.small)
```

---

### matrix.* — Matrices

Matrices are two-dimensional typed arrays. They support both element-level access and a rich set of linear algebra operations.

#### Constructor

```pine
// matrix.new<type>(rows, columns, initial_value)
m = matrix.new<float>(3, 3, 0.0)   // 3×3 float matrix, all zeros
```

#### Element access and dimensions

| Function | Description |
|---|---|
| `matrix.get(id, row, col)` | Read a single element (0-based indices) |
| `matrix.set(id, row, col, value)` | Write a single element |
| `matrix.fill(id, value)` | Set every element to the same value |
| `matrix.fill(id, value, r1, c1, r2, c2)` | Fill a rectangular subregion |
| `matrix.row(id, row)` | Extract a row as an `array` |
| `matrix.col(id, col)` | Extract a column as an `array` |
| `matrix.rows(id)` | Number of rows |
| `matrix.columns(id)` | Number of columns |
| `matrix.elements_count(id)` | Total elements (rows × columns) |
| `matrix.reshape(id, rows, cols)` | Change dimensions (total element count must stay the same) |

#### Row and column manipulation

| Function | Description |
|---|---|
| `matrix.add_row(id, row, array)` | Insert a row at index `row` |
| `matrix.add_col(id, col, array)` | Insert a column at index `col` |
| `matrix.remove_row(id, row)` | Delete a row; returns it as an array |
| `matrix.remove_col(id, col)` | Delete a column; returns it as an array |
| `matrix.swap_rows(id, r1, r2)` | Swap two rows in place |
| `matrix.swap_columns(id, c1, c2)` | Swap two columns in place |
| `matrix.submatrix(id, r1, c1, r2, c2)` | Extract a rectangular sub-matrix |
| `matrix.reverse(id)` | Reverse element order (flattened, then re-shaped) |
| `matrix.concat(id, other)` | Append rows of another matrix with same column count |

#### Linear algebra

| Function | Description |
|---|---|
| `matrix.transpose(id)` | Returns transposed copy (rows ↔ columns) |
| `matrix.det(id)` | Determinant (square matrices only) |
| `matrix.inv(id)` | Inverse matrix (square, non-singular only) |
| `matrix.pinv(id)` | Moore-Penrose pseudo-inverse |
| `matrix.rank(id)` | Rank of the matrix |
| `matrix.trace(id)` | Sum of the main diagonal |
| `matrix.eigenvalues(id)` | Array of eigenvalues (square matrices only) |
| `matrix.eigenvectors(id)` | Matrix whose columns are eigenvectors |
| `matrix.kron(id, other)` | Kronecker product |
| `matrix.mult(id, other)` | Matrix multiplication |

#### Statistics

| Function | Description |
|---|---|
| `matrix.avg(id)` | Mean of all elements |
| `matrix.max(id)` | Maximum element value |
| `matrix.min(id)` | Minimum element value |
| `matrix.sum(id)` | Sum of all elements |
| `matrix.diff(id)` | Successive differences along rows |
| `matrix.median(id)` | Median of all elements |
| `matrix.mode(id)` | Mode (most frequent value) |

#### Boolean inspectors

| Function | Returns `true` when |
|---|---|
| `matrix.is_square(id)` | Row count equals column count |
| `matrix.is_symmetric(id)` | Matrix equals its own transpose |
| `matrix.is_diagonal(id)` | All off-diagonal elements are zero |
| `matrix.is_identity(id)` | Diagonal ones, off-diagonal zeros |
| `matrix.is_zero(id)` | Every element is zero |
| `matrix.is_antidiagonal(id)` | Non-zero elements only on anti-diagonal |
| `matrix.is_antisymmetric(id)` | Matrix equals the negation of its transpose |
| `matrix.is_binary(id)` | Every element is 0 or 1 |
| `matrix.is_stochastic(id)` | Rows each sum to 1 (probability matrix) |
| `matrix.is_triangular(id, lower)` | Upper or lower triangular form |

> **Gotchas:**
> - `matrix.det()`, `matrix.inv()`, and `matrix.eigenvalues()` require **square matrices** — a runtime error is raised otherwise.
> - Row and column indices are **0-based**.

#### Example

```pine
//@version=5
indicator("Correlation matrix example", overlay = false)

len = input.int(20, "Lookback")

// Build a 2×2 covariance-style matrix from two series
closes_a = close
closes_b = request.security(syminfo.tickerid, "D", close)

// Collect recent returns into arrays
var float[] ret_a = array.new_float(0)
var float[] ret_b = array.new_float(0)

if bar_index > 0
    array.push(ret_a, math.log(close / close[1]))
    array.push(ret_b, math.log(closes_b / closes_b[1]))
    if array.size(ret_a) > len
        array.shift(ret_a)
        array.shift(ret_b)

if array.size(ret_a) == len
    // Build 2×2 matrix manually
    m = matrix.new<float>(2, 2, 0.0)
    matrix.set(m, 0, 0, array.stdev(ret_a))
    matrix.set(m, 1, 1, array.stdev(ret_b))

    // Trace = sum of variances
    t = matrix.trace(m)
    plot(t * 1000, "Trace (×1000)")
```

---

### log.* — Logging

The `log.*` functions write messages to the **Pine Logs** panel (accessible via the Pine Editor's Logs tab). They are the primary debugging tool when you cannot use `plot()` or labels.

#### Functions

| Function | Signature | Severity level |
|---|---|---|
| `log.info` | `log.info(message)` | Informational |
| `log.warning` | `log.warning(message)` | Warning |
| `log.error` | `log.error(message)` | Error |

All three also accept a format-string overload with positional placeholders:

```pine
log.info("RSI at bar {0}: {1}", bar_index, rsi_val)
// Placeholders: {0}, {1}, {2} … correspond to extra arguments in order
```

> **Gotcha — Pine Logs panel only:** Log output does not appear on the chart or in the console. You must open the Logs tab at the bottom of the Pine Editor to see it. Log calls on historical bars all execute at script load time — you can filter by severity in the panel.

#### Example

```pine
//@version=5
indicator("Logging demo", overlay = false)

rsi = ta.rsi(close, 14)

// Log a warning whenever RSI crosses into extreme territory
if ta.crossover(rsi, 70)
    log.warning("RSI crossed above 70 at bar {0}, value: {1,number,#.##}", bar_index, rsi)

if ta.crossunder(rsi, 30)
    log.info("RSI crossed below 30 at bar {0}, value: {1,number,#.##}", bar_index, rsi)

// Log an error when data is unexpectedly na
if na(rsi) and bar_index > 20
    log.error("Unexpected na RSI at bar {0}", bar_index)

plot(rsi, "RSI")
```

---

### Alerts

Pine Script supports two distinct alert mechanisms with different scopes and constraints.

#### `alert()` — flexible, works in both indicators and strategies

```pine
alert(message, freq)
```

- Available in **both** `indicator()` and `strategy()` scripts.
- Must be called inside an `if` block (or other conditional) — it fires when that code path executes.
- The `message` argument can be a `series string` (dynamically constructed).

#### `alertcondition()` — static, indicators only

```pine
alertcondition(condition, title, message)
```

- Available **only** in `indicator()` scripts — compile error in `strategy()`.
- Must be at **global scope** (not inside any `if`, `for`, or function body).
- `title` and `message` must be **`const string`** — string literals or `input.string()` values, never dynamically constructed series.
- Registers an alert template that users activate from the TradingView "Create Alert" dialog.

#### `alert.freq_*` constants

| Constant | Fires |
|---|---|
| `alert.freq_once_per_bar` | At most once per bar, on the first matching tick |
| `alert.freq_once_per_bar_close` | Only on the confirmed close of a bar |
| `alert.freq_all` | Every tick that satisfies the condition |
| `alert.freq_once_per_alert` | Only one time ever (until the alert is re-enabled) |

> **Gotchas:**
> - `alertcondition()` title and message **must be const strings** — attempting to embed `str.format()` output or any series value causes a compile error.
> - `alert()` is more flexible but the alert must be manually enabled by the user in TradingView's alert dialog; the script itself cannot trigger the notification automatically.
> - In strategies, use `alert()` rather than `alertcondition()`.

#### Example

```pine
//@version=5
indicator("Alert examples", overlay = true)

fast = ta.ema(close, 9)
slow = ta.ema(close, 21)
cross_up   = ta.crossover(fast, slow)
cross_down = ta.crossunder(fast, slow)

// --- alertcondition: static registration (indicators only, global scope, const strings)
alertcondition(cross_up,   title = "EMA Cross Up",   message = "Fast EMA crossed above Slow EMA")
alertcondition(cross_down, title = "EMA Cross Down",  message = "Fast EMA crossed below Slow EMA")

// --- alert(): dynamic message, fires from inside a conditional
if cross_up
    alert(
        str.format("BUY signal on {0} — Fast EMA crossed above Slow EMA. Close: {1}",
                   syminfo.ticker, close),
        alert.freq_once_per_bar
    )

if cross_down
    alert(
        str.format("SELL signal on {0} — Fast EMA crossed below Slow EMA. Close: {1}",
                   syminfo.ticker, close),
        alert.freq_once_per_bar
    )

plotshape(cross_up,   "Buy",  shape.triangleup,   location.belowbar, color.green)
plotshape(cross_down, "Sell", shape.triangledown,  location.abovebar, color.red)
```

---

### Drawing Object Limits Summary

| Object | Default max | Max via declaration param |
|---|---|---|
| Labels | 50 | 500 (`max_labels_count = 500`) |
| Lines | 50 | 500 (`max_lines_count = 500`) |
| Boxes | 50 | 500 (`max_boxes_count = 500`) |
| Tables | No hard per-object limit | — |
| Maps | — | 50,000 pairs per map instance |

---

## 6. Plotting

Pine Script's plotting functions are the primary way to render visual output on the chart. All plotting calls execute on every bar, but the display is driven by the series values they receive.

### `plot()` — lines and value series

```pine
//@version=5
indicator("plot() demo", overlay = true)

ma_fast = ta.ema(close, 9)
ma_slow = ta.ema(close, 21)

// Full signature:
// plot(series, title, color, linewidth, style, trackprice, histbase, offset, join, editable, show_last, display)
plot(ma_fast, title = "EMA 9",  color = color.blue,   linewidth = 2)
plot(ma_slow, title = "EMA 21", color = color.orange,  linewidth = 1,
     style = plot.style_line)
```

**Plot styles:**

| Constant | Appearance |
|---|---|
| `plot.style_line` | Continuous line (default) |
| `plot.style_linebr` | Line that breaks at `na` values |
| `plot.style_histogram` | Vertical bars from a baseline (default 0) |
| `plot.style_columns` | Filled columns from a baseline |
| `plot.style_area` | Filled area below the line |
| `plot.style_areabr` | Filled area, breaks at `na` |
| `plot.style_circles` | Dots at each bar |
| `plot.style_cross` | Cross marks at each bar |
| `plot.style_stepline` | Staircase (holds value until next bar) |

### `plotshape()` — marker shapes at specific bars

```pine
//@version=5
indicator("plotshape demo", overlay = true)

buy  = ta.crossover(ta.ema(close, 9), ta.ema(close, 21))
sell = ta.crossunder(ta.ema(close, 9), ta.ema(close, 21))

// plotshape(series, title, shape, location, color, offset, text, textcolor, size)
plotshape(buy,  title = "Buy signal",  shape = shape.triangleup,
          location = location.belowbar, color = color.green,
          text = "BUY", textcolor = color.white, size = size.small)

plotshape(sell, title = "Sell signal", shape = shape.triangledown,
          location = location.abovebar, color = color.red,
          text = "SELL", textcolor = color.white, size = size.small)
```

Common `shape.*` constants: `shape.triangleup`, `shape.triangledown`, `shape.circle`, `shape.square`, `shape.diamond`, `shape.cross`, `shape.xcross`, `shape.arrowup`, `shape.arrowdown`, `shape.flag`, `shape.labelup`, `shape.labeldown`.

Common `location.*` constants: `location.abovebar`, `location.belowbar`, `location.top`, `location.bottom`, `location.absolute`.

### `plotchar()` — single Unicode character as marker

```pine
//@version=5
indicator("plotchar demo", overlay = true)

gap_up = open > high[1]

// plotchar(series, title, char, location, color, offset, text, textcolor, size)
plotchar(gap_up, title = "Gap up", char = "▲",
         location = location.abovebar, color = color.teal,
         size = size.tiny)
```

`plotchar` accepts any single Unicode character, making it useful for custom symbols the built-in `shape.*` set does not cover.

### `plotarrow()` — directional arrows scaled by value

```pine
//@version=5
indicator("plotarrow demo", overlay = true)

momentum = close - close[5]

// plotarrow(series, title, colorup, colordown, offset, minheight, maxheight, show_last, display)
// Positive values → up arrows; negative values → down arrows
// Arrow height scales with the absolute value of series
plotarrow(momentum, title = "Momentum arrow",
          colorup = color.green, colordown = color.red)
```

### `bgcolor()` — color the chart background

```pine
//@version=5
indicator("bgcolor demo", overlay = true)

rsi = ta.rsi(close, 14)

// Tint the background when RSI is extreme
overbought_zone = rsi > 70
oversold_zone   = rsi < 30

// bgcolor(color, offset, editable, show_last, title, display)
bgcolor(overbought_zone ? color.new(color.red,   85) : na, title = "Overbought")
bgcolor(oversold_zone   ? color.new(color.green, 85) : na, title = "Oversold")
```

### `barcolor()` — recolor the price bars themselves

```pine
//@version=5
indicator("barcolor demo", overlay = true)

// barcolor(color, offset, editable, show_last, title)
// Overrides the default bar/candle color for each bar
barcolor(close > open ? color.new(color.teal, 20)
       : close < open ? color.new(color.maroon, 20)
       :                color.gray)
```

`barcolor()` affects only the primary chart bars — it has no effect in a sub-pane indicator (`overlay = false`).

### `fill()` — shade the area between two plots

```pine
// fill(plot1, plot2, color, title, editable, fillgaps, display)
// The two plots must have been created with plot() in the same script
p_upper = plot(ta.bb(close, 20, 2)[1], "BB Upper", color = color.blue, display = display.none)
p_lower = plot(ta.bb(close, 20, 2)[2], "BB Lower", color = color.blue, display = display.none)

fill(p_upper, p_lower, color = color.new(color.blue, 88), title = "BB fill")
```

A common pattern is to create "invisible" helper plots (`display = display.none`) solely for use as `fill()` boundaries, keeping the chart clean.

### `hline()` — static horizontal reference line

```pine
//@version=5
indicator("hline demo", overlay = false)

rsi = ta.rsi(close, 14)
plot(rsi, "RSI")

// hline(price, title, color, linestyle, linewidth, editable, display)
hline(70,  "Overbought", color = color.red,   linestyle = hline.style_dashed)
hline(50,  "Midpoint",   color = color.gray,  linestyle = hline.style_dotted)
hline(30,  "Oversold",   color = color.green, linestyle = hline.style_dashed)
```

`hline.style_solid`, `hline.style_dashed`, `hline.style_dotted` are the available line styles. Unlike `plot()`, `hline()` takes a `simple float` — the price level cannot vary bar by bar.

### Comprehensive plotting example

```pine
//@version=5
indicator("Combined plot showcase", overlay = false, precision = 2)

length = input.int(14, "RSI length", minval = 2)
src    = input.source(close, "Source")

rsi      = ta.rsi(src, length)
rsi_sma  = ta.sma(rsi, 5)           // smoothed signal
momentum = rsi - rsi_sma            // divergence from signal

// -- Horizontal reference lines --
ob_line  = hline(70, "OB",  color = color.new(color.red,   40), linestyle = hline.style_dashed)
mid_line = hline(50, "Mid", color = color.new(color.gray,  50), linestyle = hline.style_dotted)
os_line  = hline(30, "OS",  color = color.new(color.green, 40), linestyle = hline.style_dashed)

// Fill OB/OS zones
fill(ob_line,  mid_line, color = color.new(color.red,   92))
fill(mid_line, os_line,  color = color.new(color.green, 92))

// -- RSI line --
p_rsi = plot(rsi,     "RSI",        color = color.blue,  linewidth = 2)
p_sig = plot(rsi_sma, "RSI Signal", color = color.orange, linewidth = 1,
             style = plot.style_line)

// Fill between RSI and its signal line
fill(p_rsi, p_sig,
     color = rsi > rsi_sma ? color.new(color.blue, 80)
                            : color.new(color.orange, 80))

// -- Momentum histogram below the RSI line --
plot(momentum, "Momentum", color = momentum >= 0 ? color.teal : color.maroon,
     style = plot.style_histogram, histbase = 0)

// -- Markers at extremes --
plotshape(ta.crossunder(rsi, 70), "OB cross", shape.xcross,
          location.absolute, color.red,   offset = 0)
plotshape(ta.crossover(rsi, 30),  "OS cross", shape.xcross,
          location.absolute, color.green, offset = 0)

// -- Background tint on confirmed extremes --
bgcolor(rsi > 70 ? color.new(color.red,   92) : na, title = "OB zone")
bgcolor(rsi < 30 ? color.new(color.green, 92) : na, title = "OS zone")
```

---

## 7. Control Flow

Pine Script uses **indentation** to delimit blocks — there are no `begin`/`end` keywords and no curly braces. Two or four spaces per level are both accepted; just be consistent.

### `if` / `else if` / `else`

```pine
//@version=5
indicator("if/else demo")

rsi = ta.rsi(close, 14)

// Single-line if (no indented block needed when there is exactly one expression)
signal = if rsi > 70
    "overbought"
else if rsi < 30
    "oversold"
else
    "neutral"

// if block that executes side effects (no value assignment)
var int streak = 0
if close > close[1]
    streak := streak + 1
else
    streak := 0

plot(streak, "Bull streak")
```

An `if` block can be used as an **expression** (it returns the last evaluated value from the taken branch). When all branches return values of the same type, the result can be assigned directly.

### `for ... to` — index-based loop

```pine
//@version=5
indicator("for...to demo")

// Sum the last N bars of close manually
n = 10
var float manual_sum = 0.0
manual_sum := 0.0
for i = 0 to n - 1       // i goes from 0 to n-1 inclusive
    manual_sum += close[i]

manual_avg = manual_sum / n
plot(manual_avg, "Manual avg")
```

- Bounds are **inclusive** on both ends — `for i = 0 to 4` iterates i = 0, 1, 2, 3, 4.
- Optional `by` step: `for i = 0 to 20 by 2` increments by 2.
- `break` exits the loop immediately; `continue` skips to the next iteration.

### `for ... in` — array iteration

```pine
//@version=5
indicator("for...in demo")

var float[] vals = array.new_float(0)
array.push(vals, close)
if array.size(vals) > 20
    array.shift(vals)

// Iterate over elements — val is each element's value
float total = 0.0
for val in vals
    total += val

avg = array.size(vals) > 0 ? total / array.size(vals) : na
plot(avg, "Iterative avg")
```

`for val in myArray` gives a copy of each element. To modify elements in place you still need `array.set()` with an index loop.

### `while` — condition-based loop

```pine
//@version=5
indicator("while demo")

// Binary search for the first bar where ta.highest crosses a threshold
// (contrived example to show while syntax)
threshold = ta.sma(high, 50)

var int bars_above = 0
bars_above := 0
int i = 0
while i < 50 and i < bar_index
    if high[i] > threshold
        bars_above += 1
    i += 1

plot(bars_above, "Bars above threshold in last 50")
```

**Warning:** Pine enforces a per-bar execution time limit. Loops with a large iteration count or expensive body can trigger a "Script took too long to execute" runtime error.

### `switch` — multi-branch dispatch

```pine
//@version=5
indicator("switch demo")

mode = input.string("RSI", "Indicator", options = ["RSI", "CCI", "MFI"])

// switch expression — each branch uses => and returns a value
osc = switch mode
    "RSI" => ta.rsi(close, 14)
    "CCI" => ta.cci(close, 20)
    "MFI" => ta.mfi(close, 14)
    =>       ta.rsi(close, 14)   // default branch (bare =>)

plot(osc, "Selected oscillator")
```

Each arm uses `value => expression`. The bare `=>` at the end is the default branch (equivalent to `else`). The entire `switch` block is an expression and can be assigned to a variable.

### Ternary operator `? :`

```pine
//@version=5
indicator("Ternary demo", overlay = true)

// condition ? valueIfTrue : valueIfFalse
trend_color = close > ta.sma(close, 50) ? color.green : color.red

// Ternary chains (right-associative — reads top to bottom)
zone = ta.rsi(close, 14) > 70 ? "OB"
     : ta.rsi(close, 14) < 30 ? "OS"
     :                           "Neutral"

barcolor(trend_color)
```

The ternary operator is a single expression — it cannot contain statements or side effects. For more complex branching use `if` blocks.

---

## 8. User-Defined Functions & Types

### Function syntax

Functions are declared using `=>`. A single-expression function fits on one line; a multi-statement function uses an indented block.

```pine
//@version=5
indicator("UDF demo")

// Single-line function
percent_change(current, previous) =>
    (current - previous) / previous * 100.0

// Multi-line function — last expression is the implicit return value
zscore(src, length) =>
    avg  = ta.sma(src, length)
    dev  = ta.stdev(src, length)
    safe = math.max(dev, syminfo.mintick)   // avoid division by zero
    (src - avg) / safe                      // returned value

pct  = percent_change(close, close[1])
z    = zscore(close, 20)

plot(pct, "Pct change")
plot(z,   "Z-score", display = display.pane)
```

Functions capture their outer scope — they can read variables declared before them, but they cannot modify `var` variables declared outside (each call has its own local state).

### Tuple returns with destructuring

A function (or built-in) can return multiple values wrapped in square brackets. The caller destructures with `[a, b] = f(...)`.

```pine
//@version=5
indicator("Tuple return demo")

// Function returning two values
minmax(src, len) =>
    [ta.lowest(src, len), ta.highest(src, len)]

[lo, hi]    = minmax(close, 20)
[bb_mid, bb_upper, bb_lower] = ta.bb(close, 20, 2.0)  // built-in tuple

range_pct = (hi - lo) / lo * 100
plot(range_pct, "20-bar range %")
```

### User-Defined Types (UDTs)

The `type` keyword declares a named composite type, similar to a struct or record.

```pine
//@version=5
indicator("UDT demo", overlay = true)

// Declare a type — fields can have default values
type Signal
    int   bar       = 0
    float price     = na
    bool  is_long   = false
    color sig_color = color.gray

// Create an instance with type.new() or using field= syntax
var Signal last_sig = Signal.new()

fast = ta.ema(close, 9)
slow = ta.ema(close, 21)

if ta.crossover(fast, slow)
    last_sig := Signal.new(
         bar       = bar_index,
         price     = close,
         is_long   = true,
         sig_color = color.green)

if ta.crossunder(fast, slow)
    last_sig := Signal.new(
         bar       = bar_index,
         price     = close,
         is_long   = false,
         sig_color = color.red)

// Access fields with dot notation
if barstate.islast
    label.new(last_sig.bar, last_sig.price,
              last_sig.is_long ? "Last BUY" : "Last SELL",
              color = last_sig.sig_color,
              style = label.style_label_up)
```

### Methods on UDTs

The `method` keyword attaches a function to a type. Inside the method, `this` refers to the instance.

```pine
//@version=5
indicator("Method demo", overlay = false)

type PriceBuffer
    float[] data     = array.new_float(0)
    int     capacity = 20

// method defined on PriceBuffer
method push(PriceBuffer this, float val) =>
    array.push(this.data, val)
    if array.size(this.data) > this.capacity
        array.shift(this.data)

method average(PriceBuffer this) =>
    array.size(this.data) > 0 ? array.avg(this.data) : na

var PriceBuffer buf = PriceBuffer.new()

buf.push(close)           // call the method with dot notation
plot(buf.average(), "Buffer avg")
```

### `export` and `import` for library functions

In a `library()` script, mark public functions with `export`. Callers import the library using a version-qualified path.

```pine
// ---- In a library script titled "MathUtils" ----
//@version=5
library("MathUtils", overlay = false)

// export makes the function available to importers
export zscore(series float src, simple int len) =>
    avg = ta.sma(src, len)
    dev = ta.stdev(src, len)
    (src - avg) / math.max(dev, 1e-10)

export clamp(series float x, simple float lo, simple float hi) =>
    math.max(lo, math.min(hi, x))
```

```pine
// ---- In a consuming script ----
//@version=5
indicator("Library consumer")

import username/MathUtils/1 as MU   // version number at the end

z = MU.zscore(close, 20)
plot(z, "Z-score from library")
```

The import path follows the format `<TradingView_username>/<LibraryTitle>/<version>`. Libraries must be published (or in an organization) before they can be imported by other users.

---

## 9. Bar State & Time

### Bar state variables

These read-only boolean variables let you detect where in the script's execution you are. They are most useful for logic that should run only once (e.g., drawing a final label) or that behaves differently on live vs. historical data.

| Variable | Type | True when |
|---|---|---|
| `barstate.isfirst` | `series bool` | Currently executing the very first historical bar |
| `barstate.islast` | `series bool` | Currently executing the last bar on the chart (historical or live) |
| `barstate.isrealtime` | `series bool` | The current bar is a live, unconfirmed bar (not yet closed) |
| `barstate.isconfirmed` | `series bool` | The current bar has just closed — its OHLCV values are final |
| `barstate.isnew` | `series bool` | This is the first tick of a new bar (bar just opened) |
| `barstate.ishistory` | `series bool` | The current bar is a historical bar (complement of `isrealtime`) |
| `bar_index` | `series int` | 0-based index of the current bar (0 = oldest visible bar) |
| `last_bar_index` | `series int` | Index of the last available bar |

```pine
//@version=5
indicator("Bar state demo", overlay = true)

// Draw a label only at the very last bar (updates as new bars arrive)
if barstate.islast
    label.new(bar_index, high * 1.002,
              "← latest bar\n" + str.tostring(bar_index) + " bars loaded",
              style = label.style_label_left,
              color = color.new(color.blue, 70),
              textcolor = color.white)

// Count how many realtime ticks have been seen on the live bar
var int live_ticks = 0
if barstate.isrealtime
    live_ticks += 1
```

### Time variables

| Variable | Type | Description |
|---|---|---|
| `time` | `series int` | Unix timestamp (milliseconds) of the bar's **open** |
| `time_close` | `series int` | Unix timestamp (milliseconds) of the bar's **close** |
| `year` | `series int` | Year of the bar's open time (e.g. 2025) |
| `month` | `series int` | Month 1–12 |
| `dayofmonth` | `series int` | Day of the month 1–31 |
| `dayofweek` | `series int` | Day of the week: `dayofweek.sunday` = 1, ..., `dayofweek.saturday` = 7 |
| `hour` | `series int` | Hour 0–23 of the bar's open |
| `minute` | `series int` | Minute 0–59 of the bar's open |
| `second` | `series int` | Second 0–59 of the bar's open |

```pine
//@version=5
indicator("Time demo", overlay = true)

// Highlight Monday opens (after a weekend gap)
is_monday = dayofweek == dayofweek.monday and hour == 0 and minute == 0

bgcolor(is_monday ? color.new(color.yellow, 85) : na, title = "Monday open")

// Display timestamp of latest bar in a label
if barstate.islast
    ts = str.format("{0}-{1,number,00}-{2,number,00} {3,number,00}:{4,number,00}",
                    year, month, dayofmonth, hour, minute)
    label.new(bar_index, low, ts,
              style = label.style_label_up, size = size.small,
              color = color.new(color.gray, 60))
```

### Timeframe variables

| Variable | Type | Description |
|---|---|---|
| `timeframe.period` | `simple string` | The chart's current timeframe as a string (e.g. `"60"`, `"D"`, `"W"`) |
| `timeframe.multiplier` | `simple int` | The numeric part of the period (e.g. `60` for a 60-minute chart) |
| `timeframe.isdaily` | `simple bool` | True when chart timeframe is daily |
| `timeframe.isintraday` | `simple bool` | True when chart timeframe is sub-daily |
| `timeframe.isweekly` | `simple bool` | True when chart timeframe is weekly |
| `timeframe.ismonthly` | `simple bool` | True when chart timeframe is monthly |

```pine
//@version=5
indicator("Timeframe guard demo")

// Warn the user if the script is applied to the wrong timeframe
if barstate.isfirst
    if not timeframe.isintraday
        label.new(bar_index, close, "⚠ This script is designed for intraday charts.",
                  color = color.red, textcolor = color.white,
                  style = label.style_label_right)
```

### Symbol info variables

| Variable | Type | Description |
|---|---|---|
| `syminfo.ticker` | `simple string` | Ticker symbol without exchange prefix (e.g. `"AAPL"`) |
| `syminfo.tickerid` | `simple string` | Fully qualified symbol including exchange (e.g. `"NASDAQ:AAPL"`) |
| `syminfo.currency` | `simple string` | Currency the instrument is quoted in (e.g. `"USD"`) |
| `syminfo.pointvalue` | `simple float` | Dollar value of one full point of price movement (contract size) |
| `syminfo.mintick` | `simple float` | Smallest valid price increment (tick size) |
| `syminfo.type` | `simple string` | Instrument type: `"stock"`, `"futures"`, `"forex"`, `"crypto"`, etc. |
| `syminfo.description` | `simple string` | Full name/description of the symbol |
| `syminfo.timezone` | `simple string` | Exchange timezone string (e.g. `"America/New_York"`) |

```pine
//@version=5
indicator("Symbol info demo", overlay = true)

// Compute position size using point value
risk_per_trade  = 500.0                   // dollars at risk
stop_ticks      = 20                      // stop distance in ticks
stop_points     = stop_ticks * syminfo.mintick
dollar_per_tick = syminfo.pointvalue * syminfo.mintick
contracts       = risk_per_trade / (stop_ticks * dollar_per_tick)

if barstate.islast
    label.new(bar_index, high,
              str.format("{0} | {1} | min tick: {2}\nContracts for ${3} risk: {4,number,#.##}",
                         syminfo.ticker, syminfo.type, syminfo.mintick,
                         risk_per_trade, contracts),
              style = label.style_label_left, size = size.normal,
              color = color.new(color.navy, 50), textcolor = color.white)
```

---

## 10. Common Gotchas

### Gotcha 1 — Repainting with `request.security()`

**The problem:** On the live, unconfirmed bar, `request.security()` returns the higher-timeframe bar's current in-progress value — not its final closed value. A signal fired on this value may disappear or change direction once that bar closes.

```pine
//@version=5
indicator("Repainting demo")

// REPAINT-PRONE: uses the current unfinished daily bar
daily_rsi_live = request.security(syminfo.tickerid, "D", ta.rsi(close, 14))
plot(daily_rsi_live, "Daily RSI (repaints)", color = color.red)

// REPAINT-SAFE option 1: request the confirmed (previous) bar's value
daily_rsi_safe = request.security(syminfo.tickerid, "D", ta.rsi(close, 14)[1])
plot(daily_rsi_safe, "Daily RSI (no repaint, lagged)", color = color.green)

// REPAINT-SAFE option 2: guard signal execution on the current bar
if barstate.isconfirmed
    // any logic here only runs once the bar has fully closed
    if daily_rsi_live > 70
        label.new(bar_index, high, "OB confirmed", style = label.style_label_down)
```

**Rule of thumb:** If a signal is derived from a higher-timeframe series and must be stable on historical bars, use `close[1]` with `barmerge.lookahead_off` (the default) or gate it with `barstate.isconfirmed`.

---

### Gotcha 2 — `na` propagation

**The problem:** Almost every arithmetic or comparison operation involving `na` returns `na`. Silent `na` propagation can zero out indicators or make conditions permanently false.

```pine
//@version=5
indicator("na propagation demo")

var float acc = na    // starts as na

// BUG: acc stays na forever because na + close == na
acc := acc + close   // ← wrong if you wanted a running sum

// FIX: use nz() to substitute a safe default before the operation
var float acc2 = 0.0
acc2 := nz(acc2, 0.0) + close   // nz returns 0.0 if acc2 is na, else acc2

// Checking for na explicitly before branching
var float last_known = na
if not na(close)
    last_known := close

// fixnan() forward-fills — replaces na with most recent non-na value
filled = fixnan(acc2)

plot(acc2,  "Running sum")
plot(filled,"Forward-filled")
```

Diagnostics: plot a suspect variable and look for a flat line at zero or a gap. A flat zero usually means `na` was converted to 0 somewhere (e.g., by `plot()` clipping), while a gap means the value is genuinely `na` through those bars.

---

### Gotcha 3 — Series vs. simple context

**The problem:** Many built-in functions require their `length` (or other configuration) argument to be `simple int` — a value fixed at bar 0. Passing a `series int` (one that changes bar by bar) causes a compile error.

```pine
//@version=5
indicator("Series vs simple demo")

// This COMPILES — input.int() produces input int, which satisfies simple int
length = input.int(14, "Length")
rsi_ok = ta.rsi(close, length)   // OK

// This FAILS TO COMPILE — bar_index is a series int (changes every bar)
// rsi_bad = ta.rsi(close, bar_index)
// ERROR: "Argument 'length' of type 'series int' used where 'simple int' is expected"

// Workaround: if you genuinely need a dynamic length, you must write the
// calculation manually instead of using the built-in
dyn_len = math.min(bar_index + 1, 50)   // still series int
var float custom_sum = 0.0
// ... (manual rolling calculation)
```

**When you encounter this error:** Check whether the argument that changes each bar can be replaced with an `input.*` value. If it truly must vary, you need a manual implementation or a different algorithm.

---

### Gotcha 4 — `max_bars_back` for large historical offsets

**The problem:** Pine pre-allocates a history buffer for each series. By default the buffer holds 300–500 bars. Referencing `close[500]` or more triggers a runtime error: "Index N is too large. Maximum allowed is M."

```pine
//@version=5
// FIX 1: declare max_bars_back in the indicator() call
indicator("max_bars_back demo", max_bars_back = 1000)

// FIX 2: set it for a specific series at runtime
max_bars_back(close, 1000)

lookback = 750
old_close = close[lookback]   // works once max_bars_back is raised

// FIX 3: for request.security() expressions that look back far,
// set max_bars_back inside the security call's expression
// (the buffer limit applies to expressions evaluated inside request.security too)
```

**When you hit this error:** Add `max_bars_back = <N>` to the `indicator()` / `strategy()` declaration, or call `max_bars_back(series, N)` for specific series. Set `N` to at least the largest offset you reference.

---

### Gotcha 5 — Strategy vs. indicator restrictions

Some features are exclusive to one script type. Confusing them causes compile errors that can be hard to diagnose.

| Feature | `indicator()` | `strategy()` | `library()` |
|---|---|---|---|
| `strategy.entry/exit/close` | No — compile error | Yes | No — compile error |
| `alertcondition()` | Yes | No — compile error | No |
| `alert()` | Yes | Yes | No |
| Backtest Strategy Tester tab | No | Yes | No |
| `export` functions/types | No | No | Yes |
| Can be `import`-ed | No | No | Yes |
| `plot()`, `plotshape()`, etc. | Yes | Yes (overlay only for price plots) | No |
| `hline()` | Yes | Yes | No |
| `table.new()` / `label.new()` | Yes | Yes | No |

**Tip:** If you intend to backtest, start with `strategy()`. If you only need to display data, use `indicator()`. You cannot do both in a single script — split them into two files that share a library if needed.

---

### Gotcha 6 — Execution model: historical vs. realtime

**The problem:** Developers coming from MultiCharts PowerLanguage expect bar-by-bar execution to follow the same model they are used to. Pine's model differs in two important ways.

**Historical bars (replay mode):**
- The script executes exactly once per bar, called at the bar's **close**.
- OHLCV values are final — there is no tick-by-tick variation.
- `barstate.ishistory` is true; `barstate.isrealtime` is false.

**Realtime bar (live market):**
- The script re-executes on **every incoming tick** (every price update).
- `open`, `high`, `low`, `close`, `volume` are all live values that change each tick.
- `barstate.isrealtime` is true; `barstate.isconfirmed` is false until the bar closes.
- When the bar closes and becomes a historical bar, the script executes one final time with `barstate.isconfirmed = true` and the permanent OHLCV values.

```pine
//@version=5
indicator("Execution model demo", overlay = true)

// Variables declared with var persist; those without are reset each execution
var int confirmed_bars = 0     // accumulates once per confirmed close
var int realtime_ticks = 0     // accumulates every live tick

if barstate.isconfirmed
    confirmed_bars += 1         // increments exactly once per closed bar

if barstate.isrealtime
    realtime_ticks += 1         // increments every live price update

// Without var: recomputed on every execution (history: once/bar; live: every tick)
mid = (high + low) / 2

plot(mid, "Mid (live, ticks)")
```

**Contrast with PowerLanguage:** In MultiCharts, `CalcAtMarketClose` and `CalcOnTick` are explicit per-indicator settings that the user controls from the Properties dialog. In Pine, the behavior is always: once per historical bar at close, every tick on the live bar — with no per-indicator switch to change it. To suppress intra-bar noise, gate your logic with `if barstate.isconfirmed`.

### Gotcha 7 — History-referencing functions must be called at global scope

Functions that track state across bars — `ta.crossover()`, `ta.crossunder()`, `ta.change()`, `ta.pivothigh()`, `ta.pivotlow()`, `ta.barssince()`, `ta.valuewhen()` — must be called on **every bar** to maintain correct internal state. Calling them inside a conditional block (e.g. inside `if strategy.position_size > 0`) means they only execute on some bars, producing incorrect results and a compiler warning.

```pine
// BAD — called inside a conditional scope, triggers warning:
// "The function 'ta.crossunder' should be called on each calculation for consistency"
if strategy.position_size > 0
    if ta.crossunder(macdLine, signalLine)  // only runs when in a position
        strategy.close("LE")

// GOOD — call at global scope, use the result inside the condition
macdCrossDown = ta.crossunder(macdLine, signalLine)  // runs every bar
if strategy.position_size > 0 and macdCrossDown
    strategy.close("LE")
```

This applies to any `ta.*` function that uses historical comparison. Extract the call to a variable at the top level, then reference the variable inside your conditions.
