---
name: powerlanguage-rust-conversion
description: >-
  Use when converting, translating, porting, or migrating code between
  MultiCharts PowerLanguage and Rust, in either direction. Contains a
  lightweight Strategy trait scaffold, concept mapping tables, semantic
  difference documentation, and pre/post-conversion checklists. References
  powerlanguage-syntax for PowerLanguage-specific details. Recommends the
  ta-rs crate for technical indicators.
---

# PowerLanguage ↔ Rust Conversion

## How to use

This skill covers the structural and semantic differences between MultiCharts PowerLanguage and Rust for algorithmic trading. It does not duplicate the syntax rules of PowerLanguage — for declarations, bar references, control flow, and built-in function signatures use the `powerlanguage-syntax` skill. When performing a conversion in either direction, work through Part 0 (structural template) to set up the boilerplate, then Part 1 (concept mapping) for line-by-line translation, then review Part 2 (semantic differences and gotchas), and finally run through the relevant checklist in Part 3 before calling the output complete.

---

## Part 0: Structural Template

PowerLanguage runs the entire script top-to-bottom on each bar close automatically. Rust has no implicit bar loop, no built-in OHLCV type, and no order submission mechanism. Every PL-to-Rust conversion targets the framework-agnostic scaffold below.

### Bar struct

```rust
#[derive(Debug, Clone, Copy)]
pub struct Bar {
    pub open: f64,
    pub high: f64,
    pub low: f64,
    pub close: f64,
    pub volume: f64,
    pub time: i64,        // Unix epoch seconds
    pub bar_number: usize, // 1-based to match PL convention
}
```

### Order types

```rust
#[derive(Debug, Clone)]
pub enum Side { Long, Short }

#[derive(Debug, Clone)]
pub enum OrderType {
    Market,
    Limit(f64),
    Stop(f64),
}

#[derive(Debug, Clone)]
pub struct Order {
    pub label: String,
    pub side: Side,
    pub order_type: OrderType,
    pub qty: f64,
}
```

### Strategy trait

```rust
pub trait Strategy {
    fn on_bar(&mut self, bars: &[Bar], orders: &mut Vec<Order>);
}
```

### Strategy struct skeleton

```rust
use ta::indicators::{SimpleMovingAverage, RelativeStrengthIndex};
use ta::Next;

pub struct MyStrategy {
    // Inputs (PL: Inputs: Length(20))
    length: usize,

    // Variables (PL: Variables: my_var(0))
    my_var: f64,

    // Indicators — create once, call .next() per bar
    sma: SimpleMovingAverage,

    // Position state (PL: MarketPosition, EntryPrice, etc.)
    position: i32,          // -1, 0, +1
    entry_price: f64,
    bars_since_entry: usize,
    current_contracts: f64,
}
```

### Main loop

```rust
fn main() {
    let bars: Vec<Bar> = load_bars("data.csv"); // user-provided
    let mut strategy = MyStrategy::new(/* inputs */);
    let mut orders = Vec::new();

    for i in 0..bars.len() {
        orders.clear();
        strategy.on_bar(&bars[..=i], &mut orders);
        // execute orders against simulated book...
    }
}
```

The slice `&bars[..=i]` gives the strategy access to full history; `bars.last().unwrap()` is the current bar. This mirrors PL's implicit bar-by-bar execution.

---

## Part 1: Concept Mapping

### Table 1 — Declarations

| PowerLanguage | Rust | Notes |
|---|---|---|
| `Inputs: Length(20)` | `length: usize` field + constructor param | Inputs become immutable struct fields set at construction |
| `Variables: myVar(0)` | `my_var: f64` field (initialized in `new()`) | Mutable struct fields; set initial value in the constructor |
| `Value1` .. `Value99` | named field (e.g., `rsi_val: f64`) | Must rename to meaningful identifiers; Rust has no pre-declared variables |
| `Condition1` .. `Condition99` | named field (e.g., `is_oversold: bool`) | Same: rename to typed `bool` fields |
| `Arrays: buf[10](0)` | `buf: [f64; 11]` or `Vec<f64>` | PL `[10]` means last index is 10 (11 elements); use `[0.0; 11]` for fixed or `vec![0.0; 11]` for heap |
| `IntraBarPersist myVar(0)` | `my_var: f64` field (same as Variables) | Rust has no bar-close vs intra-bar distinction; all struct fields persist across calls |

---

### Table 2 — Data Access

| PowerLanguage | Rust | Notes |
|---|---|---|
| `Open`, `High`, `Low`, `Close`, `Volume` | `bar.open`, `bar.high`, `bar.low`, `bar.close`, `bar.volume` | `let bar = bars.last().unwrap();` for current bar |
| `Close[1]` | `bars[bars.len() - 2].close` | Lookback N: `bars[bars.len() - 1 - n].close`. Guard with `bars.len() > n` to avoid panic. |
| `Close of Data2` | separate `bars2: &[Bar]` parameter or struct field | PL Data2 is a second chart feed; pass a second bar slice to `on_bar()` |
| `Date` | `chrono::DateTime::from_timestamp(bar.time, 0).unwrap().naive_utc()` | PL `Date` is YYYMMDD integer (YYY = years since 1900, e.g., 2024 = `124`); Rust uses the `chrono` crate |
| `Time` | `chrono::DateTime::from_timestamp(bar.time, 0).unwrap().naive_utc().time()` | PL `Time` is HHMM integer; extract hour/minute from timestamp |
| `BarNumber` / `CurrentBar` | `bar.bar_number` or `i + 1` (loop index) | PL is 1-based; if using loop index `i`, add 1 |

---

### Table 3 — Technical Indicators

| PowerLanguage | Rust (ta-rs) | Notes |
|---|---|---|
| `Average(Close, Length)` | `SimpleMovingAverage::new(length).unwrap()` → `.next(bar.close)` | Create once in `new()`, call `next()` in `on_bar()` |
| `XAverage(Close, Length)` | `ExponentialMovingAverage::new(length).unwrap()` → `.next(bar.close)` | Same streaming pattern |
| `RSI(Close, Length)` | `RelativeStrengthIndex::new(length).unwrap()` → `.next(bar.close)` | Returns 0–100 range matching PL |
| `Stochastic(...)` | `SlowStochastic::new(k_period, d_period).unwrap()` → `.next(&data_item)` | Accepts f64 but needs OHLC `DataItem` for correct stochastic formula; PL takes 11 params — map k_period and d_period |
| `ADX(Length)` | Not in ta-rs; use `yata::indicators::ADX` or implement manually | ta-rs lacks ADX; `yata` crate covers it |
| `CCI(Length)` | `CommodityChannelIndex::new(length).unwrap()` → `.next(&data_item)` | PL `CCI` takes only length (uses HLC internally); ta-rs requires a type implementing `Close + High + Low` |
| `AvgTrueRange(Length)` | `AverageTrueRange::new(length).unwrap()` → `.next(&data_item)` | Accepts f64 but needs OHLC `DataItem` for correct true-range calculation (high-low range) |
| `BollingerBand(Close, Length, 2)` | `BollingerBands::new(length, 2.0).unwrap()` → `.next(bar.close)` | Returns `BollingerBandsOutput { average, upper, lower }`. Note: ta-rs may use EMA internally — verify output matches PL's SMA-based Bollinger Bands |
| `Close Crosses Over MA` | `prev_close <= prev_ma && close > ma` | No built-in crossover in ta-rs; store previous-bar values yourself |
| `Close Crosses Under MA` | `prev_close >= prev_ma && close < ma` | Same pattern, reversed inequality |
| `Highest(Close, Length)` | `Maximum::new(length).unwrap()` → `.next(bar.close)` | ta-rs `Maximum` indicator |
| `Lowest(Close, Length)` | `Minimum::new(length).unwrap()` → `.next(bar.close)` | ta-rs `Minimum` indicator |
| `Momentum(Close, Length)` | `close - bars[bars.len() - 1 - length].close` | No ta-rs built-in; compute directly from bar slice. Guard with `bars.len() > length`. |
| `TSI(Close, LongLen, ShortLen)` | Manual: double-EMA of momentum / double-EMA of abs(momentum) | No ta-rs built-in; use two nested `ExponentialMovingAverage` pairs — one for `EMA(EMA(mtm, long), short)`, one for `EMA(EMA(abs(mtm), long), short)`, then `100 * ratio` |
| `AverageFC(Close, Length)` | `SimpleMovingAverage::new(length).unwrap()` → `.next(bar.close)` | "Fast calculation" variant; same result as `Average` — use `SimpleMovingAverage` |
| `WAverage(Close, Length)` | Manual: weighted sum `Σ(close[i] * (length - i)) / Σ(1..=length)` | No ta-rs built-in; iterate `bars[len-length..len]`, weight newest bar highest |
| `AdaptiveMovAvg(Close, Length)` | `EfficiencyRatio::new(length)` + manual AMA smoothing | Use ta-rs `EfficiencyRatio`; AMA = `prev + er^2 * (close - prev)` (Kaufman formula) |
| `MidPoint(Close, Length)` | `(Maximum::new(length).next(c) + Minimum::new(length).next(c)) / 2.0` | Combine ta-rs `Maximum` and `Minimum` |
| `MACD(Close, FastLen, SlowLen)` | `ta::indicators::MovingAverageConvergenceDivergence::new(fast, slow, signal).unwrap()` → `.next(bar.close)` | Returns `MACDOutput { macd, signal, histogram }` |
| `KeltnerChannel(Close, Length, Factor)` | `KeltnerChannel::new(length, factor).unwrap()` → `.next(&data_item)` | Returns `KeltnerChannelOutput { average, upper, lower }`; needs OHLC `DataItem` |
| `DMIPlus(Length)` | Manual or `yata`; +DI = 100 × smoothed(+DM) / smoothed(TR) | Not in ta-rs; compute +DM = `max(high - prev_high, 0)` when > −DM, else 0 |
| `DMIMinus(Length)` | Manual or `yata`; −DI = 100 × smoothed(−DM) / smoothed(TR) | Not in ta-rs; compute −DM = `max(prev_low - low, 0)` when > +DM, else 0 |
| `RateOfChange(Close, Length)` | `RateOfChange::new(length).unwrap()` → `.next(bar.close)` | ta-rs `RateOfChange`; returns percentage change |
| `PercentR(Length)` | Manual: `−100 × (highest − close) / (highest − lowest)` | Use ta-rs `Maximum`/`Minimum` over `length` bars for highest-high/lowest-low |
| `MoneyFlow(Length)` | Manual: MFI = 100 − 100/(1 + pos_flow/neg_flow) | Classify each bar's typical-price × volume as positive or negative, sum over `length` |
| `Parabolic(AFStep, AFMax)` | Manual state machine tracking AF and EP | No crate built-in; maintain `af`, `ep`, `sar`, flip on new extreme; complex — ~40 lines |
| `Volatility(Length)` | `StandardDeviation::new(length).unwrap()` → `.next(bar.close)` | PL `Volatility` = standard deviation of close; ta-rs `StandardDeviation` matches |
| `UltimateOscillator(Fast, Mid, Slow)` | Manual: weighted average of BP/TR ratios over three periods | BP = close − min(low, prev_close); sum BP and TR over 7/14/28, weight 4:2:1 |
| `ChaikinOsc(FastLen, SlowLen)` | Manual: EMA(fast, ADL) − EMA(slow, ADL) | ADL = cum sum of `((close−low)−(high−close))/(high−low) × volume`; apply two EMAs |
| `PriceOscillator(FastLen, SlowLen)` | Manual: `EMA(fast) − EMA(slow)` | Two `ExponentialMovingAverage` instances; subtract slow from fast |
| `DirMovement(Length, oADX, oDIP, oDIM)` | Manual or `yata`: computes ADX, +DI, −DI together | Multi-output; return a struct `{ adx, di_plus, di_minus }` |
| `Extremes(Length, oHi, oHiBar, oLo, oLoBar)` | Manual: scan `bars[len-length..len]` for max/min and their offsets | Multi-output; return `{ highest, highest_bar, lowest, lowest_bar }` |
| `TrueRange` | `TrueRange::new()` → `.next(&data_item)` | ta-rs `TrueRange`; needs OHLC `DataItem` |
| `StandardDev(Close, Length)` | `StandardDeviation::new(length).unwrap()` → `.next(bar.close)` | ta-rs `StandardDeviation` |
| `TrueHigh` | Manual: `bar.high.max(prev_bar.close)` | Max of current high and previous close; guard `bars.len() > 1` |
| `TrueLow` | Manual: `bar.low.min(prev_bar.close)` | Min of current low and previous close; guard `bars.len() > 1` |
| `Range` | Manual: `bar.high - bar.low` | Current bar's high minus low |
| `HighestBar(Close, Length)` | Manual: index of max in `bars[len-length..len]` | Returns bars-ago offset (0 = current bar); scan with `enumerate()` + `max_by()` |
| `LowestBar(Close, Length)` | Manual: index of min in `bars[len-length..len]` | Returns bars-ago offset; scan with `enumerate()` + `min_by()` |
| `NthHighest(N, Close, Length)` | Manual: sort last `length` closes descending, take index `N-1` | Collect into `Vec`, `sort_by()` descending, return `[n-1]` |
| `NthLowest(N, Close, Length)` | Manual: sort last `length` closes ascending, take index `N-1` | Collect into `Vec`, `sort_by()` ascending, return `[n-1]` |
| `NthHighestBar(N, Close, Length)` | Manual: sort with indices, return bars-ago of Nth highest | Pair `(value, offset)`, sort descending, return offset at `N-1` |
| `NthLowestBar(N, Close, Length)` | Manual: sort with indices, return bars-ago of Nth lowest | Pair `(value, offset)`, sort ascending, return offset at `N-1` |
| `SwingHigh(Instance, Close, LeftStr, RightStr)` | Manual: `bars[pivot]` > all `LeftStr` bars before and `RightStr` bars after | Confirmed only after `RightStr` bars pass; `Instance` selects Nth most recent swing |
| `SwingLow(Instance, Close, LeftStr, RightStr)` | Manual: `bars[pivot]` < all `LeftStr` bars before and `RightStr` bars after | Same pivot logic, reversed comparison |
| `SwingHighBar(Instance, Close, LeftStr, RightStr)` | Manual: bars-ago offset of the detected swing high | Same detection as `SwingHigh`; return `bars.len() - 1 - pivot_index` |
| `SwingLowBar(Instance, Close, LeftStr, RightStr)` | Manual: bars-ago offset of the detected swing low | Same detection as `SwingLow`; return offset |
| `Summation(Close, Length)` | Manual: `bars[len-length..len].iter().map(\|b\| b.close).sum::<f64>()` | Rolling sum over last `length` bars |
| `Cum(Close)` | Manual: `self.cum_val += bar.close;` | Cumulative sum from bar 1; store running total in struct field |
| `LinearRegValue(Close, Length, Offset)` | Manual: least-squares fit over `length` bars, evaluate at `Offset` | Compute slope/intercept via `Σxy`, `Σx²`; project forward by `Offset` bars |
| `LinearRegAngle(Close, Length)` | Manual: `slope.atan().to_degrees()` | Angle in degrees of the regression line slope |
| `LinearRegSlope(Close, Length)` | Manual: `(n*Σxy − Σx*Σy) / (n*Σx² − (Σx)²)` | Standard least-squares slope formula over `length` bars |
| `Correlation(Close1, Close2, Length)` | Manual: Pearson `r` over `length` bars | `r = (nΣxy − ΣxΣy) / sqrt((nΣx²−(Σx)²)(nΣy²−(Σy)²))` |
| `RSquared(Close, Length)` | Manual: `correlation(close, 1..=length)²` | R² of close vs bar index; square the Pearson `r` |
| `StdError(Close, Length)` | Manual: std error of estimate around regression line | `sqrt(Σ(close − predicted)² / (length − 2))` |
| `Median(Close, Length)` | Manual: collect last `length` values, sort, pick middle | `let mut v: Vec<f64> = ...; v.sort_by(\|a,b\| a.partial_cmp(b).unwrap()); v[length/2]` |
| `ELDate(dt)` | `NaiveDate::from_ymd_opt(year, month, day)` (chrono crate) | PL returns YYYMMDD integer (YYY = year − 1900); Rust uses `chrono::NaiveDate` |
| `MinutesToTime(mins)` | Manual: `let hhmm = (mins / 60) * 100 + mins % 60;` | PL returns HHMM integer; Rust can also use `NaiveTime::from_hms_opt(h, m, 0)` |
| `TimeToMinutes(hhmm)` | Manual: `let mins = (hhmm / 100) * 60 + hhmm % 100;` | Inverse of `MinutesToTime`; converts HHMM integer to total minutes |
| `AvgPrice` | Manual: `(bar.open + bar.high + bar.low + bar.close) / 4.0` | Average of OHLC |
| `MedianPrice` | Manual: `(bar.high + bar.low) / 2.0` | Midpoint of high and low |
| `TypicalPrice` | Manual: `(bar.high + bar.low + bar.close) / 3.0` | HLC average |
| `WeightedClose` | Manual: `(bar.high + bar.low + bar.close * 2.0) / 4.0` | Close-weighted HLC |
| `CountIF(Cond, Length)` | Manual: `bars[len-length..len].iter().filter(\|b\| cond(b)).count()` | Count bars satisfying condition over last `length` bars |
| `MRO(Cond, Length, Instance)` | Manual: scan backward from current bar for `Instance`-th true | Returns bars-ago offset; iterate `(1..=length).rev()`, decrement instance counter on match |
| `AccumDist` | Manual: `self.ad += ((close−low)−(high−close))/(high−low) * volume` | Cumulative; guard division by zero when `high == low` |
| `IFF(Cond, TrueVal, FalseVal)` | `if cond { true_val } else { false_val }` | Direct Rust `if/else` expression; returns a value |

---

### Table 4 — Strategy Orders

| PowerLanguage | Rust | Notes |
|---|---|---|
| `Buy("label") next bar market` | `orders.push(Order { label: "label".into(), side: Side::Long, order_type: OrderType::Market, qty: 1.0 })` | Push to the orders vec |
| `SellShort("label") next bar market` | `Order { side: Side::Short, order_type: OrderType::Market, .. }` | `Side::Short` for short entry |
| `Sell("label") next bar market` | Close long: set `self.position = 0` or push a close-position variant | **WARNING: PL `Sell` exits a long — do NOT map to `Side::Short`** |
| `BuyToCover("label") next bar market` | Close short: set `self.position = 0` | PL `BuyToCover` exits an existing short |
| `Buy("label") next bar at price limit` | `Order { order_type: OrderType::Limit(price), .. }` | Use the `Limit` variant |
| `Buy("label") next bar at price stop` | `Order { order_type: OrderType::Stop(price), .. }` | Use the `Stop` variant |
| `SetStopLoss(dollars)` | `stop_price = entry_price - dollars / (qty * point_value)` | PL takes a dollar amount; Rust must convert to price level |
| `SetProfitTarget(dollars)` | `target_price = entry_price + dollars / (qty * point_value)` | Same dollar-to-price conversion |

---

### Table 5 — Plotting

| PowerLanguage | Rust | Notes |
|---|---|---|
| `Plot1(value, "label")` | `println!("{}: {}", label, value)` or log to file | No chart in Rust; output to stdout, `log` crate, or a results Vec |
| `SetPlotColor(1, Red)` | N/A | No visual output; skip or store as metadata |
| `SetPlotWidth(1, 2)` | N/A | Skip |
| `NoPlot(1)` | skip output for that bar | Conditional: don't push to results |

---

### Table 6 — Control Flow

| PowerLanguage | Rust | Notes |
|---|---|---|
| `If cond Then Begin ... End;` | `if cond { ... }` | Direct mapping |
| `If cond Then ... Else ...` | `if cond { ... } else { ... }` | Direct mapping |
| `For i = 1 to n Begin ... End;` | `for i in 1..=n { ... }` | PL `For` is inclusive; Rust `..=` is inclusive |
| `While cond Begin ... End;` | `while cond { ... }` | Direct mapping |
| `Switch (expr) Begin Case 1: ... End;` | `match expr { 1 => { ... }, _ => {} }` | Rust `match` requires exhaustive arms; add `_ => {}` default |
| `Once Begin ... End;` | `if self.first_bar { ... self.first_bar = false; }` | Use a bool field; PL `Once` runs on first bar only |

---

### Table 7 — Other Built-ins and Features

| PowerLanguage | Rust | Notes |
|---|---|---|
| `MarketPosition` | `self.position` (i32: −1/0/+1) | Track manually; update on order fills |
| `EntryPrice` | `self.entry_price` (f64) | Track manually; set when position opens |
| `CurrentContracts` | `self.current_contracts` (f64) | Track manually; absolute contract count |
| `BarsSinceEntry` | `self.bars_since_entry` (usize) | Increment each bar while `position != 0`; reset on new entry |
| `Print("text")` | `println!("text")` or `log::info!("text")` | Use the `log` crate for structured logging |
| `#BeginCmtry ... #EndCmtry` | No equivalent | PL expert commentary; skip or log |
| `Alert("msg")` | `eprintln!("ALERT: msg")` or custom callback | No built-in alert mechanism |

---

## Part 2: Semantic Differences and Gotchas

1. **`Sell` does not mean "go short".** In PowerLanguage, `Sell` exits an existing long position. The Rust equivalent is closing the position (setting position to 0 and recording the exit). Do not create a new short entry as a translation of `Sell`.

2. **PL is implicitly bar-driven; Rust requires an explicit loop.** PowerLanguage executes the entire script top-to-bottom on each bar close automatically. In Rust, you must write the `for i in 0..bars.len()` loop yourself and call `on_bar()` on each iteration. Forgetting the loop wrapper means the strategy logic runs only once.

3. **Bar lookback can panic on insufficient history.** PL uses MaxBarsBack to prevent execution on bars with insufficient history — the script simply does not run on those early bars. Rust `bars[bars.len() - 6]` will panic with an index-out-of-bounds error. Always guard lookback access with `if bars.len() > n` before indexing. When the guard fails, either skip the bar with an early return (matching PL's MaxBarsBack behavior) or use a default value.

4. **ta-rs indicators are stateful and must be created once.** Each ta-rs indicator (SMA, EMA, RSI, etc.) maintains internal state via its struct. Create the indicator in `new()` and call `.next()` on each bar. Creating a new indicator inside `on_bar()` resets the calculation and produces wrong values.

5. **Some ta-rs indicators need OHLC data for correct results.** ATR, Stochastic, and CCI all accept plain f64 via `Next<f64>`, but passing only close prices produces incorrect values — ATR needs high-low range, Stochastic needs high/low/close, CCI needs typical price. Pass a `DataItem` (via `ta::DataItem::builder().open(o).high(h).low(l).close(c).volume(v).build().unwrap()`) or implement the `High + Low + Close` traits on your `Bar` struct.

6. **Crossover/crossunder has no built-in.** PL `Crosses Over` / `Crosses Under` are language keywords. ta-rs has no crossover function. Implement as: `let crossed_over = prev_a <= prev_b && a > b;`. You must store previous-bar values in struct fields.

7. **Dollar amounts versus price levels for stops.** `SetStopLoss` and `SetProfitTarget` in PL accept a dollar (currency) amount. Rust has no implicit conversion — you must compute the price level manually: `stop_price = entry_price - stop_dollars / (qty * point_value)`.

8. **Position state is not tracked automatically.** PL provides `MarketPosition`, `EntryPrice`, `CurrentContracts`, and `BarsSinceEntry` as built-in read-only variables updated by the engine. In Rust, you must maintain these as struct fields and update them manually whenever the execution engine fills an order.

9. **Rust has no `Value1..Value99` or `Condition1..Condition99`.** These PL pre-declared variables must be replaced with named, typed struct fields. Use descriptive identifiers like `rsi_value: f64` and `is_oversold: bool`.

10. **Multi-data series requires explicit design.** PL `Close of Data2` accesses a second feed bound to the chart. In Rust, you must pass a second bar slice (`bars2: &[Bar]`) to `on_bar()` or store it as a field. There is no implicit secondary-feed mechanism.

11. **Ownership and borrowing affect indicator state.** PL variables are global mutable state with no restrictions. In Rust, indicator structs are owned by the strategy and mutated via `&mut self` in `on_bar()`. If you try to pass `&mut self.sma` and `&self` simultaneously, you will hit borrow-checker errors. Extract the needed bar data into local variables before calling `.next()`.

12. **No Portfolio Money Management (PMM) equivalent.** PL's PMM allows a single script to govern position sizing across multiple instruments. Rust has no built-in portfolio-level abstraction. You must implement cross-instrument logic as a separate orchestrator that calls individual strategy instances.

13. **Floating-point equality differs.** PL uses tolerance-based comparison for `=` on float values. Rust `==` on f64 is exact bitwise comparison. Converting PL `If Close = 100` to `if close == 100.0` may miss matches due to floating-point precision. Use an epsilon comparison: `(close - 100.0).abs() < 1e-10`.

14. **Multiple `Once` blocks need separate booleans.** PL supports multiple independent `Once Begin ... End` blocks in the same script, each executing exactly once. A single `self.first_bar` bool handles only one. If the PL source has N `Once` blocks, create N separate bool fields (e.g., `once_header: bool`, `once_init: bool`).

---

## Part 3: Conversion Checklists

### PL → Rust Pre-Conversion

- [ ] List every `Inputs:` declaration; note name, type, and default value — each becomes a struct field and constructor parameter
- [ ] List every `Variables:` declaration; note initial values — each becomes a mutable struct field initialized in `new()`
- [ ] Identify all `Value1..Value99` and `Condition1..Condition99` usages; plan meaningful replacement names
- [ ] Identify all indicator calls (Average, RSI, Stochastic, etc.); confirm each has a ta-rs equivalent or plan manual implementation
- [ ] Locate all `Data2` / `Data3` references; decide on multi-feed architecture (second parameter or struct field)
- [ ] Locate all `SetStopLoss`, `SetProfitTarget`, and dollar-based parameters; note the instrument's point value
- [ ] Check for `IntraBarPersist` variables; decide whether tick-level behavior needs replication
- [ ] Identify all `.elf` function calls; locate source and plan conversion to Rust functions or methods

### PL → Rust Post-Conversion

- [ ] Every `Sell` order maps to closing the long position, not entering short — audit all order keywords
- [ ] Every `BuyToCover` order maps to closing the short position, not entering long
- [ ] All bar lookback accesses (`Close[N]`) guarded with `if bars.len() > n` to prevent panics
- [ ] All ta-rs indicators created once in `new()`, not inside `on_bar()`
- [ ] Indicators requiring `DataItem` (ATR, Stochastic) receive properly constructed `DataItem`, not raw f64
- [ ] `Crosses Over` / `Crosses Under` implemented as two-bar comparisons with stored previous values
- [ ] `MarketPosition`, `EntryPrice`, `CurrentContracts`, `BarsSinceEntry` tracked as manually updated struct fields
- [ ] Dollar-based stop/target amounts converted to price levels
- [ ] `Value1..Value99` and `Condition1..Condition99` renamed to descriptive typed fields
- [ ] Code compiles with `cargo build` with zero errors and zero warnings
- [ ] Strategy back-tested on the same instrument and date range as the PL original; trade count and net P&L in the same order of magnitude

### Rust → PL Pre-Conversion

- [ ] List all struct fields and categorize: inputs (immutable) vs variables (mutable) vs indicators (stateful)
- [ ] Identify all ta-rs indicator types; map each to the PL built-in (SMA → Average, EMA → XAverage, RSI → RSI, etc.)
- [ ] Check for any `match` expressions with complex patterns; plan PL `Switch` or `If/Else` chain
- [ ] Identify any Rust libraries beyond ta-rs; plan PL equivalents or inline reimplementation
- [ ] Check for explicit position-tracking fields; confirm they can be replaced by PL's built-in `MarketPosition`, `EntryPrice`, etc.

### Rust → PL Post-Conversion

- [ ] Every short entry maps to `SellShort`, not `Sell`
- [ ] Every long close maps to `Sell`, not `SellShort`
- [ ] All `bars[bars.len() - 1 - n].close` lookbacks converted to `Close[n]`
- [ ] All manual crossover comparisons converted to PL `Crosses Over` / `Crosses Under` keywords
- [ ] All struct fields categorized: immutable inputs → `Inputs:`, mutable state → `Variables:`
- [ ] All ta-rs `.next()` calls replaced with PL function calls — PL handles indicator state internally
- [ ] Price-level stops/targets converted back to dollar amounts for `SetStopLoss` / `SetProfitTarget`
- [ ] Script compiled in MultiCharts PowerEditor with zero errors before testing
