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

PL `Next Bar at Market` fills at the **next bar's open**. Pine's `strategy.entry` does this by default (`process_orders_on_close=false`); the Python/Rust/C++ scaffolds queue the order on the signal bar and fill it at the next bar's open.

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

fastMA = XAverage(Close, FastLen);
slowMA = XAverage(Close, SlowLen);
atrVal = AvgTrueRange(ATRLen); { SIMPLE average of TrueRange -- not Wilder }

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
atrVal = ta.sma(ta.tr(true), atrLen)  // PL AvgTrueRange = SIMPLE avg of TrueRange; ta.atr is Wilder
hh10   = ta.highest(high, 10)         // ta.* calls stay at global scope — never inside if/for

// Default process_orders_on_close=false fills at the NEXT bar's open — same as PL "Next Bar at Market"
if ta.crossover(fastMA, slowMA)
    strategy.entry("EMA Cross", strategy.long)

if ta.crossunder(fastMA, slowMA)
    strategy.close("EMA Cross", comment="EMA Exit")

if strategy.position_size > 0
    trailStop = hh10 - trailMult * atrVal
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
        # PL AvgTrueRange = SIMPLE average of TrueRange; default ta.atr is Wilder
        df["atr"] = ta.atr(df["high"], df["low"], df["close"],
                           length=self.atr_len, mamode="sma")

        fills = [None] * len(df)
        pending = None  # order queued on bar N fills on bar N+1 (PL "Next Bar" semantics)
        for i in range(1, len(df)):
            # 1. Fill last bar's queued order at THIS bar
            if pending == "BUY":
                self.position = 1
                fills[i] = ("BUY", df["open"].iloc[i])    # market: next bar's OPEN
            elif pending == "SELL":
                self.position = 0
                fills[i] = ("SELL", df["open"].iloc[i])
            elif pending is not None and df["low"].iloc[i] <= pending[1]:
                self.position = 0                          # sell stop: intrabar at the
                fills[i] = ("TRAIL_STOP",                  # stop price (open if it gaps)
                            min(pending[1], df["open"].iloc[i]))
            pending = None

            fast_prev, fast_curr = df["fast_ma"].iloc[i - 1], df["fast_ma"].iloc[i]
            slow_prev, slow_curr = df["slow_ma"].iloc[i - 1], df["slow_ma"].iloc[i]
            if pd.isna(slow_curr) or pd.isna(df["atr"].iloc[i]):
                continue  # indicator warm-up

            # 2. Evaluate signals on this bar's close → queue for the NEXT bar
            if fast_prev <= slow_prev and fast_curr > slow_curr and self.position == 0:
                pending = "BUY"
            elif fast_prev >= slow_prev and fast_curr < slow_curr and self.position == 1:
                pending = "SELL"
            elif self.position == 1:
                trail = (df["high"].iloc[max(0, i - 9):i + 1].max()
                         - self.trail_mult * df["atr"].iloc[i])
                pending = ("TRAIL_STOP", trail)

        df["fill"] = fills
        return df
```

#### Rust (ta-rs)

```rust
use ta::indicators::{ExponentialMovingAverage, SimpleMovingAverage, TrueRange};
use ta::{DataItem, Next};

enum Pending {
    MarketBuy,
    MarketSell,
    StopSell(f64),
}

struct EmaCrossTrail {
    fast_ema: ExponentialMovingAverage,
    slow_ema: ExponentialMovingAverage,
    tr: TrueRange,
    // PL AvgTrueRange = SMA of TrueRange; ta-rs AverageTrueRange is EMA-based (NOT equivalent)
    atr_sma: SimpleMovingAverage,
    trail_mult: f64,
    position: i32, // 1 = long, 0 = flat
    prev_fast: f64,
    prev_slow: f64,
    highs: Vec<f64>,
    warmup: usize,
    pending: Option<Pending>, // order queued on bar N fills on bar N+1 (PL "Next Bar")
}

impl EmaCrossTrail {
    fn new(fast: usize, slow: usize, atr_len: usize, trail_mult: f64) -> Self {
        Self {
            fast_ema: ExponentialMovingAverage::new(fast).unwrap(),
            slow_ema: ExponentialMovingAverage::new(slow).unwrap(),
            tr: TrueRange::new(),
            atr_sma: SimpleMovingAverage::new(atr_len).unwrap(),
            trail_mult,
            position: 0,
            prev_fast: 0.0,
            prev_slow: 0.0,
            highs: Vec::new(),
            warmup: slow.max(atr_len) + 1,
            pending: None,
        }
    }

    fn on_bar(&mut self, open: f64, high: f64, low: f64, close: f64, volume: f64)
        -> Option<(&'static str, f64)>
    {
        // 1. Fill last bar's queued order at THIS bar
        let fill = match self.pending.take() {
            Some(Pending::MarketBuy)  => { self.position = 1; Some(("BUY", open)) }
            Some(Pending::MarketSell) => { self.position = 0; Some(("SELL", open)) }
            Some(Pending::StopSell(p)) if low <= p => {
                self.position = 0;
                Some(("TRAIL_STOP", p.min(open))) // sell stop: intrabar (open if it gaps)
            }
            _ => None,
        };

        // 2. Update indicators — ta-rs DataItem must come from the builder
        let bar = DataItem::builder()
            .open(open).high(high).low(low).close(close).volume(volume)
            .build().unwrap();
        let fast = self.fast_ema.next(close);
        let slow = self.slow_ema.next(close);
        let atr_val = self.atr_sma.next(self.tr.next(&bar));
        self.highs.push(high);

        // 3. Guard indicator warm-up before any trading logic
        if self.highs.len() < self.warmup {
            self.prev_fast = fast;
            self.prev_slow = slow;
            return fill;
        }

        // 4. Evaluate signals on this bar's close → queue for the NEXT bar
        if self.prev_fast <= self.prev_slow && fast > slow && self.position == 0 {
            self.pending = Some(Pending::MarketBuy);
        } else if self.prev_fast >= self.prev_slow && fast < slow && self.position == 1 {
            self.pending = Some(Pending::MarketSell);
        } else if self.position == 1 {
            let lookback = self.highs.len().saturating_sub(10);
            let highest: f64 = self.highs[lookback..].iter().copied()
                .fold(f64::NEG_INFINITY, f64::max);
            self.pending = Some(Pending::StopSell(highest - self.trail_mult * atr_val));
        }

        self.prev_fast = fast;
        self.prev_slow = slow;
        fill
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
        const std::vector<double>& open,
        const std::vector<double>& high,
        const std::vector<double>& low,
        const std::vector<double>& close)
    {
        TA_Initialize(); // once per process, before any TA_* call
        int n = static_cast<int>(close.size());
        std::vector<double> fast_ma(n), slow_ma(n), tr(n), atr(n);
        int fastBeg, slowBeg, trBeg, atrBeg, trNb, nb;

        TA_EMA(0, n - 1, close.data(), fast_, &fastBeg, &nb, fast_ma.data());
        TA_EMA(0, n - 1, close.data(), slow_, &slowBeg, &nb, slow_ma.data());
        // PL AvgTrueRange = SIMPLE average of TrueRange; TA_ATR is Wilder (NOT equivalent)
        TA_TRANGE(0, n - 1, high.data(), low.data(), close.data(),
                  &trBeg, &trNb, tr.data());
        TA_SMA(0, trNb - 1, tr.data(), atr_len_, &atrBeg, &nb, atr.data());

        // TA-Lib outputs start at index 0 but correspond to input bar outBeg:
        // bar i maps to out[i - outBeg], valid only when i >= outBeg
        int atrOff  = trBeg + atrBeg;
        int warmup  = std::max({fastBeg, slowBeg, atrOff}) + 1;

        std::vector<std::string> signals(n);
        std::string pending;       // order queued on bar N fills on bar N+1 (PL "Next Bar")
        double pendingStop = 0.0;
        for (int i = warmup; i < n; ++i) {
            // 1. Fill last bar's queued order at THIS bar
            if (pending == "BUY") {
                position_ = 1;
                signals[i] = "BUY@" + std::to_string(open[i]);   // market: next bar's OPEN
            } else if (pending == "SELL") {
                position_ = 0;
                signals[i] = "SELL@" + std::to_string(open[i]);
            } else if (pending == "TRAIL_STOP" && low[i] <= pendingStop) {
                position_ = 0;     // sell stop: intrabar at the stop price (open if it gaps)
                signals[i] = "TRAIL_STOP@" + std::to_string(std::min(pendingStop, open[i]));
            }
            pending.clear();

            double f  = fast_ma[i - fastBeg], fPrev = fast_ma[i - 1 - fastBeg];
            double s  = slow_ma[i - slowBeg], sPrev = slow_ma[i - 1 - slowBeg];
            double av = atr[i - atrOff];

            // 2. Evaluate signals on this bar's close → queue for the NEXT bar
            if (fPrev <= sPrev && f > s && position_ == 0) {
                pending = "BUY";
            } else if (fPrev >= sPrev && f < s && position_ == 1) {
                pending = "SELL";
            } else if (position_ == 1) {
                int start = std::max(0, i - 9);
                double highest = *std::max_element(high.begin() + start, high.begin() + i + 1);
                pending = "TRAIL_STOP";
                pendingStop = highest - trail_mult_ * av;
            }
        }
        return signals;
    }
};
```

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
├── tests/                                 # compile-oriented test fixtures
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

Compile-oriented plain-text fixtures in `tests/` exercise keywords and conversion patterns. Keyword-sweep files use unreachable `If False Then Begin … End;` blocks so the compiler checks syntax without executing.

**Keyword coverage:**

| File | Script type | Scope |
|---|---|---|
| `test_indicator.txt` | Indicator | 947 CHM keywords |
| `test_signal.txt` | Signal | 947 CHM keywords |
| `test_function.txt` | Function | Real `RangeRatio` function — `Average(Range, Len)` with return-by-assignment |
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
