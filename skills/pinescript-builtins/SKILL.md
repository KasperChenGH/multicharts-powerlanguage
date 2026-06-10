---
name: pinescript-builtins
description: Use when writing Pine Script logic with built-in namespaces — ta.* (averages, oscillators, crossovers), strategy.* (orders, position info), request.* (multi-timeframe), math.*, str.*, array.*, color.*, bar state, symbol info.
---

# Pine Script Built-in Namespaces

## ta.* — Technical Analysis

The `ta` namespace contains all indicator calculations. Every function operates on series data and returns series data.

### Moving Averages

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

### Oscillators

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

### Trend

`ta.macd` returns a **tuple** of three series — you must destructure with `[macdLine, signalLine, histogram]`:

```pine
[macd_line, signal_line, hist] = ta.macd(close, 12, 26, 9)
```

`ta.supertrend` also returns a **tuple** — the trend value and a direction integer (+1 or -1):

```pine
[st_value, st_direction] = ta.supertrend(3.0, 10)
// st_direction: -1 means uptrend (price above), +1 means downtrend (price below)
```

| Function | Signature | Returns |
|---|---|---|
| `ta.dmi` | `ta.dmi(diLength, adxSmoothing)` | `[diPlus, diMinus, adxValue]` tuple |

> **Gotcha — no `ta.adx()`.** Pine has no standalone ADX function. Use `ta.dmi()` which returns a three-value tuple:
> ```pine
> [di_plus, di_minus, adx_val] = ta.dmi(14, 14)
> ```

### Volatility

| Function | Signature | Returns |
|---|---|---|
| `ta.atr` | `ta.atr(length)` | `series float` — average true range |
| `ta.bb` | `ta.bb(source, length, mult)` | `[middle, upper, lower]` tuple |
| `ta.kc` | `ta.kc(source, length, mult)` | `[middle, upper, lower]` tuple (Keltner channels) |

```pine
[bb_mid, bb_upper, bb_lower] = ta.bb(close, 20, 2.0)
```

### Volume

| Function / Variable | Notes |
|---|---|
| `ta.obv` | Built-in variable (no parentheses) — on-balance volume running total |
| `ta.vwap` | Built-in variable (no parentheses) — volume-weighted average price, resets each session |

### Crossovers & Lookbacks

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
fast = ta.ema(close, 9)
slow = ta.ema(close, 21)

buy_signal  = ta.crossover(fast, slow)
sell_signal = ta.crossunder(fast, slow)

plotshape(buy_signal,  "Buy",  shape.triangleup,   location.belowbar, color.green)
plotshape(sell_signal, "Sell", shape.triangledown,  location.abovebar, color.red)
```

---

## strategy.* — Strategy Orders & Position Info

The `strategy` namespace is only available in scripts declared with `strategy()`. Attempting to call order functions in an `indicator()` or `library()` context causes a compile error.

### Order Functions

```pine
//@version=5
strategy("Order examples", overlay = true, initial_capital = 10000,
         default_qty_type = strategy.percent_of_equity, default_qty_value = 10)

fast = ta.ema(close, 9)
slow = ta.ema(close, 21)

// --- strategy.entry(id, direction, qty?, ...)
if ta.crossover(fast, slow)
    strategy.entry("Long", strategy.long)

if ta.crossunder(fast, slow)
    strategy.entry("Short", strategy.short)

// --- strategy.close(id) — closes the named open entry at market
// strategy.close("Long")

// --- strategy.close_all() — closes every open position immediately
// strategy.close_all()

// --- strategy.exit(id, from_entry, qty, qty_percent, profit, loss, limit, stop, trail_price, trail_points, trail_offset, comment)
// Units warning: profit, loss, trail_points, and trail_offset are in TICKS (counts);
// only the *_price params (stop, limit, trail_price) are price-denominated.
strategy.exit("Long Exit", from_entry = "Long",
              stop   = close * 0.98,
              limit  = close * 1.04,
              trail_points = 100,    // activate trailing after 100 ticks of profit
              trail_offset = 10)     // trail 10 ticks behind the best price

// --- strategy.order(id, direction, qty, ...)
// Lower-level: places a qty-specified order without the entry/exit pairing semantics

// --- strategy.cancel(id) / strategy.cancel_all()
// Cancels pending limit/stop orders
```

### Position Info Variables

| Variable | Type | Description |
|---|---|---|
| `strategy.position_size` | `series float` | Current open position size (positive = long, negative = short, 0 = flat) |
| `strategy.position_avg_price` | `series float` | Average fill price of the current open position |
| `strategy.opentrades` | `series int` | Number of currently open trades |
| `strategy.closedtrades` | `series int` | Total number of closed trades |
| `strategy.equity` | `series float` | Current account equity (initial capital + net profit + open profit) |
| `strategy.netprofit` | `series float` | Cumulative realized profit/loss |
| `strategy.openprofit` | `series float` | Unrealized P&L of open position(s) |
| `strategy.wintrades` | `series int` | Count of profitable closed trades |
| `strategy.losstrades` | `series int` | Count of losing closed trades |

```pine
is_long  = strategy.position_size > 0
is_short = strategy.position_size < 0
is_flat  = strategy.position_size == 0
```

---

## request.* — External Data

### `request.security()`

Pine's equivalent of MultiCharts's multi-data series (Data2, Data3, etc.) — it fetches data from a different symbol or timeframe.

```pine
//@version=5
indicator("Multi-timeframe RSI", overlay = false)

// Fetch the daily close on any intraday chart
daily_close = request.security("", "D", close)

// Fetch RSI calculated on the daily timeframe
daily_rsi = request.security(syminfo.tickerid, "D", ta.rsi(close, 14))

plot(daily_rsi, "Daily RSI", color = color.blue)
hline(70)
hline(30)
```

**Common pitfalls:**
- The `timeframe` argument must be `simple string` — you cannot pass a `series` variable.
- Requesting a **lower** timeframe returns only the last intra-bar value unless you use `request.security_lower_tf()`.
- **Repainting risk:** On the current unfinished bar, higher-timeframe data reflects the bar-in-progress. Use `close[1]` or gate with `barstate.isconfirmed`.

### `request.security_lower_tf()`

Returns all intra-bar values as an array:

```pine
one_min_closes = request.security_lower_tf(syminfo.tickerid, "1", close)
```

### `request.financial()`

Fetches fundamental financial data:

```pine
eps = request.financial(syminfo.tickerid, "EARNINGS_PER_SHARE_BASIC", "FQ")
// Period: "FQ" quarterly, "FY" annual, "TTM" trailing 12 months
```

---

## math.* — Math Functions

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

---

## str.* — String Functions

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

---

## array.* — Arrays

Pine arrays are dynamically-sized, index-based collections. All elements must share the same type.

### Creating and populating

```pine
var float[] prices = array.new_float(0)       // empty float array
var int[]   counts = array.new_int(5, 0)      // 5 elements, all initialized to 0

array.push(prices, close)            // append to end
array.unshift(prices, open)          // prepend to front
last_val  = array.pop(prices)        // remove and return last element
first_val = array.shift(prices)      // remove and return first element

array.set(prices, 0, close * 1.01)
val = array.get(prices, 0)
sz  = array.size(prices)
```

### Statistical helpers

```pine
array.sort(prices, order.ascending)
avg_price = array.avg(prices)
total     = array.sum(prices)
hi        = array.max(prices)
lo        = array.min(prices)
```

### Rolling window pattern

```pine
var float[] window = array.new_float(0)
window_size = 20

array.push(window, close)
if array.size(window) > window_size
    array.shift(window)   // drop the oldest value

rolling_avg = array.size(window) == window_size ? array.avg(window) : na
```

> **Constructors:** use `array.new_int()`, `array.new_float()`, `array.new_bool()`, `array.new_string()`, `array.new_color()`, or the generic `array.new<type>(size, initial_value)` (e.g. `array.new<float>(0)`).

---

## color.* — Colors

### Named color constants

```pine
color.red     color.green    color.blue     color.orange
color.yellow  color.purple   color.fuchsia  color.teal
color.navy    color.maroon   color.lime     color.olive
color.aqua    color.white    color.black    color.gray
color.silver
```

### `color.new()` — apply transparency

```pine
// color.new(baseColor, transparency)
// transparency: 0 = fully opaque, 100 = fully transparent
semi_blue = color.new(color.blue, 60)
```

### `color.rgb()` — build from components

```pine
// color.rgb(r, g, b, transparency?)
my_teal = color.rgb(0, 128, 128)
```

### Dynamic color

```pine
bar_col  = rsi > 70 ? color.new(color.red, 20)
         : rsi < 30 ? color.new(color.green, 20)
         :             color.new(color.gray, 60)
bgcolor(bar_col)
```

---

## Bar State & Time

### Bar state variables

| Variable | Type | True when |
|---|---|---|
| `barstate.isfirst` | `series bool` | Currently executing the very first historical bar |
| `barstate.islast` | `series bool` | Currently executing the last bar on the chart |
| `barstate.isrealtime` | `series bool` | The current bar is a live, unconfirmed bar |
| `barstate.isconfirmed` | `series bool` | The current bar has just closed — OHLCV values are final |
| `barstate.isnew` | `series bool` | This is the first tick of a new bar |
| `barstate.ishistory` | `series bool` | The current bar is a historical bar |
| `bar_index` | `series int` | 0-based index of the current bar |
| `last_bar_index` | `series int` | Index of the last available bar |

### Time variables

| Variable | Type | Description |
|---|---|---|
| `time` | `series int` | Unix timestamp (ms) of the bar's **open** |
| `time_close` | `series int` | Unix timestamp (ms) of the bar's **close** |
| `year` | `series int` | Year of the bar's open time |
| `month` | `series int` | Month 1–12 |
| `dayofmonth` | `series int` | Day of the month 1–31 |
| `dayofweek` | `series int` | Day of the week: `dayofweek.sunday` = 1, ..., `dayofweek.saturday` = 7 |
| `hour` | `series int` | Hour 0–23 of the bar's open |
| `minute` | `series int` | Minute 0–59 |
| `second` | `series int` | Second 0–59 |

### Timeframe variables

| Variable | Type | Description |
|---|---|---|
| `timeframe.period` | `simple string` | Chart timeframe as string (e.g. `"60"`, `"D"`, `"W"`) |
| `timeframe.multiplier` | `simple int` | Numeric part of the period |
| `timeframe.isdaily` | `simple bool` | True when chart is daily |
| `timeframe.isintraday` | `simple bool` | True when chart is sub-daily |
| `timeframe.isweekly` | `simple bool` | True when chart is weekly |
| `timeframe.ismonthly` | `simple bool` | True when chart is monthly |

### Symbol info variables

| Variable | Type | Description |
|---|---|---|
| `syminfo.ticker` | `simple string` | Ticker without exchange prefix (e.g. `"AAPL"`) |
| `syminfo.tickerid` | `simple string` | Fully qualified symbol (e.g. `"NASDAQ:AAPL"`) |
| `syminfo.currency` | `simple string` | Quote currency (e.g. `"USD"`) |
| `syminfo.pointvalue` | `simple float` | Dollar value of one full price point |
| `syminfo.mintick` | `simple float` | Smallest valid price increment (tick size) |
| `syminfo.type` | `simple string` | Instrument type: `"stock"`, `"futures"`, `"forex"`, `"crypto"` |
| `syminfo.description` | `simple string` | Full name of the symbol |
| `syminfo.timezone` | `simple string` | Exchange timezone string |
