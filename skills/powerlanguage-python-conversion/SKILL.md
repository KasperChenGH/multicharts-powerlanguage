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
| `SwingHigh(1, High, L, R)` | Manual: scan for pivot high | Manual: scan for pivot high | No direct library equivalent |
| `SwingLow(1, Low, L, R)` | Manual: scan for pivot low | Manual: scan for pivot low | Same |
| `HighestBar(High, N)` | `highs[-N:].idxmax()` → compute bars ago | `np.argmax(highs[-N:])` | Returns bars ago |
| `LowestBar(Low, N)` | `lows[-N:].idxmin()` → compute bars ago | `np.argmin(lows[-N:])` | Returns bars ago |
| `CountIF(cond, N)` | `cond_series.rolling(N).sum()` | Manual: `sum(1 for ...)` | Count True values |
| `Crosses Over` | `prev_a <= prev_b and a > b` | Same | No built-in; store previous values |
| `Crosses Under` | `prev_a >= prev_b and a < b` | Same | Same |

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
| `Switch (expr) Begin Case 1: ... End;` | `match expr:` with `case 1: ...` | Python 3.10+ `match/case`; no fallthrough (matches PL) |
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
