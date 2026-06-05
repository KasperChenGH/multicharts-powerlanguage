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
