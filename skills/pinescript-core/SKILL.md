---
name: pinescript-core
description: >-
  Use when writing or reading Pine Script code structure — language
  fundamentals: versioning (@version=5, @version=6), script types
  (indicator, strategy, library), type system (series, simple, input,
  const), declarations (var, varip, input.*), control flow (if/else,
  for, while, switch, ternary), user-defined functions/types/methods,
  and common gotchas (repainting, na handling, series vs simple context,
  max_bars_back, global-scope function calls). For built-in namespaces
  (ta.*, math.*, strategy.*, request.*), see pinescript-builtins. For
  plotting and drawing objects, see pinescript-visual.
---

# Pine Script Core — Language Fundamentals

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
| `request.*()` arguments | `symbol`/`timeframe` must be `simple string` | Accept `series string` — "dynamic requests" |
| `and` / `or` operators | Both operands always evaluated | Lazy (short-circuit) evaluation |
| `bool` values | Can be `na` | Strictly `true`/`false` — never `na` |
| `matrix.*` namespace | Available | Extended with more methods |
| `polyline.*` drawing | Available (added to v5 in 2023) | Available |
| `chart.point` type | Available (added to v5 in 2023) for coordinate-aware drawings | Available |
| `UDT` (user-defined types) | Available — methods attach via the `method` keyword (added to v5 in 2023) | Available |
| `import` libraries | Available; libraries can export methods | Available |

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

- Can use `plot()` and drawing functions in its global scope (typically to demo its exports); cannot place orders — `strategy.*` order functions are unavailable.
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
| `input` | Script load time — set by the user via Inputs dialog | `input`, `simple`, `series` |
| `simple` | Bar 0 (first bar) — fixed for the script's lifetime | `simple`, `series` |
| `series` | Every bar — the most general form | `series` only |

**The hierarchy is one-way.** A `const` value can be passed anywhere a less-restrictive qualifier is expected, but a `series` value cannot be passed where `simple` is required.

```pine
//@version=5
indicator("Qualifier demo")

// This works — literal 14 is const int, which satisfies simple int
length = input.int(14, "Length")
ema_val = ta.ema(close, length)  // length is input int → accepted as simple int

// This FAILS — bar index changes every bar, so it is series int
// ta.ema(close, bar_index)  // ERROR: "simple int" argument required, got "series int"

plot(ema_val)
```

Common functions that require `simple` (not `series`) arguments include `ta.ema()`, `ta.rsi()`, `ta.rma()`, `ta.atr()`, and most `request.*` functions for their `timeframe` parameter. (`ta.sma()` is more permissive — its `length` accepts `series int`.)

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
indicator("varip example")

varip int tick_count = 0  // increments every real-time tick, not just every closed bar

tick_count += 1
plot(tick_count)
```

- Like `var`, but updates survive intra-bar recalculations in real-time.
- On historical bars `varip` behaves identically to `var`.
- Rarely needed — only useful when you need state that survives intra-bar updates on the realtime bar (indicators always recalculate per tick; strategies need `calc_on_every_tick = true` in `strategy()`).

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

## 5. Control Flow

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

## 6. User-Defined Functions & Types

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
    float[] data                  // collection fields cannot have defaults — initialize via .new()
    int     capacity = 20

// method defined on PriceBuffer
method push(PriceBuffer this, float val) =>
    array.push(this.data, val)
    if array.size(this.data) > this.capacity
        array.shift(this.data)

method average(PriceBuffer this) =>
    array.size(this.data) > 0 ? array.avg(this.data) : na

var PriceBuffer buf = PriceBuffer.new(data = array.new_float(0))

buf.push(close)           // call the method with dot notation
plot(buf.average(), "Buffer avg")
```

### `export` and `import` for library functions

In a `library()` script, mark public functions with `export`. Callers import the library using a version-qualified path.

```pine
// ---- In a library script titled "MathUtils" ----
//@version=5
library("MathUtils", overlay = false)

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

## 7. Common Gotchas

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

// fixnan() forward-fills — replaces na with most recent non-na value
filled = fixnan(acc2)

plot(acc2,  "Running sum")
plot(filled,"Forward-filled")
```

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
```

**When you hit this error:** Add `max_bars_back = <N>` to the `indicator()` / `strategy()` declaration, or call `max_bars_back(series, N)` for specific series. Set `N` to at least the largest offset you reference.

---

### Gotcha 5 — Strategy vs. indicator restrictions

| Feature | `indicator()` | `strategy()` | `library()` |
|---|---|---|---|
| `strategy.entry/exit/close` | No — compile error | Yes | No — compile error |
| `alertcondition()` | Yes | No — compile error | No |
| `alert()` | Yes | Yes | No |
| Backtest Strategy Tester tab | No | Yes | No |
| `export` functions/types | No | No | Yes |
| Can be `import`-ed | No | No | Yes |
| `plot()`, `plotshape()`, etc. | Yes | Yes (overlay only for price plots) | Yes (global scope only) |

**Tip:** If you intend to backtest, start with `strategy()`. If you only need to display data, use `indicator()`. You cannot do both in a single script — split them into two files that share a library if needed.

---

### Gotcha 6 — Execution model: historical vs. realtime

**Historical bars (replay mode):**
- The script executes exactly once per bar, called at the bar's **close**.
- OHLCV values are final — there is no tick-by-tick variation.
- `barstate.ishistory` is true; `barstate.isrealtime` is false.

**Realtime bar (live market):**
- The script re-executes on **every incoming tick** (every price update).
- `open`, `high`, `low`, `close`, `volume` are all live values that change each tick.
- `barstate.isrealtime` is true; `barstate.isconfirmed` is false until the bar closes.

**Contrast with PowerLanguage:** In MultiCharts, `CalcAtMarketClose` and `CalcOnTick` are explicit per-indicator settings. In Pine, the behavior is always: once per historical bar at close, every tick on the live bar. To suppress intra-bar noise, gate your logic with `if barstate.isconfirmed`.

### Gotcha 7 — History-referencing functions must be called at global scope

Functions that track state across bars — `ta.crossover()`, `ta.crossunder()`, `ta.change()`, `ta.pivothigh()`, `ta.pivotlow()`, `ta.barssince()`, `ta.valuewhen()` — must be called on **every bar** to maintain correct internal state. Calling them inside a conditional block produces incorrect results and a compiler warning.

```pine
// BAD — called inside a conditional scope
if strategy.position_size > 0
    if ta.crossunder(macdLine, signalLine)  // only runs when in a position
        strategy.close("LE")

// GOOD — call at global scope, use the result inside the condition
macdCrossDown = ta.crossunder(macdLine, signalLine)  // runs every bar
if strategy.position_size > 0 and macdCrossDown
    strategy.close("LE")
```

This applies to any `ta.*` function that uses historical comparison. Extract the call to a variable at the top level, then reference the variable inside your conditions.
