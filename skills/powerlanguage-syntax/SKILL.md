---
name: powerlanguage-syntax
description: Use when reading or writing PowerLanguage code — declarations (Inputs, Variables, Arrays), data types (numeric, string, truefalse), the begin/end semicolon rules, control flow (If/Then/Else, For, While, Switch), bar references (Close, Close[N], Date, Time, BarNumber), operators, comments, the pre-declared Value1..Value10000 and Condition1..Condition10000 built-ins, the built-in trade-state variables (MarketPosition, EntryPrice, BarsSinceEntry, CurrentContracts), and common gotchas — including "syntax error, unexpected X" / "Wrong syntax of X" errors caused by writing keywords like Print/File/Variable/If/Yesterday/#BeginCmtry as RHS values, MarketPosition(N) being position history (NOT bar offset), and bars being labeled by their close time (NOT open time).
---

# PowerLanguage Syntax

## Declarations

Every script starts with declarations. Order matters: `Inputs:` comes before `Variables:` (or its aliases `Vars:`, `Var:`); both come before code.

```pascal
Inputs:
    Length(20),
    Threshold(0.0);

Variables:
    avgVal(0),
    triggered(False);

Arrays:
    buffer[10](0);
```

- **Inputs** — parameters exposed in the script's Format window. Each gets a default value in parentheses. Read-only inside the script.
- **Variables / Vars / Var** — script state. Each gets an initial value. Persist across bars within the same chart.
- **Arrays** — fixed-size collections. `[size]` is the index of the last element (zero-based by default), `(initial)` initializes every slot.

**Pre-declared default variables.** PowerLanguage ships with numbered built-ins that don't need a `Variables:` declaration:

| Name | Type | Count |
|---|---|---|
| `Value1` … `Value10000` | numeric | 10,000 |
| `Condition1` … `Condition10000` | truefalse | 10,000 |

Use them directly: `Value1 = Average(Close, 14);`, `If Condition1 Then Buy ...;`. No declaration line required (declaring one just shadows the built-in with an identical local). These are handy for quick scratch values when you don't want to bother naming a variable.

## Data types

PowerLanguage is loosely typed but each value is one of:

| Type | What it is | Literal examples |
|---|---|---|
| Numeric | Floating-point number | `0`, `1.5`, `-3.14` |
| String | Text | `"hello"`, `"LE"` |
| TrueFalse (bool) | Boolean | `True`, `False` |

Type is inferred from initial value in `Variables:` / `Inputs:` declarations.

## The `begin … end` rule and semicolons

`begin` opens a block; `end` closes it. **Every `end` gets a semicolon EXCEPT when followed by `else`.**

```pascal
// (pseudocode — real scripts need Variables declarations for all names)
If condition Then Begin
    statement1;
    statement2;
End                     // NO semicolon — else follows
Else Begin
    statement3;
End;                    // semicolon — outer statement boundary
```

Forgetting a semicolon on a terminal `End` is the most common compile error new PowerLanguage users hit. The rule is mechanical: if the next token is `Else`, no semicolon; otherwise yes.

## Control flow

```pascal
// (pseudocode forms — declare all variables in real scripts)
If x > 0 Then Begin ... End;

If x > 0 Then ... Else If x = 0 Then ... Else ... ;

Variables: idx(0), runTotal(0);   // loop counter + accumulator must be declared
For idx = 1 To 10 Begin
    runTotal = runTotal + idx;
End;

While condition Begin ... End;

Switch (n) Begin
    Case 1: ... ;
    Case 2: ... ;
    Default: ... ;
End;
```

**`For` / `While` loop counters must be declared as Variables.** PowerLanguage does not auto-declare loop counters. Using an undeclared name gives "Invalid type operation."

## Bar references

`Close` is the close price of the current bar; `Close[1]` is the close one bar ago; `Close[N]` is N bars ago. Same indexing for `Open`, `High`, `Low`, `Volume`, `OpenInterest`.

| Built-in | Meaning |
|---|---|
| `Close`, `Open`, `High`, `Low` | OHLC of current bar |
| `Volume` | Volume of current bar |
| `OpenInterest` | OI of current bar (futures/options) |
| `Date` | Bar date as `YYYMMDD` integer (note: only 7 digits for years up to 2099, format is `(YYYY-1900)*10000 + MM*100 + DD`) |
| `Time` | Bar **close** time as `HHMM` integer — see gotcha below |
| `BarNumber` | Sequential count, same as `CurrentBar` |

## Operators

- Arithmetic: `+`, `-`, `*`, `/`
- Comparison: `=`, `<>`, `>`, `<`, `>=`, `<=`
- Logical: `and`, `or`, `not` (lowercase; `and` is a keyword, not `&&`)

## Comments

- Line comment: `// up to end of line`
- Block comment: `{ braces — can span multiple lines }`

The `{ … }` block-comment form is also how PowerLanguage code authors traditionally write file headers.

## Built-in trade-state variables (Signal scripts)

Inside a Signal script, these are always available — no declaration needed:

| Variable | Meaning |
|---|---|
| `MarketPosition` | `1` if long, `-1` if short, `0` if flat. Optional `(N)` = Nth-ago position — see gotcha below |
| `CurrentContracts` | Absolute size of current position |
| `EntryPrice` | Average fill price of current position. Optional `(N)` = Nth-ago position |
| `BarsSinceEntry` | Bars since current position was entered. Optional `(N)` = Nth-ago position |
| `BarsSinceExit(N)` | Bars since the Nth-most-recent exit |

## Order syntax (high-level recap)

```pascal
Buy ("LE") 1 Contract Next Bar at Market;
Sell ("LX") 1 Contract Next Bar at Market;
SellShort ("SE") 1 Contract Next Bar at Market;
BuyToCover ("SX") 1 Contract Next Bar at Market;
```

Quantities use `Contract` / `Contracts` (futures, FX) or `Share` / `Shares` (equities). The price-placement keyword (`Market`, `Limit`, `Stop`, `This Bar on Close`) determines when the fill happens. See `powerlanguage-keywords-reference` for each order keyword's full signature.

## Common built-in functions

MultiCharts ships with hundreds of pre-built Functions (`.elf` and `.pla` files) that are NOT in the keyword reference. These are the most commonly used ones — get the signatures right or you'll get compile errors.

### Moving averages and smoothing

| Function | Signature | Returns |
|---|---|---|
| `Average` | `Average(Price, Length)` | numeric |
| `XAverage` | `XAverage(Price, Length)` | numeric (exponential MA) |
| `AverageFC` | `AverageFC(Price, Length)` | numeric (fast calculation) |
| `WAverage` | `WAverage(Price, Length)` | numeric (weighted MA) |
| `AdaptiveMovAvg` | `AdaptiveMovAvg(Price, EffRatioLen, FastAvgLen, SlowAvgLen)` | numeric (Kaufman AMA) |
| `MidPoint` | `MidPoint(Price, Length)` | numeric |
| `TriAverage` | `TriAverage(Price, Length)` | numeric (triangular MA; double-smoothed SMA) |

### Oscillators and indicators

| Function | Signature | Returns |
|---|---|---|
| `RSI` | `RSI(Price, Length)` | numeric (0–100) |
| `Stochastic` | `Stochastic(PriceH, PriceL, PriceC, StochLen, SmoothLen1, SmoothLen2, SmoothType, oFastK, oFastD, oSlowK, oSlowD)` | numeric (1=ok, -1=error); populates 4 ref vars |
| `BollingerBand` | `BollingerBand(Price, Length, NumDevs)` | numeric (+NumDevs for upper, -NumDevs for lower) |
| `MACD` | `MACD(Price, FastLen, SlowLen)` | numeric |
| `KeltnerChannel` | `KeltnerChannel(Price, Length, NumATRs)` | numeric |
| `CCI` | `CCI(Length)` | numeric |
| `ADX` | `ADX(Length)` | numeric |
| `DMIPlus` | `DMIPlus(Length)` | numeric |
| `DMIMinus` | `DMIMinus(Length)` | numeric |
| `Momentum` | `Momentum(Price, Length)` | numeric |
| `RateOfChange` | `RateOfChange(Price, Length)` | numeric |
| `PercentR` | `PercentR(Length)` | numeric (Williams %R) |
| `MoneyFlow` | `MoneyFlow(Length)` | numeric |
| `Parabolic` | `Parabolic(AfStep)` | numeric (Parabolic SAR) |
| `Volatility` | `Volatility(Length)` | numeric |
| `UltimateOscillator` | `UltimateOscillator(Len1, Len2, Len3)` | numeric |
| `ChaikinOsc` | `ChaikinOsc(FastLen, SlowLen, SmoothType)` | numeric |
| `PriceOscillator` | `PriceOscillator(Price, FastLen, SlowLen)` | numeric |
| `TSI` | `TSI(Price, LongLength, ShortLength)` | numeric (True Strength Index; double-smoothed momentum, range roughly −100 to +100) |
| `ADXR` | `ADXR(Length)` | numeric (ADX Rating; average of current ADX and ADX N bars ago) |
| `ADXCustom` | `ADXCustom(PriceH, PriceL, PriceC, Length)` | numeric (ADX with custom H/L/C) |
| `DMI` | `DMI(Length)` | numeric (Directional Movement Index) |
| `DMIPlusCustom` | `DMIPlusCustom(PriceH, PriceL, PriceC, Length)` | numeric (+DI with custom H/L/C) |
| `DMIMinusCustom` | `DMIMinusCustom(PriceH, PriceL, PriceC, Length)` | numeric (−DI with custom H/L/C) |
| `ParabolicCustom` | `ParabolicCustom(AfStep, AfLimit)` | numeric (Parabolic SAR with custom acceleration limit) |
| `TRIX` | `TRIX(Price, Length)` | numeric (triple EMA rate-of-change) |
| `MassIndex` | `MassIndex(SmoothingLength, SummationLength)` | numeric (signals reversal when crossing 27) |
| `EaseOfMovement` | `EaseOfMovement` | numeric (no args; volume-weighted price movement) |
| `SwingIndex` | `SwingIndex` | numeric (no args; Wilder's swing index, −100 to +100) |
| `AccumSwingIndex` | `AccumSwingIndex` | numeric (no args; cumulative running total of SwingIndex) |
| `Detrend` | `Detrend(Price, Length)` | numeric (detrended price; deviation from offset average) |
| `PercentChange` | `PercentChange(Price, Length)` | numeric (percent change vs N bars ago) |
| `UlcerIndex` | `UlcerIndex(Price, Length)` | numeric (downside volatility / drawdown stress) |

**"No Price parameter" gotcha:** These functions take **no Price parameter** — passing `Close` as the first arg is a compile error:
- **Length-only:** `CCI`, `ADX`, `ADXR`, `DMI`, `DMIPlus`, `DMIMinus`, `AvgTrueRange`, `PercentR`, `MoneyFlow`, `Volatility`, `RSquared`, `AccumDist` — call as `ADX(14)`, not `ADX(Close, 14)`.
- **Multi-length (no Price):** `UltimateOscillator(Len1, Len2, Len3)`, `ChaikinOsc(FastLen, SlowLen, SmoothType)`, `MassIndex(SmoothLen, SumLen)` — all parameters are lengths/types, not prices.
- **Single non-length:** `Parabolic(AfStep)` — takes only an acceleration factor step, e.g. `Parabolic(0.02)`.
- **No arguments:** `EaseOfMovement`, `SwingIndex`, `AccumSwingIndex`, `OBV`, `PriceVolTrend`, `LWAccDis` — use current bar OHLCV internally.

**`Stochastic` gotcha:** It takes **11 parameters**, not 3. The last 4 are output ref variables — you must declare Variables for them. The return value is just a status code (1 or -1), not the stochastic value itself. Typical usage:

```pascal
Variables: fastK(0), fastD(0), slowK(0), slowD(0);
Value1 = Stochastic(High, Low, Close, 14, 3, 3, 1, fastK, fastD, slowK, slowD);
// Use slowK and slowD for signals
```

### Stochastic helper functions

These are convenience wrappers around the full `Stochastic` function. The default variants use the current bar's `High`, `Low`, `Close`; the `Custom` variants accept explicit price inputs.

| Function | Signature | Returns |
|---|---|---|
| `FastK` | `FastK(StochLength)` | numeric (raw Fast %K using default H/L/C) |
| `FastD` | `FastD(StochLength)` | numeric (smoothed Fast %D using default H/L/C) |
| `SlowK` | `SlowK(StochLength)` | numeric (Slow %K using default H/L/C) |
| `SlowD` | `SlowD(StochLength)` | numeric (Slow %D using default H/L/C) |
| `FastKCustom` | `FastKCustom(PriceH, PriceL, PriceC, StochLength)` | numeric (raw Fast %K with custom prices) |
| `FastDCustom` | `FastDCustom(PriceH, PriceL, PriceC, StochLength)` | numeric (smoothed Fast %D with custom prices) |
| `SlowKCustom` | `SlowKCustom(PriceH, PriceL, PriceC, StochLength)` | numeric (Slow %K with custom prices) |
| `SlowDCustom` | `SlowDCustom(PriceH, PriceL, PriceC, StochLength)` | numeric (Slow %D with custom prices) |
| `StochasticExp` | `StochasticExp(PriceH, PriceL, PriceC, StochLength, SmoothLen1, SmoothLen2, oFastD, oSlowD)` | numeric (returns Fast %K); uses EMA smoothing, populates 2 ref vars |

### Multi-output functions

These functions populate output ref variables — you must declare Variables for each output parameter.

| Function | Signature | Returns |
|---|---|---|
| `DirMovement` | `DirMovement(H, L, C, Length, oDMIp, oDMIm, oADX, oDIp, oDIm, oADXr)` | numeric; populates 6 ref vars |
| `Extremes` | `Extremes(Price, Length, ExtrType, oExtUp, oExtDn)` | numeric; populates 2 ref vars |
| `ParabolicSAR` | `ParabolicSAR(AfStep, AfLimit, oParCl, oParOp, oPosition, oTransition)` | numeric; populates 4 ref vars (close/open SAR, position direction, transition flag) |
| `LinearReg` | `LinearReg(Price, Length, TgtBar, oSlope, oAngle, oIntercept, oValueRaw)` | numeric; populates 4 ref vars |

### Volatility and range

| Function | Signature | Returns |
|---|---|---|
| `AvgTrueRange` | `AvgTrueRange(Length)` | numeric |
| `TrueRange` | `TrueRange` | numeric (no args) |
| `StandardDev` | `StandardDev(Price, Length, DataType)` | numeric (DataType: 1=population, 2=sample) |
| `TrueHigh` | `TrueHigh` | numeric (no args) |
| `TrueLow` | `TrueLow` | numeric (no args) |
| `Range` | `Range` | numeric (no args; High - Low) |
| `TrueRangeCustom` | `TrueRangeCustom(HPrice, LPrice, CPrice)` | numeric (true range with custom H/L/C) |
| `VolatilityStdDev` | `VolatilityStdDev(NumDays)` | numeric (historical volatility based on stdev of closes) |
| `StandardDevAnnual` | `StandardDevAnnual(Price, Length, DataType)` | numeric (annualized standard deviation) |

### Price extremes and Nth

| Function | Signature | Returns |
|---|---|---|
| `Highest` | `Highest(Price, Length)` | numeric |
| `Lowest` | `Lowest(Price, Length)` | numeric |
| `HighestBar` | `HighestBar(Price, Length)` | numeric (bars ago) |
| `LowestBar` | `LowestBar(Price, Length)` | numeric (bars ago) |
| `NthHighest` | `NthHighest(Nth, Price, Length)` | numeric |
| `NthLowest` | `NthLowest(Nth, Price, Length)` | numeric |
| `NthHighestBar` | `NthHighestBar(Nth, Price, Length)` | numeric (bars ago) |
| `NthLowestBar` | `NthLowestBar(Nth, Price, Length)` | numeric (bars ago) |
| `HighestFC` | `HighestFC(Price, Length)` | numeric (fast calculation Highest) |
| `LowestFC` | `LowestFC(Price, Length)` | numeric (fast calculation Lowest) |

### Swing detection

| Function | Signature | Returns |
|---|---|---|
| `SwingHigh` | `SwingHigh(Occurrence, Price, Strength, Length)` | numeric (price at swing, or -1 if none) |
| `SwingLow` | `SwingLow(Occurrence, Price, Strength, Length)` | numeric (price at swing, or -1 if none) |
| `SwingHighBar` | `SwingHighBar(Occurrence, Price, Strength, Length)` | numeric (bars ago) |
| `SwingLowBar` | `SwingLowBar(Occurrence, Price, Strength, Length)` | numeric (bars ago) |

### Pivot with variable strength

Like SwingHigh/Low but with independent left and right strength parameters.

| Function | Signature | Returns |
|---|---|---|
| `PivotHighVS` | `PivotHighVS(Instance, Price, LeftStrength, RightStrength, Length)` | numeric (price at pivot, or -1 if none) |
| `PivotLowVS` | `PivotLowVS(Instance, Price, LeftStrength, RightStrength, Length)` | numeric (price at pivot, or -1 if none) |
| `PivotHighVSBar` | `PivotHighVSBar(Instance, Price, LeftStrength, RightStrength, Length)` | numeric (bars ago) |
| `PivotLowVSBar` | `PivotLowVSBar(Instance, Price, LeftStrength, RightStrength, Length)` | numeric (bars ago) |

### Divergence detection

| Function | Signature | Returns |
|---|---|---|
| `Divergence` | `Divergence(Price1, Price2, Strength, Length, HiLo)` | numeric (1 if divergence found; HiLo: -1=bullish, 1=bearish) |

### Aggregation and linear regression

| Function | Signature | Returns |
|---|---|---|
| `Summation` | `Summation(Price, Length)` | numeric |
| `Cum` | `Cum(Price)` | numeric (cumulative sum from bar 1) |
| `LinearRegValue` | `LinearRegValue(Price, Length, Offset)` | numeric |
| `LinearRegAngle` | `LinearRegAngle(Price, Length)` | numeric |
| `LinearRegSlope` | `LinearRegSlope(Price, Length)` | numeric |
| `Correlation` | `Correlation(Price1, Price2, Length)` | numeric |
| `RSquared` | `RSquared(Length)` | numeric |
| `StdError` | `StdError(Price, Length)` | numeric |
| `Median` | `Median(Price, Length)` | numeric |
| `TimeSeriesForecast` | `TimeSeriesForecast(Price, Length)` | numeric (projected regression value) |

| `SummationFC` | `SummationFC(Price, Length)` | numeric (fast calculation Summation) |

### Date/Time conversion

| Function | Signature | Returns |
|---|---|---|
| `ELDate` | `ELDate(Month, Day, Year)` | numeric (EL date format) |
| `MinutesToTime` | `MinutesToTime(Minutes)` | numeric (HHMM) |
| `TimeToMinutes` | `TimeToMinutes(Time)` | numeric (total minutes) |

### Multi-period OHLC reference

Access daily, weekly, monthly, or yearly OHLC from any intraday chart. `PeriodsAgo` = 0 is the current period.

| Function | Signature | Returns |
|---|---|---|
| `OpenD` | `OpenD(PeriodsAgo)` | numeric (daily open) |
| `HighD` | `HighD(PeriodsAgo)` | numeric (daily high) |
| `LowD` | `LowD(PeriodsAgo)` | numeric (daily low) |
| `CloseD` | `CloseD(PeriodsAgo)` | numeric (daily close) |
| `OpenW` | `OpenW(PeriodsAgo)` | numeric (weekly open) |
| `HighW` | `HighW(PeriodsAgo)` | numeric (weekly high) |
| `LowW` | `LowW(PeriodsAgo)` | numeric (weekly low) |
| `CloseW` | `CloseW(PeriodsAgo)` | numeric (weekly close) |
| `OpenM` | `OpenM(PeriodsAgo)` | numeric (monthly open) |
| `HighM` | `HighM(PeriodsAgo)` | numeric (monthly high) |
| `LowM` | `LowM(PeriodsAgo)` | numeric (monthly low) |
| `CloseM` | `CloseM(PeriodsAgo)` | numeric (monthly close) |
| `OpenY` | `OpenY(PeriodsAgo)` | numeric (yearly open) |
| `HighY` | `HighY(PeriodsAgo)` | numeric (yearly high) |
| `LowY` | `LowY(PeriodsAgo)` | numeric (yearly low) |
| `CloseY` | `CloseY(PeriodsAgo)` | numeric (yearly close) |

### Price calculation shortcuts

These take no arguments — they use the current bar's OHLC automatically.

| Function | Signature | Returns |
|---|---|---|
| `AvgPrice` | `AvgPrice` | numeric |
| `MedianPrice` | `MedianPrice` | numeric |
| `TypicalPrice` | `TypicalPrice` | numeric |
| `WeightedClose` | `WeightedClose` | numeric |

### Counting and occurrence

| Function | Signature | Returns |
|---|---|---|
| `CountIF` | `CountIF(Condition, Length)` | numeric |
| `MRO` | `MRO(Condition, Length, Occurrence)` | numeric (bars ago of Nth occurrence) |
| `LRO` | `LRO(Condition, Length, Occurrence)` | numeric (bars ago of Nth-oldest occurrence) |
| `SummationIf` | `SummationIf(Condition, Price, Length)` | numeric (conditional sum; only adds Price when Condition is true) |
| `IFFString` | `IFFString(Condition, TrueVal, FalseVal)` | string (inline ternary returning a string) |

### Volume-based

| Function | Signature | Returns |
|---|---|---|
| `AccumDist` | `AccumDist(Length)` | numeric |
| `OBV` | `OBV` | numeric (no args; On Balance Volume) |
| `VolumeROC` | `VolumeROC(Length)` | numeric (volume rate of change) |
| `VolumeOsc` | `VolumeOsc(ShortLen, LongLen)` | numeric (volume oscillator; short MA − long MA of volume) |
| `PriceVolTrend` | `PriceVolTrend` | numeric (no args; cumulative price-volume trend) |
| `LWAccDis` | `LWAccDis` | numeric (no args; Larry Williams Accumulation/Distribution) |

### Statistical

| Function | Signature | Returns |
|---|---|---|
| `IFF` | `IFF(Condition, TrueVal, FalseVal)` | numeric (inline ternary) |
| `Fisher` | `Fisher(Price)` | numeric (Fisher transformation; input should be normalized −1 to +1) |
| `FisherINV` | `FisherINV(Price)` | numeric (inverse Fisher transformation) |
| `AvgDeviation` | `AvgDeviation(Price, Length)` | numeric (mean absolute deviation) |
| `Variance` | `Variance(Price, Length)` | numeric (population variance) |
| `Kurtosis` | `Kurtosis(Price, Length)` | numeric (excess kurtosis) |
| `Skew` | `Skew(Price, Length)` | numeric (skewness) |
| `PercentRank` | `PercentRank(PriceValueToRank, PriceValue, Length)` | numeric (percent rank of value within lookback) |
| `Covariance` | `Covariance(Price1, Price2, Length)` | numeric |
| `Quartile` | `Quartile(Price, Length, Q)` | numeric (Q: 1=25th, 2=50th, 3=75th) |
| `TrimMean` | `TrimMean(Price, Length, TrimPct)` | numeric (trimmed mean) |
| `Mode` | `Mode(PriceValue, Length, Type)` | numeric (modal value) |
| `HarmonicMean` | `HarmonicMean(Price, Length)` | numeric |

### Moving averages extended

| Function | Signature | Returns |
|---|---|---|
| `SmoothedAverage` | `SmoothedAverage(Price, Length)` | numeric (Wilder smoothing) |

### Miscellaneous

| Function | Signature | Returns |
|---|---|---|
| `BarAnnualization` | `BarAnnualization` | numeric (no args; bars-per-year factor) |
| `LastBarOnChart` | `LastBarOnChart` | truefalse (no args; true on last bar) |

### Custom functions (commonly available)

These ship as `f_*` function files with many MultiCharts installations. They are **not** built-in keywords — you must have the corresponding function study (e.g. `f_StochRSI`) in your PowerLanguage Editor for the call to compile. If missing, create a new function study and paste the implementation from the source below.

| Function | Signature | Returns |
|---|---|---|
| `StochRSI` | `StochRSI(Price, RSILen, Length)` | numeric (0–1; Stochastic of RSI) |
| `supertrend` | `supertrend(ATRLen, Mult)` | numeric (trend line value; positive = uptrend support, negative = downtrend resistance) |
| `NVI` | `NVI(StartValue)` | numeric (Negative Volume Index; updates only when volume decreases) |
| `PVI` | `PVI(StartValue)` | numeric (Positive Volume Index; updates only when volume increases) |
| `Coppo` | `Coppo(N1, N2, N3)` | numeric (Coppock Curve; WMA of two ROC periods — uses `Close of Data2`) |
| `LWTI` | `LWTI(Price, Period, Length)` | numeric (Larry Williams Trading Index; 0–100 oscillator) |
| `TVI` | `TVI(Price, Vol, MinTickValue)` | numeric (Trade Volume Index; cumulative directional volume) |
| `SharpeRatio` | `SharpeRatio(Period, IntRate, CalculateRatio, InitCapital)` | numeric (portfolio-level; Period: 0=monthly, 1=daily; requires position history) |
| `WRSI` | `WRSI(Length, Price)` | numeric (0–100; Wilder RSI with session reset — original Wilder smoothing) |
| `NewMA` | `NewMA(Price, Length)` | numeric (Heikin-Ashi TEMA hybrid moving average) |

### Candlestick patterns

These return 1 if the pattern is detected, 0 otherwise. Multi-output variants populate ref variables.

| Function | Signature | Returns |
|---|---|---|
| `C_Doji` | `C_Doji(Percent)` | numeric (1 if doji; body within Percent of range) |
| `C_Hammer_HangingMan` | `C_Hammer_HangingMan(Length, Factor, oHammer, oHangingMan)` | numeric; populates 2 ref vars |
| `C_BullEng_BearEng` | `C_BullEng_BearEng(Length, oBullEng, oBearEng)` | numeric; populates 2 ref vars |
| `C_BullHar_BearHar` | `C_BullHar_BearHar(Length, oBullHar, oBearHar)` | numeric; populates 2 ref vars |
| `C_MornDoji_EveDoji` | `C_MornDoji_EveDoji(Length, Percent, oMornDoji, oEveDoji)` | numeric; populates 2 ref vars |
| `C_MornStar_EveStar` | `C_MornStar_EveStar(Length, oMornStar, oEveStar)` | numeric; populates 2 ref vars |
| `C_PierceLine_DkCloud` | `C_PierceLine_DkCloud(Length, oPierce, oDkCloud)` | numeric; populates 2 ref vars |
| `C_ShootingStar` | `C_ShootingStar(Length, Factor)` | numeric (1 if shooting star) |
| `C_3WhSolds_3BlkCrows` | `C_3WhSolds_3BlkCrows(Length, Factor, o3WhSolds, o3BlkCrows)` | numeric; populates 2 ref vars |

## Gotchas

### `MarketPosition(N)`, `EntryPrice(N)`, `BarsSinceEntry(N)` are position history, NOT bar offset

A natural-looking expression like `MarketPosition(1)` reads as "the market position one bar ago" — but it actually returns the position **one trade ago**. So `MarketPosition(1)` on bar 50, when the strategy has been flat for the last 30 bars, returns whatever the previous closed position was (long or short), not `0`.

**The same trap applies to `EntryPrice(N)` and `BarsSinceEntry(N)`.** `EntryPrice(1)` returns the entry price of the **previous closed position**, not the entry price one bar ago. `BarsSinceEntry(1)` returns the bars-since-entry of the previous position, not the current position minus one.

To detect a position transition between bars (e.g. "did we just enter long?"), store the previous bar's position at the END of each bar:

```pascal
Variables:
    _prevMP(0);

If MarketPosition <> _prevMP Then Begin
    // transition just happened this bar
    ...
End;

_prevMP = MarketPosition;     // end of bar
```

This is the canonical pattern. Don't rely on `MarketPosition(1)` for transition detection.

### Bars are labeled by their CLOSE time, not open time

A 60-minute bar covering 15:00–16:00 has `Time = 1600`, not `Time = 1500`. A filter like `If Time = 1500 Then …` will never match that bar.

To check whether the current bar is the first bar of the night session at 15:00, write:

```pascal
If Time = 1600 Then ...     // for 60-min bars
If Time = 1505 Then ...     // for 5-min bars (first close after 15:00)
If Time = 1501 Then ...     // for 1-min bars
```

Add one bar's worth of minutes to the session-start clock time.

### Variable names must not match built-in function names or reserved letters

PowerLanguage is **case-insensitive**. If you declare `Variables: dmiPlus(0);` and then call `dmiPlus = DMIPlus(14);`, the compiler sees the variable and function as the same identifier — the variable shadows the function and the call fails. This applies to every built-in function: `Average`, `RSI`, `CCI`, `ADX`, `MACD`, `Stochastic`, `BollingerBand`, `Highest`, `Lowest`, etc. **Especially dangerous** are function names that look like natural variable names: `Range`, `Momentum`, `Median`, `Correlation`, `Sign`, `Last`, `Slippage`, `Margin`.

The **single-letter data-series aliases** are also reserved and cannot be used as variable or loop-counter names: `C`(Close), `D`(Date), `H`(High), `I`(OpenInterest), `L`(Low), `O`(Open), `T`(Time), `V`(Volume). Because PL is case-insensitive, `i`, `c`, `l`, `v`, etc. are all off-limits. This is especially easy to hit with `i` in `For` loops.

Use a different name — abbreviate, add a suffix, or prefix:

```pascal
// WRONG — i is reserved (alias for OpenInterest)
For i = 1 To 10 Begin ... End;

// RIGHT — use ii, idx, cnt, n, etc.
For ii = 1 To 10 Begin ... End;

// WRONG — shadows the built-in DMIPlus function
Variables: dmiPlus(0);
dmiPlus = DMIPlus(14);        // compile error

// RIGHT
Variables: dpVal(0);
dpVal = DMIPlus(14);          // works
```

### Inputs are read-only

You cannot assign to an Input inside a script. If you need a mutable copy, declare a Variable and copy from the Input once.

### Variable types are fixed at first assignment

`Variables: x(0);` makes `x` numeric for the life of the script. You can't later assign a string to it. Same for `True`/`False` initial values (bool) and `""` (string).

### Many keywords can't appear as values on the right-hand side of `=`

A common new-user mistake is to write `Value1 = SomeKeyword;` for a keyword that looks identifier-like in the documentation but is actually a syntactic construct. PowerLanguage will throw "syntax error, unexpected '…'" or "Wrong syntax of '…'" when you do this. Empirically, the following classes never work as RHS values:

**Whole keyword classes:**

| Class | Example keywords | Why |
|---|---|---|
| Type / declaration words | `Numeric`, `String`, `TrueFalse`, `Variable`, `Var`, `NumericSeries`, `IntraBarPersist` | Used inside `Inputs:` / `Variables:` / `Arrays:` blocks |
| Control flow / operators | `If`, `Then`, `Else`, `For`, `While`, `Begin`, `End`, `To`, `DownTo`, `Switch`, `Case`, `and`, `or`, `not` | Reserved syntax |
| Script-level attributes | `IntraBarOrderGeneration`, `LegacyColorValue`, `RecoverDrawings`, `AllowSendOrdersOn…`, `PortfolioEntriesPriority` | Used in `[Attr = value];` form at script start |
| Output statements | `Print`, `FileAppend`, `FileClose`, `FileDelete`, `ClearDebug`, `ClearPrintLog`, `File`, `MessageLog`, `PlaySound` | Statement-shaped, no return value |
| DLL-calling directives | `DefineDllFunc`, `external`, `method`, `OnCreate`, `OnDestroy`, `ThreadSafe`, plus C type names (`int`, `lpstr`, `bool`, …) | Statement / declaration syntax |
| Expert Commentary | `#BeginCmtry`, `#EndCmtry`, `CheckCommentary`, `AtCommentaryBar` | Paired-block directives |
| Preprocessor (`#`-prefixed) | `#BeginCmtry`, `#EndCmtry`, `#Return`, `#Events` | Reserved positions; `#BeginCmtry` in particular opens a commentary block that runs to `#EndCmtry` |
| Connector words | `Bar`, `Bars`, `Day`, `Days`, `Point`, `Points`, `Tick`, `Ticks`, `Ago`, `Next`, `This`, `Today`, `Yesterday`, `Market`, `Contract`, `Contracts` | Used in compound phrases ("5 bars ago", "next bar at market") |

**Other rules of thumb:**

- A keyword name that contains a space in the official docs (e.g. `DateTime bar update`, `Cancel Alert`) cannot be used as a single identifier — PowerLanguage parses only the first word and chokes on the rest.
- **Single-letter data-series aliases** (`C`=Close, `D`=Date, `H`=High, `I`=OpenInt, `L`=Low, `O`=Open, `T`=Time, `V`=Volume) are reserved — using them with parentheses like `C(Close)` causes *"A keyword/variable is used as a function"*. Use square brackets for barsback: `C[1]`.
- A handful of names in otherwise-value-rich categories are reserved syntactic tokens: `Data` (used as `Close of Data2`), `Call` / `Put` / `Strike` (option-context syntax), `OptionType`, `DeltaType`, `RevSize`, `BoxSize`.
- **Procedure keywords** like `ScrollToBar`, `PlaceMarketOrder`, `ChangeMarketPosition`, and all PMM action keywords (`pmms_strategy_resume`, `pmms_strategy_pause`, `pmms_strategy_close_position`, `pmms_strategy_deny_*`, `pmms_strategy_allow_*`, `pmms_strategies_*_all`) perform an action and do NOT return a value — assigning them to `Value1` causes *"Function must have a return value"*. Call them as standalone statements: `ScrollToBar(1, 0);`.
- **Signal/portfolio-only keywords** like `Portfolio_CurrencyCode`, `StrategyCurrencyCode`, `InitialCapital` cause *"X is not applicable to this type of study"* when used in an Indicator. They only work in Signal studies.
- **Drawing-object accessors** (any `Rectangle*`, `TL_*`, `Arw_*`, `Text_*`, or `MC_TL_*`/`MC_Arw_*`/etc. function ending in `Get`/`Set`/`Delete`/`New`/…) take at least one drawing-object ID argument — never use them as bare values.
- **Setter keywords** (`Set*`, `Portfolio_Set*`, `pmm_set_*`, or any name containing `_set_`) are statement-shaped — they always require at least one value argument and don't return a value.
- **Lowercase-prefix functions** (e.g. `getTPOinfo`, `getplotstyle`) usually take parameters; the unusual lowercase naming is the signal.
- **String-returning keywords** like `Description`, `Symbol`, `GetCurrency`, `BarType_uid`, anything ending in `Name` / `Description` / `Listed` / `ToStr` — can be assigned only to a string variable, not the numeric `Value1`.
- **Boolean-returning keywords** like `Is64BitProcess`, `MouseClickShiftPressed`, `AlertEnabled`, `PosTradeIsOpen`, `PosTradeIsLong`, `pmms_strategy_is_paused` — use them inside an `If` condition (`If Is64BitProcess Then ...`); direct assignment to `Condition1` sometimes fails because PowerLanguage returns numeric 0/1 instead of `TrueFalse` for some "logical" functions. **Exception:** `MarketPosition_at_Broker_for_The_Strategy` looks boolean but returns numeric 1/0/-1 (market position) — use `Value1 = X;`, not `If X Then`.

### Quick error → fix lookup

If MultiCharts gives you one of these errors when using a keyword:

| Compile error | Likely cause | Fix |
|---|---|---|
| `syntax error, unexpected 'X'` | `X` is a reserved syntactic token (declaration / control flow / connector) | Don't use it as a value; it belongs in a different syntactic position |
| `Wrong syntax of 'X'` | `X` is a directive (e.g. `DefineDllFunc`) | Use the documented statement form, not as RHS |
| `Commentary end is expected before end of file` | You used `#BeginCmtry` without `#EndCmtry` | Pair them, or skip the construct |
| `Invalid number of parameters. N parameter(s) expected` | Function needs N args you didn't pass | Look up the signature in `powerlanguage-keywords-reference` and pass the right number |
| `Types are not compatible` | RHS returns a type incompatible with the LHS variable | Assign string→string var, bool→bool var, numeric→`Value1` |
| `A keyword/variable is used as a function` | Using a data-series alias with parentheses, e.g. `C(Close)` | Use square brackets for barsback: `C[1]`, or no brackets: `Value1 = C;` |
| `Function must have a return value` | Assigning a procedure keyword (e.g. `ScrollToBar`) to a variable | Call as a standalone statement: `ScrollToBar(1, 0);` |
| `X is not applicable to this type of study` | Using a signal-only keyword in an Indicator (e.g. `InitialCapital`) | Move to a Signal study, or remove the keyword |

When in doubt, look up the keyword in the `powerlanguage-keywords-reference` skill — the signature line shows whether it's used as `KeywordName(args)` (callable function) or in a larger construct (then it can't be the whole RHS).

## Pre-generation checklist

**Before writing any PowerLanguage code, verify every item below.** Do not skip steps — each one maps to a real compile error encountered during testing.

1. **Script type matches intent.** Indicator (plots, no orders), Signal (orders, no plots), or Function (returns a value)?
2. **Declarations exist and come first.** `Inputs:` → `Variables:` → `Arrays:` → code. Every variable used anywhere — including loop counters — must be declared.
3. **No variable-name collisions.** Check every name in `Variables:` against:
   - Built-in functions: `Average`, `RSI`, `CCI`, `ADX`, `MACD`, `DMIPlus`, `DMIMinus`, `Stochastic`, `BollingerBand`, `Highest`, `Lowest`, `Range`, `Momentum`, `Median`, `Correlation`, `Volatility`, `MoneyFlow`, `Summation`, `Cum`, `Sign`, `Last`, `Total`, etc.
   - Single-letter aliases: `C`, `D`, `H`, `I`, `L`, `O`, `T`, `V` (and their lowercase forms — `i` as a loop counter is the #1 trap).
   - Use suffixed names: `rsiVal`, `atrVal`, `dpVal`, `avgVal`, `runTotal`, `idx`, `nn`, `cnt`.
4. **Function signatures are correct.** Check every function call:
   - Length-only functions (`CCI`, `ADX`, `DMIPlus`, `DMIMinus`, `AvgTrueRange`, `PercentR`, `MoneyFlow`, `Volatility`, `RSquared`, `AccumDist`) take **no Price parameter**.
   - `Stochastic` takes **11 params** (4 are output ref vars that must be declared).
   - `DirMovement` takes **10 params** (6 are output ref vars).
   - `AdaptiveMovAvg` takes **4 params** (Price, EffRatioLen, FastAvgLen, SlowAvgLen).
   - `Parabolic` takes **1 param** (AfStep only).
   - If unsure, look it up in the "Common built-in functions" tables above.
5. **Order syntax is complete.** Every order has: a unique name string, quantity + unit, and the `at` keyword — `Next Bar at Market`, `Next Bar at <price> Stop`, `Next Bar at <price> Limit`, or `This Bar on Close`.
6. **Order names are unique.** No two orders in the same Signal share a name string.
7. **Semicolon rule.** `End` before `Else` → no semicolon. `End` at statement boundary → semicolon.
8. **Study-type restrictions.** No `Plot` in Signals. No `Buy`/`Sell` in Indicators. No `MarketPosition`/`EntryPrice` in Indicators.

## Post-generation self-review

**After writing PowerLanguage code, re-read it against this list before presenting it.** Fix any issues silently — do not present code that fails these checks.

1. **Walk the `Variables:` block.** Read each name aloud — does it match any built-in function or single-letter alias? If yes, rename it.
2. **Walk every function call.** Count the arguments. Compare to the signature table. Pay special attention to Length-only functions (no Price) and multi-output functions (ref vars declared?).
3. **Walk every order line.** Is the `at` keyword present? Is the name string unique within this Signal?
4. **Walk every `End`.** Is the next token `Else`? If yes → no semicolon. Otherwise → semicolon.
5. **Walk every `For`/`While`.** Is the loop counter declared in `Variables:`?
6. **Check type consistency.** Numeric functions → `Value1` or numeric variable. String functions (anything ending in `ToStr`, `Name`, `Description`) → string variable. Don't assign strings to `Value1`.
