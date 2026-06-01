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

**Practical rule:** Use `//@version=5` for broad compatibility with existing examples and documentation. Use `//@version=6` when you need `chart.point`, `polyline`, or the extended UDT method syntax.

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

// --- strategy.exit(id, from_entry, stop?, limit?, trail_price?, trail_offset?, loss?, profit?)
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
