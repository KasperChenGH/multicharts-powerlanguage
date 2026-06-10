# multicharts-powerlanguage

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Version](https://img.shields.io/badge/version-0.4.0-blue.svg)](https://github.com/KasperChenGH/multicharts-powerlanguage)
[![Claude Code Plugin](https://img.shields.io/badge/Claude_Code-plugin-blueviolet.svg)](https://github.com/KasperChenGH/multicharts-powerlanguage)

A Claude Code plugin for [MultiCharts](https://www.multicharts.com/) PowerLanguage — gives Claude expert knowledge of PowerLanguage syntax, 947 keywords, 160 functions (150 built-in + 10 custom), and bidirectional code conversion to [TradingView Pine Script](https://www.tradingview.com/), Python, Rust, and C++.

**947 keywords · 160 functions · 10 auto-activating skills · 4 conversion targets**

---

## Install

```bash
claude /plugin marketplace add KasperChenGH/multicharts-powerlanguage
claude /plugin install multicharts-powerlanguage@multicharts-powerlanguage-dev
```

All 10 skills auto-trigger when relevant — no manual invocation needed. Works on Windows, macOS, and Linux.

---

## How to use

After installing, just talk to Claude naturally. The plugin activates automatically when your question involves PowerLanguage, Pine Script, or code conversion — no special commands needed.

### Ask about PowerLanguage syntax

```
You: What's the difference between EntryPrice and OpenEntryPrice in MultiCharts?

You: How do I declare an array in PowerLanguage?

You: What parameters does the Stochastic function take?
```

### Generate PowerLanguage code

```
You: Write a signal that buys when RSI crosses below 30 and sells when it crosses above 70

You: Create an indicator that plots Bollinger Bands with a 20-period SMA and 2 standard deviations

You: Write a function that calculates the Sharpe ratio
```

### Convert code between languages

```
You: Convert this PowerLanguage signal to Pine Script:
     [paste your code]

You: Translate this Pine Script strategy to Python using pandas-ta:
     [paste your code]

You: Port this PowerLanguage indicator to Rust
```

### Ask about Pine Script

```
You: How does request.security() work in Pine Script?

You: What's the difference between var and varip?

You: Write a Pine Script indicator that shows RSI with overbought/oversold zones
```

### Debug and review

```
You: Why is this PowerLanguage signal giving me a compile error?
     [paste your code]

You: Review this strategy for common PowerLanguage gotchas
```

---

## Examples

### Code generation

> Write a MultiCharts signal that enters long when RSI crosses below 30 and exits when it crosses above 70, with a 2% stop loss.

```pascal
Inputs:
    RSI_Length(14),
    Oversold(30),
    Overbought(70),
    StopLossPct(2);

Variables:
    MyRSI(0);

MyRSI = RSI(Close, RSI_Length);

If MyRSI Crosses Below Oversold Then
    Buy ("RSI Long") Next Bar at Market;

If MyRSI Crosses Above Overbought Then
    Sell ("RSI Exit") Next Bar at Market;

SetStopLoss(StopLossPct * 0.01 * EntryPrice);
```

### Code conversion (quick)

> Convert this to Python / Rust / C++ / Pine Script

```pascal
Buy ("Entry") 1 Contract Next Bar at Market;
```

| Target | Output |
|---|---|
| Pine Script | `strategy.entry("Entry", strategy.long, qty=1)` |
| Python | `orders.append(Order("Entry", Side.LONG, OrderType.MARKET, 1))` |
| Rust | `orders.push(Order { label: "Entry", side: Side::Long, order_type: OrderType::Market, qty: 1 })` |
| C++ | `orders.push_back({"Entry", Side::Long, OrderType::Market, 1});` |

### Full conversion example

The following PowerLanguage strategy buys when a fast EMA crosses above a slow EMA, sells on the reverse cross, and uses an ATR-based trailing stop. Below it is the same logic in all four conversion targets.

#### PowerLanguage (source)

```pascal
Inputs:
    FastLen(9),
    SlowLen(21),
    ATRLen(14),
    TrailMult(2.0);

Variables:
    fastMA(0),
    slowMA(0),
    atrVal(0),
    trailStop(0);

fastMA = AverageFC(Close, FastLen);
slowMA = AverageFC(Close, SlowLen);
atrVal = AvgTrueRange(ATRLen);

If fastMA Crosses Over slowMA Then
    Buy ("EMA Cross") Next Bar at Market;

If fastMA Crosses Under slowMA Then
    Sell ("EMA Exit") Next Bar at Market;

If MarketPosition = 1 Then Begin
    trailStop = Highest(High, 10) - TrailMult * atrVal;
    Sell ("Trail") Next Bar at trailStop Stop;
End;
```

#### Pine Script

```pine
//@version=5
strategy("EMA Cross + ATR Trail", overlay=true,
         initial_capital=10000, default_qty_type=strategy.fixed, default_qty_value=1)

fastLen   = input.int(9,   "Fast EMA")
slowLen   = input.int(21,  "Slow EMA")
atrLen    = input.int(14,  "ATR Length")
trailMult = input.float(2.0, "Trail Multiplier")

fastMA = ta.ema(close, fastLen)
slowMA = ta.ema(close, slowLen)
atrVal = ta.atr(atrLen)

if ta.crossover(fastMA, slowMA)
    strategy.entry("EMA Cross", strategy.long)

if ta.crossunder(fastMA, slowMA)
    strategy.close("EMA Cross", comment="EMA Exit")

if strategy.position_size > 0
    trailStop = ta.highest(high, 10) - trailMult * atrVal
    strategy.exit("Trail", from_entry="EMA Cross", stop=trailStop)

plot(fastMA, "Fast EMA", color=color.blue)
plot(slowMA, "Slow EMA", color=color.orange)
```

#### Python (pandas-ta)

```python
import pandas as pd
import pandas_ta as ta

class EMACrossTrail:
    def __init__(self, fast=9, slow=21, atr_len=14, trail_mult=2.0):
        self.fast = fast
        self.slow = slow
        self.atr_len = atr_len
        self.trail_mult = trail_mult
        self.position = 0  # 1 = long, 0 = flat

    def run(self, df: pd.DataFrame) -> pd.DataFrame:
        df["fast_ma"] = ta.ema(df["close"], length=self.fast)
        df["slow_ma"] = ta.ema(df["close"], length=self.slow)
        df["atr"]     = ta.atr(df["high"], df["low"], df["close"], length=self.atr_len)

        signals = []
        for i in range(1, len(df)):
            signal = None
            fast_prev, fast_curr = df["fast_ma"].iloc[i - 1], df["fast_ma"].iloc[i]
            slow_prev, slow_curr = df["slow_ma"].iloc[i - 1], df["slow_ma"].iloc[i]

            # EMA crossover → buy
            if fast_prev <= slow_prev and fast_curr > slow_curr and self.position == 0:
                self.position = 1
                signal = "BUY"

            # EMA crossunder → sell
            elif fast_prev >= slow_prev and fast_curr < slow_curr and self.position == 1:
                self.position = 0
                signal = "SELL"

            # ATR trailing stop
            elif self.position == 1:
                trail = df["high"].iloc[max(0, i - 9):i + 1].max() - self.trail_mult * df["atr"].iloc[i]
                if df["close"].iloc[i] < trail:
                    self.position = 0
                    signal = "TRAIL_STOP"

            signals.append(signal)

        df["signal"] = [None] + signals
        return df
```

#### Rust (ta-rs)

```rust
use ta::indicators::ExponentialMovingAverage;
use ta::indicators::AverageTrueRange;
use ta::Next;

struct EmaCrossTrail {
    fast_ema: ExponentialMovingAverage,
    slow_ema: ExponentialMovingAverage,
    atr: AverageTrueRange,
    trail_mult: f64,
    position: i32, // 1 = long, 0 = flat
    prev_fast: f64,
    prev_slow: f64,
    highs: Vec<f64>,
}

impl EmaCrossTrail {
    fn new(fast: usize, slow: usize, atr_len: usize, trail_mult: f64) -> Self {
        Self {
            fast_ema: ExponentialMovingAverage::new(fast).unwrap(),
            slow_ema: ExponentialMovingAverage::new(slow).unwrap(),
            atr: AverageTrueRange::new(atr_len).unwrap(),
            trail_mult,
            position: 0,
            prev_fast: 0.0,
            prev_slow: 0.0,
            highs: Vec::new(),
        }
    }

    fn on_bar(&mut self, high: f64, low: f64, close: f64) -> Option<&str> {
        let fast = self.fast_ema.next(close);
        let slow = self.slow_ema.next(close);
        let atr_val = self.atr.next((high, low, close));
        self.highs.push(high);

        let signal = if self.prev_fast <= self.prev_slow && fast > slow && self.position == 0 {
            self.position = 1;
            Some("BUY")
        } else if self.prev_fast >= self.prev_slow && fast < slow && self.position == 1 {
            self.position = 0;
            Some("SELL")
        } else if self.position == 1 {
            let lookback = self.highs.len().saturating_sub(10);
            let highest: f64 = self.highs[lookback..].iter().copied()
                .fold(f64::NEG_INFINITY, f64::max);
            let trail = highest - self.trail_mult * atr_val;
            if close < trail {
                self.position = 0;
                Some("TRAIL_STOP")
            } else {
                None
            }
        } else {
            None
        };

        self.prev_fast = fast;
        self.prev_slow = slow;
        signal
    }
}
```

#### C++ (TA-Lib)

```cpp
#include <vector>
#include <string>
#include <algorithm>
#include "ta-lib/ta_libc.h"

class EmaCrossTrail {
    int fast_, slow_, atr_len_;
    double trail_mult_;
    int position_ = 0; // 1 = long, 0 = flat

public:
    EmaCrossTrail(int fast, int slow, int atr_len, double trail_mult)
        : fast_(fast), slow_(slow), atr_len_(atr_len), trail_mult_(trail_mult) {}

    std::vector<std::string> run(
        const std::vector<double>& high,
        const std::vector<double>& low,
        const std::vector<double>& close)
    {
        int n = static_cast<int>(close.size());
        std::vector<double> fast_ma(n), slow_ma(n), atr(n);
        int begin_idx, out_count;

        TA_EMA(0, n - 1, close.data(), fast_, &begin_idx, &out_count, fast_ma.data());
        TA_EMA(0, n - 1, close.data(), slow_, &begin_idx, &out_count, slow_ma.data());
        TA_ATR(0, n - 1, high.data(), low.data(), close.data(),
               atr_len_, &begin_idx, &out_count, atr.data());

        std::vector<std::string> signals(n);
        for (int i = 1; i < n; ++i) {
            // EMA crossover → buy
            if (fast_ma[i - 1] <= slow_ma[i - 1] && fast_ma[i] > slow_ma[i]
                && position_ == 0) {
                position_ = 1;
                signals[i] = "BUY";
            }
            // EMA crossunder → sell
            else if (fast_ma[i - 1] >= slow_ma[i - 1] && fast_ma[i] < slow_ma[i]
                     && position_ == 1) {
                position_ = 0;
                signals[i] = "SELL";
            }
            // ATR trailing stop
            else if (position_ == 1) {
                int start = std::max(0, i - 9);
                double highest = *std::max_element(high.begin() + start, high.begin() + i + 1);
                double trail = highest - trail_mult_ * atr[i];
                if (close[i] < trail) {
                    position_ = 0;
                    signals[i] = "TRAIL_STOP";
                }
            }
        }
        return signals;
    }
};

---

## Skills overview

### PowerLanguage knowledge

| Skill | Description |
|---|---|
| `multicharts-fundamentals` | Script types (Indicator / Signal / Function), execution model, multi-data series, order keywords |
| `powerlanguage-syntax` | Declarations, `begin/end` semicolon rule, control flow, bar references, 160 function signatures (150 built-in + 10 custom), code-generation gotchas |
| `powerlanguage-keywords-reference` | 947 keywords across 40 categories — signature, parameters, description, and wiki link for each |

### Target language reference

| Skill | Description |
|---|---|
| `pinescript-core` | Pine Script fundamentals — versioning, script types, type system, declarations, control flow, UDFs/UDTs, gotchas |
| `pinescript-builtins` | Pine Script built-in namespaces — `ta.*`, `strategy.*`, `request.*`, `math.*`, `str.*`, `array.*`, `color.*`, bar state, time |
| `pinescript-visual` | Pine Script plotting and drawing — `plot()`, `label.*`, `line.*`, `box.*`, `table.*`, `map.*`, `matrix.*`, `log.*`, alerts |

### Code conversion

All four converters follow the same structure:

| Part | Contents |
|---|---|
| Part 0 | Target-language scaffold — types, entry point, main loop |
| Part 1 | Concept mapping tables — indicators, order types, data access |
| Part 2 | Semantic gotchas specific to the target language |
| Part 3 | Pre/post-conversion checklists in both directions |

| Skill | Target | Scaffold | Indicator library |
|---|---|---|---|
| `powerlanguage-pinescript-conversion` | Pine Script | `strategy()` | `ta.*` built-ins |
| `powerlanguage-python-conversion` | Python | `Strategy(ABC)` + `on_bar` | pandas-ta (primary), TA-Lib (alt) |
| `powerlanguage-rust-conversion` | Rust | `Strategy` trait + `on_bar` | ta-rs (streaming) |
| `powerlanguage-cpp-conversion` | C++ | `Strategy` base class + `on_bar` | TA-Lib (batch) |

---

### Custom functions

10 commonly available `f_*` function studies that ship with many MultiCharts installations. These are **not** built-in keywords — they require the corresponding function study in your PowerLanguage Editor. If missing, create the function study and paste the implementation (source available in the MultiCharts `StudyServer` directory).

| Function | Signature | Description |
|---|---|---|
| `StochRSI` | `StochRSI(Price, RSILen, Length)` | Stochastic of RSI (0–1) |
| `supertrend` | `supertrend(ATRLen, Mult)` | ATR-based trend line |
| `NVI` | `NVI(StartValue)` | Negative Volume Index |
| `PVI` | `PVI(StartValue)` | Positive Volume Index |
| `Coppo` | `Coppo(N1, N2, N3)` | Coppock Curve (WMA of two ROCs) |
| `LWTI` | `LWTI(Price, Period, Length)` | Larry Williams Trading Index |
| `TVI` | `TVI(Price, Vol, MinTickValue)` | Trade Volume Index |
| `SharpeRatio` | `SharpeRatio(Period, IntRate, CalculateRatio, InitCapital)` | Portfolio-level Sharpe Ratio |
| `WRSI` | `WRSI(Length, Price)` | Wilder RSI (session-reset variant) |
| `NewMA` | `NewMA(Price, Length)` | Heikin-Ashi TEMA hybrid MA |

---

## How it works

Skills are markdown files with YAML frontmatter (`name` and `description`). Claude reads each skill's description and activates it on the fly based on what you're asking. No install-time scripts, no runtime hooks, no platform-specific tooling.

---

## Project structure

```
multicharts-powerlanguage/
├── .claude-plugin/
│   ├── plugin.json                        # plugin metadata
│   └── marketplace.json                   # marketplace registry
├── skills/
│   ├── multicharts-fundamentals/          # platform fundamentals
│   ├── powerlanguage-syntax/              # language syntax + built-ins
│   ├── powerlanguage-keywords-reference/  # 947 keywords (40 categories)
│   │   ├── SKILL.md
│   │   └── details/                       # 40 category folders
│   ├── pinescript-core/                   # Pine Script fundamentals
│   ├── pinescript-builtins/               # Pine Script built-in namespaces
│   ├── pinescript-visual/                 # Pine Script plotting & drawing
│   ├── powerlanguage-pinescript-conversion/
│   ├── powerlanguage-python-conversion/
│   ├── powerlanguage-rust-conversion/
│   └── powerlanguage-cpp-conversion/
├── tests/                                 # 19 compile-test files
├── scripts/
│   ├── lib/                               # 8 PowerShell build modules
│   └── tests/                             # 11 Pester test files (189 tests)
├── package.json
├── NOTICE
└── LICENSE
```

---

<details>
<summary><strong>Testing (maintainer only)</strong></summary>

### Automated tests (Pester)

```powershell
Invoke-Pester scripts/tests/ -Output Detailed
```

11 test files, 189 tests — frontmatter validation, metadata consistency, keyword parsing, paraphrase quality, build pipeline, custom function consistency.

### Manual compile tests

19 plain-text files in `tests/` exercise keywords and conversion patterns. PowerLanguage files use unreachable `If False Then Begin … End;` blocks so the compiler checks syntax without executing.

**Keyword coverage (8 files):**

| File | Script type | Scope |
|---|---|---|
| `test_indicator.txt` | Indicator | 947 CHM keywords |
| `test_signal.txt` | Signal | 947 CHM keywords |
| `test_function.txt` | Function | 947 CHM keywords |
| `test_builtins.txt` | Signal | 160 function signatures (150 built-in + 10 custom) |
| `test_syntax.txt` | Signal | Control flow, operators, crosses |
| `test_orders.txt` | Signal | All order combinations + stops |
| `test_declarations.txt` | Signal | Inputs, Variables, Arrays, multi-data |
| `test_plotting.txt` | Indicator | Plots, colors, drawing objects |

**Strategy conversions (6 files, 14 strategies each):**

| File | Target | Library |
|---|---|---|
| `test_strategies.txt` | PowerLanguage (source) | — |
| `test_pine_from_pl.txt` / `test_pl_from_pine.txt` | Pine Script | `ta.*` |
| `test_python_from_pl.txt` | Python | pandas-ta |
| `test_rust_from_pl.txt` | Rust | ta-rs |
| `test_cpp_from_pl.txt` | C++ | TA-Lib |

The 14 strategies cover 39+ indicators: MA crossover, RSI+ATR stop, Bollinger breakout, ADX/CCI multi-indicator, regime filter, EMA momentum, Donchian channel, MACD trailing stop, Stochastic, time filter, DMI/Keltner/SAR, Williams %R/ROC/volatility, money flow/linear regression, and swing detection.

**New function conversions (5 files, 93 built-in + 10 custom functions each):**

| File | Target | Library |
|---|---|---|
| `test_new_functions.txt` | PowerLanguage (compile test) | — |
| `test_pine_new_functions.txt` | Pine Script | `ta.*` |
| `test_python_new_functions.txt` | Python | pandas-ta / TA-Lib |
| `test_rust_new_functions.txt` | Rust | ta-rs |
| `test_cpp_new_functions.txt` | C++ | TA-Lib |

To compile-test: open PowerLanguage Editor, create a new study matching the script type, paste the file contents, press **F3** (Verify). Expected: 0 errors, 0 warnings.

</details>

---

## Attribution

MultiCharts and PowerLanguage are trademarks of MCT Limited. TradingView and Pine Script are trademarks of TradingView, Inc. This plugin is not affiliated with or endorsed by either company.

Third-party library references (no source code redistributed):

| Library | License | Used by |
|---|---|---|
| [ta-rs](https://crates.io/crates/ta) | MIT | Rust conversion |
| [yata](https://crates.io/crates/yata) | Apache-2.0 | Rust conversion (ADX/CCI) |
| [TA-Lib](https://ta-lib.org/) | BSD | C++ conversion |
| [pandas-ta](https://github.com/twopirllc/pandas-ta) | MIT | Python conversion |

See `NOTICE` for full attribution.

## License

MIT — see `LICENSE`.

## Source

https://github.com/KasperChenGH/multicharts-powerlanguage
