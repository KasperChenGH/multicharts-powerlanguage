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
| `TriAverage(Close, Length)` | Manual: `SimpleMovingAverage` applied twice | Double-SMA; create two `SimpleMovingAverage` instances, feed output of first into second |
| `FastK(StochLength)` | Manual: `(close - min) / (max - min) * 100` using `Minimum`/`Maximum` | Raw %K from default H/L/C; no ta-rs helper |
| `FastD(StochLength)` | Manual: `SimpleMovingAverage::new(3)` applied to FastK values | Smoothed Fast %K |
| `SlowK(StochLength)` | `SlowStochastic::new(StochLength, 3).unwrap()` → `.next(&data_item)` | Same as SlowStochastic output |
| `SlowD(StochLength)` | Manual: `SimpleMovingAverage::new(3)` applied to SlowK values | Double-smoothed |
| `FastKCustom(H, L, C, StochLen)` | Manual: `(c - lowest_l) / (highest_h - lowest_l) * 100` | Custom prices; use `Maximum`/`Minimum` on custom series |
| `FastDCustom(H, L, C, StochLen)` | Manual: SMA(3) of FastKCustom | Same pattern |
| `SlowKCustom(H, L, C, StochLen)` | Manual: SMA(3) of FastKCustom | Same as FastDCustom |
| `SlowDCustom(H, L, C, StochLen)` | Manual: SMA(3) of FastKCustom | Slow %D with custom prices |
| `StochasticExp(H, L, C, StochLen, S1, S2, ...)` | Manual: EMA smoothing of FastKCustom | Use `ExponentialMovingAverage` instead of SMA for smoothing |
| `ADXR(Length)` | Manual: `(adx + adx_n_bars_ago) / 2.0` | Store ADX history; average current with N-bar-ago value |
| `ADXCustom(H, L, C, Length)` | Manual or `yata::indicators::ADX` with custom prices | Same as `ADX` but with custom H/L/C inputs |
| `DMI(Length)` | Manual or `yata`; same as ADX | Wrapper; same computation |
| `DMIPlusCustom(H, L, C, Length)` | Manual: `+DI` using custom highs/lows | Compute +DM from custom price series |
| `DMIMinusCustom(H, L, C, Length)` | Manual: `−DI` using custom highs/lows | Compute −DM from custom price series |
| `ParabolicCustom(AfStep, AfLimit)` | Manual SAR state machine with custom limit | Same as `Parabolic` but cap AF at `AfLimit` |
| `TRIX(Close, Length)` | Manual: ROC of triple `ExponentialMovingAverage` | Three nested EMA, then `(ema3 - prev_ema3) / prev_ema3 * 100` |
| `MassIndex(SmoothLen, SumLen)` | Manual: sum of `EMA(H-L) / EMA(EMA(H-L))` over `SumLen` | Two nested EMAs, compute ratio, rolling sum |
| `EaseOfMovement` | Manual: `((h + l) / 2 - (prev_h + prev_l) / 2) / (volume / (h - l))` | No crate built-in; uses current + previous bar |
| `SwingIndex` | Manual: Wilder swing index formula using OHLC | Complex ~20-line formula with limit move |
| `AccumSwingIndex` | Manual: `self.accum_si += swing_index` | Running cumulative sum of SwingIndex |
| `Detrend(Close, Length)` | Manual: `close - sma_value_offset` | SMA offset by Length/2 bars |
| `PercentChange(Close, Length)` | Manual: `(close - bars[len-1-length].close) / bars[len-1-length].close * 100.0` | Simple percent change formula |
| `UlcerIndex(Close, Length)` | Manual: `(sum_of_squared_drawdown_pct / length).sqrt()` | Track highest close in window, compute drawdown pct |
| `ParabolicSAR(AfStep, AfLimit, ...)` | Manual SAR with direction/transition tracking | Extend SAR state machine to track position changes |
| `LinearReg(Close, Length, TgtBar, ...)` | Manual: least-squares returning `(value, slope, angle, intercept)` | Full regression output as struct |
| `TrueRangeCustom(H, L, C)` | Manual: `(h - l).max((h - prev_c).abs()).max((l - prev_c).abs())` | Same formula as `TrueRange` with custom prices |
| `VolatilityStdDev(NumDays)` | Manual: stdev of log returns × `(252.0_f64).sqrt()` | Annualized historical volatility |
| `StandardDevAnnual(Close, Length, DataType)` | Manual: `StandardDeviation::new(length).next(close) * (252.0_f64).sqrt()` | Annualize the ta-rs `StandardDeviation` output |
| `HighestFC(Close, Length)` | `Maximum::new(length).unwrap()` → `.next(bar.close)` | Same as `Highest`; ta-rs `Maximum` |
| `LowestFC(Close, Length)` | `Minimum::new(length).unwrap()` → `.next(bar.close)` | Same as `Lowest`; ta-rs `Minimum` |
| `PivotHighVS(Inst, Price, LStr, RStr, Len)` | Manual: scan for bar higher than `LStr` bars left and `RStr` bars right | Asymmetric left/right strength; return price or -1.0 |
| `PivotLowVS(Inst, Price, LStr, RStr, Len)` | Manual: scan for bar lower than `LStr` bars left and `RStr` bars right | Same pattern for lows |
| `PivotHighVSBar(Inst, Price, LStr, RStr, Len)` | Manual: bars-ago offset of pivot high | Same detection, return `bars.len() - 1 - pivot_index` |
| `PivotLowVSBar(Inst, Price, LStr, RStr, Len)` | Manual: bars-ago offset of pivot low | Same detection, return offset |
| `Divergence(P1, P2, Str, Len, HiLo)` | Manual: compare pivot highs/lows of price vs indicator | Return 1 if divergence found between two series |
| `TimeSeriesForecast(Close, Length)` | Manual: `linear_reg_value + slope` | Uses same slope/intercept as `LinearRegValue` |

| `SummationFC(Close, Length)` | Manual: `bars[len-length..len].iter().map(\|b\| b.close).sum::<f64>()` | Same as `Summation`; fast calc variant |
| `OpenD(N)` | Manual: aggregate bars into daily periods, return `daily_bars[daily_bars.len()-1-N].open` | Requires daily bar aggregation from intraday data |
| `HighD(N)` | Manual: `daily_bars[..].high` | Aggregate highs per day |
| `LowD(N)` | Manual: `daily_bars[..].low` | Aggregate lows per day |
| `CloseD(N)` | Manual: `daily_bars[..].close` | Last close per day |
| `OpenW(N)` | Manual: aggregate to weekly | Same pattern, weekly periods |
| `HighW(N)` | Manual: aggregate to weekly | Weekly high |
| `LowW(N)` | Manual: aggregate to weekly | Weekly low |
| `CloseW(N)` | Manual: aggregate to weekly | Weekly close |
| `OpenM(N)` | Manual: aggregate to monthly | Monthly open |
| `HighM(N)` | Manual: aggregate to monthly | Monthly high |
| `LowM(N)` | Manual: aggregate to monthly | Monthly low |
| `CloseM(N)` | Manual: aggregate to monthly | Monthly close |
| `OpenY(N)` | Manual: aggregate to yearly | Yearly open |
| `HighY(N)` | Manual: aggregate to yearly | Yearly high |
| `LowY(N)` | Manual: aggregate to yearly | Yearly low |
| `CloseY(N)` | Manual: aggregate to yearly | Yearly close |
| `LRO(Cond, Length, N)` | Manual: scan from `length` bars ago forward, find Nth true | Least recent occurrence; returns bars-ago offset |
| `SummationIf(Cond, Price, Length)` | Manual: sum price over last `length` bars where cond is true | Conditional rolling sum |
| `IFFString(Cond, TrueStr, FalseStr)` | `if cond { true_str.to_string() } else { false_str.to_string() }` | Rust `if` expression returning `String` |
| `OBV` | Manual: `self.obv += if close > prev_close { vol } else if close < prev_close { -vol } else { 0.0 }` | On Balance Volume; running total |
| `VolumeROC(Length)` | `RateOfChange::new(length).unwrap()` → `.next(bar.volume)` | ta-rs `RateOfChange` on volume |
| `VolumeOsc(ShortLen, LongLen)` | Manual: `SMA(volume, short) - SMA(volume, long)` | Two `SimpleMovingAverage` on volume, subtract |
| `PriceVolTrend` | Manual: `self.pvt += (close - prev_close) / prev_close * volume` | Cumulative price-volume trend |
| `LWAccDis` | Manual: `self.lwad += (close - open) / (high - low) * volume` | Larry Williams A/D; running total |
| `Fisher(Price)` | Manual: normalize to −0.999..0.999, then `0.5 * ((1.0 + norm) / (1.0 - norm)).ln()` | Fisher transformation |
| `FisherINV(Price)` | Manual: `((2.0 * price).exp() - 1.0) / ((2.0 * price).exp() + 1.0)` | Inverse Fisher |
| `C_Doji(Pct)` | Manual: `(close - open).abs() <= (high - low) * pct / 100.0` | Doji detection |
| `C_Hammer_HangingMan(Len, Factor, ...)` | Manual: check body/shadow ratios | Lower shadow ≥ 2× body |
| `C_BullEng_BearEng(Len, ...)` | Manual: current body engulfs previous | Compare current and previous OHLC |
| `C_BullHar_BearHar(Len, ...)` | Manual: current body inside previous | Opposite of engulfing |
| `C_MornDoji_EveDoji(Len, Pct, ...)` | Manual: 3-bar pattern with middle doji | Check 3 consecutive bars |
| `C_MornStar_EveStar(Len, ...)` | Manual: 3-bar reversal | Down-small-up or up-small-down |
| `C_PierceLine_DkCloud(Len, ...)` | Manual: 2-bar piercing pattern | Gap + close past midpoint |
| `C_ShootingStar(Len, Factor)` | Manual: small body, long upper shadow | Upper shadow ≥ 2× body |
| `C_3WhSolds_3BlkCrows(Len, Factor, ...)` | Manual: 3 consecutive trend bars | Three ascending or descending closes |
| **Statistical extended** | | |
| `AvgDeviation(Close, N)` | Manual: mean absolute deviation over window | MAD |
| `Variance(Close, N)` | Manual: `sum((x - mean)^2) / N` | Population variance |
| `Kurtosis(Close, N)` | Manual: 4th moment calculation | Excess kurtosis |
| `Skew(Close, N)` | Manual: 3rd moment calculation | Skewness |
| `PercentRank(ValToRank, Price, N)` | Manual: count values ≤ target / N | Percent rank |
| `Covariance(P1, P2, N)` | Manual: `sum((P1-mean1)*(P2-mean2)) / N` | Covariance |
| `Quartile(Close, N, Q)` | Manual: sort window, pick percentile | Quartile value |
| `TrimMean(Close, N, Pct)` | Manual: sort, trim edges, average | Trimmed mean |
| `Mode(Close, N, Type)` | Manual: frequency count over window | Modal value |
| `HarmonicMean(Close, N)` | Manual: `N / sum(1/x)` | Harmonic mean |
| **Moving averages extended** | | |
| `SmoothedAverage(Close, N)` | Manual: Wilder smoothing `prev*(N-1)/N + val/N` | Same as RMA |
| **Miscellaneous** | | |
| `BarAnnualization` | Manual: compute from bar frequency | Bars-per-year factor |
| `LastBarOnChart` | `bar_index == data.len() - 1` | True on last bar |
| **Custom functions** | | |
| `StochRSI(Close, N, M)` | Manual: compute RSI, then `(rsi - lowest(rsi, M)) / (highest(rsi, M) - lowest(rsi, M))` | Stochastic RSI |
| `supertrend(N, Mult)` | Manual: ATR bands + direction flip logic | Supertrend |
| `NVI(Start)` | Manual: accumulate on volume-down bars | Negative Volume Index |
| `PVI(Start)` | Manual: accumulate on volume-up bars | Positive Volume Index |
| `Coppo(N1, N2, N3)` | Manual: WMA of two ROC periods | Coppock Curve |
| `LWTI(Close, P, N)` | Manual: `(sma(diff, N) / sma(range, N)) * 50 + 50` | Larry Williams TI |
| `TVI(Close, Vol, Tick)` | Manual: cumulative directional volume | Trade Volume Index |
| `SharpeRatio(Period, Rate, Calc, Cap)` | Manual: `(avg_return - rf) / std_return` | Portfolio Sharpe |
| `WRSI(N, Close)` | Manual: Wilder smoothing RSI (same formula as standard RSI) | Wilder RSI |
| `NewMA(Close, N)` | Manual: Heikin-Ashi + triple EMA hybrid | Hybrid MA |

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
| `Switch (expr) Begin Case 1: ... End;` | `match expr { 1 => { ... }, _ => {} }` | Rust `match` requires exhaustive arms; add `_ => {}` default; PL empty case body is a compile error — use `Value1 = Value1;` as no-op |
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
