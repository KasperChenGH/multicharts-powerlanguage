---
name: powerlanguage-python-conversion
description: Use when converting, translating, porting, or migrating code between MultiCharts PowerLanguage and Python, in either direction. Contains a lightweight Strategy ABC scaffold, concept mapping tables, semantic difference documentation, and pre/post-conversion checklists. References powerlanguage-syntax for PowerLanguage-specific details. Recommends pandas-ta as the primary indicator library with TA-Lib as an alternative.
---

# PowerLanguage ↔ Python Conversion

## How to use

This skill covers the structural and semantic differences between MultiCharts PowerLanguage and Python for algorithmic trading. It does not duplicate the syntax rules of PowerLanguage — for declarations, bar references, control flow, and built-in function signatures use the `powerlanguage-syntax` skill. When performing a conversion in either direction, work through Part 0 (structural template) to set up the boilerplate, then Part 1 (concept mapping) for line-by-line translation, then review Part 2 (semantic differences and gotchas), and finally run through the relevant checklist in Part 3 before calling the output complete.

---

## Part 0: Structural Template

PowerLanguage runs the entire script top-to-bottom on each bar close automatically. Python has no implicit bar loop, no built-in OHLCV type, and no order submission mechanism. Every PL-to-Python conversion targets the framework-agnostic scaffold below.

### Bar dataclass

```python
from dataclasses import dataclass

@dataclass
class Bar:
    open: float
    high: float
    low: float
    close: float
    volume: float
    time: int          # Unix epoch seconds
    bar_number: int    # 1-based to match PL convention
```

### Order types

```python
from enum import Enum, auto
from dataclasses import dataclass

class Side(Enum):
    LONG = auto()
    SHORT = auto()

class OrderType(Enum):
    MARKET = auto()
    LIMIT = auto()
    STOP = auto()

class Action(Enum):
    ENTRY = auto()
    EXIT = auto()
    STOP_LOSS = auto()
    PROFIT_TARGET = auto()
    BREAK_EVEN = auto()

@dataclass
class Order:
    label: str
    action: Action
    side: Side
    order_type: OrderType
    price: float = 0.0   # 0.0 for Market
    qty: float = 1.0
```

### Strategy ABC

```python
from abc import ABC, abstractmethod

class Strategy(ABC):
    @abstractmethod
    def on_bar(self, bars: list[Bar], orders: list[Order]) -> None:
        ...
```

### Strategy subclass skeleton

```python
import pandas as pd
import pandas_ta as ta

class MyStrategy(Strategy):
    def __init__(self, length: int = 20, threshold: float = 0.5):
        # Inputs (PL: Inputs: Length(20), Threshold(0.5))
        self.length = length
        self.threshold = threshold

        # Variables (PL: Variables: my_var(0))
        self.my_var = 0.0

        # Position state (PL: MarketPosition, EntryPrice, etc.)
        self.position = 0           # -1, 0, +1
        self.entry_price = 0.0
        self.bars_since_entry = 0
        self.current_contracts = 0.0

    def on_bar(self, bars: list[Bar], orders: list[Order]) -> None:
        if len(bars) < self.length:
            return

        closes = pd.Series([b.close for b in bars])

        # pandas-ta: compute indicator on the full series
        sma = ta.sma(closes, length=self.length)
        current_sma = sma.iloc[-1]

        # ... strategy logic, push to orders list ...
```

### Alternative: TA-Lib indicator pattern

```python
import talib
import numpy as np

class MyStrategy(Strategy):
    def on_bar(self, bars: list[Bar], orders: list[Order]) -> None:
        closes = np.array([b.close for b in bars])

        # TA-Lib: batch array API (NumPy in, NumPy out)
        sma = talib.SMA(closes, timeperiod=self.length)
        current_sma = sma[-1]
```

pandas-ta is recommended as the primary library (pure Python, zero install friction, pip-installable). TA-Lib is the performance alternative (C-based, requires compiling the C library). The concept mapping tables in Part 1 show both.

### Main loop

```python
def main():
    bars: list[Bar] = load_bars("data.csv")  # user-provided
    strategy = MyStrategy(length=20, threshold=0.5)

    for i in range(len(bars)):
        orders: list[Order] = []
        strategy.on_bar(bars[: i + 1], orders)
        # execute orders against simulated book...
```

The slice `bars[:i+1]` gives the strategy access to full history; `bars[-1]` is the current bar. This mirrors PL's implicit bar-by-bar execution.

---

## Part 1: Concept Mapping

### Table 1 — Declarations

| PowerLanguage | Python | Notes |
|---|---|---|
| `Inputs: Length(20)` | `__init__` parameter with default: `def __init__(self, length: int = 20)` | Stored as `self.length`; treat as read-only after construction |
| `Variables: myVar(0)` | `self.my_var = 0.0` in `__init__` | Mutable instance attributes |
| `Value1` .. `Value99` | Named attribute (e.g., `self.rsi_val`) | Must rename to meaningful identifiers; Python has no pre-declared variables |
| `Condition1` .. `Condition99` | Named attribute (e.g., `self.is_oversold`) | Same: rename to typed `bool` attributes |
| `Arrays: buf[10](0)` | `self.buf = [0.0] * 11` | PL `[10]` means last index is 10 (11 elements); use a Python `list` |
| `IntraBarPersist myVar(0)` | `self.my_var = 0.0` (same as Variables) | Python has no bar-close vs intra-bar distinction; all instance attributes persist |

---

### Table 2 — Data Access

| PowerLanguage | Python | Notes |
|---|---|---|
| `Open`, `High`, `Low`, `Close`, `Volume` | `bars[-1].open`, `.high`, `.low`, `.close`, `.volume` | `bars[-1]` for current bar |
| `Close[1]` | `bars[-2].close` | Lookback N: `bars[-1 - n].close`. Guard with `len(bars) > n`. |
| `Close of Data2` | separate `bars2: list[Bar]` parameter | PL Data2 is a second chart feed; pass a second list to `on_bar()` |
| `Date` | `datetime.fromtimestamp(bars[-1].time, tz=timezone.utc)` | PL `Date` is YYYMMDD integer; Python uses `datetime` module |
| `Time` | `dt.hour * 100 + dt.minute` (from datetime object) | PL `Time` is HHMM integer |
| `BarNumber` / `CurrentBar` | `bars[-1].bar_number` or `len(bars)` | PL is 1-based |

---

### Table 3 — Technical Indicators (dual-library)

| PowerLanguage | pandas-ta (primary) | TA-Lib (alternative) | Notes |
|---|---|---|---|
| `Average(Close, N)` | `ta.sma(closes, length=N)` | `talib.SMA(closes, timeperiod=N)` | Current value: `.iloc[-1]` / `[-1]` |
| `XAverage(Close, N)` | `ta.ema(closes, length=N)` | `talib.EMA(closes, timeperiod=N)` | |
| `RSI(Close, N)` | `ta.rsi(closes, length=N)` | `talib.RSI(closes, timeperiod=N)` | Returns 0–100 |
| `BollingerBand(Close, N, 2)` | `ta.bbands(closes, length=N, std=2)` | `talib.BBANDS(closes, timeperiod=N, nbdevup=2, nbdevdn=2)` | Returns upper/mid/lower |
| `MACD(Close, 12, 26)` | `ta.macd(closes, fast=12, slow=26, signal=9)` | `talib.MACD(closes, fastperiod=12, slowperiod=26, signalperiod=9)` | Returns MACD/signal/histogram |
| `Stochastic(...)` | `ta.stoch(highs, lows, closes, k=14, d=3)` | `talib.STOCH(highs, lows, closes, fastk_period=14, slowk_period=3, slowd_period=3)` | Returns slowK/slowD |
| `ADX(N)` | `ta.adx(highs, lows, closes, length=N)` | `talib.ADX(highs, lows, closes, timeperiod=N)` | |
| `CCI(N)` | `ta.cci(highs, lows, closes, length=N)` | `talib.CCI(highs, lows, closes, timeperiod=N)` | |
| `AvgTrueRange(N)` | `ta.atr(highs, lows, closes, length=N)` | `talib.ATR(highs, lows, closes, timeperiod=N)` | Requires HLC |
| `Momentum(Close, N)` | `ta.mom(closes, length=N)` | `talib.MOM(closes, timeperiod=N)` | |
| `Highest(High, N)` | `highs.rolling(N).max()` | `talib.MAX(highs, timeperiod=N)` | |
| `Lowest(Low, N)` | `lows.rolling(N).min()` | `talib.MIN(lows, timeperiod=N)` | |
| `DMIPlus(N)` / `DMIMinus(N)` | `ta.dm(highs, lows, length=N)` | `talib.PLUS_DI(...)` / `talib.MINUS_DI(...)` | |
| `KeltnerChannel(Close, N, mult)` | `ta.kc(highs, lows, closes, length=N, scalar=mult)` | Manual: `talib.EMA(closes, N) ± mult * talib.ATR(highs, lows, closes, N)` | |
| `Parabolic(step)` | `ta.psar(highs, lows, af0=step, max_af=0.2)` | `talib.SAR(highs, lows, acceleration=step, maximum=0.2)` | |
| `PercentR(N)` | `ta.willr(highs, lows, closes, length=N)` | `talib.WILLR(highs, lows, closes, timeperiod=N)` | Returns −100..0 range |
| `RateOfChange(Close, N)` | `ta.roc(closes, length=N)` | `talib.ROC(closes, timeperiod=N)` | |
| `Volatility(N)` | `ta.stdev(closes, length=N)` | `talib.STDDEV(closes, timeperiod=N)` | Approximation |
| `StandardDev(Close, N, 1)` | `ta.stdev(closes, length=N)` | `talib.STDDEV(closes, timeperiod=N, nbdev=1)` | |
| `TrueRange` | `ta.true_range(highs, lows, closes)` | `talib.TRANGE(highs, lows, closes)` | Per-bar, no period |
| `MoneyFlow(N)` | `ta.mfi(highs, lows, closes, volumes, length=N)` | `talib.MFI(highs, lows, closes, volumes, timeperiod=N)` | Requires HLCV |
| `AccumDist` | `ta.ad(highs, lows, closes, volumes)` | `talib.AD(highs, lows, closes, volumes)` | Cumulative, no period |
| `LinearRegValue(Close, N, 0)` | `ta.linreg(closes, length=N)` | `talib.LINEARREG(closes, timeperiod=N)` | |
| `LinearRegSlope(Close, N)` | `ta.linreg(closes, length=N, slope=True)` | `talib.LINEARREG_SLOPE(closes, timeperiod=N)` | |
| `Summation(Close, N)` | `closes.rolling(N).sum()` | `talib.SUM(closes, timeperiod=N)` | |
| `Cum(Volume)` | `volumes.cumsum()` | `np.cumsum(volumes)` | Running total |
| `WAverage(Close, N)` | `ta.wma(closes, length=N)` | `talib.WMA(closes, timeperiod=N)` | |
| `MidPoint(Close, N)` | `ta.midpoint(closes, length=N)` | `talib.MIDPOINT(closes, timeperiod=N)` | |
| `TSI(Close, LongLen, ShortLen)` | `ta.tsi(closes, fast=ShortLen, slow=LongLen)` | Manual: double-EMA of momentum / double-EMA of abs(momentum) | pandas-ta `fast`=short, `slow`=long (reversed naming vs PL) |
| `SwingHigh(1, High, L, R)` | Manual: scan for pivot high | Manual: scan for pivot high | No direct library equivalent |
| `SwingLow(1, Low, L, R)` | Manual: scan for pivot low | Manual: scan for pivot low | Same |
| `HighestBar(High, N)` | `highs[-N:].idxmax()` → compute bars ago | `np.argmax(highs[-N:])` | Returns bars ago |
| `LowestBar(Low, N)` | `lows[-N:].idxmin()` → compute bars ago | `np.argmin(lows[-N:])` | Returns bars ago |
| `CountIF(cond, N)` | `cond_series.rolling(N).sum()` | Manual: `sum(1 for ...)` | Count True values |
| `Crosses Over` | `prev_a <= prev_b and a > b` | Same | No built-in; store previous values |
| `Crosses Under` | `prev_a >= prev_b and a < b` | Same | Same |
| `AverageFC(Close, N)` | `ta.sma(closes, length=N)` | `talib.SMA(closes, timeperiod=N)` | Fast version of Average; same math, use SMA |
| `AdaptiveMovAvg(Close, N)` | `ta.kama(closes, length=N)` | `talib.KAMA(closes, timeperiod=N)` | Kaufman Adaptive Moving Average |
| `UltimateOscillator(7,14,28)` | `ta.uo(highs, lows, closes, fast=7, medium=14, slow=28)` | `talib.ULTOSC(highs, lows, closes, timeperiod1=7, timeperiod2=14, timeperiod3=28)` | Requires HLC |
| `ChaikinOsc(3, 10)` | `ta.adosc(highs, lows, closes, volumes, fast=3, slow=10)` | `talib.ADOSC(highs, lows, closes, volumes, fastperiod=3, slowperiod=10)` | Requires HLCV |
| `PriceOscillator(Fast, Slow)` | `ta.apo(closes, fast=Fast, slow=Slow)` | `talib.APO(closes, fastperiod=Fast, slowperiod=Slow)` | Absolute Price Oscillator |
| `DirMovement(N, ...)` | `ta.dm(highs, lows, length=N)` + `ta.adx(...)` | `talib.PLUS_DI(...)` + `talib.MINUS_DI(...)` + `talib.ADX(...)` | Multi-output: +DI, −DI, ADX |
| `Extremes(High, Low, N, oHH, oLL, oHHBar, oLLBar)` | Manual: rolling max/min + argmax/argmin | Manual: rolling max/min + argmax/argmin | Returns highest, lowest, and their bar offsets |
| `TrueHigh` | `np.maximum(highs, closes.shift(1))` | Same | `max(High, Close[1])` |
| `TrueLow` | `np.minimum(lows, closes.shift(1))` | Same | `min(Low, Close[1])` |
| `Range` | `highs - lows` | Same | Per-bar range; no period |
| `NthHighest(N, Close, Len)` | Manual: `closes.rolling(Len).apply(lambda x: np.sort(x)[-N])` | Manual: sort rolling window | Nth largest value in window |
| `NthLowest(N, Close, Len)` | Manual: `closes.rolling(Len).apply(lambda x: np.sort(x)[N-1])` | Manual: sort rolling window | Nth smallest value in window |
| `NthHighestBar(N, Close, Len)` | Manual: find bar offset of Nth highest | Manual: find bar offset of Nth highest | Returns bars ago of Nth highest |
| `NthLowestBar(N, Close, Len)` | Manual: find bar offset of Nth lowest | Manual: find bar offset of Nth lowest | Returns bars ago of Nth lowest |
| `SwingHighBar(1, High, L, R)` | Manual: pivot detection with bar offset | Manual: pivot detection with bar offset | Bars since Nth swing high |
| `SwingLowBar(1, Low, L, R)` | Manual: pivot detection with bar offset | Manual: pivot detection with bar offset | Bars since Nth swing low |
| `LinearRegAngle(Close, N)` | `np.degrees(np.arctan(ta.linreg(closes, length=N, slope=True)))` | `talib.LINEARREG_ANGLE(closes, timeperiod=N)` | Slope converted to degrees |
| `Correlation(Close, Volume, N)` | `ta.correlation(closes, volumes, length=N)` | `talib.CORREL(closes, volumes, timeperiod=N)` | Pearson correlation |
| `RSquared(Close, N)` | `ta.correlation(closes, ..., length=N) ** 2` | `talib.CORREL(closes, ..., timeperiod=N) ** 2` | Square of correlation |
| `StdError(Close, N)` | Manual: `ta.stdev(closes, length=N) / np.sqrt(N)` | Manual: `talib.STDDEV(closes, timeperiod=N) / np.sqrt(N)` | Standard error of estimate |
| `Median(Close, N)` | `ta.median(closes, length=N)` | `closes.rolling(N).median()` | Rolling median |
| `ELDate(dt)` | Manual: `(y - 1900) * 10000 + m * 100 + d` | Same | EasyLanguage YYYMMDD date format |
| `MinutesToTime(mins)` | Manual: `(mins // 60) * 100 + mins % 60` | Same | Minutes since midnight to HHMM |
| `TimeToMinutes(hhmm)` | Manual: `(hhmm // 100) * 60 + hhmm % 100` | Same | HHMM to minutes since midnight |
| `AvgPrice` | `(opens + highs + lows + closes) / 4` | `talib.AVGPRICE(opens, highs, lows, closes)` | Average of OHLC |
| `MedianPrice` | `(highs + lows) / 2` | `talib.MEDPRICE(highs, lows)` | Median of HL |
| `TypicalPrice` | `(highs + lows + closes) / 3` | `talib.TYPPRICE(highs, lows, closes)` | Typical price HLC |
| `WeightedClose` | `(highs + lows + 2 * closes) / 4` | `talib.WCLPRICE(highs, lows, closes)` | Weighted close HLCC |
| `MRO(cond, N, 1)` | Manual: find Nth True in `cond_series[-N:]` | Manual: iterate lookback | Most Recent Occurrence; returns bars ago |
| `IFF(cond, trueVal, falseVal)` | `trueVal if cond else falseVal` | Same | Python ternary; or `np.where(cond, trueVal, falseVal)` for Series |
| `TriAverage(Close, N)` | `ta.trima(closes, length=N)` | `talib.TRIMA(closes, timeperiod=N)` | Triangular MA |
| `FastK(N)` | `ta.stoch(highs, lows, closes, k=N, d=1, smooth_k=1)['STOCHk_N_1_1']` | `talib.STOCHF(highs, lows, closes, fastk_period=N)` | Raw Fast %K |
| `FastD(N)` | `ta.stoch(highs, lows, closes, k=N, d=3)['STOCHd_N_3_3']` | `talib.STOCHF(highs, lows, closes, fastk_period=N, fastd_period=3)` | Smoothed Fast %D |
| `SlowK(N)` | `ta.stoch(highs, lows, closes, k=N, d=3)['STOCHk_N_3_3']` | `talib.STOCH(highs, lows, closes, fastk_period=N, slowk_period=3)` | Slow %K |
| `SlowD(N)` | `ta.stoch(highs, lows, closes, k=N, d=3)['STOCHd_N_3_3']` | `talib.STOCH(highs, lows, closes, fastk_period=N, slowk_period=3, slowd_period=3)` | Slow %D |
| `FastKCustom(H, L, C, N)` | `ta.stoch(H, L, C, k=N, d=1, smooth_k=1)['STOCHk_...']` | `talib.STOCHF(H, L, C, fastk_period=N)` | Custom prices |
| `FastDCustom(H, L, C, N)` | `ta.stoch(H, L, C, k=N, d=3)['STOCHd_...']` | `talib.STOCHF(H, L, C, fastk_period=N, fastd_period=3)` | Custom prices |
| `SlowKCustom(H, L, C, N)` | `ta.stoch(H, L, C, k=N, d=3)['STOCHk_...']` | `talib.STOCH(H, L, C, fastk_period=N, slowk_period=3)` | Custom prices |
| `SlowDCustom(H, L, C, N)` | `ta.stoch(H, L, C, k=N, d=3)["STOCHd_N_3_3"]` | `talib.STOCH(H, L, C, fastk_period=N)[2]` | Slow %D with custom prices |
| `StochasticExp(H, L, C, N, S1, S2, ...)` | Manual: compute FastK then apply EMA smoothing | Manual: compute with `talib.STOCHF` then `talib.EMA` | Exponential smoothing variant |
| `ADXR(N)` | `ta.adx(highs, lows, closes, length=N)` then `(adx + adx.shift(N)) / 2` | `talib.ADXR(highs, lows, closes, timeperiod=N)` | TA-Lib has direct ADXR |
| `ADXCustom(H, L, C, N)` | `ta.adx(H, L, C, length=N)` | `talib.ADX(H, L, C, timeperiod=N)` | Pass custom price Series |
| `DMI(N)` | `ta.adx(highs, lows, closes, length=N)` | `talib.ADX(highs, lows, closes, timeperiod=N)` | Wrapper; same as ADX |
| `DMIPlusCustom(H, L, C, N)` | `ta.dm(H, L, length=N)['DMP_N']` | `talib.PLUS_DI(H, L, C, timeperiod=N)` | +DI with custom prices |
| `DMIMinusCustom(H, L, C, N)` | `ta.dm(H, L, length=N)['DMN_N']` | `talib.MINUS_DI(H, L, C, timeperiod=N)` | −DI with custom prices |
| `ParabolicCustom(step, limit)` | `ta.psar(highs, lows, af0=step, max_af=limit)` | `talib.SAR(highs, lows, acceleration=step, maximum=limit)` | Parabolic SAR with custom limit |
| `TRIX(Close, N)` | `ta.trix(closes, length=N)` | `talib.TRIX(closes, timeperiod=N)` | Triple EMA ROC |
| `MassIndex(SmoothLen, SumLen)` | `ta.massi(highs, lows, fast=SmoothLen, slow=SumLen)` | Manual: EMA ratio sum | Mass Index |
| `EaseOfMovement` | `ta.eom(highs, lows, closes, volumes)` | Manual: distance moved / box ratio | Requires HLCV |
| `SwingIndex` | Manual: Wilder swing index formula | Manual: same | No library built-in |
| `AccumSwingIndex` | Manual: cumulative sum of SwingIndex | Manual: same | No library built-in |
| `Detrend(Close, N)` | Manual: `closes - closes.rolling(N).mean().shift(N // 2 + 1)` | Manual: offset SMA | Detrended price |
| `PercentChange(Close, N)` | `closes.pct_change(N) * 100` | `talib.ROC(closes, timeperiod=N)` | Percent change |
| `UlcerIndex(Close, N)` | `ta.ui(closes, length=N)` | Manual: RMS of drawdown pct | Downside volatility |
| `ParabolicSAR(step, limit, ...)` | `ta.psar(highs, lows, af0=step, max_af=limit)` | `talib.SAR(highs, lows, acceleration=step, maximum=limit)` | Multi-output; extract position from PSARl/PSARs columns |
| `LinearReg(Close, N, TgtBar, ...)` | `ta.linreg(closes, length=N)` + manual slope/angle | `talib.LINEARREG(closes, timeperiod=N)` + `talib.LINEARREG_SLOPE/ANGLE/INTERCEPT` | Multi-output; combine four TA-Lib calls |
| `TrueRangeCustom(H, L, C)` | `ta.true_range(H, L, C)` | `talib.TRANGE(H, L, C)` | Custom prices |
| `VolatilityStdDev(NumDays)` | `np.log(closes / closes.shift(1)).rolling(NumDays).std() * np.sqrt(252)` | Manual: annualized stdev of log returns | Historical volatility |
| `StandardDevAnnual(Close, N, DataType)` | `ta.stdev(closes, length=N) * np.sqrt(252)` | `talib.STDDEV(closes, timeperiod=N) * np.sqrt(252)` | Annualized stdev |
| `HighestFC(Close, N)` | `closes.rolling(N).max()` | `talib.MAX(closes, timeperiod=N)` | Same as Highest |
| `LowestFC(Close, N)` | `closes.rolling(N).min()` | `talib.MIN(closes, timeperiod=N)` | Same as Lowest |
| `PivotHighVS(Inst, Price, LStr, RStr, Len)` | Manual: scan for pivot high with L/R strength | Manual: same | Asymmetric left/right strength |
| `PivotLowVS(Inst, Price, LStr, RStr, Len)` | Manual: scan for pivot low with L/R strength | Manual: same | Same |
| `PivotHighVSBar(Inst, Price, LStr, RStr, Len)` | Manual: bars ago of pivot high | Manual: same | Returns offset |
| `PivotLowVSBar(Inst, Price, LStr, RStr, Len)` | Manual: bars ago of pivot low | Manual: same | Returns offset |
| `Divergence(P1, P2, Str, Len, HiLo)` | Manual: compare pivot highs/lows of two series | Manual: same | No library built-in |
| `TimeSeriesForecast(Close, N)` | `ta.tsf(closes, length=N)` | `talib.TSF(closes, timeperiod=N)` | Time Series Forecast |

| `SummationFC(Close, N)` | `closes.rolling(N).sum()` | `talib.SUM(closes, timeperiod=N)` | Same as Summation |
| `OpenD(N)` | `df.resample('D').first()['open'].iloc[-1-N]` | Manual: resample to daily | Daily open |
| `HighD(N)` | `df.resample('D').max()['high'].iloc[-1-N]` | Manual: resample | Daily high |
| `LowD(N)` | `df.resample('D').min()['low'].iloc[-1-N]` | Manual: resample | Daily low |
| `CloseD(N)` | `df.resample('D').last()['close'].iloc[-1-N]` | Manual: resample | Daily close |
| `OpenW(N)` | `df.resample('W').first()['open'].iloc[-1-N]` | Manual: resample | Weekly open |
| `HighW(N)` | `df.resample('W').max()['high'].iloc[-1-N]` | Manual: resample | Weekly high |
| `LowW(N)` | `df.resample('W').min()['low'].iloc[-1-N]` | Manual: resample | Weekly low |
| `CloseW(N)` | `df.resample('W').last()['close'].iloc[-1-N]` | Manual: resample | Weekly close |
| `OpenM(N)` | `df.resample('ME').first()['open'].iloc[-1-N]` | Manual: resample | Monthly open |
| `HighM(N)` | `df.resample('ME').max()['high'].iloc[-1-N]` | Manual: resample | Monthly high |
| `LowM(N)` | `df.resample('ME').min()['low'].iloc[-1-N]` | Manual: resample | Monthly low |
| `CloseM(N)` | `df.resample('ME').last()['close'].iloc[-1-N]` | Manual: resample | Monthly close |
| `OpenY(N)` | `df.resample('YE').first()['open'].iloc[-1-N]` | Manual: resample | Yearly open |
| `HighY(N)` | `df.resample('YE').max()['high'].iloc[-1-N]` | Manual: resample | Yearly high |
| `LowY(N)` | `df.resample('YE').min()['low'].iloc[-1-N]` | Manual: resample | Yearly low |
| `CloseY(N)` | `df.resample('YE').last()['close'].iloc[-1-N]` | Manual: resample | Yearly close |
| `LRO(cond, N, Inst)` | Manual: `cond_series[-N:].iloc[::-1]` find Nth True from end | Manual: same | Least Recent Occurrence |
| `SummationIf(cond, Price, N)` | `(Price * cond).rolling(N).sum()` | Manual: multiply then sum | Conditional rolling sum |
| `IFFString(cond, trueStr, falseStr)` | `trueStr if cond else falseStr` | Same | String ternary; or `np.where` |
| `OBV` | `ta.obv(closes, volumes)` | `talib.OBV(closes, volumes)` | On Balance Volume |
| `VolumeROC(N)` | `ta.roc(volumes, length=N)` | `talib.ROC(volumes, timeperiod=N)` | Volume rate of change |
| `VolumeOsc(ShortLen, LongLen)` | `ta.sma(volumes, length=ShortLen) - ta.sma(volumes, length=LongLen)` | `talib.SMA(volumes, ShortLen) - talib.SMA(volumes, LongLen)` | Volume oscillator |
| `PriceVolTrend` | `ta.pvt(closes, volumes)` | Manual: cumulative `pct_change * volume` | Price Volume Trend |
| `LWAccDis` | Manual: `((closes - opens) / (highs - lows) * volumes).cumsum()` | Manual: same | Larry Williams A/D |
| `Fisher(Price)` | Manual: normalize, then `0.5 * np.log((1 + norm) / (1 - norm))` | Manual: same | Fisher transformation |
| `FisherINV(Price)` | Manual: `(np.exp(2 * Price) - 1) / (np.exp(2 * Price) + 1)` | Manual: same | Inverse Fisher |
| `C_Doji(Pct)` | Manual: `abs(close - open) <= (high - low) * Pct / 100` | `talib.CDLDOJI(opens, highs, lows, closes)` | TA-Lib has CDL* family |
| `C_Hammer_HangingMan(Len, Factor, ...)` | Manual: body/shadow ratios | `talib.CDLHAMMER(...)` / `talib.CDLHANGINGMAN(...)` | Separate TA-Lib functions |
| `C_BullEng_BearEng(Len, ...)` | Manual: engulfing detection | `talib.CDLENGULFING(opens, highs, lows, closes)` | +100=bullish, -100=bearish |
| `C_BullHar_BearHar(Len, ...)` | Manual: harami detection | `talib.CDLHARAMI(opens, highs, lows, closes)` | +100=bullish, -100=bearish |
| `C_MornDoji_EveDoji(Len, Pct, ...)` | Manual: 3-bar doji star | `talib.CDLMORNINGDOJISTAR(...)` / `talib.CDLEVENINGDOJISTAR(...)` | Separate functions |
| `C_MornStar_EveStar(Len, ...)` | Manual: 3-bar star | `talib.CDLMORNINGSTAR(...)` / `talib.CDLEVENINGSTAR(...)` | Separate functions |
| `C_PierceLine_DkCloud(Len, ...)` | Manual: piercing/cloud | `talib.CDLPIERCING(...)` / `talib.CDLDARKCLOUDCOVER(...)` | Separate functions |
| `C_ShootingStar(Len, Factor)` | Manual: shooting star | `talib.CDLSHOOTINGSTAR(opens, highs, lows, closes)` | TA-Lib direct |
| `C_3WhSolds_3BlkCrows(Len, Factor, ...)` | Manual: 3-bar trend | `talib.CDL3WHITESOLDIERS(...)` / `talib.CDL3BLACKCROWS(...)` | Separate functions |
| **Statistical extended** | | | |
| `AvgDeviation(Close, N)` | `ta.mad(closes, length=N)` | Manual: `(closes - closes.rolling(N).mean()).abs().rolling(N).mean()` | Mean absolute deviation |
| `Variance(Close, N)` | `ta.variance(closes, length=N)` | `talib.VAR(closes, timeperiod=N)` | Population variance |
| `Kurtosis(Close, N)` | `closes.rolling(N).kurt()` | Manual: 4th moment | Excess kurtosis |
| `Skew(Close, N)` | `closes.rolling(N).skew()` | Manual: 3rd moment | Skewness |
| `PercentRank(ValToRank, Price, N)` | `closes.rolling(N).apply(lambda w: stats.percentileofscore(w, w.iloc[-1]))` | Manual | Percent rank |
| `Covariance(P1, P2, N)` | `P1.rolling(N).cov(P2)` | Manual | Covariance |
| `Quartile(Close, N, Q)` | `closes.rolling(N).quantile(Q*0.25)` | Manual | Quartile value |
| `TrimMean(Close, N, Pct)` | `closes.rolling(N).apply(lambda w: stats.trim_mean(w, Pct/100))` | Manual | Trimmed mean |
| `Mode(Close, N, Type)` | `closes.rolling(N).apply(lambda w: w.mode().iloc[0])` | Manual | Modal value |
| `HarmonicMean(Close, N)` | `closes.rolling(N).apply(stats.hmean)` | Manual | Harmonic mean |
| **Moving averages extended** | | | |
| `SmoothedAverage(Close, N)` | `ta.rma(closes, length=N)` | Manual: Wilder smoothing | Wilder/RMA |
| **Miscellaneous** | | | |
| `BarAnnualization` | Manual: compute from bar frequency | Manual | Bars-per-year factor |
| `LastBarOnChart` | `idx == len(df) - 1` | Manual | True on last bar |
| **Custom functions** | | | |
| `StochRSI(Close, N, M)` | `pandas_ta.stochrsi(df["close"], length=N, rsi_length=N, k=M)` | `pandas_ta.stochrsi()` | Stochastic RSI |
| `supertrend(N, Mult)` | `pandas_ta.supertrend(df["high"], df["low"], df["close"], length=N, multiplier=Mult)` | `pandas_ta.supertrend()` | Supertrend |
| `NVI(Start)` | Manual: accumulate on volume-down bars | Manual | Negative Volume Index |
| `PVI(Start)` | Manual: accumulate on volume-up bars | Manual | Positive Volume Index |
| `Coppo(N1, N2, N3)` | `pandas_ta.coppock(df["close"], length=N3, fast=N2, slow=N1)` | `pandas_ta.coppock()` | Coppock Curve |
| `LWTI(Close, P, N)` | Manual: `(sma(close-close.shift(P), N) / sma(high-low, N)) * 50 + 50` | Manual | Larry Williams TI |
| `TVI(Close, Vol, Tick)` | Manual: cumulative directional volume | Manual | Trade Volume Index |
| `SharpeRatio(Period, Rate, Calc, Cap)` | Manual: `(returns.mean() - rf) / returns.std()` | Manual | Portfolio Sharpe |
| `WRSI(N, Close)` | `pandas_ta.rsi(df["close"], length=N)` | `pandas_ta.rsi()` | Wilder RSI (default) |
| `NewMA(Close, N)` | Manual: Heikin-Ashi + TEMA hybrid | Manual | Hybrid MA |

---

### Table 4 — Strategy Orders

| PowerLanguage | Python | Notes |
|---|---|---|
| `Buy("label") next bar market` | `orders.append(Order(label="label", action=Action.ENTRY, side=Side.LONG, order_type=OrderType.MARKET))` | Append to orders list |
| `SellShort("label") next bar market` | `Order(action=Action.ENTRY, side=Side.SHORT, order_type=OrderType.MARKET)` | `Side.SHORT` for short entry |
| `Sell("label") next bar market` | Close long: `Order(action=Action.EXIT, side=Side.LONG, order_type=OrderType.MARKET)` | **WARNING: PL `Sell` exits a long — do NOT map to `Side.SHORT`** |
| `BuyToCover("label") next bar market` | Close short: `Order(action=Action.EXIT, side=Side.SHORT, order_type=OrderType.MARKET)` | PL `BuyToCover` exits an existing short |
| `Buy("label") next bar at price limit` | `Order(order_type=OrderType.LIMIT, price=price)` | Limit order |
| `Buy("label") next bar at price stop` | `Order(order_type=OrderType.STOP, price=price)` | Stop order |
| `SetStopLoss(dollars)` | `stop_price = entry_price - dollars / (qty * point_value)` | PL takes a dollar amount; Python must convert to price level |
| `SetProfitTarget(dollars)` | `target_price = entry_price + dollars / (qty * point_value)` | Same dollar-to-price conversion |

---

### Table 5 — Plotting

| PowerLanguage | Python | Notes |
|---|---|---|
| `Plot1(value, "label")` | `print(f"{label}: {value}")` or log to file | No chart in Python; output to stdout, `logging` module, or results list |
| `SetPlotColor(1, Red)` | N/A | No visual output; skip or store as metadata |
| `SetPlotWidth(1, 2)` | N/A | Skip |
| `NoPlot(1)` | Skip output for that bar | Conditional: don't append to results |

---

### Table 6 — Control Flow

| PowerLanguage | Python | Notes |
|---|---|---|
| `If cond Then Begin ... End;` | `if cond:` | Direct mapping |
| `If cond Then ... Else ...` | `if cond: ... else: ...` | Direct mapping |
| `For i = 1 to n Begin ... End;` | `for i in range(1, n + 1):` | PL `For` is inclusive; Python `range` excludes upper bound |
| `For i = n DownTo 1 Begin ... End;` | `for i in range(n, 0, -1):` | PL DownTo; Python reversed range |
| `While cond Begin ... End;` | `while cond:` | Direct mapping |
| `Switch (expr) Begin Case 1: ... End;` | `match expr:` with `case 1: ...` | Python 3.10+ `match/case`; no fallthrough (matches PL); PL empty case body is a compile error — use `Value1 = Value1;` as no-op |
| `Once Begin ... End;` | `if not self._once_done: ... self._once_done = True` | Use a bool attribute; PL `Once` runs on first bar only |

---

### Table 7 — Other Built-ins and Features

| PowerLanguage | Python | Notes |
|---|---|---|
| `MarketPosition` | `self.position` (int: −1/0/+1) | Track manually; update on order fills |
| `EntryPrice` | `self.entry_price` (float) | Track manually; set when position opens |
| `CurrentContracts` | `self.current_contracts` (float) | Track manually; absolute contract count |
| `BarsSinceEntry` | `self.bars_since_entry` (int) | Increment each bar while `position != 0`; reset on new entry |
| `Print("text")` | `print("text")` | Direct mapping |
| `#BeginCmtry ... #EndCmtry` | No equivalent | PL expert commentary; skip or log |
| `Alert("msg")` | `print("ALERT: msg", file=sys.stderr)` | No built-in alert; write to stderr or use callback |

---

## Part 2: Semantic Differences and Gotchas

1. **`Sell` does not mean "go short".** In PowerLanguage, `Sell` exits an existing long position. The Python equivalent is closing the position (setting `self.position = 0`). Do not create a new short entry as a translation of `Sell`.

2. **PL is implicitly bar-driven; Python requires an explicit loop.** PowerLanguage executes the entire script top-to-bottom on each bar close automatically. In Python, you must write the `for i in range(len(bars))` loop yourself and call `on_bar()` on each iteration. Forgetting the loop wrapper means the strategy logic runs only once.

3. **Negative indexing is convenient but still needs bounds guarding.** `bars[-2].close` is Pythonic for "previous bar" but raises `IndexError` when `len(bars) < 2`. Guard with `if len(bars) > n` before any lookback access. PL handles this automatically via MaxBarsBack; Python does not.

4. **pandas-ta operates on full Series, not streaming.** Each `on_bar()` call recomputes the indicator on the entire series up to the current bar. This is correct but O(n²) over a backtest. For performance, pre-compute indicators outside the loop or cache results.

5. **NaN values in indicator output.** pandas-ta returns `NaN` for the first `length - 1` bars where the indicator has insufficient history. Always check `pd.notna(value)` or `not math.isnan(value)` before using the result. PL silently returns 0 for insufficient history; Python raises errors or produces silent NaN propagation.

6. **Mutable default arguments are a classic Python trap.** Never write `def __init__(self, buf=[])` — use `None` and assign inside: `self.buf = buf if buf is not None else []`. This doesn't affect PL conversion directly, but catches new Python users.

7. **Python `match` does not fall through.** Unlike C++ `switch`, Python 3.10+ `match/case` has no fallthrough. This matches PL's `Switch/Case` behavior, so the mapping is direct.

8. **Float equality.** Use `math.isclose(a, b)` or `abs(a - b) < 1e-10` instead of `==`. PL uses tolerance-based comparison for `=` on float values; Python `==` on floats is exact bitwise comparison.

9. **No `Value1..Value99` or `Condition1..Condition99`.** These PL pre-declared variables must be replaced with named instance attributes. Use descriptive identifiers like `self.rsi_value` and `self.is_oversold`.

10. **Position state is not tracked automatically.** PL provides `MarketPosition`, `EntryPrice`, `CurrentContracts`, and `BarsSinceEntry` as built-in read-only variables updated by the engine. In Python, you must maintain these as instance attributes and update them manually whenever the execution engine fills an order.

11. **Dollar amounts versus price levels for stops.** `SetStopLoss` and `SetProfitTarget` in PL accept a dollar (currency) amount. Python has no implicit conversion — you must compute the price level manually: `stop_price = entry_price - stop_dollars / (qty * point_value)`.

12. **Multi-data series requires explicit design.** PL `Close of Data2` accesses a second feed bound to the chart. In Python, you must pass a second bar list (`bars2: list[Bar]`) to `on_bar()` or store it as an attribute. There is no implicit secondary-feed mechanism.

13. **No Portfolio Money Management (PMM) equivalent.** PL's PMM allows a single script to govern position sizing across multiple instruments. Python has no built-in portfolio-level abstraction. You must implement cross-instrument logic as a separate orchestrator that calls individual strategy instances.

14. **`datetime.utcfromtimestamp` is deprecated in Python 3.12+.** Use `datetime.fromtimestamp(ts, tz=timezone.utc)` instead to avoid deprecation warnings.

---

## Part 3: Conversion Checklists

### PL → Python Pre-Conversion

- [ ] List every `Inputs:` declaration → `__init__` parameter with default
- [ ] List every `Variables:` declaration → instance attribute in `__init__`
- [ ] Identify `Value1..99` / `Condition1..99` → plan meaningful replacement names
- [ ] Identify all indicator calls → confirm pandas-ta / TA-Lib equivalent exists
- [ ] Locate `Data2`/`Data3` references → plan multi-feed architecture
- [ ] Locate `SetStopLoss`/`SetProfitTarget` → note point value for dollar→price conversion
- [ ] Check `IntraBarPersist` → decide if tick-level behavior matters
- [ ] Identify `.elf` function calls → plan Python function equivalents

### PL → Python Post-Conversion

- [ ] Every `Sell` maps to closing the long, not entering short
- [ ] Every `BuyToCover` maps to closing the short, not entering long
- [ ] All bar lookback accesses guarded with `len(bars) > n`
- [ ] All indicator results checked for `NaN` before use
- [ ] `Crosses Over` / `Crosses Under` implemented as two-bar comparisons
- [ ] `MarketPosition`, `EntryPrice`, `CurrentContracts`, `BarsSinceEntry` tracked as instance attributes
- [ ] Dollar-based stop/target amounts converted to price levels
- [ ] `Value1..99` and `Condition1..99` renamed to descriptive typed attributes
- [ ] Code runs with `python -Wall script.py` with zero errors and zero warnings
- [ ] Strategy back-tested on same instrument/date range; trade count and P&L in same order of magnitude

### Python → PL Pre-Conversion

- [ ] List all `__init__` attributes → categorize: inputs (immutable) vs variables (mutable) vs indicator state
- [ ] Identify all pandas-ta / TA-Lib calls → map each to PL built-in
- [ ] Check for `match` statements with guard clauses → plan PL `Switch` or `If/Else`
- [ ] Identify any libraries beyond pandas-ta/TA-Lib → plan PL equivalents
- [ ] Check for explicit position-tracking attributes → confirm PL built-ins suffice

### Python → PL Post-Conversion

- [ ] Every short entry maps to `SellShort`, not `Sell`
- [ ] Every long close maps to `Sell`, not `SellShort`
- [ ] All `bars[-1-n].close` lookbacks converted to `Close[n]`
- [ ] All manual crossover comparisons converted to PL `Crosses Over` / `Crosses Under`
- [ ] All attributes categorized: immutable → `Inputs:`, mutable → `Variables:`
- [ ] All pandas-ta/TA-Lib calls replaced with PL function calls
- [ ] NaN handling removed (PL handles lookback alignment internally)
- [ ] Price-level stops/targets converted to dollar amounts for `SetStopLoss`/`SetProfitTarget`
- [ ] Script compiled in MultiCharts PowerEditor with zero errors
