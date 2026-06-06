# multicharts-powerlanguage

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Version](https://img.shields.io/badge/version-0.3.0-blue.svg)](https://github.com/KasperChenGH/multicharts-powerlanguage)
[![Claude Code Plugin](https://img.shields.io/badge/Claude_Code-plugin-blueviolet.svg)](https://github.com/KasperChenGH/multicharts-powerlanguage)

A Claude Code plugin for [MultiCharts](https://www.multicharts.com/) PowerLanguage — gives Claude expert knowledge of PowerLanguage syntax, 947 keywords, 65 built-in functions, and bidirectional code conversion to [TradingView Pine Script](https://www.tradingview.com/), Python, Rust, and C++.

**947 keywords · 65 compile-verified functions · 8 auto-activating skills · 4 conversion targets**

---

## Install

```bash
claude /plugin marketplace add KasperChenGH/multicharts-powerlanguage
claude /plugin install multicharts-powerlanguage@multicharts-powerlanguage-dev
```

All 8 skills auto-trigger when relevant — no manual invocation needed. Works on Windows, macOS, and Linux.

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

### Code conversion

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

---

## Skills overview

### PowerLanguage knowledge

| Skill | Description |
|---|---|
| `multicharts-fundamentals` | Script types (Indicator / Signal / Function), execution model, multi-data series, order keywords |
| `powerlanguage-syntax` | Declarations, `begin/end` semicolon rule, control flow, bar references, 65 built-in function signatures, code-generation gotchas |
| `powerlanguage-keywords-reference` | 947 keywords across 40 categories — signature, parameters, description, and wiki link for each |

### Target language reference

| Skill | Description |
|---|---|
| `pinescript-reference` | Pine Script v5 — type system, 15 built-in namespaces (`ta.*`, `strategy.*`, `request.*`, etc.), alerts, plotting, gotchas |

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
│   ├── pinescript-reference/              # Pine Script v5 reference
│   ├── powerlanguage-pinescript-conversion/
│   ├── powerlanguage-python-conversion/
│   ├── powerlanguage-rust-conversion/
│   └── powerlanguage-cpp-conversion/
├── tests/                                 # 14 compile-test files
├── scripts/
│   ├── lib/                               # 8 PowerShell build modules
│   └── tests/                             # 10 Pester test files (67 tests)
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

10 test files, 67 tests — frontmatter validation, metadata consistency, keyword parsing, paraphrase quality, build pipeline.

### Manual compile tests

14 plain-text files in `tests/` exercise keywords and conversion patterns. PowerLanguage files use unreachable `If False Then Begin … End;` blocks so the compiler checks syntax without executing.

**Keyword coverage (8 files):**

| File | Script type | Scope |
|---|---|---|
| `test_indicator.txt` | Indicator | 947 CHM keywords |
| `test_signal.txt` | Signal | 947 CHM keywords |
| `test_function.txt` | Function | 947 CHM keywords |
| `test_builtins.txt` | Signal | 65 built-in function signatures |
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
