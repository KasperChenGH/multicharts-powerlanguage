---
name: powerlanguage-cpp-conversion
description: >-
  Use when converting, translating, porting, or migrating code between
  MultiCharts PowerLanguage and C++, in either direction. Contains a
  lightweight Strategy base class scaffold, concept mapping tables, semantic
  difference documentation, and pre/post-conversion checklists. References
  powerlanguage-syntax for PowerLanguage-specific details. Recommends
  TA-Lib for technical indicators.
---

# PowerLanguage ↔ C++ Conversion

## How to use

This skill covers the structural and semantic differences between MultiCharts PowerLanguage and C++ for algorithmic trading. It does not duplicate the syntax rules of PowerLanguage — for declarations, bar references, control flow, and built-in function signatures use the `powerlanguage-syntax` skill. When performing a conversion in either direction, work through Part 0 (structural template) to set up the boilerplate, then Part 1 (concept mapping) for line-by-line translation, then review Part 2 (semantic differences and gotchas), and finally run through the relevant checklist in Part 3 before calling the output complete.

---

## Part 0: Structural Template

PowerLanguage runs the entire script top-to-bottom on each bar close automatically. C++ has no implicit bar loop, no built-in OHLCV type, and no order submission mechanism. Every PL-to-C++ conversion targets the framework-agnostic scaffold below.

### Bar struct

```cpp
#include <cstdint>
#include <string>
#include <vector>

struct Bar {
    double open;
    double high;
    double low;
    double close;
    double volume;
    int64_t time;       // Unix epoch seconds
    size_t bar_number;  // 1-based to match PL convention
};
```

### Order types

```cpp
enum class Side { Long, Short };

enum class OrderType { Market, Limit, Stop };

struct Order {
    std::string label;
    Side side;
    OrderType type;
    double price;  // 0.0 for Market
    double qty;
};
```

### Strategy base class

```cpp
class Strategy {
public:
    virtual ~Strategy() = default;
    virtual void on_bar(const std::vector<Bar>& bars,
                        std::vector<Order>& orders) = 0;
};
```

### Strategy subclass skeleton

```cpp
#include "ta_libc.h"  // TA-Lib

class MyStrategy : public Strategy {
public:
    // Inputs (PL: Inputs: Length(20))
    MyStrategy(int length, double threshold)
        : length_(length), threshold_(threshold) {}

    void on_bar(const std::vector<Bar>& bars,
                std::vector<Order>& orders) override;

private:
    // Inputs (immutable after construction)
    int length_;
    double threshold_;

    // Variables (PL: Variables: my_var(0))
    double my_var_ = 0.0;

    // Position state (PL: MarketPosition, EntryPrice, etc.)
    int position_ = 0;           // -1, 0, +1
    double entry_price_ = 0.0;
    int bars_since_entry_ = 0;
    double current_contracts_ = 0.0;
};
```

### TA-Lib call pattern

```cpp
// Extract close prices into a contiguous array (TA-Lib needs parallel arrays)
std::vector<double> closes(bars.size());
for (size_t i = 0; i < bars.size(); ++i) closes[i] = bars[i].close;

// Batch API: compute SMA over the full close array
int outBeg = 0, outNBElement = 0;
std::vector<double> sma_out(bars.size());
TA_SMA(0, static_cast<int>(closes.size()) - 1,
       closes.data(), length_,
       &outBeg, &outNBElement, sma_out.data());

// Current bar's SMA is the LAST valid output element
double current_sma = sma_out[outNBElement - 1];
```

The output array is NOT aligned with the input array. The first valid output is at `sma_out[0]`, which corresponds to `closes[outBeg]`. The current value is always `sma_out[outNBElement - 1]`.

### Main loop

```cpp
int main() {
    std::vector<Bar> bars = load_bars("data.csv"); // user-provided
    MyStrategy strategy(20, 0.5);
    std::vector<Order> orders;

    for (size_t i = 0; i < bars.size(); ++i) {
        orders.clear();
        std::vector<Bar> history(bars.begin(), bars.begin() + i + 1);
        strategy.on_bar(history, orders);
        // execute orders against simulated book...
    }
    return 0;
}
```

The `history` vector up to and including bar `i` mirrors PL's implicit bar-by-bar execution. `bars.back()` inside `on_bar()` is the current bar.

### Incremental alternative (TA-Lib RT)

TA-Lib RT is a community fork that adds streaming APIs: `TA_SMA_StateInit()`, `TA_SMA_State()`, `TA_SMA_StateFree()`. These maintain internal state across calls, avoiding full-array recomputation on each bar. Use TA-Lib RT when performance matters for large bar counts.

---

## Part 1: Concept Mapping

### Table 1 — Declarations

| PowerLanguage | C++ | Notes |
|---|---|---|
| `Inputs: Length(20)` | `int length_` member + constructor param | Inputs become const or private members set at construction |
| `Variables: myVar(0)` | `double my_var_ = 0.0` member | Mutable members; initialize in-class or in the constructor initializer list |
| `Value1` .. `Value99` | named member (e.g., `double rsi_val_ = 0.0`) | Must rename to meaningful identifiers |
| `Condition1` .. `Condition99` | named member (e.g., `bool is_oversold_ = false`) | Same: rename to typed `bool` members |
| `Arrays: buf[10](0)` | `double buf_[11] = {};` or `std::vector<double> buf_(11, 0.0)` | PL `[10]` means last index is 10 (11 elements) |
| `IntraBarPersist myVar(0)` | `double my_var_ = 0.0` member (same as Variables) | C++ has no bar-close vs intra-bar distinction; all members persist |

---

### Table 2 — Data Access

| PowerLanguage | C++ | Notes |
|---|---|---|
| `Open`, `High`, `Low`, `Close`, `Volume` | `bars.back().open`, `.high`, `.low`, `.close`, `.volume` | `bars.back()` for current bar |
| `Close[1]` | `bars[bars.size() - 2].close` | Lookback N: `bars[bars.size() - 1 - n].close`. Check `bars.size() > n` to avoid UB. |
| `Close of Data2` | separate `const std::vector<Bar>& bars2` parameter | PL Data2 is a second chart feed; pass a second vector reference |
| `Date` | `time_t t = bar.time; auto* tm = std::gmtime(&t);` → `tm->tm_year`, `tm->tm_mon`, `tm->tm_mday` | PL `Date` is YYYMMDD integer (YYY = years since 1900); C++ uses `<ctime>` or `<chrono>`. Cast `int64_t` to `time_t` for portability. |
| `Time` | `time_t t = bar.time; auto* tm = std::gmtime(&t);` → `tm->tm_hour`, `tm->tm_min` | PL `Time` is HHMM integer |
| `BarNumber` / `CurrentBar` | `bar.bar_number` or `i + 1` (loop index) | PL is 1-based |

---

### Table 3 — Technical Indicators

| PowerLanguage | C++ (TA-Lib) | Notes |
|---|---|---|
| `Average(Close, Length)` | `TA_SMA(0, endIdx, inClose, length, &outBeg, &outNB, outSma)` | Current value: `outSma[outNB - 1]` |
| `XAverage(Close, Length)` | `TA_EMA(0, endIdx, inClose, length, &outBeg, &outNB, outEma)` | Same batch pattern |
| `RSI(Close, Length)` | `TA_RSI(0, endIdx, inClose, length, &outBeg, &outNB, outRsi)` | Returns 0–100 range |
| `Stochastic(...)` | `TA_STOCH(0, endIdx, inHigh, inLow, inClose, fastK, slowK, slowKMAType, slowD, slowDMAType, &outBeg, &outNB, outSlowK, outSlowD)` | Full %K/%D smoothing control — maps better to PL's 11-param version than Pine's simple `ta.stoch` |
| `ADX(Length)` | `TA_ADX(0, endIdx, inHigh, inLow, inClose, length, &outBeg, &outNB, outAdx)` | Direct equivalent |
| `CCI(Length)` | `TA_CCI(0, endIdx, inHigh, inLow, inClose, length, &outBeg, &outNB, outCci)` | PL `CCI` takes only length (uses HLC internally); TA-Lib requires explicit HLC arrays |
| `AvgTrueRange(Length)` | `TA_ATR(0, endIdx, inHigh, inLow, inClose, length, &outBeg, &outNB, outAtr)` | Requires HLC arrays |
| `BollingerBand(Close, Length, 2)` | `TA_BBANDS(0, endIdx, inClose, length, 2.0, 2.0, TA_MAType_SMA, &outBeg, &outNB, outUpper, outMiddle, outLower)` | Returns three arrays: upper, middle, lower |
| `Close Crosses Over MA` | `prev_close <= prev_ma && close > ma` | No built-in crossover in TA-Lib; implement as two-bar comparison |
| `Close Crosses Under MA` | `prev_close >= prev_ma && close < ma` | Same pattern |
| `Highest(Close, Length)` | `TA_MAX(0, endIdx, inClose, length, &outBeg, &outNB, outMax)` | Direct equivalent |
| `Lowest(Close, Length)` | `TA_MIN(0, endIdx, inClose, length, &outBeg, &outNB, outMin)` | Direct equivalent |
| `Momentum(Close, Length)` | `TA_MOM(0, endIdx, inClose, length, &outBeg, &outNB, outMom)` | Direct equivalent |
| `TSI(Close, LongLen, ShortLen)` | Manual: compute momentum, apply `TA_EMA` twice (long then short) to both momentum and abs(momentum), then `100.0 * smoothed_mtm / smoothed_abs_mtm` | TA-Lib has no `TA_TSI`; chain two EMA passes |
| `AverageFC(Close, Length)` | `TA_SMA(0, endIdx, inClose, length, &outBeg, &outNB, outSma)` | Same as `Average`; FC = "fast calculation" (PL optimization, no C++ equivalent) |
| `WAverage(Close, Length)` | `TA_WMA(0, endIdx, inClose, length, &outBeg, &outNB, outWma)` | Weighted moving average; direct equivalent |
| `AdaptiveMovAvg(Close, Length)` | `TA_KAMA(0, endIdx, inClose, length, &outBeg, &outNB, outKama)` | Kaufman Adaptive MA; direct equivalent |
| `MidPoint(Close, Length)` | `TA_MIDPOINT(0, endIdx, inClose, length, &outBeg, &outNB, outMid)` | (Highest + Lowest) / 2 over period |
| `MACD(Close, FastLen, SlowLen)` | `TA_MACD(0, endIdx, inClose, fastLen, slowLen, signalLen, &outBeg, &outNB, outMACD, outSignal, outHist)` | Returns three arrays: MACD line, signal, histogram |
| `KeltnerChannel(Close, Length, Mult)` | Manual: `TA_EMA` for midline ± `Mult * TA_ATR` for bands | No single TA-Lib function; combine EMA + ATR |
| `DMIPlus(Length)` | `TA_PLUS_DI(0, endIdx, inHigh, inLow, inClose, length, &outBeg, &outNB, outPlusDI)` | +DI component of DMI |
| `DMIMinus(Length)` | `TA_MINUS_DI(0, endIdx, inHigh, inLow, inClose, length, &outBeg, &outNB, outMinusDI)` | −DI component of DMI |
| `RateOfChange(Close, Length)` | `TA_ROC(0, endIdx, inClose, length, &outBeg, &outNB, outRoc)` | Percentage rate of change |
| `PercentR(Length)` | `TA_WILLR(0, endIdx, inHigh, inLow, inClose, length, &outBeg, &outNB, outWillR)` | Williams %R; direct equivalent |
| `MoneyFlow(Length)` | `TA_MFI(0, endIdx, inHigh, inLow, inClose, inVolume, length, &outBeg, &outNB, outMfi)` | Money Flow Index; requires HLCV arrays |
| `Parabolic(AFStep, AFMax)` | `TA_SAR(0, endIdx, inHigh, inLow, AFStep, AFMax, &outBeg, &outNB, outSar)` | Parabolic SAR; requires HL arrays |
| `Volatility(Length)` | `TA_STDDEV(0, endIdx, inClose, length, 1.0, &outBeg, &outNB, outStdDev)` | PL Volatility returns annualized StdDev of log returns; adjust scaling |
| `UltimateOscillator(Len1, Len2, Len3)` | `TA_ULTOSC(0, endIdx, inHigh, inLow, inClose, len1, len2, len3, &outBeg, &outNB, outUltOsc)` | Three-period weighted oscillator |
| `ChaikinOsc(FastLen, SlowLen)` | `TA_ADOSC(0, endIdx, inHigh, inLow, inClose, inVolume, fastLen, slowLen, &outBeg, &outNB, outAdosc)` | Chaikin A/D Oscillator; requires HLCV |
| `PriceOscillator(FastLen, SlowLen)` | `TA_APO(0, endIdx, inClose, fastLen, slowLen, TA_MAType_SMA, &outBeg, &outNB, outApo)` | Absolute Price Oscillator |
| `DirMovement(Length, oPlusDI, oMinusDI, oADX)` | Call `TA_PLUS_DI`, `TA_MINUS_DI`, and `TA_ADX` separately | Multi-output; split into three TA-Lib calls |
| `Extremes(Length, oHighest, oLowest)` | Manual: track running max/min over lookback window | No single TA-Lib function; use `TA_MAX` + `TA_MIN` or manual loop |
| `TrueRange` | `TA_TRANGE(0, endIdx, inHigh, inLow, inClose, &outBeg, &outNB, outTRange)` | Single-bar true range; direct equivalent |
| `StandardDev(Close, Length)` | `TA_STDDEV(0, endIdx, inClose, length, 1.0, &outBeg, &outNB, outStdDev)` | `nbDev` param = 1.0 for one standard deviation |
| `TrueHigh` | `std::max(bars[i].high, bars[i-1].close)` | Manual one-liner; guard `i > 0` |
| `TrueLow` | `std::min(bars[i].low, bars[i-1].close)` | Manual one-liner; guard `i > 0` |
| `Range` | `bars[i].high - bars[i].low` | Simple arithmetic; no TA-Lib needed |
| `HighestBar(Close, Length)` | `TA_MAXINDEX(0, endIdx, inClose, length, &outBeg, &outNB, outIdx)` | Returns index of highest value; convert to bars-ago offset |
| `LowestBar(Close, Length)` | `TA_MININDEX(0, endIdx, inClose, length, &outBeg, &outNB, outIdx)` | Returns index of lowest value; convert to bars-ago offset |
| `NthHighest(N, Close, Length)` | Manual: copy window into temp array, `std::nth_element`, pick Nth | No TA-Lib equivalent |
| `NthLowest(N, Close, Length)` | Manual: copy window, `std::nth_element`, pick Nth from low end | No TA-Lib equivalent |
| `NthHighestBar(N, Close, Length)` | Manual: find Nth highest value, then scan for its bar index | No TA-Lib equivalent |
| `NthLowestBar(N, Close, Length)` | Manual: find Nth lowest value, then scan for its bar index | No TA-Lib equivalent |
| `SwingHigh(1, Close, LeftStr, RightStr)` | Manual: check `Close[RightStr+i] < Close[0]` for right side and `Close[LeftStr+i] < Close[0]` for left side | Pivot-point detection; no TA-Lib equivalent |
| `SwingLow(1, Close, LeftStr, RightStr)` | Manual: check `Close[i] > Close[0]` on both sides of candidate bar | Mirror of SwingHigh with `>` comparisons |
| `SwingHighBar(1, Close, LeftStr, RightStr)` | Manual: find SwingHigh, return bars-ago offset | Same pivot logic, return offset instead of price |
| `SwingLowBar(1, Close, LeftStr, RightStr)` | Manual: find SwingLow, return bars-ago offset | Same pivot logic, return offset instead of price |
| `Summation(Close, Length)` | `TA_SUM(0, endIdx, inClose, length, &outBeg, &outNB, outSum)` | Rolling sum; direct equivalent |
| `Cum(Close)` | Manual: `cumulative_ += bars.back().close` (running total as member) | Cumulative sum from bar 1; no period param |
| `LinearRegValue(Close, Length, Offset)` | `TA_LINEARREG(0, endIdx, inClose, length, &outBeg, &outNB, outLinReg)` | Offset projection requires manual adjustment |
| `LinearRegAngle(Close, Length)` | `TA_LINEARREG_ANGLE(0, endIdx, inClose, length, &outBeg, &outNB, outAngle)` | Angle in degrees; direct equivalent |
| `LinearRegSlope(Close, Length)` | `TA_LINEARREG_SLOPE(0, endIdx, inClose, length, &outBeg, &outNB, outSlope)` | Slope coefficient; direct equivalent |
| `Correlation(Close, Close2, Length)` | `TA_CORREL(0, endIdx, inClose, inClose2, length, &outBeg, &outNB, outCorr)` | Pearson correlation; direct equivalent |
| `RSquared(Close, Length)` | Manual: `pow(TA_CORREL result, 2)` | Coefficient of determination; square the correlation |
| `StdError(Close, Length)` | Manual: `TA_STDDEV result / sqrt(length)` | Standard error of the mean |
| `Median(Close, Length)` | Manual: copy window, `std::nth_element(begin, mid, end)`, read middle | No TA-Lib rolling median |
| `ELDate` | Manual: convert `bar.time` to YYYMMDD format (YYY = year − 1900) | PL EasyLanguage date format |
| `MinutesToTime(mins)` | Manual: `int hhmm = (mins / 60) * 100 + (mins % 60)` | Convert total minutes to HHMM integer |
| `TimeToMinutes(hhmm)` | Manual: `int mins = (hhmm / 100) * 60 + (hhmm % 100)` | Convert HHMM integer to total minutes |
| `AvgPrice` | `TA_AVGPRICE(0, endIdx, inOpen, inHigh, inLow, inClose, &outBeg, &outNB, outAvg)` | (O+H+L+C)/4; direct equivalent |
| `MedianPrice` | `TA_MEDPRICE(0, endIdx, inHigh, inLow, &outBeg, &outNB, outMedPr)` | (H+L)/2; direct equivalent |
| `TypicalPrice` | `TA_TYPPRICE(0, endIdx, inHigh, inLow, inClose, &outBeg, &outNB, outTyp)` | (H+L+C)/3; direct equivalent |
| `WeightedClose` | `TA_WCLPRICE(0, endIdx, inHigh, inLow, inClose, &outBeg, &outNB, outWcl)` | (H+L+2C)/4; direct equivalent |
| `CountIF(Cond, Length)` | Manual: `int count = 0; for (int j = 0; j < length; ++j) if (cond[size-1-j]) ++count;` | Count true occurrences in lookback window |
| `MRO(Cond, Length, Instance)` | Manual: scan backwards through lookback for Nth true occurrence, return bars-ago | Most Recent Occurrence; manual loop |
| `AccumDist` | `TA_AD(0, endIdx, inHigh, inLow, inClose, inVolume, &outBeg, &outNB, outAD)` | Cumulative A/D line; requires HLCV arrays |
| `IFF(Cond, TrueVal, FalseVal)` | `cond ? trueVal : falseVal` | C++ ternary operator; direct equivalent |
| `TriAverage(Close, Length)` | `TA_TRIMA(0, endIdx, inClose, length, &outBeg, &outNB, outTrima)` | Triangular MA; direct equivalent |
| `FastK(StochLength)` | `TA_STOCHF(0, endIdx, inHigh, inLow, inClose, StochLength, 1, TA_MAType_SMA, &outBeg, &outNB, outFastK, outFastD)` | Use `TA_STOCHF` for fast stochastic; `outFastK` is raw %K |
| `FastD(StochLength)` | `TA_STOCHF(0, endIdx, inHigh, inLow, inClose, StochLength, 3, TA_MAType_SMA, &outBeg, &outNB, outFastK, outFastD)` | `outFastD` is smoothed Fast %D |
| `SlowK(StochLength)` | `TA_STOCH(0, endIdx, inHigh, inLow, inClose, StochLength, 3, TA_MAType_SMA, 3, TA_MAType_SMA, &outBeg, &outNB, outSlowK, outSlowD)` | `outSlowK` from full stochastic |
| `SlowD(StochLength)` | `TA_STOCH(0, endIdx, inHigh, inLow, inClose, StochLength, 3, TA_MAType_SMA, 3, TA_MAType_SMA, &outBeg, &outNB, outSlowK, outSlowD)` | `outSlowD` from full stochastic |
| `FastKCustom(H, L, C, StochLen)` | `TA_STOCHF(0, endIdx, H, L, C, StochLen, 1, TA_MAType_SMA, &outBeg, &outNB, outFastK, outFastD)` | Custom price arrays |
| `FastDCustom(H, L, C, StochLen)` | `TA_STOCHF(0, endIdx, H, L, C, StochLen, 3, TA_MAType_SMA, &outBeg, &outNB, outFastK, outFastD)` | Custom prices; use `outFastD` |
| `SlowKCustom(H, L, C, StochLen)` | `TA_STOCH(0, endIdx, H, L, C, StochLen, 3, TA_MAType_SMA, 3, TA_MAType_SMA, &outBeg, &outNB, outSlowK, outSlowD)` | Custom prices |
| `SlowDCustom(H, L, C, StochLen, S1, S2)` | `TA_STOCH(0, endIdx, H, L, C, StochLen, S1, TA_MAType_SMA, S2, TA_MAType_SMA, &outBeg, &outNB, outSlowK, outSlowD)` | Custom smoothing periods |
| `StochasticExp(H, L, C, StochLen, S1, S2, ...)` | `TA_STOCH(0, endIdx, H, L, C, StochLen, S1, TA_MAType_EMA, S2, TA_MAType_EMA, &outBeg, &outNB, outSlowK, outSlowD)` | Use `TA_MAType_EMA` for exponential smoothing |
| `ADXR(Length)` | `TA_ADXR(0, endIdx, inHigh, inLow, inClose, length, &outBeg, &outNB, outAdxr)` | Direct equivalent; ADX Rating |
| `ADXCustom(H, L, C, Length)` | `TA_ADX(0, endIdx, H, L, C, length, &outBeg, &outNB, outAdx)` | Custom price arrays |
| `DMI(Length)` | `TA_ADX(0, endIdx, inHigh, inLow, inClose, length, &outBeg, &outNB, outAdx)` | Wrapper; same as ADX |
| `DMIPlusCustom(H, L, C, Length)` | `TA_PLUS_DI(0, endIdx, H, L, C, length, &outBeg, &outNB, outPlusDI)` | +DI with custom prices |
| `DMIMinusCustom(H, L, C, Length)` | `TA_MINUS_DI(0, endIdx, H, L, C, length, &outBeg, &outNB, outMinusDI)` | −DI with custom prices |
| `ParabolicCustom(AfStep, AfLimit)` | `TA_SAR(0, endIdx, inHigh, inLow, AfStep, AfLimit, &outBeg, &outNB, outSar)` | Same as `Parabolic` with explicit limit |
| `TRIX(Close, Length)` | `TA_TRIX(0, endIdx, inClose, length, &outBeg, &outNB, outTrix)` | Direct equivalent |
| `MassIndex(SmoothLen, SumLen)` | Manual: `TA_EMA` of range, ratio, then sum | No single TA-Lib function; chain EMA calls |
| `EaseOfMovement` | Manual: distance moved / box ratio | No TA-Lib function; compute from OHLCV |
| `SwingIndex` | Manual: Wilder swing index formula | No TA-Lib function; ~20 lines of C++ |
| `AccumSwingIndex` | Manual: running sum of SwingIndex | No TA-Lib function |
| `Detrend(Close, Length)` | Manual: close minus offset SMA | No direct TA-Lib; use `TA_SMA` with offset |
| `PercentChange(Close, Length)` | `TA_ROC(0, endIdx, inClose, length, &outBeg, &outNB, outRoc)` | Same as Rate of Change |
| `UlcerIndex(Close, Length)` | Manual: RMS of drawdown percentage | No TA-Lib function; track max, compute pct drawdown |
| `ParabolicSAR(AfStep, AfLimit, ...)` | `TA_SAR(0, endIdx, inHigh, inLow, AfStep, AfLimit, &outBeg, &outNB, outSar)` + manual position tracking | Track sign changes in SAR vs price for position/transition |
| `LinearReg(Close, Length, TgtBar, ...)` | `TA_LINEARREG(...)` + `TA_LINEARREG_SLOPE(...)` + `TA_LINEARREG_ANGLE(...)` + `TA_LINEARREG_INTERCEPT(...)` | Combine four TA-Lib calls for multi-output |
| `TrueRangeCustom(H, L, C)` | `TA_TRANGE(0, endIdx, H, L, C, &outBeg, &outNB, outTRange)` | Custom price arrays |
| `VolatilityStdDev(NumDays)` | Manual: compute log returns, then `TA_STDDEV` × `sqrt(252)` | Annualized historical volatility |
| `StandardDevAnnual(Close, Length, DataType)` | `TA_STDDEV(0, endIdx, inClose, length, 1.0, &outBeg, &outNB, outStdDev)` then multiply by `sqrt(252)` | Annualize the output |
| `HighestFC(Close, Length)` | `TA_MAX(0, endIdx, inClose, length, &outBeg, &outNB, outMax)` | Same as `Highest` |
| `LowestFC(Close, Length)` | `TA_MIN(0, endIdx, inClose, length, &outBeg, &outNB, outMin)` | Same as `Lowest` |
| `PivotHighVS(Inst, Price, LStr, RStr, Len)` | Manual: scan for bar higher than L bars left and R bars right | Asymmetric pivot detection |
| `PivotLowVS(Inst, Price, LStr, RStr, Len)` | Manual: scan for bar lower than L bars left and R bars right | Same for lows |
| `PivotHighVSBar(Inst, Price, LStr, RStr, Len)` | Manual: return offset of detected pivot high | bars-ago index |
| `PivotLowVSBar(Inst, Price, LStr, RStr, Len)` | Manual: return offset of detected pivot low | bars-ago index |
| `Divergence(P1, P2, Str, Len, HiLo)` | Manual: compare pivot highs/lows of two series | No TA-Lib function |
| `TimeSeriesForecast(Close, Length, TgtBar)` | `TA_TSF(0, endIdx, inClose, length, &outBeg, &outNB, outTsf)` | Direct equivalent |
| `LinearRegLine(Close, Length)` | `TA_LINEARREG(0, endIdx, inClose, length, &outBeg, &outNB, outLinReg)` | Value on regression line |
| `SummationFC(Close, Length)` | `TA_SUM(0, endIdx, inClose, length, &outBeg, &outNB, outSum)` | Same as `Summation` |
| `OpenD(N)` | Manual: aggregate intraday bars into daily `struct DailyBar`, index `daily_bars[size-1-N].open` | Requires daily bar aggregation |
| `HighD(N)` | Manual: `daily_bars[size-1-N].high` | Daily high from aggregation |
| `LowD(N)` | Manual: `daily_bars[size-1-N].low` | Daily low |
| `CloseD(N)` | Manual: `daily_bars[size-1-N].close` | Daily close |
| `OpenW(N)` | Manual: aggregate to weekly bars | Same pattern |
| `HighW(N)` | Manual: weekly high | Weekly aggregation |
| `LowW(N)` | Manual: weekly low | Weekly aggregation |
| `CloseW(N)` | Manual: weekly close | Weekly aggregation |
| `OpenM(N)` | Manual: aggregate to monthly bars | Monthly aggregation |
| `HighM(N)` | Manual: monthly high | Monthly aggregation |
| `LowM(N)` | Manual: monthly low | Monthly aggregation |
| `CloseM(N)` | Manual: monthly close | Monthly aggregation |
| `OpenY(N)` | Manual: aggregate to yearly bars | Yearly aggregation |
| `HighY(N)` | Manual: yearly high | Yearly aggregation |
| `LowY(N)` | Manual: yearly low | Yearly aggregation |
| `CloseY(N)` | Manual: yearly close | Yearly aggregation |
| `LRO(Cond, Length, N)` | Manual: scan from `length` bars ago forward, find Nth true | Least Recent Occurrence |
| `SummationIf(Cond, Price, Length)` | Manual: `for (int i = 0; i < length; i++) if (cond[end-i]) sum += price[end-i];` | Conditional rolling sum |
| `IFFString(Cond, TrueStr, FalseStr)` | `cond ? trueStr : falseStr` | C++ ternary with `std::string` |
| `OBV` | `TA_OBV(0, endIdx, inClose, inVolume, &outBeg, &outNB, outObv)` | Direct equivalent |
| `VolumeROC(Length)` | `TA_ROC(0, endIdx, inVolume, length, &outBeg, &outNB, outRoc)` | Apply ROC to volume array |
| `VolumeOsc(ShortLen, LongLen)` | Manual: `TA_SMA(volume, ShortLen) - TA_SMA(volume, LongLen)` | Difference of two volume SMAs |
| `PriceVolTrend` | Manual: cumulative `(close[i] - close[i-1]) / close[i-1] * volume[i]` | Running sum |
| `LWAccDis` | Manual: cumulative `(close - open) / (high - low) * volume` | Larry Williams A/D |
| `Fisher(Price)` | Manual: normalize, then `0.5 * log((1 + norm) / (1 - norm))` | Fisher transformation |
| `FisherINV(Price)` | Manual: `(exp(2 * price) - 1) / (exp(2 * price) + 1)` | Inverse Fisher |
| `C_Doji(Pct)` | `TA_CDLDOJI(0, endIdx, inOpen, inHigh, inLow, inClose, &outBeg, &outNB, outInt)` | TA-Lib CDL* functions return ±100 |
| `C_Hammer_HangingMan(Pct, ...)` | `TA_CDLHAMMER(...)` / `TA_CDLHANGINGMAN(...)` | Separate TA-Lib functions for each pattern |
| `C_BullEng_BearEng(...)` | `TA_CDLENGULFING(0, endIdx, inOpen, inHigh, inLow, inClose, &outBeg, &outNB, outInt)` | +100=bullish, −100=bearish |
| `C_BullHar_BearHar(...)` | `TA_CDLHARAMI(0, endIdx, inOpen, inHigh, inLow, inClose, &outBeg, &outNB, outInt)` | +100=bullish, −100=bearish |
| `C_MornDoji_EveDoji(Pct, ...)` | `TA_CDLMORNINGDOJISTAR(...)` / `TA_CDLEVENINGDOJISTAR(...)` | Separate functions |
| `C_MornStar_EveStar(...)` | `TA_CDLMORNINGSTAR(...)` / `TA_CDLEVENINGSTAR(...)` | Separate functions |
| `C_PierceLine_DkCloud(...)` | `TA_CDLPIERCING(...)` / `TA_CDLDARKCLOUDCOVER(...)` | Separate functions |
| `C_ShootingStar(Pct)` | `TA_CDLSHOOTINGSTAR(0, endIdx, inOpen, inHigh, inLow, inClose, &outBeg, &outNB, outInt)` | Direct equivalent |
| `C_3WhSolds_3BlkCrows(...)` | `TA_CDL3WHITESOLDIERS(...)` / `TA_CDL3BLACKCROWS(...)` | Separate functions |

---

### Table 4 — Strategy Orders

| PowerLanguage | C++ | Notes |
|---|---|---|
| `Buy("label") next bar market` | `orders.push_back({"label", Side::Long, OrderType::Market, 0.0, 1.0})` | Push to the orders vector |
| `SellShort("label") next bar market` | `Order{"label", Side::Short, OrderType::Market, 0.0, 1.0}` | `Side::Short` for short entry |
| `Sell("label") next bar market` | Close long: set `position_ = 0` or push a close-position variant | **WARNING: PL `Sell` exits a long — do NOT map to `Side::Short`** |
| `BuyToCover("label") next bar market` | Close short: set `position_ = 0` | PL `BuyToCover` exits an existing short |
| `Buy("label") next bar at price limit` | `Order{"label", Side::Long, OrderType::Limit, price, 1.0}` | Limit order |
| `Buy("label") next bar at price stop` | `Order{"label", Side::Long, OrderType::Stop, price, 1.0}` | Stop order |
| `SetStopLoss(dollars)` | `stop_price = entry_price_ - dollars / (qty * point_value)` | PL takes a dollar amount; C++ must convert to price level |
| `SetProfitTarget(dollars)` | `target_price = entry_price_ + dollars / (qty * point_value)` | Same dollar-to-price conversion |

---

### Table 5 — Plotting

| PowerLanguage | C++ | Notes |
|---|---|---|
| `Plot1(value, "label")` | `std::cout << label << ": " << value << "\n"` or log to file | No chart in C++; output to stdout, file, or results container |
| `SetPlotColor(1, Red)` | N/A | No visual output; skip or store as metadata |
| `SetPlotWidth(1, 2)` | N/A | Skip |
| `NoPlot(1)` | skip output for that bar | Conditional: don't write to results |

---

### Table 6 — Control Flow

| PowerLanguage | C++ | Notes |
|---|---|---|
| `If cond Then Begin ... End;` | `if (cond) { ... }` | C++ requires parentheses around condition |
| `If cond Then ... Else ...` | `if (cond) { ... } else { ... }` | Direct mapping |
| `For i = 1 to n Begin ... End;` | `for (int i = 1; i <= n; ++i) { ... }` | PL `For` is inclusive; use `<=` in C++ |
| `While cond Begin ... End;` | `while (cond) { ... }` | Direct mapping |
| `Switch (expr) Begin Case 1: ... End;` | `switch (expr) { case 1: ... break; default: break; }` | C++ `switch` requires `break;` to prevent fallthrough |
| `Once Begin ... End;` | `if (first_bar_) { ... first_bar_ = false; }` | Use a bool member; PL `Once` runs on first bar only |

---

### Table 7 — Other Built-ins and Features

| PowerLanguage | C++ | Notes |
|---|---|---|
| `MarketPosition` | `position_` (int: −1/0/+1) | Track manually as member; update on fills |
| `EntryPrice` | `entry_price_` (double) | Track manually |
| `CurrentContracts` | `current_contracts_` (double) | Track manually |
| `BarsSinceEntry` | `bars_since_entry_` (int) | Increment each bar while in position; reset on entry |
| `Print("text")` | `std::cout << "text" << std::endl` | Use iostream or fprintf |
| `#BeginCmtry ... #EndCmtry` | No equivalent | Skip or log |
| `Alert("msg")` | `std::cerr << "ALERT: msg" << std::endl` or callback | Design depends on framework |

---

## Part 2: Semantic Differences and Gotchas

1. **`Sell` does not mean "go short".** In PowerLanguage, `Sell` exits an existing long position. The C++ equivalent is closing the position (setting `position_` to 0). Do not create a new short entry as a translation of `Sell`.

2. **PL is implicitly bar-driven; C++ requires an explicit loop.** PowerLanguage executes the entire script top-to-bottom on each bar close automatically. In C++, you must write the `for (size_t i = 0; i < bars.size(); ++i)` loop and call `on_bar()` on each iteration.

3. **Bar lookback causes undefined behavior without bounds checking.** PL uses MaxBarsBack to prevent execution on bars with insufficient history — the script simply does not run on those early bars. C++ `bars[bars.size() - 6]` is undefined behavior when `bars.size() < 6` — likely a crash, but possibly silent corruption. Always check `bars.size() > n` before lookback access, and skip the bar or use a default value when history is insufficient.

4. **TA-Lib uses batch computation, not streaming.** TA-Lib functions like `TA_SMA` process an entire array at once and return `outBegIdx` (first valid output index) and `outNBElement` (count of valid outputs). Calling TA-Lib on every bar with a growing history slice recomputes the entire series each time. For performance, consider TA-Lib RT's streaming API or caching previous results.

5. **TA-Lib `outBegIdx` offset is the most common TA-Lib mistake.** The output array is NOT aligned with the input array. The first valid output is at `output[0]`, which corresponds to `input[outBegIdx]`. The current bar's value is `output[outNBElement - 1]`. Ignoring this offset and reading `output[inputIndex]` produces incorrect indicator values.

6. **Crossover/crossunder has no TA-Lib built-in.** PL `Crosses Over` / `Crosses Under` are language keywords. TA-Lib has no crossover function. Implement as: `bool crossed_over = prev_a <= prev_b && a > b;`. Store previous-bar values as member variables.

7. **Dollar amounts versus price levels for stops.** `SetStopLoss` and `SetProfitTarget` in PL accept a dollar amount. C++ must convert to price levels explicitly: `stop_price = entry_price_ - stop_dollars / (qty * point_value)`.

8. **Position state is not tracked automatically.** PL provides `MarketPosition`, `EntryPrice`, `CurrentContracts`, and `BarsSinceEntry` as built-in variables updated by the engine. In C++, you must maintain these as class members and update them manually on order fills.

9. **C++ has no `Value1..Value99` or `Condition1..Condition99`.** Replace with named, typed class members using descriptive identifiers.

10. **TA-Lib output arrays must be pre-allocated.** All `TA_*` functions write into caller-allocated arrays. Size them at least as large as the input array. Failing to allocate enough space causes a buffer overflow. Use `std::vector` instead of raw arrays to avoid this class of bugs.

11. **Multi-data series requires explicit design.** PL `Close of Data2` accesses a second feed bound to the chart. In C++, pass `const std::vector<Bar>& bars2` as a second parameter. There is no implicit secondary-feed mechanism.

12. **No Portfolio Money Management (PMM) equivalent.** PL's PMM allows a single script to govern position sizing across multiple instruments. C++ has no built-in portfolio abstraction. You must implement cross-instrument logic as a separate portfolio manager that calls individual strategy instances.

---

## Part 3: Conversion Checklists

### PL → C++ Pre-Conversion

- [ ] List every `Inputs:` declaration; note name, type, default — each becomes a constructor parameter and private member
- [ ] List every `Variables:` declaration; note initial values — each becomes a private member initialized in-class or in the constructor
- [ ] Identify all `Value1..Value99` and `Condition1..Condition99` usages; plan meaningful replacement names
- [ ] Identify all indicator calls; confirm each has a TA-Lib equivalent (check `ta_func.h` for the function name)
- [ ] Locate all `Data2` / `Data3` references; decide on multi-feed architecture
- [ ] Locate all `SetStopLoss`, `SetProfitTarget`, and dollar-based parameters; note point value for conversion
- [ ] Check for `IntraBarPersist` variables; decide whether tick-level behavior matters
- [ ] Identify all `.elf` function calls; plan conversion to C++ free functions or member functions

### PL → C++ Post-Conversion

- [ ] Every `Sell` maps to closing the long, not entering short — audit all order keywords
- [ ] Every `BuyToCover` maps to closing the short, not entering long
- [ ] All lookback accesses (`Close[N]`) guarded with `bars.size() > n`
- [ ] All TA-Lib output arrays properly pre-allocated (use `std::vector`, not raw arrays)
- [ ] All TA-Lib results read from `output[outNBElement - 1]`, not `output[inputIndex]` — `outBegIdx` offset accounted for
- [ ] `Crosses Over` / `Crosses Under` implemented as two-bar comparisons
- [ ] `MarketPosition`, `EntryPrice`, `CurrentContracts`, `BarsSinceEntry` tracked as manually updated members
- [ ] Dollar-based stop/target amounts converted to price levels
- [ ] `Value1..Value99` and `Condition1..Condition99` renamed to descriptive typed members
- [ ] Code compiles with `g++ -std=c++17 -Wall -Wextra -Werror` with zero errors and zero warnings
- [ ] Strategy back-tested on the same instrument and date range as PL original; trade count and net P&L in the same order of magnitude

### C++ → PL Pre-Conversion

- [ ] List all class members and categorize: inputs (const/set-once) vs variables (mutable) vs indicator state
- [ ] Identify all TA-Lib function calls; map each to the PL built-in (TA_SMA → Average, TA_EMA → XAverage, TA_RSI → RSI, etc.)
- [ ] Check for `switch` statements with fallthrough — PL `Switch` does not fallthrough
- [ ] Identify any C++ libraries beyond TA-Lib; plan PL equivalents or inline reimplementation
- [ ] Check for explicit position-tracking members; confirm they can be replaced by PL's built-in `MarketPosition`, `EntryPrice`, etc.

### C++ → PL Post-Conversion

- [ ] Every short entry maps to `SellShort`, not `Sell`
- [ ] Every long close maps to `Sell`, not `SellShort`
- [ ] All `bars[bars.size() - 1 - n].close` lookbacks converted to `Close[n]`
- [ ] All manual crossover comparisons converted to PL `Crosses Over` / `Crosses Under` keywords
- [ ] All class members categorized: const inputs → `Inputs:`, mutable state → `Variables:`
- [ ] All TA-Lib batch calls replaced with PL function calls (e.g., `TA_SMA(...)` → `Average(Close, Length)`)
- [ ] TA-Lib `outBegIdx` / `outNBElement` index arithmetic eliminated — PL handles lookback alignment internally
- [ ] Price-level stops/targets converted to dollar amounts for `SetStopLoss` / `SetProfitTarget`
- [ ] Script compiled in MultiCharts PowerEditor with zero errors before testing
