# multicharts-powerlanguage

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Version](https://img.shields.io/badge/version-0.3.0-blue.svg)](https://github.com/KasperChenGH/multicharts-powerlanguage)
[![Claude Code Plugin](https://img.shields.io/badge/Claude_Code-plugin-blueviolet.svg)](https://github.com/KasperChenGH/multicharts-powerlanguage)

A Claude Code plugin for [MultiCharts](https://www.multicharts.com/) PowerLanguage — gives Claude expert knowledge of PowerLanguage syntax, 947 keywords, 64 built-in functions, and bidirectional code conversion to [TradingView Pine Script](https://www.tradingview.com/), Python, Rust, and C++. Works on Windows, macOS, and Linux.

**947 keywords · 64 compile-verified functions · 8 auto-activating skills · 4 conversion targets**

## Quick start

```bash
claude /plugin marketplace add KasperChenGH/multicharts-powerlanguage
claude /plugin install multicharts-powerlanguage@multicharts-powerlanguage-dev
```

After install, all 8 skills auto-trigger when relevant — no manual invocation needed. Ask Claude about MultiCharts, PowerLanguage, Pine Script, or any conversion target and the right skill activates.

## Example — code generation

**Prompt:**
> Write a MultiCharts signal that enters long when RSI crosses below 30 and exits when it crosses above 70, with a 2% stop loss.

**Generated PowerLanguage (compiles with 0 errors):**
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

## Example — code conversion

**PowerLanguage input:**
```pascal
Buy ("Entry") 1 Contract Next Bar at Market;
```

| Target | Output |
|---|---|
| **Pine Script** | `strategy.entry("Entry", strategy.long, qty=1)` |
| **Python** | `orders.append(Order("Entry", Side.LONG, OrderType.MARKET, 1))` |
| **Rust** | `orders.push(Order { label: "Entry", side: Side::Long, order_type: OrderType::Market, qty: 1 })` |
| **C++** | `orders.push_back({"Entry", Side::Long, OrderType::Market, 1});` |

## Skills

Eight skills organized into three groups:

### PowerLanguage knowledge (3 skills)

| Skill | What it provides |
|---|---|
| `multicharts-fundamentals` | What MultiCharts is, script types (Indicator / Signal / Function), execution model, multi-data series, order keywords, unique-signal-name compile rule |
| `powerlanguage-syntax` | Declarations, `begin/end` semicolon rule, control flow, bar references, operators, 64 compile-verified built-in function signatures, code-generation gotchas |
| `powerlanguage-keywords-reference` | 947 official keywords across 40 categories — each with signature, parameters, paraphrased description, and wiki link |

### Target language reference (1 skill)

| Skill | What it provides |
|---|---|
| `pinescript-reference` | Pine Script v5 syntax, type system, 15 built-in namespaces (`ta.*`, `strategy.*`, `request.*`, `math.*`, `str.*`, `array.*`, `color.*`, `label.*`, `line.*`, `box.*`, `table.*`, `map.*`, `matrix.*`, `log.*`), alerts, plotting, user-defined functions/types, gotchas |

### Code conversion (4 skills)

Each conversion skill follows the same 4-part structure:

- **Part 0** — target-language scaffold (types, entry point, main loop)
- **Part 1** — concept mapping tables (indicators, order types, data access)
- **Part 2** — semantic gotchas specific to the target language
- **Part 3** — pre/post-conversion checklists (both directions)

| Skill | Direction | Scaffold | Indicator library |
|---|---|---|---|
| `powerlanguage-pinescript-conversion` | PL <-> Pine Script | `strategy()` script | `ta.*` built-ins |
| `powerlanguage-python-conversion` | PL <-> Python | `Strategy(ABC)` with `on_bar` | pandas-ta (primary), TA-Lib (alternative) |
| `powerlanguage-rust-conversion` | PL <-> Rust | `Strategy` trait with `on_bar` | ta-rs (streaming API) |
| `powerlanguage-cpp-conversion` | PL <-> C++ | `Strategy` base class with `on_bar` | TA-Lib (batch API) |

## Project structure

```
multicharts-powerlanguage/
  .claude-plugin/
    plugin.json              # plugin metadata (name, version, author)
    marketplace.json         # marketplace registry entry
  skills/
    multicharts-fundamentals/SKILL.md
    powerlanguage-syntax/SKILL.md
    powerlanguage-keywords-reference/
      SKILL.md
      details/               # 40 category folders, 947 keyword files
    pinescript-reference/SKILL.md
    powerlanguage-pinescript-conversion/SKILL.md
    powerlanguage-python-conversion/SKILL.md
    powerlanguage-rust-conversion/SKILL.md
    powerlanguage-cpp-conversion/SKILL.md
  tests/                     # 14 test files (see below)
  scripts/
    lib/                     # 8 PowerShell modules (build pipeline)
    tests/                   # 10 Pester test files (67 tests)
  package.json               # npm-style version metadata
  NOTICE                     # attribution and trademark notices
  LICENSE                    # MIT
```

## Test suite

### Pester tests (automated)

```powershell
Invoke-Pester scripts/tests/ -Output Detailed
```

10 test files, 67 tests covering frontmatter validation, metadata, keyword parsing, paraphrase quality, and build pipeline correctness.

### Compile tests (manual, maintainer only)

The `tests/` directory contains 14 plain-text source files that exercise keywords and code patterns. PowerLanguage files use unreachable `If False Then Begin … End;` blocks so the compiler verifies syntax without executing anything. They are NOT `.pla` archives — they cannot be imported via File → Import.

| File | Type | What it covers |
|---|---|---|
| `test_indicator.txt` | Indicator | 947 CHM keywords |
| `test_signal.txt` | Signal | 947 CHM keywords |
| `test_function.txt` | Function | 947 CHM keywords |
| `test_builtins.txt` | Signal | 64 built-in function (`.elf`) signatures |
| `test_syntax.txt` | Signal | If/Else, For/While, Switch, Once, operators, crosses over/under |
| `test_orders.txt` | Signal | Buy/Sell/SellShort/BuyToCover x Market/Limit/Stop/Close, SetStopLoss/SetProfitTarget |
| `test_declarations.txt` | Signal | Inputs, Variables, Arrays, IntraBarPersist, multi-data, Value1-99 |
| `test_plotting.txt` | Indicator | Plot1-4, SetPlotColor/Width/Style, TL/Text/Arw drawing |
| `test_strategies.txt` | Signal | 14 mini-strategies combining 39+ indicators, conditions, and orders |
| `test_pine_from_pl.txt` | Pine Script | 14 strategies converted from PL |
| `test_pl_from_pine.txt` | Signal | 14 strategies converted from Pine Script |
| `test_python_from_pl.txt` | Python | 14 strategies converted from PL (pandas-ta) |
| `test_rust_from_pl.txt` | Rust | 14 strategies converted from PL (ta-rs) |
| `test_cpp_from_pl.txt` | C++ | 14 strategies converted from PL (TA-Lib) |

The 14 strategies cover: MA crossover, RSI+ATR stop, Bollinger breakout, multi-indicator (ADX/CCI/BB), regime filter, EMA momentum, Donchian channel, MACD trailing stop, stochastic with switch/for/while, time filter with print/alert, DMI/Keltner/SAR, Williams %R/ROC/volatility, money flow/linear regression, and swing detection.

To manually compile-test a PowerLanguage file: open MultiCharts PowerLanguage Editor, create a new study matching the script type, paste the file contents, and press **F3** (Verify). Expected: 0 errors, 0 warnings.

## How it works

Skills are markdown files with YAML frontmatter (`name` and `description`). Claude reads each plugin's skill descriptions and decides on the fly which to invoke. There are no install-time scripts, no runtime hooks, and no platform-specific tooling.

## Attribution

MultiCharts and PowerLanguage are trademarks of MCT Limited. TradingView and Pine Script are trademarks of TradingView, Inc. This plugin is not affiliated with or endorsed by either company.

The PowerLanguage keyword summaries are original paraphrased descriptions; each links to its official wiki page. The Pine Script reference is hand-curated from general language knowledge and open-source resources — no content was scraped from tradingview.com.

Third-party library references (no source code redistributed):
- [ta-rs](https://crates.io/crates/ta) — MIT-licensed Rust crate (Rust conversion skill)
- [yata](https://crates.io/crates/yata) — Apache-2.0-licensed Rust crate (Rust conversion skill, ADX/CCI)
- [TA-Lib](https://ta-lib.org/) — BSD-licensed C library (C++ conversion skill)
- [pandas-ta](https://github.com/twopirllc/pandas-ta) — MIT-licensed Python library (Python conversion skill)

See `NOTICE` for the full attribution.

## License

MIT — see `LICENSE`.

## Source

https://github.com/KasperChenGH/multicharts-powerlanguage
