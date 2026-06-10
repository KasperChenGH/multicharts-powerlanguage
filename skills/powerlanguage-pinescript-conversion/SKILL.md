---
name: powerlanguage-pinescript-conversion
description: Use when converting or porting code between MultiCharts PowerLanguage and TradingView Pine Script in either direction — concept mapping tables, semantic differences, conversion checklists.
---

# PowerLanguage ↔ Pine Script Conversion

## How to use

This skill covers the structural and semantic differences between MultiCharts PowerLanguage and TradingView Pine Script. It does not duplicate the syntax rules of either language — for PowerLanguage declarations, bar references, control flow, and built-in function signatures use the `powerlanguage-syntax` skill; for Pine Script fundamentals use `pinescript-core`, for built-in namespaces use `pinescript-builtins`, and for plotting/drawing use `pinescript-visual`. When performing a conversion in either direction, work through Part 1 (concept mapping) first, then review Part 2 (semantic differences and gotchas), and finally run through the relevant checklist in Part 3 before calling the output complete.

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
| `Date`, `Time` | `year(time_close)`, `month(time_close)`, `dayofmonth(time_close)`, `hour(time_close)`, `minute(time_close)` | PL `Date` is a YYYMMDD integer with a 1900 offset (1260610 = 2026-06-10); reconstruct as `(year(time_close) - 1900) * 10000 + ...`. PL `Date`/`Time` label the bar CLOSE — use `time_close`, not `time` (Pine `time` is the bar-OPEN timestamp) |
| `BarNumber` | `bar_index + 1` | PL `BarNumber` is 1-based (first bar = 1); Pine `bar_index` is 0-based (first bar = 0) |
| `CurrentBar` | `bar_index + 1` | Same mapping as `BarNumber` — but `CurrentBar` counts from the first executed bar after MaxBarsBack, so `bar_index + 1` is exact only when MaxBarsBack = 0 |

---

### Table 3 — Technical Indicators

| PowerLanguage | Pine Script | Notes |
|---|---|---|
| `Average(Close, Length)` | `ta.sma(close, length)` | Direct equivalent |
| `XAverage(Close, Length)` | `ta.ema(close, length)` | Direct equivalent |
| `RSI(Close, Length)` | `ta.rsi(close, length)` | Direct equivalent |
| `Stochastic(High, Low, Close, Length, 1, 3, 0, 0, 0, 0, 0)` | `ta.stoch(close, high, low, length)` | PL arg order starts High, Low, Close; PL takes 11 params including smoothing; Pine returns raw %K only — %D must be smoothed manually |
| `ADX(Length)` | `[diplus, diminus, adx] = ta.dmi(length, length)` | Pine `ta.dmi` returns a 3-tuple; destructure before use |
| `CCI(Length)` | `ta.cci(hlc3, length)` | PL `CCI` takes only length (uses typical price internally); Pine computes on whatever source you pass — pass `hlc3` to match |
| `AvgTrueRange(Length)` | `ta.sma(ta.tr(true), length)` | PL `AvgTrueRange` is a SIMPLE average of TrueRange. Pine `ta.atr` is Wilder/RMA — use it only if the PL side used `SmoothedAverage(TrueRange, Len)`, which is the matching Wilder pair |
| `BollingerBand(Close, Length, 2)` | `[mid, upper, lower] = ta.bb(close, length, 2)` | Pine returns a 3-tuple; PL returns the upper or lower band depending on the final argument |
| `Close Crosses Over MA` | `ta.crossover(close, ma)` | PL keyword phrase; Pine is a function returning bool |
| `Close Crosses Under MA` | `ta.crossunder(close, ma)` | Same pattern as above |
| `Highest(Close, Length)` | `ta.highest(close, length)` | Direct equivalent |
| `Lowest(Close, Length)` | `ta.lowest(close, length)` | Direct equivalent |
| `Momentum(Close, Length)` | `ta.mom(close, length)` | Direct equivalent |
| `TSI(Close, LongLen, ShortLen)` | `ta.tsi(close, ShortLen, LongLen) * 100` | Pine signature is `ta.tsi(source, short_length, long_length)` and returns −1..+1 — swap the length order and multiply by 100 |
| `AverageFC(Close, Length)` | `ta.sma(close, length)` | Fast-ceiling variant; Pine `ta.sma` is equivalent |
| `WAverage(Close, Length)` | `ta.wma(close, length)` | Direct equivalent |
| `AdaptiveMovAvg(Close, Length)` | manual KAMA formula | No Pine built-in; implement Kaufman AMA manually |
| `MidPoint(Close, Length)` | `(ta.highest(close, length) + ta.lowest(close, length)) / 2` | No built-in; average of highest and lowest |
| `MACD(Close, FastLen, SlowLen)` | `[macdLine, signal, hist] = ta.macd(close, FastLen, SlowLen, sigLen)` | Pine returns a 3-tuple; PL returns a single value |
| `KeltnerChannel(Close, Length, NumATRs)` | `[mid, upper, lower] = ta.kc(close, length, NumATRs)` | Pine returns a 3-tuple; select the band needed |
| `DMIPlus(Length)` | `[diplus, diminus, adx] = ta.dmi(Length, Length)` | Destructure tuple; use `diplus` |
| `DMIMinus(Length)` | `[diplus, diminus, adx] = ta.dmi(Length, Length)` | Destructure tuple; use `diminus` |
| `RateOfChange(Close, Length)` | `ta.roc(close, length)` | Direct equivalent |
| `PercentR(Length)` | `ta.wpr(length) + 100` or `100 * (close − ta.lowest(low, Length)) / (ta.highest(high, Length) − ta.lowest(low, Length))` | PL `PercentR` takes length only and is POSITIVE 0..100 (= Williams %R + 100); overbought/oversold thresholds become 80/20 on the positive scale |
| `MoneyFlow(Length)` | `ta.mfi(hlc3, length)` | Pine `ta.mfi` is Money Flow Index; PL uses typical price internally — pass `hlc3`, not `close` |
| `Parabolic(AFStep, AFLimit)` | manual Parabolic SAR formula | No Pine built-in; implement SAR loop manually |
| `Volatility(Length)` | `ta.ema(ta.tr(true), length)` (or `ta.rma`) | PL `Volatility` is a smoothed average of TrueRange weighted toward the most recent bar — NOT a stdev-based measure (`StandardDev` is stdev of closes; `VolatilityStdDev` is annualized stdev of log returns) |
| `UltimateOscillator(Len1, Len2, Len3)` | manual formula using `ta.atr` and buying pressure sums | No Pine built-in; compute from three-period ratios |
| `ChaikinOsc(FastLen, SlowLen)` | manual: `ta.ema(ad, FastLen) − ta.ema(ad, SlowLen)` | No Pine built-in; compute A/D line first, then EMA difference |
| `PriceOscillator(Close, FastLen, SlowLen)` | manual: `ta.ema(close, FastLen) − ta.ema(close, SlowLen)` | No Pine built-in; difference of two EMAs |
| `DirMovement(Length, oADX, oDMIPlus, oDMIMinus)` | `[diplus, diminus, adx] = ta.dmi(Length, Length)` | PL writes to reference params; Pine returns a tuple |
| `Extremes(Price, Length, oHighest, oLowest)` | `h = ta.highest(Price, Length)` + `l = ta.lowest(Price, Length)` | PL writes to reference params; use two Pine calls |
| `TrueRange` | `ta.tr` | Direct equivalent; both return current bar true range |
| `StandardDev(Close, Length)` | `ta.stdev(close, length)` | Direct equivalent |
| `TrueHigh` | `math.max(high, close[1])` | No Pine built-in; max of current high and prior close |
| `TrueLow` | `math.min(low, close[1])` | No Pine built-in; min of current low and prior close |
| `Range` | `high - low` | No Pine built-in; simple bar range |
| `HighestBar(Close, Length)` | `ta.highestbars(close, length)` | Pine returns **negative** offset (e.g., −3); PL returns positive |
| `LowestBar(Close, Length)` | `ta.lowestbars(close, length)` | Pine returns **negative** offset; PL returns positive |
| `NthHighest(Close, Length, N)` | manual: sort last `Length` bars, pick Nth | No Pine built-in; use a loop or `array.sort` |
| `NthLowest(Close, Length, N)` | manual: sort last `Length` bars, pick Nth | No Pine built-in; use a loop or `array.sort` |
| `NthHighestBar(Close, Length, N)` | manual: find bar offset of Nth highest | No Pine built-in; combine loop with comparison |
| `NthLowestBar(Close, Length, N)` | manual: find bar offset of Nth lowest | No Pine built-in; combine loop with comparison |
| `SwingHigh(Occur, Price, Strength, Length)` | `ta.pivothigh(Price, Strength, Strength)` | Occurrence is the FIRST PL arg; PL returns −1 when no swing found (Pine returns `na`); `Length` must exceed `Strength` |
| `SwingLow(Occur, Price, Strength, Length)` | `ta.pivotlow(Price, Strength, Strength)` | Same: Occurrence first, −1 when none found, `Length` > `Strength` |
| `SwingHighBar(Occur, Price, Strength, Length)` | manual: track bar offset of `ta.pivothigh` | No direct built-in; record `bar_index` when pivot appears |
| `SwingLowBar(Occur, Price, Strength, Length)` | manual: track bar offset of `ta.pivotlow` | No direct built-in; record `bar_index` when pivot appears |
| `Summation(Close, Length)` | `math.sum(close, length)` | Direct equivalent — `math.sum` exists in v5 |
| `Cum(Close)` | `ta.cum(close)` | Direct equivalent; cumulative sum from bar 0 |
| `LinearRegValue(Close, Length, Offset)` | `ta.linreg(close, length, offset)` | Direct equivalent |
| `LinearRegAngle(Close, Length, Offset)` | manual: `math.todegrees(math.atan(ta.linreg(close, length, offset) − ta.linreg(close, length, offset + 1)))` | No Pine built-in; derive from regression slope |
| `LinearRegSlope(Close, Length)` | manual: `ta.linreg(close, length, 0) − ta.linreg(close, length, 1)` | No Pine built-in; approximate from two offsets |
| `Correlation(X, Y, Length)` | `ta.correlation(X, Y, length)` | Direct equivalent |
| `RSquared(Close, Length)` | `math.pow(ta.correlation(close, bar_index, length), 2)` | R-squared of linear regression; square the correlation |
| `StdError(Close, Length)` | manual: `math.sqrt(sumSqResid / (Length - 2))` from residuals against `ta.linreg(close, Length, 0)` | Standard error of the linear-regression residuals — NOT SE of the mean; no Pine built-in |
| `Median(Close, Length)` | `ta.median(close, length)` | Direct equivalent |
| `ELDate` | `(year(time) - 1900) * 10000 + month(time) * 100 + dayofmonth(time)` | PL YYYMMDD format (1900-based century); reconstruct in Pine |
| `MinutesToTime(mins)` | manual: `int(mins / 60) * 100 + (mins % 60)` | PL returns HHMM integer; replicate arithmetic |
| `TimeToMinutes(t)` | manual: `int(t / 100) * 60 + (t % 100)` | Inverse of MinutesToTime; convert HHMM to minutes |
| `AvgPrice` | `ohlc4` | Pine built-in `ohlc4` = (O+H+L+C)/4 |
| `MedianPrice` | `hl2` | Pine built-in `hl2` = (H+L)/2 |
| `TypicalPrice` | `hlc3` | Pine built-in `hlc3` = (H+L+C)/3 |
| `WeightedClose` | `(high + low + close * 2) / 4` | No Pine built-in; compute manually |
| `CountIF(Cond, Length)` | manual: `ta.cum(Cond ? 1 : 0) − ta.cum(Cond ? 1 : 0)[length]` | No Pine built-in; rolling sum of boolean-as-int |
| `MRO(Cond, Length, N)` | manual: loop back through `Length` bars | No Pine built-in; most recent occurrence of condition |
| `AccumDist` | manual: `ta.cum(((close − low) − (high − close)) / (high − low) * volume)` | No Pine built-in; cumulative A/D line formula |
| `IFF(Cond, TrueVal, FalseVal)` | `Cond ? TrueVal : FalseVal` | Pine ternary operator is the direct equivalent |
| `TriAverage(Close, Length)` | `halfLen = math.ceil((length + 1) * 0.5)` then `ta.sma(ta.sma(close, halfLen), halfLen)` | Triangular MA = SMA of SMA with HALVED length `ceil((Length+1)*0.5)` — not the full length applied twice |
| `FastK(StochLength)` | `ta.stoch(close, high, low, StochLength)` | Raw %K; Pine `ta.stoch` returns raw %K |
| `FastD(StochLength)` | `ta.sma(ta.stoch(close, high, low, StochLength), 3)` | Smoothed %K; apply SMA(3) to FastK |
| `SlowK(StochLength)` | `ta.sma(ta.stoch(close, high, low, StochLength), 3)` | Same as FastD |
| `SlowD(StochLength)` | `ta.sma(ta.sma(ta.stoch(close, high, low, StochLength), 3), 3)` | Double-smoothed; SMA of SlowK |
| `FastKCustom(H, L, C, Length)` | `ta.stoch(C, H, L, Length)` | Custom prices; Pine signature is `(close, high, low, length)` |
| `FastDCustom(H, L, C, Length)` | `ta.sma(ta.stoch(C, H, L, Length), 3)` | Smooth FastKCustom with SMA(3) |
| `SlowKCustom(H, L, C, Length)` | `ta.sma(ta.stoch(C, H, L, Length), 3)` | Same as FastDCustom |
| `SlowDCustom(H, L, C, Length)` | `ta.sma(ta.sma(ta.stoch(C, H, L, Length), 3), 3)` | Slow %D with custom prices |
| `StochasticExp(H, L, C, Length, S1, S2, ...)` | `ta.ema(ta.stoch(C, H, L, Length), S1)` | Uses EMA smoothing instead of SMA; compute %D from %K manually |
| `ADXR(Length)` | `[diPlus, diMinus, adxV] = ta.dmi(Length, Length)` at global scope, then `(adxV + adxV[Length]) / 2` | Average of current ADX and ADX N bars ago; `[]` indexing on a function call (or chained `[2][Length]`) is invalid — destructure into a variable first |
| `ADXCustom(H, L, C, Length)` | Manual: replicate ADX using custom H/L/C | No Pine built-in; implement Wilder smoothing with custom prices |
| `DMI(Length)` | `ta.dmi(Length, Length)` | Same as `ADX`; wrapper that returns DMI value |
| `DMIPlusCustom(H, L, C, Length)` | Manual: `+DI` with custom prices | No Pine built-in; compute +DM from custom highs |
| `DMIMinusCustom(H, L, C, Length)` | Manual: `−DI` with custom prices | No Pine built-in; compute −DM from custom lows |
| `ParabolicCustom(AfStep, AfLimit)` | Manual Parabolic SAR with limit | No Pine built-in; implement SAR loop with `AfLimit` cap |
| `TRIX(Close, Length)` | Manual: `ta.change(ta.ema(ta.ema(ta.ema(close, Length), Length), Length))` | Triple EMA ROC; no Pine built-in |
| `MassIndex(SmoothLen, SumLen)` | Manual: `math.sum(ta.ema(high - low, SmoothLen) / ta.ema(ta.ema(high - low, SmoothLen), SmoothLen), SumLen)` | No Pine built-in; ratio of single/double EMA of range |
| `EaseOfMovement` | Manual: `((high + low) / 2 - (high[1] + low[1]) / 2) / (volume / (high - low))` | No Pine built-in; distance moved / box ratio |
| `SwingIndex` | Manual: Wilder swing index formula | No Pine built-in; complex formula using O/H/L/C of current and previous bars |
| `AccumSwingIndex` | Manual: cumulative sum of SwingIndex | No Pine built-in; `ta.cum(swingIndex)` |
| `Detrend(Close, Length)` | `close - ta.sma(close, Length)[int(Length / 2 + 1)]` | No Pine built-in; offset SMA detrending |
| `PercentChange(Close, Length)` | `ta.change(close, Length) / close[Length] * 100` | Manual computation; or `ta.roc(close, Length)` if ROC matches |
| `UlcerIndex(Close, Length)` | Manual: `math.sqrt(ta.sma(math.pow((close - ta.highest(close, Length)) / ta.highest(close, Length) * 100, 2), Length))` | No Pine built-in; RMS of drawdown percentage |
| `ParabolicSAR(AfStep, AfLimit, ...)` | Manual SAR with position/transition outputs | Multi-output version; implement SAR loop tracking direction changes |
| `LinearReg(Close, Length, TgtBar, ...)` | `ta.linreg(close, Length, TgtBar)` + manual slope/angle/intercept | Multi-output; Pine `ta.linreg` returns value only |
| `TrueRangeCustom(H, L, C)` | `math.max(H - L, math.abs(H - C[1]), math.abs(L - C[1]))` | Custom prices; same formula as `ta.tr` |
| `VolatilityStdDev(NumDays)` | `ta.stdev(math.log(close / close[1]), NumDays) * math.sqrt(252)` | Historical vol; annualized stdev of log returns |
| `StandardDevAnnual(Close, Length, DataType)` | `ta.stdev(close, Length) * math.sqrt(252)` | Annualized standard deviation |
| `HighestFC(Close, Length)` | `ta.highest(close, Length)` | Fast calc variant; same as `Highest` in Pine |
| `LowestFC(Close, Length)` | `ta.lowest(close, Length)` | Fast calc variant; same as `Lowest` in Pine |
| `PivotHighVS(Inst, Price, LStr, RStr, Length)` | `ta.pivothigh(Price, LStr, RStr)` | Pine `ta.pivothigh` supports asymmetric left/right; returns `na` when no pivot |
| `PivotLowVS(Inst, Price, LStr, RStr, Length)` | `ta.pivotlow(Price, LStr, RStr)` | Same as above for lows |
| `PivotHighVSBar(Inst, Price, LStr, RStr, Length)` | Manual: track `bar_index` when `ta.pivothigh` fires | Record bar offset when pivot appears |
| `PivotLowVSBar(Inst, Price, LStr, RStr, Length)` | Manual: track `bar_index` when `ta.pivotlow` fires | Record bar offset when pivot appears |
| `Divergence(Price1, Price2, Str, Len, HiLo)` | Manual: compare pivots of two series | No Pine built-in; detect when price makes new high/low but indicator doesn't |
| `TimeSeriesForecast(Close, Length)` | `ta.linreg(close, Length, 0)` | Direct equivalent |
| `SummationFC(Close, Length)` | `math.sum(close, Length)` | Fast calc Summation; same as `Summation` in Pine |
| `OpenD(N)` | `request.security(syminfo.tickerid, "D", open[N])` | Daily open; requires `request.security` for MTF |
| `HighD(N)` | `request.security(syminfo.tickerid, "D", high[N])` | Daily high |
| `LowD(N)` | `request.security(syminfo.tickerid, "D", low[N])` | Daily low |
| `CloseD(N)` | `request.security(syminfo.tickerid, "D", close[N])` | Daily close |
| `OpenW(N)` | `request.security(syminfo.tickerid, "W", open[N])` | Weekly open |
| `HighW(N)` | `request.security(syminfo.tickerid, "W", high[N])` | Weekly high |
| `LowW(N)` | `request.security(syminfo.tickerid, "W", low[N])` | Weekly low |
| `CloseW(N)` | `request.security(syminfo.tickerid, "W", close[N])` | Weekly close |
| `OpenM(N)` | `request.security(syminfo.tickerid, "M", open[N])` | Monthly open |
| `HighM(N)` | `request.security(syminfo.tickerid, "M", high[N])` | Monthly high |
| `LowM(N)` | `request.security(syminfo.tickerid, "M", low[N])` | Monthly low |
| `CloseM(N)` | `request.security(syminfo.tickerid, "M", close[N])` | Monthly close |
| `OpenY(N)` | `request.security(syminfo.tickerid, "12M", open[N])` | Yearly open; Pine uses "12M" for yearly |
| `HighY(N)` | `request.security(syminfo.tickerid, "12M", high[N])` | Yearly high |
| `LowY(N)` | `request.security(syminfo.tickerid, "12M", low[N])` | Yearly low |
| `CloseY(N)` | `request.security(syminfo.tickerid, "12M", close[N])` | Yearly close |
| `LRO(Cond, Length, N)` | Manual: find Nth-oldest True in lookback | No Pine built-in; scan from `Length` bars ago forward |
| `SummationIf(Cond, Price, Length)` | Manual: `ta.cum(Cond ? Price : 0) - nz(ta.cum(Cond ? Price : 0)[Length])` | Conditional rolling sum |
| `IFFString(Cond, TrueStr, FalseStr)` | `Cond ? TrueStr : FalseStr` | Pine ternary works with strings |
| `OBV` | `ta.obv` | Direct equivalent; Pine built-in |
| `VolumeROC(Length)` | `ta.roc(volume, Length)` | Rate of change applied to volume |
| `VolumeOsc(ShortLen, LongLen)` | `ta.sma(volume, ShortLen) - ta.sma(volume, LongLen)` | Difference of two volume SMAs |
| `PriceVolTrend` | Manual: `ta.cum(ta.change(close) / close[1] * volume)` | Cumulative price-volume trend |
| `LWAccDis` | Manual: `ta.cum((close - open) / (high - low) * volume)` | Larry Williams A/D |
| `Fisher(Price)` | Manual: `0.5 * math.log((1 + norm) / (1 - norm))` | Normalize price to −0.999..+0.999 first |
| `FisherINV(Price)` | Manual: `(math.exp(2 * Price) - 1) / (math.exp(2 * Price) + 1)` | Inverse Fisher transformation |
| `C_Doji(Percent)` | Manual: `math.abs(close - open) <= (high - low) * Percent / 100` | Detect doji pattern |
| `C_Hammer_HangingMan(Len, Factor, ...)` | Manual: check body/shadow ratios | Lower shadow ≥ 2× body, small upper shadow |
| `C_BullEng_BearEng(Len, ...)` | Manual: current body engulfs previous body | Bullish: down bar followed by larger up bar |
| `C_BullHar_BearHar(Len, ...)` | Manual: current body inside previous body | Opposite of engulfing; small body inside large |
| `C_MornDoji_EveDoji(Len, Pct, ...)` | Manual: 3-bar pattern with middle doji | Morning/Evening star variant with doji middle |
| `C_MornStar_EveStar(Len, ...)` | Manual: 3-bar reversal pattern | Down-small-up (morning) or up-small-down (evening) |
| `C_PierceLine_DkCloud(Len, ...)` | Manual: 2-bar pattern, close pierces midpoint | Gap down then close above midpoint of prior bar |
| `C_ShootingStar(Len, Factor)` | Manual: small body at low, long upper shadow | Upper shadow ≥ 2× body, small lower shadow |
| `C_3WhSolds_3BlkCrows(Len, Factor, ...)` | Manual: 3 consecutive bars in same direction | Three ascending closes (soldiers) or three descending (crows) |
| **Statistical extended** | | |
| `AvgDeviation(Close, N)` | Manual: `math.sum(math.abs(close - ta.sma(close, N)), N) / N` | Mean absolute deviation |
| `Variance(Close, N)` | `ta.variance(close, N)` | Population variance |
| `Kurtosis(Close, N)` | Manual: 4th moment calculation | Excess kurtosis |
| `Skew(Close, N)` | Manual: 3rd moment calculation | Skewness |
| `PercentRank(ValToRank, Price, N)` | `ta.percentrank(close, N)` | Percent rank within lookback |
| `Covariance(P1, P2, N)` | Manual: `ta.sma(P1*P2, N) - ta.sma(P1, N)*ta.sma(P2, N)` | Covariance — note this `sma(xy) − sma(x)·sma(y)` identity gives the POPULATION (ddof=0) covariance |
| `Quartile(Close, N, Q)` | `ta.percentile_nearest_rank(close, N, Q*25)` | Quartile value |
| `TrimMean(Close, N, Pct)` | Manual: sort window, trim, average | Trimmed mean |
| `Mode(Close, N, Type)` | Manual: frequency count over window | Modal value |
| `HarmonicMean(Close, N)` | Manual: `N / math.sum(1/close, N)` | Harmonic mean |
| **Moving averages extended** | | |
| `SmoothedAverage(Close, N)` | `ta.rma(close, N)` | Wilder smoothing = RMA |
| **Miscellaneous** | | |
| `BarAnnualization` | Manual: compute from `timeframe.period` | Bars-per-year factor |
| `LastBarOnChart` | `barstate.islast` | True on last bar |
| **Custom functions** | | |
| `StochRSI(Close, N, M)` | `rsiVal = ta.rsi(close, N)` → `(rsiVal - ta.lowest(rsiVal, M)) / (ta.highest(rsiVal, M) - ta.lowest(rsiVal, M))` | Stochastic of RSI (0–1) |
| `supertrend(N, Mult)` | `[st, dir] = ta.supertrend(Mult, N)` | Pine order is `(factor, atrPeriod)` — reversed |
| `NVI(Start)` | Manual: accumulate `prev*(1+(close-close[1])/close[1])` when `volume < volume[1]` | Negative Volume Index |
| `PVI(Start)` | Manual: accumulate `prev*(1+(close-close[1])/close[1])` when `volume > volume[1]` | Positive Volume Index |
| `Coppo(N1, N2, N3)` | `ta.wma(ta.roc(close, N1) + ta.roc(close, N2), N3)` | Coppock Curve |
| `LWTI(Close, P, N)` | Manual: `ta.sma(close-close[P], N) / ta.sma(high-low, N) * 50 + 50` | Larry Williams Trading Index |
| `TVI(Close, Vol, Tick)` | Manual: cumulative directional volume with tick threshold | Trade Volume Index |
| `SharpeRatio(Period, Rate, Calc, Cap)` | Manual: portfolio-level `(avgReturn - riskFree) / stdReturn` | No Pine equivalent; portfolio only |
| `WRSI(N, Close)` | `ta.rsi(close, N)` | Pine RSI already uses Wilder smoothing |
| `NewMA(Close, N)` | Manual: Heikin-Ashi + triple EMA hybrid | No direct Pine equivalent |

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
| `SetStopLoss(dollars)` | `strategy.exit("id", stop=strategy.position_avg_price - dollars / (qty * syminfo.pointvalue))` | PL takes a dollar amount; Pine takes an absolute price level — convert via point value |
| `SetProfitTarget(dollars)` | `strategy.exit("id", limit=strategy.position_avg_price + dollars / (qty * syminfo.pointvalue))` | Same dollar-to-price conversion required |
| `SetDollarTrailing(dollars)` | `strategy.exit("id", trail_points=activationTicks, trail_offset=dollars / (qty * syminfo.pointvalue) / syminfo.mintick)` | **Pine trailing needs an activation level (`trail_price` or `trail_points`) that PL does not have, and `trail_points`/`trail_offset` are in TICKS** — convert dollars → price distance → ticks |
| `SetPercentTrailing(dollars, pct)` | `strategy.exit("id", trail_price=activationPrice, trail_offset=offsetTicks)` | Same tick-unit and activation-level warnings; PL arms after `dollars` of open profit then gives back `pct`% of the peak profit — compute the activation price for `trail_price` manually |
| `[IntrabarOrderGeneration = true]` | `strategy(..., calc_on_every_tick=true)` | Closest mapping, but semantics differ: PL IOG evaluates intrabar on real ticks both live and in backtest; Pine `calc_on_every_tick` affects real-time only — historical bars still fill on OHLC-modeled prices unless bar magnifier is enabled |

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
| `For idx = 1 to n Begin ... End;` | `for i = 1 to n\n    ...` | Loop body is indented; no `Begin`/`End` needed. PL side uses `idx` because `i` is reserved (alias for OpenInterest) |
| `While cond Begin ... End;` | `while cond\n    ...` | Same indentation pattern |
| `Switch (expr) Begin Case 1: ...; End;` | `switch expr\n    1 => ...` | Pine `switch` uses `=>` arrows and indentation; PL empty case body is a compile error — use `Value1 = Value1;` as no-op |
| `Once Begin ... End;` | `if barstate.isfirst\n    ...` | PL `Once` runs code on the first bar only; Pine uses the `barstate.isfirst` built-in |

---

### Table 7 — Other Built-ins and Features

| PowerLanguage | Pine Script | Notes |
|---|---|---|
| `MarketPosition` | `strategy.position_size` | PL returns -1/0/1; Pine returns the actual signed position size — check sign rather than comparing to 1 or -1 |
| `EntryPrice` | `strategy.position_avg_price` | Pine gives the average entry price of the current position |
| `CurrentContracts` | `math.abs(strategy.position_size)` | PL gives absolute contract count; Pine position size is signed |
| `BarsSinceEntry` | `bar_index - strategy.opentrades.entry_bar_index(strategy.opentrades - 1)` | Built-in since v5; gives bars since the most recent open trade's entry — no manual tracker needed |
| `Print("text")` | `label.new(bar_index, high, "text")` or `log.info("text")` | `label.new` creates on-chart labels; `log.info` writes to the Pine console |
| `#BeginCmtry ... #EndCmtry` | no equivalent | Pine has no commentary output; use `label.new` for visible annotations |
| `Alert("msg", AlertType)` | `alert("msg", alert.freq_once_per_bar)` or `alertcondition(cond, "title")` | Pine `alertcondition` registers a condition for the Alerts dialog; `alert()` fires immediately |

---

## Part 2: Semantic Differences and Gotchas

### Order fill timing — the #1 conversion bug

- **PL fills on the NEXT bar.** `Buy next bar at market` fills at the NEXT bar's OPEN. `Buy next bar at X Stop` / `Limit` fills intrabar on the next bar at the stop/limit price (or at the open if the bar gaps through it). Any conversion that flips position on the signal bar at that bar's close is one bar early and uses the wrong price.
- **Pine matches PL by default.** `strategy.entry` with the default `process_orders_on_close=false` fills at the next bar's open — same as PL `next bar at market`. Setting `process_orders_on_close=true` fills at the SAME bar's close, which does NOT match PL — never set it when converting from PL.
- **EMA seeding/warmup differs.** PL `XAverage` seeds recursively from the first bar's price; Pine `ta.ema` is `na` during warmup. Early-history values (and therefore early signals) differ between the two platforms — discard roughly the first 3×Length bars before comparing backtests.

1. **`Sell` does not mean "go short".** In PowerLanguage, `Sell` exits an existing long position. The Pine equivalent is `strategy.close()`. If you write `strategy.entry("label", strategy.short)` as a translation of `Sell`, you will create a new short position rather than closing the long — this is one of the most common and costly conversion mistakes.

2. **Multi-data feed architecture is fundamentally different.** PowerLanguage allows a second (or third) price feed to be attached directly to the chart as Data2/Data3, and accesses its bars with `Close of Data2`. Pine Script has no concept of a second chart feed; instead you must call `request.security(syminfo.tickerid, "D", close)` with an explicit symbol string and timeframe. There is no direct bar-by-bar alignment guarantee across different timeframes in Pine the way there is when you add a second data series in MultiCharts.

3. **Dollar amounts versus price levels.** `SetStopLoss` and `SetProfitTarget` in PowerLanguage accept a dollar (currency) amount, which MultiCharts converts internally to a price level using the instrument's point value and position size. Pine Script's `strategy.exit()` `stop` and `limit` parameters require an absolute price level. You must perform the conversion explicitly: `stop_price = strategy.position_avg_price - stop_dollars / (qty * syminfo.pointvalue)`.

4. **Stochastic parameter mismatch.** PowerLanguage's `Stochastic` function accepts 11 parameters covering %K and %D periods, smoothing type, and detrending options. Pine's `ta.stoch()` accepts 4 parameters and returns raw %K only. If your PL strategy relies on the smoothed %D line or any of the advanced smoothing options, you must replicate that smoothing manually in Pine after calling `ta.stoch()`.

5. **Bar numbering is offset by one.** PowerLanguage's `BarNumber` and `CurrentBar` start at 1 for the first historical bar. Pine's `bar_index` starts at 0. Any logic that compares bar counts, computes bar offsets, or initializes arrays based on `BarNumber` must subtract or add 1 when converting. Caveat: `CurrentBar` counts from the first EXECUTED bar after MaxBarsBack is satisfied, so `bar_index + 1` is exact only when MaxBarsBack = 0.

6. **Position size semantics differ.** `MarketPosition` in PowerLanguage returns exactly -1 (short), 0 (flat), or 1 (long) regardless of how many contracts are held. Pine's `strategy.position_size` returns the signed number of contracts — for example, +3 if three long contracts are open. Code that tests `if MarketPosition = 1` should become `if strategy.position_size > 0` in Pine, not `if strategy.position_size = 1`.

7. **Execution model: confirmed close versus real-time tick.** PowerLanguage strategies execute on bar close by default (the bar is confirmed before orders are evaluated). Pine Script strategies also default to executing on bar close, but the behavior of `calc_on_every_tick` and `calc_on_order_fills` can alter this. When porting a PL strategy, verify that the Pine `strategy()` declaration does not add intrabar recalculation that was absent in the original.

8. **Portfolio Money Management (PMM) has no Pine equivalent.** MultiCharts PMM allows a single money-management script to govern position sizing across a portfolio of instruments. Pine Script has no portfolio-level concept; each script runs independently on a single symbol. PMM logic must be reimplemented as per-symbol position sizing inside the Pine strategy itself.

9. **PowerLanguage Functions (.elf files) must become Pine user-defined functions or libraries.** A PL `.elf` (EasyLanguage Function) is a reusable calculation unit compiled separately and called from indicators or strategies. In Pine, the equivalent is either a user-defined function defined with `f_name(params) =>` syntax within the same script, or a published Pine library imported with `import`. There is no separate compilation step in Pine.

10. **History-referencing functions must be called at global scope in Pine.** In PL, `Crosses Over` / `Crosses Under` can appear inside any `If` block without issue. In Pine, `ta.crossover()`, `ta.crossunder()`, `ta.change()`, `ta.pivothigh()`, `ta.pivotlow()`, and similar functions must be called on every bar at the global scope to maintain correct internal state. Calling them inside a conditional block (e.g. `if strategy.position_size > 0`) produces a compiler warning and potentially incorrect results. Extract the call to a variable at the top level, then use that variable inside conditions.

11. **Value1..Value99 and Condition1..Condition99 must be renamed.** These PL numbered built-ins have no Pine counterpart. Every occurrence must be replaced with a descriptive typed variable (`var float`, `var bool`, or a plain expression). Do not carry over numbers as Pine variable names — names like `val1` are legal but `Value1` in a Pine context is just an undefined identifier that will cause a compile error.

---

## Part 3: Conversion Checklists

### PL → Pine Pre-Conversion

- [ ] Target `//@version=5` for all conversions — v5 is the proven baseline; v6 may require additional syntax adjustments
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
- [ ] `BarsSinceEntry` replaced with `bar_index - strategy.opentrades.entry_bar_index(strategy.opentrades - 1)`
- [ ] Dollar-based stop/target amounts converted to price levels in all `strategy.exit()` calls
- [ ] `Value1..Value99` and `Condition1..Condition99` renamed to typed Pine variables
- [ ] Stochastic %D smoothing replicated manually if the original strategy used the smoothed line
- [ ] All `ta.crossover()`, `ta.crossunder()`, and other history-referencing functions called at global scope, not inside conditional blocks
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
