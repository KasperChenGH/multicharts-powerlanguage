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
