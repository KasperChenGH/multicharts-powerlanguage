# PowerLanguage ↔ Python Conversion Skill — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add bidirectional PL ↔ Python conversion support — a new skill file and a test file with all 14 strategies converted to Python.

**Architecture:** Single `SKILL.md` following the same 4-part layout as the existing C++ and Rust conversion skills (Part 0: scaffold, Part 1: concept mapping tables, Part 2: semantic gotchas, Part 3: checklists). Test file mirrors `test_cpp_from_pl.txt` / `test_rust_from_pl.txt` with Python conversions of all 14 strategies from `test_strategies.txt`.

**Tech Stack:** Python 3.10+, `pandas-ta` (primary TA library), `talib` (alternative), `dataclasses`, `abc`, `enum`, `datetime`.

---

## File Map

| Action | Path | Purpose |
|---|---|---|
| Create | `skills/powerlanguage-python-conversion/SKILL.md` | Conversion skill (4 parts) |
| Create | `tests/test_python_from_pl.txt` | 14 strategy conversions in Python |
| Modify | `scripts/tests/Skill-Frontmatter.Tests.ps1` | Add frontmatter test for new skill |

---

### Task 1: Create SKILL.md — frontmatter + Part 0 (structural template)

**Files:**
- Create: `skills/powerlanguage-python-conversion/SKILL.md`

- [ ] **Step 1: Create directory and SKILL.md with frontmatter + Part 0**

The frontmatter MUST satisfy the Pester validator in `scripts/lib/Test-Frontmatter.psm1`:
- `name:` must equal the folder name (`powerlanguage-python-conversion`)
- `description:` must start with `Use when`

Write `skills/powerlanguage-python-conversion/SKILL.md` with this content:

~~~markdown
---
name: powerlanguage-python-conversion
description: >-
  Use when converting, translating, porting, or migrating code between
  MultiCharts PowerLanguage and Python, in either direction. Contains a
  lightweight Strategy ABC scaffold, concept mapping tables, semantic
  difference documentation, and pre/post-conversion checklists. References
  powerlanguage-syntax for PowerLanguage-specific details. Recommends
  pandas-ta as the primary indicator library with TA-Lib as an alternative.
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
~~~

- [ ] **Step 2: Verify frontmatter passes the validator**

Run:
```powershell
Import-Module scripts/lib/Test-Frontmatter.psm1 -Force
$r = Test-SkillFrontmatter "skills/powerlanguage-python-conversion/SKILL.md"
$r.Valid  # must be True
$r.Name   # must be 'powerlanguage-python-conversion'
```

Expected: `True` and `powerlanguage-python-conversion`.

- [ ] **Step 3: Commit**

```
git add skills/powerlanguage-python-conversion/SKILL.md
git commit -m "feat: add powerlanguage-python-conversion skill — Part 0 scaffold"
```

---

### Task 2: Add Part 1 — Concept Mapping Tables

**Files:**
- Modify: `skills/powerlanguage-python-conversion/SKILL.md`

- [ ] **Step 1: Append Part 1 after the Part 0 section**

Append the following after the last line of Part 0 (after the main loop explanation). Use the Edit tool to insert before the end of file. Reference `skills/powerlanguage-rust-conversion/SKILL.md` and `skills/powerlanguage-cpp-conversion/SKILL.md` for the exact table structure — Python tables follow the same 7-table layout.

Key mappings for each table:

**Table 1 — Declarations:**

| PowerLanguage | Python | Notes |
|---|---|---|
| `Inputs: Length(20)` | `__init__` parameter with default: `def __init__(self, length: int = 20)` | Stored as `self.length`; treat as read-only after construction |
| `Variables: myVar(0)` | `self.my_var = 0.0` in `__init__` | Mutable instance attributes |
| `Value1` .. `Value99` | Named attribute (e.g., `self.rsi_val`) | Must rename to meaningful identifiers; Python has no pre-declared variables |
| `Condition1` .. `Condition99` | Named attribute (e.g., `self.is_oversold`) | Same: rename to typed `bool` attributes |
| `Arrays: buf[10](0)` | `self.buf = [0.0] * 11` | PL `[10]` means last index is 10 (11 elements); use a Python `list` |
| `IntraBarPersist myVar(0)` | `self.my_var = 0.0` (same as Variables) | Python has no bar-close vs intra-bar distinction; all instance attributes persist |

**Table 2 — Data Access:**

| PowerLanguage | Python | Notes |
|---|---|---|
| `Open`, `High`, `Low`, `Close`, `Volume` | `bars[-1].open`, `.high`, `.low`, `.close`, `.volume` | `bars[-1]` for current bar |
| `Close[1]` | `bars[-2].close` | Lookback N: `bars[-1 - n].close`. Guard with `len(bars) > n`. |
| `Close of Data2` | separate `bars2: list[Bar]` parameter | PL Data2 is a second chart feed; pass a second list to `on_bar()` |
| `Date` | `datetime.utcfromtimestamp(bars[-1].time)` → `.year`, `.month`, `.day` | PL `Date` is YYYMMDD integer; Python uses `datetime` module |
| `Time` | `datetime.utcfromtimestamp(bars[-1].time)` → `.hour * 100 + .minute` | PL `Time` is HHMM integer |
| `BarNumber` / `CurrentBar` | `bars[-1].bar_number` or `len(bars)` | PL is 1-based |

**Table 3 — Technical Indicators (dual-library):**

Show two columns: pandas-ta (primary) and TA-Lib (alternative). Cover all indicators used in strategies 1-14:

| PowerLanguage | pandas-ta | TA-Lib | Notes |
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
| `PercentR(N)` | `ta.willr(highs, lows, closes, length=N)` | `talib.WILLR(highs, lows, closes, timeperiod=N)` | Returns -100..0 range |
| `RateOfChange(Close, N)` | `ta.roc(closes, length=N)` | `talib.ROC(closes, timeperiod=N)` | |
| `Volatility(N)` | `ta.stdev(closes, length=N)` | `talib.STDDEV(closes, timeperiod=N)` | Approximation |
| `StandardDev(Close, N, 1)` | `ta.stdev(closes, length=N)` | `talib.STDDEV(closes, timeperiod=N, nbdev=1)` | |
| `TrueRange` | `ta.true_range(highs, lows, closes)` | `talib.TRANGE(highs, lows, closes)` | Per-bar, no period |
| `MoneyFlow(N)` | `ta.mfi(highs, lows, closes, volumes, length=N)` | `talib.MFI(highs, lows, closes, volumes, timeperiod=N)` | Requires HLCV |
| `AccumDist(N)` | `ta.ad(highs, lows, closes, volumes)` | `talib.AD(highs, lows, closes, volumes)` | Cumulative, no period |
| `LinearRegValue(Close, N, 0)` | `ta.linreg(closes, length=N)` | `talib.LINEARREG(closes, timeperiod=N)` | |
| `LinearRegSlope(Close, N)` | `ta.linreg(closes, length=N, offset=0) - ta.linreg(closes, length=N, offset=1)` | `talib.LINEARREG_SLOPE(closes, timeperiod=N)` | |
| `Summation(Close, N)` | `closes.rolling(N).sum()` | `talib.SUM(closes, timeperiod=N)` | |
| `Cum(Volume)` | `volumes.cumsum()` | Manual: `np.cumsum(volumes)` | Running total |
| `WAverage(Close, N)` | `ta.wma(closes, length=N)` | `talib.WMA(closes, timeperiod=N)` | |
| `MidPoint(Close, N)` | `ta.midpoint(closes, length=N)` | `talib.MIDPOINT(closes, timeperiod=N)` | |
| `SwingHigh(1, High, L, R)` | Manual: scan for pivot high | Manual: scan for pivot high | No direct pandas-ta/TA-Lib equivalent |
| `SwingLow(1, Low, L, R)` | Manual: scan for pivot low | Manual: scan for pivot low | Same |
| `HighestBar(High, N)` | `highs[-N:].idxmax()` → compute bars ago | Manual: `np.argmax(highs[-N:])` | Returns bars ago |
| `LowestBar(Low, N)` | `lows[-N:].idxmin()` → compute bars ago | Manual: `np.argmin(lows[-N:])` | Returns bars ago |
| `CountIF(cond, N)` | `cond_series.rolling(N).sum()` | Manual: `sum(1 for ...)` | Count True values |
| `Crosses Over` | `prev_a <= prev_b and a > b` | Same | No built-in; store previous values |
| `Crosses Under` | `prev_a >= prev_b and a < b` | Same | Same |

**Tables 4-7:** Follow the identical structure from the C++/Rust skills (Strategy Orders, Plotting, Control Flow, Other Built-ins). Adapt the code examples to Python syntax. Key differences from C++/Rust:
- Orders: `orders.append(Order(label="X", action=Action.ENTRY, side=Side.LONG, order_type=OrderType.MARKET))`
- Control flow: `if`/`for`/`while`/`match` (Python 3.10+ `match` for PL `Switch`)
- `Once Begin...End` → `if not self._once_done: ... self._once_done = True`
- `Print(...)` → `print(...)`
- `Alert(...)` → `print(f"ALERT: ...", file=sys.stderr)`

- [ ] **Step 2: Commit**

```
git add skills/powerlanguage-python-conversion/SKILL.md
git commit -m "feat: add Part 1 concept mapping tables to Python conversion skill"
```

---

### Task 3: Add Part 2 (Semantic Gotchas) + Part 3 (Checklists)

**Files:**
- Modify: `skills/powerlanguage-python-conversion/SKILL.md`

- [ ] **Step 1: Append Part 2 — Semantic Differences and Gotchas**

Model after Part 2 in `skills/powerlanguage-rust-conversion/SKILL.md` (14 items) and `skills/powerlanguage-cpp-conversion/SKILL.md` (12 items). Include the same universal gotchas (Sell ≠ go short, explicit bar loop, position state not automatic, dollar vs price for stops, no Value1..99, multi-data, no PMM) plus these Python-specific items:

1. **`Sell` does not mean "go short."** Same as C++/Rust.
2. **PL is implicitly bar-driven; Python requires an explicit loop.** Same pattern.
3. **Negative indexing is convenient but still needs bounds guarding.** `bars[-2].close` is Pythonic for "previous bar" but raises `IndexError` when `len(bars) < 2`. Guard with `if len(bars) > n` before lookback.
4. **pandas-ta operates on full Series, not streaming.** Each `on_bar()` call recomputes the indicator on the entire series up to the current bar. This is correct but O(n²) over a backtest. For performance, pre-compute indicators outside the loop or cache results.
5. **NaN values in indicator output.** pandas-ta returns `NaN` for the first `length - 1` bars where the indicator has insufficient history. Always check `pd.notna(value)` or `not math.isnan(value)` before using the result. PL silently returns 0 for insufficient history; Python raises errors or produces silent NaN propagation.
6. **Mutable default arguments are a classic Python trap.** Never write `def __init__(self, buf=[])` — use `None` and assign inside: `self.buf = buf if buf is not None else []`. This doesn't affect PL conversion directly, but catches new Python users.
7. **Python `match` does not fall through.** Unlike C++ `switch`, Python 3.10+ `match/case` has no fallthrough. This matches PL's `Switch/Case` behavior, so the mapping is direct.
8. **Float equality.** Same concern as Rust. Use `math.isclose(a, b)` or `abs(a - b) < 1e-10` instead of `==`.
9. **No `Value1..Value99` or `Condition1..Condition99`.** Replace with named instance attributes.
10. **Position state is not tracked automatically.** Same as C++/Rust.
11. **Dollar amounts versus price levels for stops.** Same as C++/Rust.
12. **Multi-data series requires explicit design.** Same as C++/Rust.
13. **No Portfolio Money Management equivalent.** Same as C++/Rust.
14. **`datetime.utcfromtimestamp` is deprecated in Python 3.12+.** Use `datetime.fromtimestamp(ts, tz=timezone.utc)` instead.

- [ ] **Step 2: Append Part 3 — Conversion Checklists**

Four checklists, mirroring the C++/Rust skill structure:

**PL → Python Pre-Conversion:**
- List every `Inputs:` declaration → `__init__` parameter with default
- List every `Variables:` declaration → instance attribute
- Identify `Value1..99` / `Condition1..99` → plan meaningful replacement names
- Identify all indicator calls → confirm pandas-ta / TA-Lib equivalent exists
- Locate `Data2`/`Data3` references → plan multi-feed architecture
- Locate `SetStopLoss`/`SetProfitTarget` → note point value for dollar→price
- Check `IntraBarPersist` → decide if tick-level behavior matters
- Identify `.elf` function calls → plan Python function equivalents

**PL → Python Post-Conversion:**
- Every `Sell` maps to closing the long, not entering short
- Every `BuyToCover` maps to closing the short, not entering long
- All bar lookback accesses guarded with `len(bars) > n`
- All indicator results checked for `NaN` before use
- `Crosses Over` / `Crosses Under` implemented as two-bar comparisons
- `MarketPosition`, `EntryPrice`, `CurrentContracts`, `BarsSinceEntry` tracked as instance attributes
- Dollar-based stop/target amounts converted to price levels
- `Value1..99` and `Condition1..99` renamed to descriptive typed attributes
- Code runs with `python -Wall script.py` with zero errors and zero warnings
- Strategy back-tested on same instrument/date range; trade count and P&L in same order of magnitude

**Python → PL Pre-Conversion:**
- List all `__init__` attributes → categorize: inputs (immutable) vs variables (mutable) vs indicator state
- Identify all pandas-ta / TA-Lib calls → map each to PL built-in
- Check for `match` statements with guard clauses → plan PL `Switch` or `If/Else`
- Identify any libraries beyond pandas-ta/TA-Lib → plan PL equivalents
- Check for explicit position-tracking attributes → confirm PL built-ins suffice

**Python → PL Post-Conversion:**
- Every short entry maps to `SellShort`, not `Sell`
- Every long close maps to `Sell`, not `SellShort`
- All `bars[-1-n].close` lookbacks converted to `Close[n]`
- All manual crossover comparisons converted to PL `Crosses Over` / `Crosses Under`
- All attributes categorized: immutable → `Inputs:`, mutable → `Variables:`
- All pandas-ta/TA-Lib calls replaced with PL function calls
- NaN handling removed (PL handles lookback alignment internally)
- Price-level stops/targets converted to dollar amounts for `SetStopLoss`/`SetProfitTarget`
- Script compiled in MultiCharts PowerEditor with zero errors

- [ ] **Step 3: Commit**

```
git add skills/powerlanguage-python-conversion/SKILL.md
git commit -m "feat: add Part 2 gotchas and Part 3 checklists to Python conversion skill"
```

---

### Task 4: Add Pester frontmatter test for new skill

**Files:**
- Modify: `scripts/tests/Skill-Frontmatter.Tests.ps1:27-43`

- [ ] **Step 1: Add a test case for the Python conversion skill**

In the `Context 'happy path against real skill files'` block (line 27), add after the existing three `It` blocks:

```powershell
    It 'powerlanguage-python-conversion has valid frontmatter' {
      $r = Test-SkillFrontmatter "$repoRoot/skills/powerlanguage-python-conversion/SKILL.md"
      $r.Valid | Should -BeTrue -Because $r.Reason
      $r.Name  | Should -Be 'powerlanguage-python-conversion'
    }
```

- [ ] **Step 2: Run the Pester frontmatter tests**

Run:
```powershell
Invoke-Pester scripts/tests/Skill-Frontmatter.Tests.ps1 -Output Detailed
```

Expected: All tests pass including the new one.

- [ ] **Step 3: Commit**

```
git add scripts/tests/Skill-Frontmatter.Tests.ps1
git commit -m "test: add Pester frontmatter test for Python conversion skill"
```

---

### Task 5: Write test_python_from_pl.txt — Strategies 1-7

**Files:**
- Create: `tests/test_python_from_pl.txt`

- [ ] **Step 1: Write the test file header and strategies 1-7**

Create `tests/test_python_from_pl.txt`. Follow the exact style of `tests/test_cpp_from_pl.txt` and `tests/test_rust_from_pl.txt`:
- File header block explaining dependencies (`pandas-ta`, `talib`), the Strategy ABC, and the Order dataclass
- Each strategy is a self-contained class inheriting from `Strategy`
- Separator lines (`# ====...====`) between strategies
- Conversion notes comment block mapping each PL function to its Python equivalent
- `# END STRATEGY N` markers

The source PL for each strategy is in `tests/test_strategies.txt`. Convert strategies 1-7:

- **S1 (MA Crossover):** `pandas-ta` `ta.sma()` on `pd.Series` of closes. Crossover via `prev_fast <= prev_slow and fast > slow`.
- **S2 (RSI + ATR Stop):** `ta.rsi()`, `ta.atr()`. Position detection via `self.position != self.prev_position`.
- **S3 (BB Breakout + Volume):** `ta.bbands()` returns DataFrame with upper/lower columns. `ta.sma()` on volume.
- **S4 (Multi-Indicator + Risk Mgmt):** `ta.adx()`, `ta.cci()`. SetStopLoss/SetProfitTarget/SetBreakEven as explicit Order objects with `Action.STOP_LOSS` / `Action.PROFIT_TARGET` / `Action.BREAK_EVEN`.
- **S5 (Multi-Data Regime):** `on_bar_multi(self, bars, bars2, orders)` method. `ta.sma()` on bars2 closes, `ta.rsi()` on primary closes.
- **S6 (EMA Momentum + Limit + Time Exit):** `ta.ema()`, `ta.mom()`. `Once` → `if not self._once_done`. `BarsSinceEntry` manual tracking. Limit order via `OrderType.LIMIT`.
- **S7 (Donchian Channel):** `highs.rolling(20).max()`, `lows.rolling(20).min()`. `[1]` bar ref → previous bar's channel values.

Indicator computation pattern for each strategy:

```python
closes = pd.Series([b.close for b in bars])
highs = pd.Series([b.high for b in bars])
lows = pd.Series([b.low for b in bars])
volumes = pd.Series([b.volume for b in bars])
```

Then call `ta.sma(closes, length=N)`, read `.iloc[-1]` for current value, `.iloc[-2]` for previous.

- [ ] **Step 2: Commit**

```
git add tests/test_python_from_pl.txt
git commit -m "test: add Python conversions of PL strategies 1-7"
```

---

### Task 6: Append test_python_from_pl.txt — Strategies 8-14

**Files:**
- Modify: `tests/test_python_from_pl.txt`

- [ ] **Step 1: Append strategies 8-14**

Continue the file with:

- **S8 (MACD + Trailing Stop):** `ta.macd()` returns DataFrame. Signal line is the signal column. `ta.atr()` for trailing stop distance. Trailing ratchet: `self.trail_stop = max(self.trail_stop, close - 3 * atr)`.
- **S9 (Stochastic + Switch + Array + For):** `ta.stoch()`. Python `match self.position:` for Switch. `self.k_history = [0.0] * 5` for array. `for i in range(4, 0, -1):` for `For Value2 = 4 DownTo 1`.
- **S10 (While + Date/Time + Print/Alert):** `while` loop counting consecutive up bars. `datetime.utcfromtimestamp()` for time filter. `print()` for Print, `print(..., file=sys.stderr)` for Alert.
- **S11 (DMI + Keltner + SAR):** `ta.dm()` for DMI+/DMI-. `ta.adx()` for ADX. `ta.kc()` for Keltner Channel. `ta.psar()` for Parabolic SAR.
- **S12 (Williams %R + ROC + Vol + StdDev):** `ta.willr()`, `ta.roc()`, `ta.stdev()`, `ta.true_range()`. `range_val = bar.high - bar.low` for Range.
- **S13 (MFI + AccumDist + LinReg + WAverage):** `ta.mfi()`, `ta.ad()`, `ta.linreg()`, `closes.rolling(10).sum()`, `volumes.cumsum()`, `ta.wma()`, `ta.midpoint()`.
- **S14 (Swing + HighestBar + CountIF + Prices):** Manual swing detection (same logic as C++/Rust). `np.argmax()` for HighestBar. Count up-closes in loop. `(o+h+l+c)/4` for AvgPrice, `(h+l+c)/3` for TypicalPrice.

- [ ] **Step 2: Verify all 14 strategy markers present**

Run:
```powershell
Select-String -Path tests/test_python_from_pl.txt -Pattern 'STRATEGY \d+' | Measure-Object | Select-Object -ExpandProperty Count
```

Expected: 28 (14 start markers + 14 end markers).

- [ ] **Step 3: Verify order labels match test_strategies.txt**

Run:
```powershell
(Select-String -Path tests/test_python_from_pl.txt -Pattern '"S\d+_[A-Z]+"' -AllMatches).Matches.Value | Sort-Object -Unique
```

Compare against:
```powershell
(Select-String -Path tests/test_strategies.txt -Pattern '"S\d+_[A-Z]+"' -AllMatches).Matches.Value | Sort-Object -Unique
```

The Python file should contain all labels from the PL file, plus the risk management labels (S4_SL, S4_TP, S4_BE) that map from SetStopLoss/SetProfitTarget/SetBreakEven.

- [ ] **Step 4: Commit**

```
git add tests/test_python_from_pl.txt
git commit -m "test: add Python conversions of PL strategies 8-14"
```

---

### Task 7: Run full Pester suite and final commit

**Files:** None (verification only)

- [ ] **Step 1: Run full Pester suite**

Run:
```powershell
Invoke-Pester scripts/tests -Output Detailed
```

Expected: All tests pass (67 total — the original 66 plus the new frontmatter test).

- [ ] **Step 2: Verify final file inventory**

Run:
```powershell
git status --short
```

Expected modified/new files:
- `skills/powerlanguage-python-conversion/SKILL.md` (new)
- `tests/test_python_from_pl.txt` (new)
- `scripts/tests/Skill-Frontmatter.Tests.ps1` (modified)

No other files should be changed.
