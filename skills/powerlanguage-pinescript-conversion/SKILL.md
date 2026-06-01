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

## How to use

This skill covers the structural and semantic differences between MultiCharts PowerLanguage and TradingView Pine Script. It does not duplicate the syntax rules of either language — for PowerLanguage declarations, bar references, control flow, and built-in function signatures use the `powerlanguage-syntax` skill; for Pine Script types, built-ins, and execution model details use the `pinescript-reference` skill. When performing a conversion in either direction, work through Part 1 (concept mapping) first, then review Part 2 (semantic differences and gotchas), and finally run through the relevant checklist in Part 3 before calling the output complete.

---

## Part 1: Concept Mapping

### Table 1 — Declarations

| PowerLanguage | Pine Script | Notes |
|---|---|---|
| `Inputs: Length(20)` | `length = input.int(20, "Length")` | Pine requires an explicit title string; PL labels come from the Format window |
| `Variables: myVar(0)` | `var float myVar = 0.0` | `var` retains value across bars, matching PL default behavior |
| `Value1` .. `Value99` | named variable (e.g., `val1`) | PL numbered built-ins have no Pine equivalent; must rename to meaningful identifiers |
| `Condition1` .. `Condition99` | named bool (e.g., `cond1`) | Same: rename to typed `bool` or expression variable |
| `Arrays: buf[10](0)` | `buf = array.new_float(11, 0.0)` | PL `[10]` means last index is 10 (11 elements); Pine size is element count |
| `IntraBarPersist myVar(0)` | `varip float myVar = 0.0` | Both update intrabar on live ticks; `varip` is the closest Pine equivalent |

---

### Table 2 — Data Access

| PowerLanguage | Pine Script | Notes |
|---|---|---|
| `Open`, `High`, `Low`, `Close`, `Volume` | `open`, `high`, `low`, `close`, `volume` | Pine is all-lowercase; PL is case-insensitive but conventionally capitalized |
| `Close[1]` | `close[1]` | Bracket indexing works the same; both are 0-based offset (0 = current bar) |
| `Close of Data2` | `request.security(symbol, timeframe.period, close)` | PL Data2 is a second chart feed; Pine requires explicit symbol and timeframe strings |
| `Date`, `Time` | `year(time)`, `month(time)`, `dayofmonth(time)`, `hour(time)`, `minute(time)` | PL `Date` is YYMMDD integer; Pine uses component functions on the `time` timestamp |
| `BarNumber` | `bar_index + 1` | PL `BarNumber` is 1-based (first bar = 1); Pine `bar_index` is 0-based (first bar = 0) |
| `CurrentBar` | `bar_index + 1` | Same mapping as `BarNumber`; both refer to the sequential bar count from history start |

---

### Table 3 — Technical Indicators

| PowerLanguage | Pine Script | Notes |
|---|---|---|
| `Average(Close, Length)` | `ta.sma(close, length)` | Direct equivalent |
| `XAverage(Close, Length)` | `ta.ema(close, length)` | Direct equivalent |
| `RSI(Close, Length)` | `ta.rsi(close, length)` | Direct equivalent |
| `Stochastic(Close, High, Low, Length, 1, 3, 0, 0, 0, 0, 0)` | `ta.stoch(high, low, close, length)` | PL takes 11 params including smoothing; Pine returns raw %K only — %D must be smoothed manually |
| `ADX(Length)` | `[diplus, diminus, adx] = ta.dmi(length, length)` | Pine `ta.dmi` returns a 3-tuple; destructure before use |
| `CCI(Close, Length)` | `ta.cci(close, length)` | Direct equivalent (note argument order differs from some PL references) |
| `AvgTrueRange(Length)` | `ta.atr(length)` | Direct equivalent |
| `BollingerBand(Close, Length, 2)` | `[mid, upper, lower] = ta.bb(close, length, 2)` | Pine returns a 3-tuple; PL returns the upper or lower band depending on the final argument |
| `Close Crosses Over MA` | `ta.crossover(close, ma)` | PL keyword phrase; Pine is a function returning bool |
| `Close Crosses Under MA` | `ta.crossunder(close, ma)` | Same pattern as above |
| `Highest(Close, Length)` | `ta.highest(close, length)` | Direct equivalent |
| `Lowest(Close, Length)` | `ta.lowest(close, length)` | Direct equivalent |
| `MomentumFunc(Close, Length)` | `ta.mom(close, length)` | Direct equivalent |

---

### Table 4 — Strategy Orders

| PowerLanguage | Pine Script | Notes |
|---|---|---|
| `Buy("label") next bar market` | `strategy.entry("label", strategy.long)` | PL keyword `Buy` always means enter long |
| `SellShort("label") next bar market` | `strategy.entry("label", strategy.short)` | PL keyword `SellShort` always means enter short |
| `Sell("label") next bar market` | `strategy.close("label")` | **WARNING: `Sell` in PL exits an existing long — use `strategy.close`, NOT `strategy.entry(strategy.short)`** |
| `BuyToCover("label") next bar market` | `strategy.close("label")` | PL `BuyToCover` exits an existing short |
| `Buy(qty, "label") shares next bar market` | `strategy.entry("label", strategy.long, qty=qty)` | Pass contract/share count via `qty` parameter |
| `Buy("label") next bar at price limit` | `strategy.entry("label", strategy.long, limit=price)` | Limit orders use the `limit` param |
| `Buy("label") next bar at price stop` | `strategy.entry("label", strategy.long, stop=price)` | Stop orders use the `stop` param |
| `SetStopLoss(dollars)` | `strategy.exit("id", stop=strategy.position_avg_price - dollars / qty)` | PL takes a dollar amount; Pine takes an absolute price level — must convert manually |
| `SetProfitTarget(dollars)` | `strategy.exit("id", limit=strategy.position_avg_price + dollars / qty)` | Same dollar-to-price conversion required |

---

### Table 5 — Plotting

| PowerLanguage | Pine Script | Notes |
|---|---|---|
| `Plot1(value, "label")` | `plot(value, title="label")` | Pine `plot()` is a statement, not an indexed output slot |
| `SetPlotColor(1, Red)` | `plot(value, color=color.red)` | PL sets color separately by plot index; Pine sets it inline as a parameter |
| `SetPlotWidth(1, 2)` | `plot(value, linewidth=2)` | Same: inline in Pine, separate call in PL |
| `NoPlot(1)` | `plot(na)` | Passing `na` suppresses the plot for that bar |

---

### Table 6 — Control Flow

| PowerLanguage | Pine Script | Notes |
|---|---|---|
| `If cond Then Begin ... End;` | `if cond\n    ...` | Pine uses indentation instead of `Begin`/`End` delimiters |
| `If cond Then Begin ... End Else Begin ... End;` | `if cond\n    ...\nelse\n    ...` | Same indentation pattern for `else` blocks |
| `For i = 1 to n Begin ... End;` | `for i = 1 to n\n    ...` | Loop body is indented; no `Begin`/`End` needed |
| `While cond Begin ... End;` | `while cond\n    ...` | Same indentation pattern |
| `Switch (expr) Begin Case 1: ...; End;` | `switch expr\n    1 => ...` | Pine `switch` uses `=>` arrows and indentation |
| `Once Begin ... End;` | `if barstate.isfirst\n    ...` | PL `Once` runs code on the first bar only; Pine uses the `barstate.isfirst` built-in |

---

### Table 7 — Other Built-ins and Features

| PowerLanguage | Pine Script | Notes |
|---|---|---|
| `MarketPosition` | `strategy.position_size` | PL returns -1/0/1; Pine returns the actual signed position size — check sign rather than comparing to 1 or -1 |
| `EntryPrice` | `strategy.position_avg_price` | Pine gives the average entry price of the current position |
| `CurrentContracts` | `math.abs(strategy.position_size)` | PL gives absolute contract count; Pine position size is signed |
| `BarsSinceEntry` | manual: `bar_index - entryBar` | No Pine built-in; track entry bar index manually with a `var` variable |
| `Print("text")` | `label.new(bar_index, high, "text")` or `log.info("text")` | `label.new` creates on-chart labels; `log.info` writes to the Pine console |
| `#BeginCmtry ... #EndCmtry` | no equivalent | Pine has no commentary output; use `label.new` for visible annotations |
| `Alert("msg", AlertType)` | `alert("msg", alert.freq_once_per_bar)` or `alertcondition(cond, "title")` | Pine `alertcondition` registers a condition for the Alerts dialog; `alert()` fires immediately |

---

## Part 2: Semantic Differences and Gotchas

1. **`Sell` does not mean "go short".** In PowerLanguage, `Sell` exits an existing long position. The Pine equivalent is `strategy.close()`. If you write `strategy.entry("label", strategy.short)` as a translation of `Sell`, you will create a new short position rather than closing the long — this is one of the most common and costly conversion mistakes.

2. **Multi-data feed architecture is fundamentally different.** PowerLanguage allows a second (or third) price feed to be attached directly to the chart as Data2/Data3, and accesses its bars with `Close of Data2`. Pine Script has no concept of a second chart feed; instead you must call `request.security(syminfo.tickerid, "D", close)` with an explicit symbol string and timeframe. There is no direct bar-by-bar alignment guarantee across different timeframes in Pine the way there is when you add a second data series in MultiCharts.

3. **Dollar amounts versus price levels.** `SetStopLoss` and `SetProfitTarget` in PowerLanguage accept a dollar (currency) amount, which MultiCharts converts internally to a price level using the instrument's point value and position size. Pine Script's `strategy.exit()` `stop` and `limit` parameters require an absolute price level. You must perform the conversion explicitly: `stop_price = strategy.position_avg_price - stop_dollars / (qty * syminfo.pointvalue)`.

4. **Stochastic parameter mismatch.** PowerLanguage's `Stochastic` function accepts 11 parameters covering %K and %D periods, smoothing type, and detrending options. Pine's `ta.stoch()` accepts 4 parameters and returns raw %K only. If your PL strategy relies on the smoothed %D line or any of the advanced smoothing options, you must replicate that smoothing manually in Pine after calling `ta.stoch()`.

5. **Bar numbering is offset by one.** PowerLanguage's `BarNumber` and `CurrentBar` start at 1 for the first historical bar. Pine's `bar_index` starts at 0. Any logic that compares bar counts, computes bar offsets, or initializes arrays based on `BarNumber` must subtract or add 1 when converting.

6. **Position size semantics differ.** `MarketPosition` in PowerLanguage returns exactly -1 (short), 0 (flat), or 1 (long) regardless of how many contracts are held. Pine's `strategy.position_size` returns the signed number of contracts — for example, +3 if three long contracts are open. Code that tests `if MarketPosition = 1` should become `if strategy.position_size > 0` in Pine, not `if strategy.position_size = 1`.

7. **Execution model: confirmed close versus real-time tick.** PowerLanguage strategies execute on bar close by default (the bar is confirmed before orders are evaluated). Pine Script strategies also default to executing on bar close, but the behavior of `calc_on_every_tick` and `calc_on_order_fills` can alter this. When porting a PL strategy, verify that the Pine `strategy()` declaration does not add intrabar recalculation that was absent in the original.

8. **Portfolio Money Management (PMM) has no Pine equivalent.** MultiCharts PMM allows a single money-management script to govern position sizing across a portfolio of instruments. Pine Script has no portfolio-level concept; each script runs independently on a single symbol. PMM logic must be reimplemented as per-symbol position sizing inside the Pine strategy itself.

9. **PowerLanguage Functions (.elf files) must become Pine user-defined functions or libraries.** A PL `.elf` (EasyLanguage Function) is a reusable calculation unit compiled separately and called from indicators or strategies. In Pine, the equivalent is either a user-defined function defined with `f_name(params) =>` syntax within the same script, or a published Pine library imported with `import`. There is no separate compilation step in Pine.

10. **Value1..Value99 and Condition1..Condition99 must be renamed.** These PL numbered built-ins have no Pine counterpart. Every occurrence must be replaced with a descriptive typed variable (`var float`, `var bool`, or a plain expression). Do not carry over numbers as Pine variable names — names like `val1` are legal but `Value1` in a Pine context is just an undefined identifier that will cause a compile error.

---

## Part 3: Conversion Checklists

### PL → Pine Pre-Conversion

- [ ] List every `Inputs:` declaration; note the type (numeric / string / bool) and default value so each can be mapped to the correct `input.*()` function
- [ ] Identify all `Data2` / `Data3` references; confirm what symbol and timeframe each feed represents so `request.security()` calls can be written correctly
- [ ] Locate all `SetStopLoss`, `SetProfitTarget`, and dollar-based order parameters; note the instrument's point value for the price-level conversion
- [ ] Confirm whether `IntraBarPersist` variables are used; if so, decide whether Pine `varip` behavior is acceptable or whether the strategy must run on confirmed bars only
- [ ] Check for any `.elf` function calls; locate the function source code and plan whether to inline it or create a Pine library

### PL → Pine Post-Conversion

- [ ] Every `Sell` order maps to `strategy.close()`, not `strategy.entry(strategy.short)` — audit all order keywords
- [ ] Every `BuyToCover` order maps to `strategy.close()`, not `strategy.entry(strategy.long)`
- [ ] `BarNumber` / `CurrentBar` comparisons adjusted for 0-based `bar_index`
- [ ] `MarketPosition` comparisons converted from `= 1` / `= -1` to `> 0` / `< 0`
- [ ] `CurrentContracts` replaced with `math.abs(strategy.position_size)`
- [ ] `BarsSinceEntry` replaced with a manual `var int entryBar` tracker
- [ ] Dollar-based stop/target amounts converted to price levels in all `strategy.exit()` calls
- [ ] `Value1..Value99` and `Condition1..Condition99` renamed to typed Pine variables
- [ ] Stochastic %D smoothing replicated manually if the original strategy used the smoothed line
- [ ] Strategy compiled and back-tested on the same instrument and date range as the PL original; trade count and net P&L should be in the same order of magnitude

### Pine → PL Pre-Conversion

- [ ] List every `request.security()` call; determine whether MultiCharts can supply the required symbol and timeframe as a secondary data feed
- [ ] Identify any Pine libraries (`import` statements); locate equivalent PL functions or plan to reimplement the library logic inline
- [ ] Check for `strategy.position_size` comparisons; note the exact values tested so the sign-based logic can be converted to PL's -1/0/1 model
- [ ] Confirm whether `varip` variables are used and whether the equivalent PL `IntraBarPersist` behavior is needed or can be dropped

### Pine → PL Post-Conversion

- [ ] Every `strategy.entry(strategy.short)` maps to `SellShort`, not `Sell`
- [ ] Every `strategy.close()` on a long position maps to `Sell`, not `SellShort`
- [ ] `bar_index` comparisons incremented by 1 for PL's 1-based `BarNumber`
- [ ] `strategy.position_size > 0` / `< 0` converted to `MarketPosition = 1` / `= -1`
- [ ] `strategy.exit()` price levels converted back to dollar amounts for `SetStopLoss` / `SetProfitTarget`
- [ ] Any Pine tuple returns (e.g., `ta.dmi`, `ta.bb`) unpacked before the equivalent PL function calls — PL functions return scalar values
- [ ] `ta.stoch()` %K result wrapped with appropriate smoothing if the PL target uses `Stochastic`'s built-in %D
- [ ] Script compiled in MultiCharts PowerEditor with zero errors before testing
